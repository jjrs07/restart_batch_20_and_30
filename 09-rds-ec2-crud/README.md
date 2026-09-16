# Amazon RDS with EC2 — Persistent CRUD Web Application

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 75–90 minutes<br>
**Format:** Independent, self-paced AWS Management Console activity<br>
**Region:** `us-west-2` (Oregon), or the Region assigned by your instructor

> **Important:** This lab creates billable AWS resources. Use a sandbox account,
> keep the lab short, and complete the cleanup section before you leave.

This lab connects an Amazon Linux 2023 EC2 instance to an Amazon RDS for MySQL
database. The EC2 user-data script installs Apache, PHP, and the MySQL client;
creates a `profiles` table in RDS; and deploys a small CRUD application.

The important design change is that the application server is disposable while
the data is persistent:

```text
Browser
   |
   | HTTP :80
   v
EC2: Apache + PHP + user-data bootstrap
   |
   | MySQL :3306, allowed by security-group reference
   v
RDS for MySQL: restart_db.profiles
```

## Learning Objectives

By the end of this lab, you will be able to:

1. Explain the difference between compute storage and managed database storage.
2. Deploy an RDS for MySQL instance in the same VPC as an EC2 instance.
3. Allow database traffic with a security-group-to-security-group rule.
4. Use EC2 user data to install a LAMP stack and initialize a database schema.
5. Verify CRUD operations through a PHP application backed by RDS.
6. Prove that data survives when the EC2 instance is replaced.
7. Troubleshoot common DNS, security-group, credentials, and bootstrap failures.

## Before You Start

You need:

- An AWS sandbox account with permission to create and delete EC2, RDS, and
  security-group resources.
- A key pair that lets you connect to Amazon Linux 2023, if you want SSH access
  for troubleshooting.
- A laptop with a web browser and an SSH client.
- The [`web-rds.sh`](web-rds.sh) user-data file supplied with this lab.

> **Credential safety:** The sample file contains database credentials. Replace
> every sample password before launching an instance, and do not commit a file
> containing a real password. For a production design, retrieve credentials from
> AWS Secrets Manager or another approved secret store instead of embedding them
> in user data.

## Part 0 — Prepare the Network Rules

Use one VPC and one Region for both resources. The simplest classroom setup is
the default VPC with a public subnet for EC2. RDS should remain private.

### 1. Create the EC2 security group

In **EC2 → Security Groups**, create a group named something like
`rds-demo-ec2-sg` in your chosen VPC.

Add these inbound rules:

| Type | Port | Source | Purpose |
|---|---:|---|---|
| HTTP | 80 | My IP, or `0.0.0.0/0` for a short classroom demo | Browser access |
| SSH | 22 | My IP (`your-ip/32`) | Optional troubleshooting |

Do not add an inbound rule for port `3306` to this group.

### 2. Create the RDS security group

Create a second group named `rds-demo-db-sg` in the same VPC.

Add exactly this inbound rule:

| Type | Port | Source | Purpose |
|---|---:|---|---|
| MySQL/Aurora | 3306 | **Custom → `rds-demo-ec2-sg`** | EC2-to-RDS traffic |

Choose the EC2 security group as the source, not an IP address and not
`0.0.0.0/0`. This rule means that an instance carrying the EC2 group may connect
to the database, even if the instance's public IP changes.

> **Common mistake:** Selecting the RDS group as its own source does not allow
> the EC2 instance to connect. The source must be the EC2 security group.

## Part 1 — Create the RDS Database

Open **RDS → Databases → Create database** and choose:

| Setting | Value |
|---|---|
| Creation method | Standard create |
| Engine | MySQL |
| Version | A current MySQL 8.0 version permitted by the account |
| Template | Free tier, if available |
| DB instance identifier | `rds-demo-db` |
| Master username | `admin` |
| Master password | A new password stored securely; do not use the example password |
| Instance class | Smallest permitted burstable class |
| Storage | Small encrypted `gp3` volume |
| Availability | Single-AZ for this disposable lab |
| VPC | The same VPC used for the EC2 security group |
| Public access | **No** |
| VPC security group | Choose `rds-demo-db-sg` |
| Initial database name | Leave blank; the script creates `restart_db` |
| Deletion protection | Off for this disposable lab |
| Backup retention | Minimum permitted value |

Create the database and wait until its status is **Available**. Copy its
**Endpoint** from the Connectivity and security section. Copy only the hostname;
do not append `:3306`.

**Checkpoint:** The endpoint should look similar to:

```text
rds-demo-db.abc123.us-west-2.rds.amazonaws.com
```

## Part 2 — Prepare the User Data

Make a private working copy of the supplied script. From the repository root:

```bash
cp 09-rds-ec2-crud/web-rds.sh /tmp/web-rds-lab.sh
chmod 600 /tmp/web-rds-lab.sh
```

Edit `/tmp/web-rds-lab.sh` and change only the configuration values near the top:

```bash
DB_HOST="YOUR_RDS_ENDPOINT"
DB_PORT="3306"
DB_USER="admin"
DB_PASS="YOUR_RDS_MASTER_PASSWORD"
DB_NAME="restart_db"
```

Use the same master username and password configured on RDS. Keep the endpoint
unquoted as shown by the RDS console and do not add a port to `DB_HOST`.

> **Teaching point:** User data runs on the EC2 instance during its first boot.
> It installs packages, writes the PHP configuration outside the web root,
> waits for RDS, creates the schema, and starts Apache. It does not make the
> EC2 instance the database; the rows live in RDS.

## Part 3 — Launch EC2 with User Data

In **EC2 → Instances → Launch instance**, choose:

| Setting | Value |
|---|---|
| Name | `rds-demo-web` |
| AMI | Amazon Linux 2023, 64-bit x86 |
| Instance type | Smallest permitted burstable class |
| Key pair | Your lab key pair |
| VPC/subnet | Same VPC as RDS; use a public subnet |
| Auto-assign public IP | Enabled |
| Security group | Select `rds-demo-ec2-sg` |
| Storage | Small encrypted `gp3` root volume |

Expand **Advanced details**, paste the complete contents of your private
`/tmp/web-rds-lab.sh` file into **User data**, and launch the instance.

Wait for **Running** and both status checks to pass. User data may take several
minutes because it runs a package update and waits for RDS to accept connections.

**Checkpoint:** In the instance's **Actions → Monitor and troubleshoot → Get
system log**, or through SSH, look for:

```text
RDS reachable after ... attempt(s).
Apache is running.
=== BOOTSTRAP COMPLETE ===
```

If the instance has a public IPv4 address, open:

```text
http://YOUR_EC2_PUBLIC_IP/
```

The page should show **Profile Manager**, the EC2 hostname, and the RDS host.

## Part 4 — Exercise the CRUD Application

Use the form to add a profile with a name, email, and role. Then verify each
operation:

1. **Create:** Add a profile and confirm it appears in the table.
2. **Read:** Refresh the page and confirm the row remains.
3. **Update:** Choose **Edit**, change the role, and save.
4. **Delete:** Remove the profile and confirm it disappears.
5. **Unique constraint:** Add the same email twice and observe the duplicate
   email error.

The application uses prepared statements for writes and HTML escaping for values
rendered in the page. The health endpoint is available at:

```text
http://YOUR_EC2_PUBLIC_IP/health.php
```

It should return JSON with `"status":"healthy"` when EC2 can reach RDS.

## Part 5 — Prove Persistence Across EC2 Replacement

1. Add a profile and note its name and email.
2. Terminate the EC2 instance. Do not delete the RDS database.
3. Launch a second EC2 instance with the same user data and security group.
4. Wait for the bootstrap to finish and open the second instance's public IP.
5. Confirm the profile created on the first instance is still present.

**Conclusion:** The web server was replaced, but the row survived because it was
stored in RDS. This is the basic separation between stateless compute and
persistent data services.

## Troubleshooting

### The page does not load

- Confirm the EC2 instance has a public IPv4 address.
- Confirm the EC2 security group allows HTTP on port 80 from your current IP.
- Confirm Apache is active: `sudo systemctl status httpd`.
- Check bootstrap output: `sudo tail -n 100 /var/log/user-data.log`.

### User data says RDS is not reachable

- Confirm EC2 and RDS are in the same VPC.
- Confirm the RDS security group allows TCP 3306 from `rds-demo-ec2-sg`.
- Confirm the endpoint is copied exactly and has no `:3306` suffix.
- Confirm the RDS status is **Available**.
- Confirm the EC2 subnet route and network ACLs allow the connection.

### Access denied for user `admin`

- Check the username and password in the private user-data copy.
- Do not confuse the RDS identifier with the RDS endpoint.
- If the password was exposed, rotate it in RDS and update the user data before
  launching another instance.

### The page shows a database error after bootstrap

- Check that the schema step completed in `/var/log/user-data.log`.
- Confirm `restart_db` exists and the `profiles` table was created.
- Use `/health.php` to separate an Apache problem from a database connectivity
  problem.

## Part 6 — Clean Up

Delete resources in this order:

1. Terminate every EC2 instance created for this lab.
2. In RDS, delete `rds-demo-db`.
3. Choose **Skip final snapshot** only for this disposable classroom database.
4. Delete `rds-demo-db-sg` after RDS finishes deleting.
5. Delete `rds-demo-ec2-sg` after the EC2 instances are gone.
6. Remove local temporary files containing credentials:

```bash
rm -f /tmp/web-rds-lab.sh
```

Do not delete a production database or choose **Skip final snapshot** outside a
disposable lab.

## Quick Reference Card

- RDS stores the data; EC2 runs the application.
- RDS port `3306` should allow the EC2 security group, not the public internet.
- RDS endpoint is a hostname; the port is configured separately as `3306`.
- User data runs during first boot and its output is available in
  `/var/log/user-data.log` and `/var/log/cloud-init-output.log`.
- A successful `health.php` response proves the application can round-trip to
  the database.

## Self-Check Questions

1. Why should the RDS security group reference the EC2 security group instead of
   allowing `0.0.0.0/0` on port 3306?
2. What happens to the rows when the EC2 instance is terminated?
3. Why does the user-data script wait before creating the schema?
4. Which security group controls traffic from EC2 to RDS?
5. What evidence would distinguish an HTTP security-group problem from an RDS
   connectivity problem?

---

*AWS re/Start Batch 29 and 30 — Amazon RDS with EC2 Hands-On Lab*