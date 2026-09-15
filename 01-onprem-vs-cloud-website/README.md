# ReStart Deploy Demo — On-Prem vs Cloud

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 60–90 minutes<br>
**Format:** Independent, self-paced Linux terminal and AWS Management Console activity<br>
**Region:** `us-east-2` (Ohio) for the EC2 deployment

One identical web app, deployed to **two environments** so students can *see* that
deployment is about the **environment**, not the code.

- **On-Premise** → your **WSL** machine or a **RHEL-family VM** stands in for a
  server you own and operate.
- **Cloud** → an **AWS EC2** instance you rent.

Both run the **same files** on **Apache + PHP**. The only difference is one Apache
setting (`DEPLOY_ENV`) that the deploy script injects. The page reports, live, which
environment served the request.

```
restart-demo/
├── public/                 # the whole app (identical in both environments)
│   ├── index.html          #   frontend
│   ├── assets/style.css
│   ├── assets/app.js       #   asks the backend "where am I running?"
│   └── api/info.php         #   tiny backend: reports env, host, time, hit count
├── deploy/deploy.sh        # installs Apache+PHP, deploys, sets onprem|cloud
└── README.md
```

---

## 1) On-Premise deploy (WSL or RHEL VM) — the real thing

> **Before you run `deploy.sh`:** there's a short one-time manual setup per
> platform (cloning the repo, and on RHEL, opening the firewall) — follow the
> full step-by-step guide for your machine before jumping to the command below:
> - **WSL / Ubuntu VM:** [`docs/SETUP-DEPLOY-WSL.md`](docs/SETUP-DEPLOY-WSL.md)
> - **RHEL / CentOS / Rocky / AlmaLinux VM:** [`docs/SETUP-DEPLOY-RHEL.md`](docs/SETUP-DEPLOY-RHEL.md)

Once that's done, from your terminal:

```bash
cd ~/restart-demo
sudo ./deploy/deploy.sh onprem
```

It will prompt for your password, then install Apache + PHP, copy the app to
`/var/www/html`, and start Apache. When it finishes:

```bash
curl -s http://localhost/api/info.php     # see the JSON the frontend reads
```

Open **http://localhost/** in your browser. The badge shows **On-Premise**.

**Teaching point:** *you* just installed and configured the server by hand. You own
the box, the patches, and the uptime.

---

## 2) Cloud deploy (AWS EC2) — the same app, rented hardware

1. Launch an EC2 instance (Amazon Linux 2023, `t2.micro` is fine).
2. In its **security group**, allow inbound **HTTP (port 80)** from anywhere, and
   **SSH (port 22)** from your IP.
3. Copy the project up and deploy:

```bash
# from your machine — copy the project to the instance
scp -i your-key.pem -r ~/restart-demo ec2-user@YOUR_EC2_PUBLIC_IP:~

# then SSH in and deploy as "cloud"
ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
cd ~/restart-demo
sudo ./deploy/deploy.sh cloud "AWS EC2 - <your region>"
```

The same script detects Amazon Linux and uses `httpd` + `php` instead of Ubuntu's
`apache2`. Open **http://YOUR_EC2_PUBLIC_IP/** — the badge now shows **Cloud**.

**Teaching point:** identical files, identical Apache, but the hardware belongs to
AWS, and you reached it over the public internet.

---

## The whole lesson in one line

| | On-Premise (WSL) | Cloud (EC2) |
|---|---|---|
| Who owns the hardware | You | AWS |
| Who installs/patches Apache | You | You (but can bake an image) |
| Scaling | Buy more hardware | Add instances / load balancer |
| Reached via | localhost / your LAN | public IP over the internet |
| The app code | **identical** | **identical** |

Put the two browser tabs side by side. Same page, two badges. That is the point.

---

## Handy commands

```bash
# switch this machine's environment label without reinstalling:
sudo ./deploy/deploy.sh cloud "Demo: pretending to be cloud"

# watch Apache logs
sudo tail -f /var/log/apache2/access.log     # Ubuntu/WSL
sudo tail -f /var/log/httpd/access_log       # Amazon Linux/EC2

# stop / start Apache
sudo systemctl restart apache2   # Ubuntu/WSL  (or: sudo service apache2 restart)
sudo systemctl restart httpd     # Amazon Linux/EC2
```

### Note on WSL + `systemd`
Recent WSL runs `systemd`. If `systemctl` errors, enable it once: put
```
[boot]
systemd=true
```
in `/etc/wsl.conf`, then run `wsl --shutdown` from PowerShell and reopen WSL. The
deploy script already falls back to `service apache2 …` if `systemd` is off.
