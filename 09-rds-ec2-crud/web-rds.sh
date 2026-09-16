#!/bin/bash
################################################################################
# EC2 User Data - LAMP CRUD app on Amazon Linux 2023 backed by Amazon RDS MySQL
#
# Paste this into: Launch Instance > Advanced details > User data
#
# Prereqs before launching:
#   1. RDS MySQL instance already created and Available.
#   2. RDS security group INBOUND allows TCP 3306 FROM the EC2 instance's
#      security group (SG-to-SG reference, NOT 0.0.0.0/0).
#   3. EC2 security group INBOUND allows TCP 80 from your IP (or an ALB SG).
#   4. EC2 and RDS in the same VPC. EC2 in a public subnet w/ IGW if you want
#      direct browser access; RDS stays in private subnets.
#   5. Edit the CONFIG block below with your real RDS endpoint and credentials.
#
# Log output lands in /var/log/cloud-init-output.log on the instance.
################################################################################

set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

############################### CONFIG #########################################
# Replace these with your values. Endpoint = the RDS "Endpoint" (no :3306).
DB_HOST="YOUR-RDS-ENDPOINT-HERE"
DB_PORT="3306"
DB_USER="admin"
DB_PASS="YOUR-RDS-PASSWORD-HERE"
DB_NAME="restart_db"
################################################################################

echo "=== [1/6] Updating packages and installing LAMP stack ==="
dnf -y update
# php-mysqlnd is the PDO/MySQL driver. mariadb105 gives us the 'mysql' CLI,
# which AL2023 does NOT ship by default (common gotcha vs AL2).
dnf -y install httpd php php-mysqlnd php-json mariadb105

echo "=== [2/6] Writing DB config OUTSIDE the web root ==="
# /var/www/inc is not served by Apache, so a PHP misconfiguration cannot leak
# this file as plain text the way it would from /var/www/html.
install -d -m 0750 -o root -g apache /var/www/inc
cat > /var/www/inc/dbconfig.php <<EOF
<?php
define('DB_HOST', '${DB_HOST}');
define('DB_PORT', ${DB_PORT});
define('DB_USER', '${DB_USER}');
define('DB_PASS', '${DB_PASS}');
define('DB_NAME', '${DB_NAME}');
EOF
chown root:apache /var/www/inc/dbconfig.php
chmod 0640 /var/www/inc/dbconfig.php

echo "=== [3/6] Waiting for RDS to accept connections ==="
# RDS can still be flipping to Available while the EC2 boots. Retry instead of
# failing the whole bootstrap on a race.
for i in $(seq 1 30); do
  if mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" -e "SELECT 1" >/dev/null 2>&1; then
    echo "RDS reachable after ${i} attempt(s)."
    break
  fi
  echo "Attempt ${i}: RDS not reachable yet, sleeping 10s..."
  sleep 10
  if [ "${i}" -eq 30 ]; then
    echo "ERROR: Could not reach RDS after 5 minutes."
    echo "Check: RDS SG inbound 3306 from the EC2 SG, same VPC, correct endpoint, correct password."
    exit 1
  fi
done

echo "=== [4/6] Creating schema ==="
mysql -h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" -p"${DB_PASS}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE \`${DB_NAME}\`;
CREATE TABLE IF NOT EXISTS profiles (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name   VARCHAR(100) NOT NULL,
  email       VARCHAR(255) NOT NULL,
  role        VARCHAR(60)  NOT NULL DEFAULT 'Student',
  created_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_profiles_email (email)
) ENGINE=InnoDB;
SQL

echo "=== [5/6] Deploying the application ==="
# Quoted heredoc ('PHPAPP') so bash does not touch PHP's \$variables.
cat > /var/www/html/index.php <<'PHPAPP'
<?php
declare(strict_types=1);
require_once '/var/www/inc/dbconfig.php';

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
                       DB_HOST, DB_PORT, DB_NAME);
        // ERRMODE_EXCEPTION so failures are loud, EMULATE_PREPARES=false so we
        // get real server-side prepared statements (true parameter binding).
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }
    return $pdo;
}

function h(?string $s): string {
    return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8');
}

function redirect(string $msg, string $type = 'ok'): never {
    header('Location: index.php?msg=' . urlencode($msg) . '&type=' . $type);
    exit;
}

// ---------------------------------------------------------------------------
// Write operations. POST-only, then redirect (POST/Redirect/GET) so a browser
// refresh does not replay the last insert.
// ---------------------------------------------------------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    try {
        switch ($action) {
            case 'create':
                $stmt = db()->prepare(
                    'INSERT INTO profiles (full_name, email, role) VALUES (?, ?, ?)'
                );
                $stmt->execute([
                    trim($_POST['full_name'] ?? ''),
                    trim($_POST['email'] ?? ''),
                    trim($_POST['role'] ?? 'Student'),
                ]);
                redirect('Profile added.');

            case 'update':
                $stmt = db()->prepare(
                    'UPDATE profiles SET full_name = ?, email = ?, role = ? WHERE id = ?'
                );
                $stmt->execute([
                    trim($_POST['full_name'] ?? ''),
                    trim($_POST['email'] ?? ''),
                    trim($_POST['role'] ?? 'Student'),
                    (int)($_POST['id'] ?? 0),
                ]);
                redirect('Profile updated.');

            case 'delete':
                $stmt = db()->prepare('DELETE FROM profiles WHERE id = ?');
                $stmt->execute([(int)($_POST['id'] ?? 0)]);
                redirect('Profile deleted.');

            default:
                redirect('Unknown action.', 'err');
        }
    } catch (PDOException $e) {
        // 23000 = integrity constraint, almost always the UNIQUE email here.
        $msg = ($e->getCode() === '23000')
            ? 'That email already exists.'
            : 'Database error: ' . $e->getMessage();
        redirect($msg, 'err');
    }
}

// ---------------------------------------------------------------------------
// Read
// ---------------------------------------------------------------------------
$editing = null;
if (isset($_GET['edit'])) {
    $stmt = db()->prepare('SELECT * FROM profiles WHERE id = ?');
    $stmt->execute([(int)$_GET['edit']]);
    $editing = $stmt->fetch() ?: null;
}
$rows     = db()->query('SELECT * FROM profiles ORDER BY id DESC')->fetchAll();
$hostname = gethostname();
$flash    = $_GET['msg']  ?? '';
$flashType= ($_GET['type'] ?? 'ok') === 'err' ? 'err' : 'ok';
?>
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Profile Manager &middot; EC2 + RDS Demo</title>
<style>
  :root { --line:#e3e6ea; --ink:#1b2430; --muted:#6b7684; --accent:#ff9900; --bad:#c0392b; --good:#1e8449; }
  * { box-sizing:border-box; }
  body { margin:0; font:15px/1.5 system-ui,-apple-system,Segoe UI,Roboto,sans-serif; color:var(--ink); background:#f5f7fa; }
  header { background:#232f3e; color:#fff; padding:18px 24px; }
  header h1 { margin:0; font-size:19px; font-weight:600; }
  header p { margin:4px 0 0; font-size:13px; color:#b9c2cc; }
  main { max-width:960px; margin:24px auto; padding:0 16px; }
  .card { background:#fff; border:1px solid var(--line); border-radius:8px; padding:20px; margin-bottom:20px; }
  .card h2 { margin:0 0 14px; font-size:15px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }
  .grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:12px; }
  label { display:block; font-size:12px; font-weight:600; color:var(--muted); margin-bottom:4px; }
  input,select { width:100%; padding:9px 10px; border:1px solid var(--line); border-radius:6px; font-size:14px; }
  input:focus,select:focus { outline:2px solid var(--accent); outline-offset:-1px; }
  .actions { margin-top:14px; display:flex; gap:8px; }
  button { padding:9px 16px; border:0; border-radius:6px; font-size:14px; font-weight:600; cursor:pointer; background:var(--accent); color:#1b2430; }
  button.ghost { background:#eef1f5; color:var(--ink); }
  button.danger { background:#fdecea; color:var(--bad); }
  table { width:100%; border-collapse:collapse; }
  th,td { text-align:left; padding:10px 8px; border-bottom:1px solid var(--line); font-size:14px; vertical-align:middle; }
  th { font-size:11px; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }
  td.num { color:var(--muted); font-variant-numeric:tabular-nums; }
  .row-actions { display:flex; gap:6px; }
  .row-actions button { padding:5px 10px; font-size:12px; }
  .flash { padding:11px 14px; border-radius:6px; margin-bottom:20px; font-size:14px; }
  .flash.ok  { background:#e8f6ee; color:var(--good); border:1px solid #bfe3cd; }
  .flash.err { background:#fdecea; color:var(--bad);  border:1px solid #f5c6c0; }
  .empty { color:var(--muted); padding:18px 8px; }
  footer { max-width:960px; margin:0 auto 40px; padding:0 16px; font-size:12px; color:var(--muted); }
  code { background:#eef1f5; padding:1px 5px; border-radius:4px; }
</style>
</head>
<body>
<header>
  <h1>Profile Manager</h1>
  <p>Served by EC2 <code style="background:#36455a;color:#fff"><?= h($hostname) ?></code>
     &middot; data stored in RDS MySQL <code style="background:#36455a;color:#fff"><?= h(DB_HOST) ?></code></p>
</header>

<main>
<?php if ($flash !== ''): ?>
  <div class="flash <?= $flashType ?>"><?= h($flash) ?></div>
<?php endif; ?>

  <div class="card">
    <h2><?= $editing ? 'Edit profile #' . (int)$editing['id'] : 'Add a profile' ?></h2>
    <form method="post" action="index.php">
      <input type="hidden" name="action" value="<?= $editing ? 'update' : 'create' ?>">
      <?php if ($editing): ?>
        <input type="hidden" name="id" value="<?= (int)$editing['id'] ?>">
      <?php endif; ?>
      <div class="grid">
        <div>
          <label for="full_name">Full name</label>
          <input id="full_name" name="full_name" required maxlength="100"
                 value="<?= h($editing['full_name'] ?? '') ?>" placeholder="Juan dela Cruz">
        </div>
        <div>
          <label for="email">Email</label>
          <input id="email" name="email" type="email" required maxlength="255"
                 value="<?= h($editing['email'] ?? '') ?>" placeholder="juan@example.com">
        </div>
        <div>
          <label for="role">Role</label>
          <select id="role" name="role">
            <?php foreach (['Student','Instructor','Admin','Guest'] as $r): ?>
              <option value="<?= $r ?>" <?= (($editing['role'] ?? '') === $r) ? 'selected' : '' ?>><?= $r ?></option>
            <?php endforeach; ?>
          </select>
        </div>
      </div>
      <div class="actions">
        <button type="submit"><?= $editing ? 'Save changes' : 'Add profile' ?></button>
        <?php if ($editing): ?>
          <button type="button" class="ghost" onclick="location.href='index.php'">Cancel</button>
        <?php endif; ?>
      </div>
    </form>
  </div>

  <div class="card">
    <h2>Profiles (<?= count($rows) ?>)</h2>
    <?php if (!$rows): ?>
      <p class="empty">No profiles yet. Add one above &mdash; it gets written straight to RDS.</p>
    <?php else: ?>
    <table>
      <thead>
        <tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th><th>Created</th><th></th></tr>
      </thead>
      <tbody>
      <?php foreach ($rows as $r): ?>
        <tr>
          <td class="num"><?= (int)$r['id'] ?></td>
          <td><?= h($r['full_name']) ?></td>
          <td><?= h($r['email']) ?></td>
          <td><?= h($r['role']) ?></td>
          <td class="num"><?= h($r['created_at']) ?></td>
          <td>
            <div class="row-actions">
              <button type="button" class="ghost"
                      onclick="location.href='index.php?edit=<?= (int)$r['id'] ?>'">Edit</button>
              <form method="post" action="index.php"
                    onsubmit="return confirm('Delete <?= h($r['full_name']) ?>?');">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<?= (int)$r['id'] ?>">
                <button type="submit" class="danger">Delete</button>
              </form>
            </div>
          </td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
    <?php endif; ?>
  </div>
</main>

<footer>
  Lab app. Reload after adding a row, then terminate this EC2 and launch a new one
  from the same user data &mdash; the data survives, because it lives in RDS, not on the instance.
</footer>
</body>
</html>
PHPAPP

# Health endpoint - returns 200 only if the DB round-trips. Point an ALB target
# group at /health.php to demo real health checking instead of "is port 80 open".
cat > /var/www/html/health.php <<'PHPHEALTH'
<?php
require_once '/var/www/inc/dbconfig.php';
header('Content-Type: application/json');
try {
    $pdo = new PDO(
        sprintf('mysql:host=%s;port=%d;dbname=%s', DB_HOST, DB_PORT, DB_NAME),
        DB_USER, DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_TIMEOUT => 3]
    );
    $pdo->query('SELECT 1');
    echo json_encode(['status' => 'healthy', 'host' => gethostname()]);
} catch (Throwable $e) {
    http_response_code(503);
    echo json_encode(['status' => 'unhealthy', 'host' => gethostname()]);
}
PHPHEALTH

# Remove the default AL2023 welcome page so index.php is what loads at /
rm -f /etc/httpd/conf.d/welcome.conf
chown -R root:apache /var/www/html
chmod -R 0750 /var/www/html

echo "=== [6/6] Starting Apache ==="
# Only matters if SELinux is enforcing; harmless no-op otherwise.
if command -v setsebool >/dev/null 2>&1; then
  setsebool -P httpd_can_network_connect 1 || true
fi

systemctl enable --now httpd
systemctl is-active --quiet httpd && echo "Apache is running."

echo "=== BOOTSTRAP COMPLETE ==="
echo "Open: http://$(curl -s -H "X-aws-ec2-metadata-token: $(curl -s -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 60')" http://169.254.169.254/latest/meta-data/public-ipv4)/"