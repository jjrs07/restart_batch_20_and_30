# Navigating the Linux File System — Absolute vs Relative Paths

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 35–50 minutes<br>
**Format:** Independent, self-paced Linux terminal activity<br>
**Region:** Not applicable for local Linux; use `us-east-2` (Ohio) if using EC2

---

## Before You Start

You need a Linux shell. Any of these works:
- **WSL** on Windows (Ubuntu)
- An **EC2** instance you SSH into
- The lab machine your instructor gives you

Get the practice files by building them with the setup script in this folder:

```bash
cd 03-navigating-linux-file-system
./setup.sh
```

That creates a `practice/cloudmart/` folder tree for you to explore. If you ever mess it up, just run `./setup.sh` again to reset it.

> If `./setup.sh` says *permission denied*, make it executable first: `chmod +x setup.sh`.

---

## Learning Objectives

By the end of this exercise you will be able to:

1. Explain the difference between an **absolute path** and a **relative path**
2. Use `pwd`, `ls`, and `cd` to move around the file system
3. Use the shortcuts `/`, `~`, `.`, `..`, and `cd -`
4. Reach any file or folder using **either** an absolute or a relative path
5. Read a file with `cat` to confirm you landed in the right place
6. Use paths with **file commands** like `cp` and `cat` — not just with `cd`

---

## Part 0 — The Vocabulary (3 min)

| Term | What it means | Example |
|---|---|---|
| **Path** | The "address" of a file or folder | `/home/jsant/notes.txt` |
| **Absolute path** | Starts from the **root** `/`. Works from **anywhere**. | `/home/jsant/practice/cloudmart` |
| **Relative path** | Starts from **where you are right now** (`pwd`). | `departments/hr` |
| `/` | The **root** of the whole file system (the very top) | `cd /` |
| `~` | Shortcut for **your home** directory (e.g. `/home/jsant`) | `cd ~` |
| `.` | **This** directory (where you are now) | `./setup.sh` |
| `..` | The **parent** directory (one level up) | `cd ..` |
| `pwd` | **Print Working Directory** — "where am I?" | `pwd` |

> **The one rule to remember:**
> **Absolute paths start with `/`. Relative paths don't.**
> If a path begins with `/`, the shell reads it from the root. If it doesn't, the shell reads it starting from your current location.
>
> Two questions to ask yourself about **any** path you see or type:
> - **Absolute path** → *"Where is this, starting from `/` (the root)?"*
> - **Relative path** → *"Where is this, starting from where I am right now?"*

---

## Part 1 — Where am I? (`pwd`) (3 min)

1. Open your terminal and go into the practice tree:

```bash
cd 03-navigating-linux-file-system/practice/cloudmart
```

2. Ask the shell where you are:

```bash
pwd
```

You'll see something like:

```
/home/jsant/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart
```

**That full line — starting with `/` — is your absolute path.** Write it down; it is your "base camp" for this lab. Yours will differ depending on where you cloned the repo and your username.

> **Teaching point:** `pwd` is the most important command when you're lost. Any time a command "can't find" a file, run `pwd` first and ask: *"Relative to here, does my path make sense?"*

---

## Part 2 — Look around (`ls`) (4 min)

1. List what's in the current folder:

```bash
ls
```

You should see: `README.txt` and `departments`.

2. List with more detail (long format, shows folders vs files):

```bash
ls -l
```

3. List everything, including a peek two levels down:

```bash
ls departments
ls departments/engineering
```

Notice you just used **relative paths** (`departments`, `departments/engineering`) — they don't start with `/`, so `ls` read them starting from where you are.

**Checkpoint:** `ls departments` shows `engineering`, `finance`, and `hr`.

---

## Part 3 — Absolute paths (works from anywhere) (7 min)

An absolute path always begins with `/`, so it doesn't matter where you currently are.

1. First jump somewhere totally unrelated:

```bash
cd /
pwd        # you are now at the root
```

2. Now go **straight** to the finance 2026 reports using an **absolute path**. Replace the front part with **your** base camp from Part 1:

```bash
cd /home/<you>/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/finance/reports/2026
pwd
ls
```

**Checkpoint:** `ls` shows `q1.txt` and `q2.txt`.

3. Confirm you're really there by reading a file:

```bash
cat q1.txt
```

It prints its own location — proof you navigated correctly.

> **Tip — save typing with `~`:** If your repo is under your home folder, you can put `~` at the front:
> ```bash
> cd ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart
> ```
> `~` is **not** a path by itself — it's a **shell shortcut for your home directory**. Before the command runs, the shell does **tilde expansion**: it swaps `~` for your real home. So `~/practice` becomes something like `/home/ec2-user/practice`. *After* that swap, the path starts with `/`, so what actually runs is an ordinary **absolute path** — just quicker to type.

> **Teaching point:** Scripts and cron jobs almost always use **absolute paths**, because they can run from any working directory and must not guess where "here" is.

---

## Part 4 — Relative paths (from where you stand) (8 min)

Relative paths are shorter and are what you'll use most while working interactively. They start from your current location. The magic words are `..` (up one level) and the folder names going down.

1. Go back to base camp:

```bash
cd ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart
pwd
```

2. Move **down** into HR's policies using a **relative** path (no leading `/`):

```bash
cd departments/hr/policies
pwd
ls
cat leave.txt
```

3. Now move **up** one level with `..`:

```bash
cd ..
pwd        # you're back in departments/hr
```

4. Go from `hr` **across** to `engineering` in one move. You go up to `departments`, then down into `engineering`:

```bash
cd ../engineering/projects/alpha
pwd
cat README.txt
```

Read that command out loud: *"up to departments (`..`), then down into engineering/projects/alpha."*

5. Stack `..` to jump up several levels at once. From `alpha`, go up **four** levels back to `cloudmart`:

```bash
cd ../../../..
pwd        # should be ...practice/cloudmart
```

> **Checkpoint:** `pwd` ends in `practice/cloudmart`.

> **Common mistake:** Forgetting the leading `/` difference. `cd departments` (relative) works from `cloudmart`. `cd /departments` (absolute) fails, because there is no `departments` folder at the root of the whole system.

---

## Part 5 — Handy shortcuts (5 min)

| Command | What it does |
|---|---|
| `cd` (alone) or `cd ~` | Jump to your **home** directory |
| `cd -` | Jump **back** to the last directory you were in (like a toggle) |
| `cd ..` | Up one level |
| `cd ../..` | Up two levels |
| `cd .` | Stay put (rarely useful alone, but `.` matters in `./script.sh`) |

Try the toggle:

```bash
cd ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/finance
cd ~            # go home
cd -            # go straight back to finance
pwd
```

> **Why `./` before a script?** When you run `./setup.sh`, the `./` says *"the setup.sh in THIS folder"*. Without it, the shell searches its `PATH` (a list of system folders) and won't find your local script.

---

## Part 6 — Paths work with *commands*, not just `cd` (7 min)

So far you've used paths with `cd` to move around. Here's the bigger idea:
**almost every Linux command that touches a file takes a path** — and those paths
follow the exact same absolute-vs-relative rules you just learned.

Let's prove it with `cp` (copy). Its shape is `cp <source> <destination>` — **two** paths.

### 6a. Copy using relative paths

1. Start at base camp:

```bash
cd ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart
pwd
```

2. Make a backup of HR's leave policy — **both paths are relative** (no leading `/`):

```bash
cp departments/hr/policies/leave.txt departments/hr/leave-backup.txt
```

3. Check it worked:

```bash
ls departments/hr
cat departments/hr/leave-backup.txt
```

**Checkpoint:** `ls departments/hr` now shows `leave-backup.txt` next to `employees.txt` and `policies`.

> **Ask yourself:** *Are the source and destination absolute or relative?*
> **Both are relative** — neither begins with `/`. Linux resolved each one starting
> from where you're standing (`cloudmart`). If you ran the exact same command from a
> different folder, it would look for `departments/...` in the wrong place and fail.

### 6b. The same copy using absolute paths

Relative paths depend on where you are. Absolute paths don't — they work from anywhere. Let's prove it by first resetting, then moving somewhere unrelated.

1. Reset the environment to a clean state (this also removes the backup from 6a):

```bash
cd ~/restart_batch_20_and_30/03-navigating-linux-file-system
./setup.sh
```

2. Jump somewhere completely unrelated:

```bash
cd /
pwd        # you're at the root now — nowhere near cloudmart
```

3. Run the **same** copy, but with **absolute paths**. Replace `/home/<you>` with your real home from Part 1 (or use `~`):

```bash
cp ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/hr/policies/leave.txt \
   ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/hr/leave-backup.txt
```

4. Confirm — with an absolute path again, since you're still at `/`:

```bash
ls ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart/departments/hr
```

**Checkpoint:** `leave-backup.txt` is there — even though you ran the command from `/`.

> **The lesson in one line:**
> **Relative paths depend on your current directory. Absolute paths work regardless of it.**
> The relative copy in 6a only worked because you were standing in `cloudmart`.
> This absolute copy worked from `/` — it would work from *anywhere*.

### 6c. Mixing path styles in one command

The source and destination don't have to use the same style — you can mix them.

1. Go back to base camp so the relative source makes sense:

```bash
cd ~/restart_batch_20_and_30/03-navigating-linux-file-system/practice/cloudmart
```

2. Copy the leave policy into `/tmp` — **relative source, absolute destination**:

```bash
cp departments/hr/policies/leave.txt /tmp/leave.txt
cat /tmp/leave.txt
```

> **Read the two paths:**
> - `departments/hr/policies/leave.txt` — **relative** (no leading `/`), found starting from `cloudmart` where you're standing.
> - `/tmp/leave.txt` — **absolute** (starts with `/`), the system-wide temp folder.
>
> Linux evaluates each path on its own, so one command can happily use one of each.

> **Teaching point — the big one:** Paths are **not** just for navigation. Commands like
> `cat`, `cp`, `mv`, `rm`, and `ls` all operate on paths. You do **not** have to `cd` into
> a folder before touching a file — you can name the file by its path from wherever you
> are. `cd` moves *you*; a path tells a command *which file to act on*.

---

## Part 7 — Challenges (12 min)

Do these **without peeking** at `SOLUTIONS.md`. For each one, run `pwd` and `ls` (or `cat`) to prove it worked. Start each challenge from base camp (`cloudmart`) unless told otherwise.

1. Go to **Project Beta** using a **relative** path, then `cat` its `README.txt`.
2. From Project Beta, go to the **HR policies** folder using a **relative** path (hint: lots of `..`).
3. From anywhere, go to the **2025** finance report using an **absolute** path. `cat q4.txt`.
4. From the 2025 report, reach the **2026** report using a **relative** path (they're siblings).
5. Go **home** with a single word, then return to where you were with a single command.
6. From base camp, reach `alpha/notes.txt` and read it **without using `cd`** — just `cat` a relative path.
7. From base camp, **copy** `finance/budget.txt` into the `finance/reports/2026` folder using **only relative paths**. Verify with `ls`.
8. From `/`, **copy** CloudMart's top-level `README.txt` to `/tmp/cloudmart-readme.txt` using **absolute paths**. `cat` it to confirm.
9. **Spot the path styles:** in the command `cp departments/hr/policies/leave.txt /tmp/leave.txt`, which argument is a **relative** path and which is **absolute**? How can you tell?
10. **Bonus:** What does `cd ../../../../../../..` do from deep inside the tree? Try it, run `pwd`, and explain why you can't go higher than `/`.

Check your commands against [`SOLUTIONS.md`](SOLUTIONS.md) when you're done.

---

## Reset / Clean Up

- To **reset** the tree to its original state (e.g. after the copy exercises, or after deleting files): run `./setup.sh` again. It rebuilds a fresh `cloudmart/`, so any `leave-backup.txt` or other copies you made inside `practice/` simply disappear.
- The mixing exercise copies a file into `/tmp` (outside `practice/`, so `setup.sh` won't touch it). `/tmp` clears on reboot, or remove the copies now:

```bash
rm -f /tmp/leave.txt /tmp/cloudmart-readme.txt
```

- To **remove** the practice files entirely:

```bash
rm -rf 03-navigating-linux-file-system/practice
```

---

## Quick Reference Card

- **Absolute path** = starts with `/`, works from anywhere: `/home/you/dir` → *"where is this, starting from `/`?"*
- **Relative path** = no leading `/`, starts from `pwd`: `departments/hr` → *"where is this, starting from where I am now?"*
- **Paths aren't just for `cd`** — `cat`, `cp`, `mv`, `rm`, and `ls` all take paths too. No need to `cd` in first.
- `~` = a shortcut the shell expands to your home dir (then it's an absolute path)
- `pwd` — where am I? · `ls` — what's here? · `cd` — go there
- `/` = root · `.` = here · `..` = up one · `cd -` = previous dir
- Lost? Run **`pwd`** first, then decide if your path should be absolute or relative.

---

## Self-Check Questions

1. In one sentence, what is the difference between an absolute and a relative path?
2. You're in `/home/you/practice/cloudmart/departments/hr`. Write a **relative** path to `engineering/team.txt`.
3. Write the same journey as an **absolute** path.
4. What does `cd -` do?
5. Why do you type `./setup.sh` and not just `setup.sh`?
6. What is the one command that always tells you where you are?
7. In `cp reports/2026/q1.txt /tmp/q1.txt`, which argument is a relative path and which is absolute — and how can you tell at a glance?
8. True or false: you must `cd` into a folder before you can read a file inside it. Explain.

---

*AWS re/Start Batch 29 and 30 — Navigating the Linux File System*
