# Setting Up and Running `deploy.sh` — Student Guide (WSL / Ubuntu VM)

**Goal:** get the `restart-demo` project onto your own machine and run the
on-premise deploy, so you see the app live on Apache + PHP with your machine
acting as "the server."

**Time:** ~10 minutes

**Works on:** WSL (Windows Subsystem for Linux, Ubuntu) **or** a plain Ubuntu VM
— the steps are identical either way, since both are just Ubuntu underneath.

---

## What you need before you start

- A Ubuntu-based terminal: either WSL on Windows, or an Ubuntu VM (VirtualBox,
  VMware, etc.) with network access.
- `sudo` access on that machine.
- Internet access (to clone the repo and install packages).

---

## Step 1 — Confirm you're on Ubuntu/Debian with sudo

```bash
cat /etc/os-release | grep -i pretty
sudo -v
```

The first command should mention **Ubuntu** or **Debian**. The second will ask
for your password once — that confirms you can `sudo`.

> If you're on WSL and don't have a Linux distro installed yet, open PowerShell
> as Administrator and run `wsl --install -d Ubuntu`, reboot if prompted, then
> open "Ubuntu" from the Start menu and create your Unix username/password.

---

## Step 2 — Install git (if it isn't already there)

```bash
sudo apt-get update -y
sudo apt-get install -y git
```

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

1. Detect your platform (Ubuntu → uses `apt-get` and the `apache2` service).
2. Install **Apache** and **PHP**.
3. Copy the app from `public/` into `/var/www/html`.
4. Write an Apache config that tags this instance as `"onprem"`.
5. Start (or restart) Apache.

It will prompt for your `sudo` password once, then print progress for each
step. It takes under a minute.

---

## Step 6 — Verify it worked

Check the backend directly from the terminal:

```bash
curl -s http://localhost/api/info.php
```

You should get back JSON that includes `"env": "onprem"`.

Then open a browser:

- **WSL users:** open **http://localhost/** in your normal Windows browser —
  WSL forwards `localhost` automatically.
- **Ubuntu VM users:** open **http://localhost/** inside the VM's own browser,
  or use the VM's IP address (`hostname -I`) from your host machine's browser
  if the VM's network is set to bridged/NAT with port access.

You should see the ReStart demo page with an **On-Premise** badge.

---

## Troubleshooting

- **"Port 80 already in use" / Apache fails to start** — something else is
  already listening on port 80 (maybe a previous install, or IIS on Windows
  competing on the same port in some WSL networking setups). Run
  `sudo apache2ctl -S` to check Apache's own config, or
  `sudo ss -tlnp | grep :80` to see what's holding the port.
- **`curl: (7) Failed to connect`** — Apache isn't running yet. Run
  `sudo systemctl status apache2` (or `sudo service apache2 status` if there's
  no systemd) to check.
- **Nothing loads in the Windows browser (WSL only)** — confirm you're on
  **WSL 2** (`wsl -l -v` from PowerShell) and that no VPN/firewall is blocking
  local traffic. Try `http://127.0.0.1/` as well.
- **Want to start over?** See the "Ubuntu / Debian (WSL)" section of
  `docs/UNINSTALL-APACHE.md` in this repo, then re-run Step 5.

---

## What's next

Once this works, `docs/EC2-DEPLOYMENT-GUIDE.md` walks through deploying the
*same* app to an AWS EC2 instance with `sudo ./deploy/deploy.sh cloud`, so you
can compare on-premise vs. cloud side by side.
