# Linux Log Management — Cron, Rotation, Retention & journalctl

**AWS re/Start — Batch 29 and 30**

**Duration:** 60–75 minutes

**Format:** Follow along on an Amazon Linux EC2 instance or another systemd-based Linux machine. Type each command yourself.

---

## Before You Start

You need a Linux shell, Bash, and a system that uses systemd for the journal sections. Amazon Linux on EC2 is the main target. Commands are generic where practical, but service names and traditional log files differ between distributions.

```bash
cd ~/restart_batch_20_and_30/04-linux-log-management
chmod +x scripts/*.sh
```

If you cloned the repository somewhere else, adjust the first path. You may also need the cron and logrotate packages for their sections; do not install anything unless your instructor asks.

---

## Learning Objectives

By the end of this lab you will be able to:

1. Create and inspect an application log without overwriting old entries
2. Automate a command with cron and explain all five schedule fields
3. Calculate log volume and estimate future storage consumption
4. Explain rotation, compression, and policy-driven retention
5. Use `journalctl` to query messages collected by `systemd-journald`
6. Describe why production teams centralize logs

---

## Lab Architecture / Concept

```text
Application script --appends--> ~/log-demo/app.log
       cron --------runs-------> application script every 5 minutes
   logrotate ------manages-----> rotation, compression, retention

Linux services / applications / kernel
              |
              v
       systemd-journald
              |
              v
        System Journal
              |
              v
          journalctl
```

> **Remember this:** cron decides **when a job runs**. Logrotate manages a log file's **lifecycle**. `systemd-journald` collects journal messages, while `journalctl` lets you query them.

---

## Part 1 — Generate a Log Manually

Run the application log generator:

```bash
./scripts/generate-log.sh
```

It creates `~/log-demo/` when needed and appends an entry to `app.log`:

```text
2026-08-18 01:15:00,INFO,Application health check successful
```

The fields are timestamp, log type, and description. `INFO` is the default type. The script uses `>>`, which **appends**. A single `>` would overwrite the file and lose earlier events.

```bash
cat ~/log-demo/app.log
tail -n 5 ~/log-demo/app.log
```

**Checkpoint:** Run the generator again. Both entries should remain, and the latest five appear in the terminal.

---

## Part 2 — Understand File Size

Compare four views of the same file:

```bash
ls -l ~/log-demo/app.log
ls -lh ~/log-demo/app.log
wc -c ~/log-demo/app.log
du -h ~/log-demo/app.log
```

- `ls -l` shows the logical file size in bytes.
- `ls -lh` shows that logical size using readable units.
- `wc -c` counts the exact bytes.
- `du -h` shows disk space consumed. It may differ because filesystems allocate blocks.

### Classroom calculation

If:

```text
2 log entries = 122 bytes
```

then:

```text
122 / 2 = 61 bytes per log entry

60 / 5 = 12 entries/hour
12 * 24 = 288 entries/day
288 * 61 = 17,568 bytes/day
17,568 / 1024 ≈ 17.16 KiB/day
```

Assuming the average remains **61 bytes per entry**:

```text
30 days: 17,568 * 30 = 527,040 bytes ≈ 514.69 KiB
365 days: 17,568 * 365 = 6,412,320 bytes ≈ 6,262.03 KiB ≈ 6.12 MiB
```

Log-size results are estimates because description lengths vary.

Binary size units use `1 KiB = 1024 bytes` and `1 MiB = 1024 KiB`. They are different from decimal KB and MB.

---

## Part 3 — Automate with Cron

Cron runs commands according to schedules. Open the provided example:

```bash
cat cron/crontab-example.txt
```

```text
 ┌───────────── minute
 │ ┌─────────── hour
 │ │ ┌───────── day-of-month
 │ │ │ ┌─────── month
 │ │ │ │ ┌───── day-of-week
 │ │ │ │ │
 * * * * * command
```

The sample schedule is:

```cron
*/5 * * * * /home/ec2-user/restart_batch_20_and_30/04-linux-log-management/scripts/generate-log.sh
```

The actual absolute path depends on where you cloned the repository. Find yours with `pwd`; cron should not have to guess the working directory.

| Schedule | Meaning | Example times |
|---|---|---|
| `5 * * * *` | Minute 5 of every hour | 00:05, 01:05, 02:05 |
| `*/5 * * * *` | Every five minutes | 00:00, 00:05, 00:10 |
| `0 */5 * * *` | Every five hours, at minute 0 | 00:00, 05:00, 10:00 |

`*` does **not** mean disabled. It means every possible value for that field. In the minute field, `*/5` steps through the available minutes in increments of five.

To edit your own schedule manually:

```bash
crontab -e
```

This lab does not modify crontab automatically. On Amazon Linux the cron service is commonly named `crond`; other distributions may use `cron`.

---

## Part 4 — Calculate Log Growth

Run:

```bash
./scripts/calculate-log-size.sh
```

The script reports the current entry count, exact bytes, readable disk usage, and average bytes per entry. It assumes one entry every five minutes:

```text
60 / 5 = 12 logs per hour
12 * 24 = 288 logs per day
24 * 60 / 5 = 288 logs per day
```

It estimates the size after 1, 30, and 365 days using binary units. An empty file is handled safely: its average and estimates are zero instead of causing division by zero.

> **Teaching point:** An estimate is a planning tool, not a guarantee. Real entries, traffic, errors, and description lengths vary.

---

## Part 5 — Generate Sample Data

Create 20 entries with the default:

```bash
./scripts/generate-sample-logs.sh
```

Or choose a positive count:

```bash
./scripts/generate-sample-logs.sh 100
```

The script cycles through `INFO`, `WARNING`, and `ERROR` examples without external packages. Inspect the result and calculate again:

```bash
tail ~/log-demo/app.log
./scripts/calculate-log-size.sh
```

---

## Part 6 — Introduce Logrotate

Logs grow while applications keep appending. Logrotate can rename old logs, start a new lifecycle, compress older copies, and remove copies beyond the configured count.

The provided **example** is:

```text
/home/ec2-user/log-demo/app.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

| Directive | Meaning |
|---|---|
| `daily` | Make the log eligible for rotation daily when logrotate runs |
| `rotate 7` | Retain seven rotated files, then remove the oldest |
| `compress` | Compress older rotated files to reduce storage |
| `missingok` | Continue without an error if the log is missing |
| `notifempty` | Do not rotate an empty file |

Cron schedules jobs; logrotate manages log lifecycle. They are different tools. Logrotate does not necessarily run continuously—it is commonly invoked periodically by a systemd timer, cron, or another scheduler.

### Supervised classroom demo

First adjust `/home/ec2-user` in the example if your home directory differs. These commands require appropriate permissions and are **not** run by this lab:

```bash
sudo cp logrotate/app-log.conf /etc/logrotate.d/log-demo
sudo logrotate -d /etc/logrotate.d/log-demo
sudo logrotate -f /etc/logrotate.d/log-demo
ls -lh ~/log-demo/
```

`-d` is a debug/dry-run-style inspection: it reports what logrotate would do without changing logs, so show it first. `-f` forces rotation; that is useful for a controlled lab but should be used carefully in production. File permissions and ownership can affect rotation. Some applications also need to reopen their log after rotation; production configurations may therefore require extra directives.

This repository never copies the file into `/etc/logrotate.d` and never executes logrotate automatically.

---

## Part 7 — Discuss Retention

There is **no universal log-retention period**. Retention depends on troubleshooting needs, security investigations, compliance, audit requirements, available storage, operational cost, and company policy.

Illustrations—not standards:

- Operational logs: 7–30 days locally may be reasonable in some environments.
- Security or audit logs: policy or compliance may require 90 days, one year, or longer.

**Retention should be policy-driven.**

```text
Logs
  |
  v
Rotate
  |
  v
Compress
  |
  v
Retain
  |
  +----> Archive if required
  |
  v
Delete according to policy
```

Rotation is not the same as retention policy: rotation is a mechanism; policy decides what must be kept, where, and for how long.

---

## Part 8 — Understanding systemd-journald and journalctl

`systemd-journald` is the service/daemon that collects journal messages. `journalctl` is the command used to query and view the journal. **journalctl is not the logging daemon.**

```text
Linux services / applications / kernel
              |
              v
       systemd-journald
              |
              v
        System Journal
              |
              v
          journalctl
```

Think of `systemd-journald` as a **CCTV recorder**, the system journal as the **recorded footage**, and `journalctl` as the **tool/interface used to search and view recordings**. Journal data is structured, with fields such as unit and priority; it is not simply a normal text `.log` file.

```bash
journalctl
journalctl -n 20
journalctl -f
journalctl --since today
journalctl --since "1 hour ago"
journalctl -k
journalctl --disk-usage
sudo journalctl -u sshd
sudo journalctl -u crond
```

| Option | Meaning |
|---|---|
| `-n 20` | Show the latest 20 entries |
| `-f` | Follow new events in real time; press Ctrl+C to stop |
| `-u` | Filter by systemd unit |
| `-k` | Show kernel messages |

Unit names vary. SSH may be `sshd` or `ssh`; cron may be `crond` or `cron`. Permissions can also limit which journal entries a user can see.

### Journal storage and retention

Persistent journal data is commonly stored below `/var/log/journal/` and survives reboot. Volatile journal data may be stored below `/run/log/journal/` and is lost at reboot. The active behavior and limits depend on the distribution and system configuration.

Inspect usage safely:

```bash
journalctl --disk-usage
```

Administrators can remove journal data older than a time or reduce it toward a size limit:

```bash
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=500M
```

Do **not** run those cleanup commands automatically. Never delete production logs simply because they are large. First check the retention policy, active incident needs, compliance requirements, and security requirements.

### Traditional text logs

Depending on the distribution and installed services, you may encounter:

```text
/var/log/messages       /var/log/secure
/var/log/cron           /var/log/syslog
/var/log/auth.log       /var/log/nginx/
/var/log/httpd/
```

Different Linux distributions use different log files. Do not assume every path exists on Amazon Linux—or on any one machine.

---

## Part 9 — Production Centralized Logging Concept

```text
EC2 / Linux Server
       |
       +---- Application logs
       |
       +---- systemd journal
       |
       v
Centralized Logging
       |
       +---- Amazon CloudWatch Logs
       |
       +---- OpenSearch / SIEM
       |
       +---- Amazon S3 archive
```

On one training EC2 instance, manually viewing logs is fine. With dozens or hundreds of servers, centralized logging makes searching, monitoring, alerting, security investigations, retention, and analysis much more useful. It also keeps evidence available if an instance fails or is replaced. This lab introduces the concept only; it does not deploy CloudWatch.

---

## Student Exercises

Complete [the student exercises](exercises/student-exercises.md). Suggested answers are collapsed at the bottom so you can attempt each task first.

---

## Clean Up

This removes only the classroom application log directory after you inspect it:

```bash
rm -r ~/log-demo
```

Before running it, use `ls -la ~/log-demo` and confirm it contains only this lab's sample logs. If you manually added the cron entry or logrotate configuration during the supervised demo, ask your instructor to help remove those entries too. Journal data is not part of this cleanup—do not vacuum or delete it merely because the lab is finished.

---

## Key Takeaways

- `>>` appends; `>` overwrites.
- At five-minute intervals, one source generates 288 entries per day.
- File growth estimates depend on the average entry size and event frequency.
- Cron schedules execution; logrotate rotates, compresses, and retains files.
- Retention must follow policy, investigations, security, and compliance needs.
- `systemd-journald` collects the structured journal; `journalctl` queries it.
- Centralized logging becomes valuable as the number of systems grows.

---

## Instructor Demo Flow

A concise 15–20 minute sequence:

1. Enter the lab: `cd ~/restart_batch_20_and_30/04-linux-log-management`.
2. Make scripts executable: `chmod +x scripts/*.sh`.
3. Generate one entry: `./scripts/generate-log.sh`.
4. Show it: `cat ~/log-demo/app.log`.
5. Run the generator several more times.
6. Compare `ls -l ~/log-demo/app.log`, `ls -lh ~/log-demo/app.log`, `wc -c ~/log-demo/app.log`, and `du -h ~/log-demo/app.log`.
7. Explain the 122-byte classroom example and binary KiB calculation.
8. Run `./scripts/calculate-log-size.sh`.
9. Explain `*/5 * * * *` and contrast it with the other schedules.
10. Show `crontab -e`, but do not automatically install an entry.
11. Generate data: `./scripts/generate-sample-logs.sh 50`.
12. Demonstrate logrotate safely: inspect with `-d` before a supervised `-f` rotation.
13. Run `journalctl -n 20` and `journalctl --disk-usage`.
14. Show a service example such as `sudo journalctl -u sshd` (adjust the unit name if needed).
15. Finish with `Logs -> Rotate -> Compress -> Retain -> Archive/Delete`, then explain centralized logging.

---

*AWS re/Start Batch 29 and 30 — Linux Log Management Hands-On Lab*
