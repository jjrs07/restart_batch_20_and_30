# AWS re/Start — Batch 29 and 30 · Labs & Demos

Hands-on labs, demos, and walkthroughs for **AWS re/Start Batch 29 and 30**.
Each lab lives in its own numbered folder and is self-contained — open the folder
for today's session and follow its `README.md`.

---

## 📚 Labs

| # | Topic | What you'll do | Folder |
|---|---|---|---|
| 01 | **On-Prem vs Cloud — Website Deployment** | Deploy one *identical* web app two ways: on-premise (your WSL machine) and in the cloud (AWS EC2 with Apache). See that deployment is about the *environment*, not the code. | [`01-onprem-vs-cloud-website/`](01-onprem-vs-cloud-website/) |
| 02 | **Amazon S3 — Hands-On (Console)** | Buckets, objects & keys, versioning, encryption at rest, the three access-control layers, presigned URLs, storage classes & lifecycle, and cleanup. | [`02-s3-lab/`](02-s3-lab/) |
| 03 | **Navigating the Linux File System** | Move around Linux with `pwd`, `ls`, and `cd`. Master **absolute vs relative paths** using `/`, `~`, `.`, and `..` on a sample folder tree. | [`03-navigating-linux-file-system/`](03-navigating-linux-file-system/) |
| 04 | **Linux Log Management** | Generate logs, automate them with cron, estimate log growth, configure logrotate retention, and troubleshoot Linux services with `journalctl`. | [`04-linux-log-management/`](04-linux-log-management/) |
| 05 | **Downloading with curl and wget** | Compare `curl` and `wget`, download the AWS CLI installer with both tools, and choose the right command for common use cases. | [`05-curl-vs-wget/`](05-curl-vs-wget/) |
| 06 | **MySQL Conditional Search and Data Organization** | Build an Amazon Linux 2023 EC2 instance, install MariaDB, query a 30-employee dataset, and organize results with `ORDER BY`, `GROUP BY`, and `HAVING`. | [`06-mysql-conditional-search/`](06-mysql-conditional-search/) |

More labs (VPC, IAM, EC2 deep-dive, etc.) will be added as numbered folders.

---

## 📖 References

- **IPv4 Subnetting Cheat Sheet:** [GitHub-friendly Markdown](references/subnetting/) · [View rendered HTML](https://jjrs07.github.io/restart_batch_20_and_30/references/subnetting/)

---

## 🎓 For students

1. Get the materials:
   ```bash
   git clone https://github.com/jjrs07/restart_batch_20_and_30.git
   cd restart_batch_20_and_30
   ```
   *(Or download the ZIP and unzip it.)*
2. Open the folder for today's lab, e.g. `02-s3-lab/`.
3. Read that folder's `README.md` and follow along in **your own sandbox account / shell**.
4. **Always do the Clean Up step** at the end of each lab so you're not billed.

---

## 🧑‍🏫 For the instructor

- Each lab is a numbered folder with its own `README.md`.
- To add a new lab, copy the template and fill it in:
  ```bash
  mkdir 04-my-new-lab
  cp LAB-TEMPLATE.md 04-my-new-lab/README.md
  ```
- Update the **Labs** table above with a new row so students can find it.
- Instructor-only tooling (preview server, user-data generator) is listed in
  `.gitignore` so it stays out of the student clone.

---

*AWS re/Start — Batch 29 and 30 · Maintained by the instructor.*
