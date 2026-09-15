# MySQL Conditional Search and Data Organization

**AWS re/Start — Batch 29**<br>
**Duration:** 60–75 minutes<br>
**Format:** Build an Amazon EC2 instance, install MariaDB, and run the activity from the command line.

---

## Learning Objectives

By the end of this activity, you will be able to:

1. Launch and securely connect to an Amazon Linux 2023 EC2 instance
2. Install, start, validate, and harden MariaDB
3. Filter records with `WHERE`, `AND`, `OR`, `BETWEEN`, `IN`, `LIKE`, and `IS NULL`
4. Use string, date, numeric, NULL-handling, and conditional functions
5. Sort results with `ORDER BY`
6. Summarize records with aggregate functions and `GROUP BY`
7. Filter grouped results with `HAVING`

---

## Before You Start

| Item | Requirement |
|---|---|
| AWS access | A sandbox account with permission to launch and terminate EC2 instances and manage security groups and key pairs |
| Region | Use the same Region as your instructor; the examples use `us-east-1` |
| Compute | One disposable Amazon Linux 2023 EC2 instance |
| Database | MariaDB 10.5 or later, installed during this activity |
| Database access | Local administrative access through `sudo mariadb`; no remote database port is required |
| Script | [`employee-search-demo.sql`](employee-search-demo.sql) |

> **Warning:** The script drops and recreates a database named
> `conditional_search_demo`. Run it only in a classroom or disposable MariaDB
> environment. Do not reuse that database name for production data.

---

## Activity Architecture

```text
Student computer
└── SSH over TCP/22 from the student's IP only
    └── Amazon Linux 2023 EC2 instance
        └── MariaDB bound locally; TCP/3306 is not exposed
            └── conditional_search_demo database
                └── employees table (20 rows)
                    ├── WHERE filters individual rows
                    ├── functions calculate or transform values
                    ├── GROUP BY creates summary groups
                    ├── HAVING filters the groups
                    └── ORDER BY sorts the final result
```

MariaDB is a community-developed, MySQL-compatible relational database. This lab
uses SQL that runs on MariaDB 10.5+ and MySQL 8.0+. The examples use one table so
the focus stays on query logic rather than joins. The data includes different
departments, salaries, cities, employment statuses, hire dates, and NULL manager
values so each condition returns a useful result.

---

## Part 0 — Build the EC2 and MariaDB Prerequisites

### Step 1: Launch the EC2 instance

1. Open the **Amazon EC2 console** in the Region selected by your instructor.
2. Choose **Launch instance**.
3. Configure the instance:

   | Setting | Value |
   |---|---|
   | Name | `batch29-mariadb-lab` |
   | AMI | Amazon Linux 2023 AMI, 64-bit x86 |
   | Instance type | `t3.micro`, or the small instance type permitted by your sandbox |
   | Key pair | Select an existing lab key pair or create a new `.pem` key pair |
   | Network | Default VPC and a public subnet for this short-lived lab |
   | Public IPv4 | Enabled so the student can connect by SSH |
   | Storage | 8 GiB `gp3`, encrypted |

4. Create a security group named `batch29-mariadb-sg` with one inbound rule:

   | Type | Protocol | Port | Source |
   |---|---|---:|---|
   | SSH | TCP | 22 | **My IP** (`your-public-ip/32`) |

5. Do **not** add inbound rules for MariaDB/MySQL port `3306`, HTTP, or HTTPS.
6. Launch the instance and wait until it is `Running` and both status checks pass.

> **Security point:** MariaDB is used only from the EC2 shell. Keeping port
> `3306` closed prevents direct database access from the internet. A production
> database should normally run in private subnets with controlled application or
> administrative access, not on a public EC2 instance.

### Step 2: Connect by SSH

Copy the instance's **Public DNS name** from the EC2 console. From Linux, macOS,
or WSL, protect the downloaded key and connect:

```bash
chmod 400 batch29-mariadb.pem
ssh -i batch29-mariadb.pem ec2-user@YOUR_EC2_PUBLIC_DNS
```

From Windows PowerShell, use:

```powershell
ssh -i .\batch29-mariadb.pem ec2-user@YOUR_EC2_PUBLIC_DNS
```

Replace the key filename and DNS name with your actual values. Amazon Linux uses
`ec2-user` as the default SSH username.

**Checkpoint:** The shell prompt should identify the Amazon Linux EC2 instance.

### Step 3: Install and start MariaDB

On the EC2 instance, update the packages and install Git and the Amazon Linux
2023 MariaDB server package:

```bash
sudo dnf upgrade -y
sudo dnf install -y git mariadb105-server
```

Enable MariaDB at boot and start it now:

```bash
sudo systemctl enable --now mariadb
```

Validate the service and database engine:

```bash
sudo systemctl is-active mariadb
mysql --version
sudo mariadb -e "SELECT VERSION() AS mariadb_version;"
```

**Checkpoint:** `systemctl` must return `active`, and the version query must
return a MariaDB version.

### Step 4: Apply basic MariaDB hardening

Run the interactive security utility:

```bash
sudo mysql_secure_installation
```

Follow the prompts shown by your installed version. Remove anonymous users,
disable remote root login, remove the test database, and reload the privilege
tables. Store any password you create in an approved password manager; do not put
it in shell commands, scripts, screenshots, or Git.

> **Production tradeoff:** A local administrative login is acceptable for this
> isolated classroom activity. Applications should use a separate, least-
> privilege database account and should not connect as `root`.

### Step 5: Get the activity files

Clone this repository on the EC2 instance and enter the lab folder:

```bash
git clone https://github.com/jjrs07/restart_batch_29.git
cd restart_batch_29/06-mysql-conditional-search
```

Confirm that both activity files are present:

```bash
ls -l README.md employee-search-demo.sql
```

---

## Part 1 — Create the Demo Data

From the lab folder on the EC2 instance, load the complete dataset and examples:

```bash
sudo mariadb < employee-search-demo.sql
```

The script prints several result sets because it includes both the 20-row dataset
and the demonstration queries. To run queries individually, open the client:

```bash
sudo mariadb conditional_search_demo
```

Confirm the dataset:

```sql
USE conditional_search_demo;

SELECT COUNT(*) AS total_employees
FROM employees;
```

**Checkpoint:** The result must show `20` employees.

---

## Part 2 — Conditional Search

A `WHERE` clause decides which individual rows are allowed into the result.

```sql
SELECT employee_name, department, salary, employment_status
FROM employees
WHERE department = 'IT'
  AND employment_status = 'Active'
  AND salary >= 80000;
```

Parentheses are important when combining `AND` and `OR`:

```sql
SELECT employee_name, department, employment_status
FROM employees
WHERE employment_status = 'Active'
  AND (department = 'IT' OR department = 'Finance');
```

Without the parentheses, SQL may evaluate the conditions differently from what
you intended because `AND` has higher precedence than `OR`.

Other useful search operators are demonstrated in the SQL script:

- `BETWEEN` searches an inclusive range.
- `IN` matches any value in a list.
- `LIKE` searches a text pattern; `%` represents zero or more characters.
- `IS NULL` finds missing values. Do not use `= NULL`.

---

## Part 3 — Functions in Queries

Functions transform values or calculate new values:

```sql
SELECT
    employee_name,
    UPPER(department) AS department_upper,
    ROUND(salary / 12, 2) AS monthly_salary,
    YEAR(hire_date) AS hire_year
FROM employees
WHERE LOWER(job_title) LIKE '%engineer%'
ORDER BY monthly_salary DESC;
```

The script also demonstrates:

| Function or expression | Purpose |
|---|---|
| `CONCAT()` | Join text values |
| `TIMESTAMPDIFF()` | Calculate elapsed time |
| `COALESCE()` | Replace a NULL result with another value |
| `IF()` | Return one of two values based on a condition |
| `CASE` | Return a category based on multiple conditions |
| `COUNT()`, `AVG()`, `MIN()`, `MAX()` | Calculate group summaries |

> **Performance note:** Applying a function to an indexed column in `WHERE` can
> prevent normal index use. For production date searches, prefer a range such as
> `hire_date >= '2024-01-01' AND hire_date < '2025-01-01'` over
> `YEAR(hire_date) = 2024`.

---

## Part 4 — `ORDER BY`, `GROUP BY`, and `HAVING`

Use `ORDER BY` to sort individual rows:

```sql
SELECT employee_name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;
```

Use `GROUP BY` with aggregate functions to summarize rows:

```sql
SELECT
    department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS average_salary
FROM employees
GROUP BY department
ORDER BY average_salary DESC;
```

Use `HAVING` to filter the grouped results:

```sql
SELECT
    department,
    COUNT(*) AS active_employee_count,
    ROUND(AVG(salary), 2) AS average_active_salary
FROM employees
WHERE employment_status = 'Active'
GROUP BY department
HAVING COUNT(*) >= 2
   AND AVG(salary) >= 60000
ORDER BY average_active_salary DESC;
```

Remember the logical query flow:

```text
FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY
```

- `WHERE` filters individual employee rows before grouping.
- `HAVING` filters department summaries after grouping.
- `ORDER BY` sorts the final result.

---

## Practice Challenges

Write and run queries for the following requirements. The comments at the end of
the SQL file repeat these challenges but do not provide the completed queries.

1. Find active employees in Manila or Makati who earn at least `60000`. Sort the
   highest salary first.
2. Show each city's employee count and average salary. Return only cities with at
   least three employees.
3. Find employees whose job title contains `Manager` and display how many
   completed years they have worked.

For every query, verify both the returned rows and the column headings. A query
that runs without an error can still implement the wrong business condition.

---

## Clean Up

Inside MariaDB, remove the demo database and exit:

```sql
DROP DATABASE IF EXISTS conditional_search_demo;
EXIT;
```

Back at the EC2 shell, confirm that the database no longer exists. The command
should return no output:

```bash
sudo mariadb --batch --skip-column-names -e \
  "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'conditional_search_demo';"
```

Then return to the EC2 console and terminate `batch29-mariadb-lab`. Verify that
the instance reaches the `Terminated` state. Delete the lab-only security group
and key pair if your instructor does not need them for another activity.

> **Cost point:** Stopping an instance stops compute charges, but its EBS volume
> can continue to incur storage charges. Terminating the disposable lab instance
> and confirming its volume deletion avoids leaving recurring resources behind.

---

## Troubleshooting

### `ERROR 1046: No database selected`

Select the demo database before running the queries:

```sql
USE conditional_search_demo;
```

### SSH connection times out

Confirm that the instance is running, both status checks passed, it has a public
IPv4 address, and the security group allows TCP/22 from your current public IP.
If your ISP changed your IP address, update the `/32` SSH source instead of
opening SSH to `0.0.0.0/0`.

### `No match for argument: mariadb105-server`

Confirm that the instance uses Amazon Linux 2023, then refresh package metadata:

```bash
sudo dnf clean metadata
sudo dnf makecache
sudo dnf info mariadb105-server
```

Do not copy package commands intended for Ubuntu, Amazon Linux 2, or another
distribution.

### MariaDB does not start

Inspect the service state and its recent log messages before changing anything:

```bash
sudo systemctl status mariadb --no-pager
sudo journalctl -u mariadb --no-pager -n 50
```

### `Access denied for user 'root'@'localhost'`

Use the local administrative socket login for this lab:

```bash
sudo mariadb
```

### The row count is greater than 20

Run the complete setup script again. It recreates the dedicated demo database and
loads exactly 20 rows.

### A grouped query fails with `ONLY_FULL_GROUP_BY`

Every selected column that is not inside an aggregate function must be included
in `GROUP BY`. Keep strict SQL mode enabled; fix the query instead of disabling
the safety setting.

### `IS NULL` works but `= NULL` does not

NULL means an unknown or missing value, so use `IS NULL` or `IS NOT NULL` rather
than an equality operator.

---

## Quick Reference

```sql
SELECT
    grouping_column,
    COUNT(*) AS row_count,
    ROUND(AVG(numeric_column), 2) AS average_value
FROM table_name
WHERE row_condition
GROUP BY grouping_column
HAVING COUNT(*) >= 2
ORDER BY average_value DESC;
```

---

## AWS References

- [Launch a test EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/tutorial-launch-a-test-ec2-instance.html)
- [Install MariaDB on Amazon Linux 2023](https://docs.aws.amazon.com/linux/al2023/ug/ec2-lamp-amazon-linux-2023.html)
- [Configure EC2 security groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-security-group.html)

---

*AWS re/Start Batch 29 — MySQL Conditional Search and Data Organization*
