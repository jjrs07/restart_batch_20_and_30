# Solutions — Navigating the Linux File System

> Try the challenges yourself first! These assume you start at **base camp**:
> `.../practice/cloudmart`. Replace `~/restart_batch_20_and_30` with wherever you cloned the repo.

## Part 7 — Challenges

**1. Go to Project Beta (relative), then cat its README:**
```bash
cd departments/engineering/projects/beta
pwd
cat README.txt
```

**2. From Project Beta to HR policies (relative):**
```bash
cd ../../../hr/policies
pwd
```
Read it as: up out of `beta` → `projects` → `engineering` → into `departments`, then down to `hr/policies`. That's three `..` then `hr/policies`.

**3. To the 2025 finance report (absolute), from anywhere:**
```bash
cd ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/finance/reports/2025
cat q4.txt
```
(Absolute path — starts from `~`, which expands to `/home/<you>`.)

**4. From 2025 report to 2026 report (relative, siblings):**
```bash
cd ../2026
pwd
```
Up one level to `reports`, then down into `2026`.

**5. Go home, then return:**
```bash
cd            # (or: cd ~)  -> home
cd -          # -> back to where you were
```

**6. Read alpha/notes.txt without cd (relative path to cat):**
```bash
# from base camp (cloudmart):
cat departments/engineering/projects/alpha/notes.txt
```

**7. Copy `finance/budget.txt` into `finance/reports/2026` (relative), from base camp:**
```bash
cp departments/finance/budget.txt departments/finance/reports/2026/budget.txt
ls departments/finance/reports/2026
```
Both paths are **relative** (neither starts with `/`), so Linux resolves them from `cloudmart` where you're standing.

**8. From `/`, copy CloudMart's top `README.txt` to `/tmp` (absolute):**
```bash
cd /
cp ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/README.txt /tmp/cloudmart-readme.txt
cat /tmp/cloudmart-readme.txt
```
The source starts with `~` (which expands to `/home/<you>/...`, an **absolute** path), so it works even though you're sitting at `/`. `/tmp/cloudmart-readme.txt` is **absolute** too. A relative source like `README.txt` would have failed here — there's no `README.txt` at `/`.

**9. Spot the path styles** in `cp departments/hr/policies/leave.txt /tmp/leave.txt`:
- `departments/hr/policies/leave.txt` → **relative** — it does **not** begin with `/`, so it's read from the current directory.
- `/tmp/leave.txt` → **absolute** — it **begins with `/`**, so it's read from the root.

How to tell at a glance: **look at the first character. A leading `/` means absolute; anything else means relative.**

**10. Bonus — `cd ../../../../../../..`:**
It walks up seven levels. Once you reach `/` (the root), extra `..` just stays at `/` — you **cannot go higher than root**, because root has no parent. Verify:
```bash
cd /
cd ..
pwd     # still shows /
```

---

## Self-Check Answers

1. **Absolute** starts at the root `/` and works from anywhere; **relative** starts from your current directory (`pwd`) and depends on where you are.
2. Relative from `.../departments/hr`:
   ```bash
   cat ../engineering/team.txt
   ```
3. Absolute (same target):
   ```bash
   cat ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/engineering/team.txt
   ```
4. `cd -` jumps back to the **previous** directory you were in (a toggle between two locations).
5. `./` means "in **this** folder." Without it, the shell only looks in the directories listed in `$PATH`, and your local `setup.sh` isn't there, so it wouldn't be found.
6. `pwd` (print working directory).
7. `reports/2026/q1.txt` is **relative** (no leading `/`); `/tmp/q1.txt` is **absolute** (leading `/`). Tell them apart by the first character — a leading `/` = absolute.
8. **False.** Commands like `cat`, `cp`, `mv`, and `rm` take a path, so you can act on a file from anywhere by naming its path (relative or absolute). `cd` moves *you*; it isn't required just to read or copy a file.

---

*AWS re/Start Batch 29 and 30 — instructor answer key.*
