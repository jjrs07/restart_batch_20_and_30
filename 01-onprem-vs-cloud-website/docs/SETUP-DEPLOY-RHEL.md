# Setting Up and Running `deploy.sh` — Student Guide (RHEL VM)

**Goal:** get the `restart-demo` project onto your own RHEL-family VM and run
the on-premise deploy, so you see the app live on Apache (`httpd`) + PHP with
your VM acting as "the server."

**Time:** ~10 minutes

**Works on:** RHEL, CentOS Stream, Rocky Linux, or AlmaLinux — anything using
`dnf`/`yum`. If you're on Ubuntu/WSL instead, use `docs/SETUP-DEPLOY-WSL.md`.

---

## What you need before you start

- A RHEL-family VM (VirtualBox, VMware, or a cloud VM) with network access.
- `sudo` access on that machine.
- Internet access (to clone the repo and install packages).

---

## Step 1 — Confirm you're on a RHEL-family distro with sudo

```bash
cat /etc/os-release | grep -i pretty
sudo -v
```

The first command should mention **Red Hat**, **CentOS**, **Rocky**, or
**AlmaLinux**. The second will ask for your password once — that confirms you
can `sudo`.

---

## Step 2 — Install git (if it isn't already there)

```bash
sudo dnf install -y git
```

> On older systems without `dnf`, use `sudo yum install -y git` instead —
> `deploy.sh` itself falls back to `yum` automatically if `dnf` isn't found.

---

## Step 3 — Clone the project

```bash
cd ~
git clone https://github.com/jjrs07/restart_batch_20_and_30.git restart-demo
cd restart-demo
```

You should now see this structure:

```
restart-demo/
├── public/            # the app (frontend + PHP backend)
├── deploy/deploy.sh   # installs Apache+PHP and deploys the app
└── README.md
```

---

## Step 4 — Make the deploy script executable

```bash
chmod +x deploy/deploy.sh
```

---

## Step 5 — Run the on-premise deploy

```bash
sudo ./deploy/deploy.sh onprem
```

This will:

1. Detect your platform (`dnf`/`yum` → uses the `httpd` service).
2. Install **Apache (`httpd`)** and **PHP**.
3. Copy the app from `public/` into `/var/www/html`.
4. Write an Apache config (`/etc/httpd/conf.d/restart-demo.conf`) that tags
   this instance as `"onprem"`.
5. Start (or restart) `httpd`.

It will prompt for your `sudo` password once, then print progress for each
step. It takes under a minute.

---

## Step 6 — Open the firewall for HTTP

RHEL-family distros ship with **`firewalld` enabled by default**, unlike
WSL/Ubuntu. Even though Apache is now running, nothing outside `localhost`
can reach it until you open port 80:

```bash
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload
```

You only need to do this once — it's not part of `deploy.sh` itself.

---

## Step 7 — Verify it worked

Check the backend directly from the terminal:

```bash
curl -s http://localhost/api/info.php
```

You should get back JSON that includes `"env": "onprem"`.

Then open a browser to **http://\<VM-IP\>/** (find the IP with `hostname -I`) —
either from the VM itself, or from your host machine if the VM's network is
bridged/NAT with port access. You should see the ReStart demo page with an
**On-Premise** badge.

---

## Troubleshooting

- **Page loads on the VM but not from your host machine** — almost always the
  firewall (Step 6) or the VM's network mode (needs bridged, or NAT with port
  80 forwarded).
- **"Port 80 already in use" / Apache fails to start** — run
  `sudo ss -tlnp | grep :80` to see what's holding the port.
- **`curl: (7) Failed to connect`** — Apache isn't running yet. Run
  `sudo systemctl status httpd` to check.
- **403 Forbidden with nothing obviously wrong in the config** — check
  **SELinux**, which is enforcing by default on RHEL. The standard
  `/var/www/html` docroot already carries the right `httpd_sys_content_t`
  label, but if you moved files around manually, check recent denials with:
  ```bash
  sudo ausearch -m avc -ts recent
  ```
- **Want to start over?** See the "RHEL-family" section of
  `docs/UNINSTALL-APACHE.md` in this repo, then re-run Step 5.

---

## What's next

Once this works, `docs/EC2-DEPLOYMENT-GUIDE.md` walks through deploying the
*same* app to an AWS EC2 instance with `sudo ./deploy/deploy.sh cloud`, so you
can compare on-premise vs. cloud side by side.
