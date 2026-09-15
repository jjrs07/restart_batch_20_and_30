# MySQL Conditional Search and Data Organization

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 60–75 minutes<br>
**Format:** Build an Amazon EC2 instance, install MariaDB, and run the activity from the command line.

---

## Learning Objectives

By the end of this activity, you will be able to:

1. Launch and securely connect to an Amazon Linux 2023 EC2 instance
2. Install, start, validate, and harden MariaDB
3. Build conditional searches with `WHERE`, comparison operators, logical
   operators, wildcards, column aliases, arithmetic expressions, and NULL values
4. Work with character strings and string functions
5. Use conversion, date, mathematical, aggregate, and control flow functions
6. Compare `DISTINCT`, `COUNT(*)`, `COUNT(column)`, and `COUNT(DISTINCT column)`
7. Sort results with `ORDER BY`
8. Summarize records with aggregate functions and `GROUP BY`
9. Filter grouped results with `HAVING`

---

## Before You Start

| Item | Requirement |
|---|---|
| AWS access | A sandbox account with permission to launch and terminate EC2 instances and manage security groups and key pairs |
| Region | Use the same Region as your instructor; the examples use `us-east-1` |
| Compute | One disposable Amazon Linux 2023 EC2 instance |
| Database | MariaDB 10.5 or later, installed during this activity |
| Database access | Local administrative access through `sudo mariadb`; no remote database port is required |
| Salary data | Illustrative gross monthly Philippine pesos (`PHP`); not an official compensation survey |
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
                └── employees table (30 rows)
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

The `salary` column stores illustrative **gross monthly salary in Philippine
pesos (PHP)**. Values are calibrated by job family and seniority for classroom
use, but actual compensation varies by experience, employer, location, benefits,
and market conditions.

Employee names are stored separately in `first_name` and `last_name`. This makes
sorting, filtering, and formatting either part of a name simpler; queries can
use `CONCAT(first_name, ' ', last_name)` when a full display name is needed.

---

## Part 0 — Build the EC2 and MariaDB Prerequisites

### Step 1: Launch the EC2 instance

1. Open the **Amazon EC2 console** in the Region selected by your instructor.
2. Choose **Launch instance**.
3. Configure the instance:

   | Setting | Value |
   |---|---|
   | Name | `batch29-30-mariadb-lab` |
   | AMI | Amazon Linux 2023 AMI, 64-bit x86 |
   | Instance type | `t3.micro`, or the small instance type permitted by your sandbox |
   | Key pair | Select an existing lab key pair or create a new `.pem` key pair |
   | Network | Default VPC and a public subnet for this short-lived lab |
   | Public IPv4 | Enabled so the student can connect by SSH |
   | Storage | 8 GiB `gp3`, encrypted |

4. Create a security group named `batch29-30-mariadb-sg` with one inbound rule:

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
chmod 400 batch29-30-mariadb.pem
ssh -i batch29-30-mariadb.pem ec2-user@YOUR_EC2_PUBLIC_DNS
```

From Windows PowerShell, use:

```powershell
ssh -i .\batch29-30-mariadb.pem ec2-user@YOUR_EC2_PUBLIC_DNS
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
git clone https://github.com/jjrs07/restart_batch_20_and_30.git
cd restart_batch_20_and_30/06-mysql-conditional-search
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

The script prints several result sets because it includes both the 30-row dataset
and the demonstration queries. To run queries individually, open the client:

```bash
sudo mariadb conditional_search_demo
```

Confirm the dataset:

```sql
USE conditional_search_demo;

SELECT COUNT(*) AS total_employees
FROM employees;

DESCRIBE employees;
```

**Checkpoint:** The count must show `30`. The table definition must contain
`first_name` and `last_name`, with no `employee_name` column.

---

## Part 2 — Conditional Search

A `WHERE` clause decides which individual rows are allowed into the result.

| Exercise topic | SQL syntax demonstrated |
|---|---|
| `WHERE` clauses | `WHERE department = 'IT'` |
| Comparison operators | `=`, `<>`, `>`, `>=`, `<`, `<=`, and `BETWEEN` |
| Arithmetic operators | `+`, `-`, `*`, `/`, and `%` |
| Logical operators | `AND`, `OR`, and `NOT` |
| Wildcards | `%` for zero or more characters and `_` for one character |
| Column aliases | `AS monthly_salary`, `AS annual_salary`, and `AS full_name` |
| NULL values | `IS NULL`, `IS NOT NULL`, and `IFNULL()` |

This example combines comparison and logical operators. All three conditions
must evaluate to true:

```sql
SELECT first_name, last_name, department, salary, employment_status
FROM employees
WHERE department = 'IT'
  AND employment_status = 'Active'
  AND salary >= 80000;
```

Parentheses are important when combining `AND` and `OR`:

```sql
SELECT first_name, last_name, department, employment_status
FROM employees
WHERE NOT employment_status = 'Inactive'
  AND (department = 'IT' OR department = 'Finance');
```

Without the parentheses, SQL may evaluate the conditions differently from what
you intended because `AND` has higher precedence than `OR`.

Use arithmetic operators to calculate result columns and `AS` to give each
calculated column a clear alias:

```sql
SELECT
    first_name,
    last_name,
    salary AS monthly_salary,
    salary * 0.05 AS estimated_monthly_bonus,
    salary + (salary * 0.05) AS projected_monthly_pay,
    salary - 5000 AS monthly_salary_minus_5000,
    salary * 12 AS annual_salary,
    employee_id % 2 AS id_remainder
FROM employees
WHERE salary >= 60000;
```

`LIKE` uses wildcards when an exact text value is not known:

```sql
-- % matches zero or more characters
SELECT first_name, last_name, job_title
FROM employees
WHERE job_title LIKE '%Manager';

-- _ matches exactly one character
SELECT first_name, last_name
FROM employees
WHERE first_name LIKE '_a%';
```

NULL represents a missing or unknown value. Test it with `IS NULL` or
`IS NOT NULL`, never `= NULL` or `<> NULL`:

```sql
SELECT first_name, last_name, manager_id
FROM employees
WHERE manager_id IS NULL;
```

Other useful search operators demonstrated in the SQL script include:

- `BETWEEN` searches an inclusive range.
- `IN` matches any value in a list.
- `LIKE` searches a text pattern with `%` and `_` wildcards.
- `IS NULL` and `IS NOT NULL` test missing and present values.

---

## Part 3 — Required Query Features

Run Sections 3–9 of `employee-search-demo.sql`. Each requested feature has its
own query so you can change one expression at a time and compare the output.

| Feature | Examples included |
|---|---|
| Aggregate functions | `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()` |
| Conversion functions | `CAST()`, `CONVERT()` |
| Date functions | `CURDATE()`, `YEAR()`, `MONTHNAME()`, `DATEDIFF()`, `TIMESTAMPDIFF()` |
| String functions | `UPPER()`, `LOWER()`, `CONCAT()`, `TRIM()`, `SUBSTRING()`, `CHAR_LENGTH()` |
| Mathematical functions | `ROUND()`, `CEILING()`, `FLOOR()`, `ABS()`, `MOD()` |
| Control flow functions and expressions | `IF()`, `IFNULL()`, `CASE` |
| Distinct values | `DISTINCT department` and `DISTINCT department, city` |
| Counting | `COUNT(*)`, `COUNT(manager_id)`, `COUNT(DISTINCT department)` |
| Character strings | Single-quoted literals, `VARCHAR` columns, concatenation, length, substring, trimming, and pattern matching |

### Character strings and string functions

Character strings are written inside single quotes, such as `'Active'` and
`'%engineer%'`. Columns including `first_name`, `last_name`, `department`, and
`job_title` use `VARCHAR` because their text lengths vary.

```sql
SELECT
    first_name,
    last_name,
    CONCAT(first_name, ' ', last_name) AS full_name,
    CHAR_LENGTH(CONCAT(first_name, ' ', last_name)) AS full_name_length,
    SUBSTRING(first_name, 1, 3) AS first_three_characters,
    CONCAT(UPPER(department), ': ', TRIM(job_title)) AS employee_summary
FROM employees
WHERE LOWER(job_title) LIKE '%engineer%';
```

### Conversion functions

Use `CAST()` or `CONVERT()` when the result needs a different data type:

```sql
SELECT
    first_name,
    last_name,
    CAST(employee_id AS CHAR) AS employee_id_text,
    CAST(salary AS SIGNED) AS salary_whole_number,
    CONVERT(hire_date, CHAR) AS hire_date_text
FROM employees;
```

### Date functions

```sql
SELECT
    first_name,
    last_name,
    YEAR(hire_date) AS hire_year,
    MONTHNAME(hire_date) AS hire_month,
    DATEDIFF(CURDATE(), hire_date) AS days_employed,
    TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS completed_years
FROM employees;
```

> **Performance note:** Applying a function to an indexed column in `WHERE` can
> prevent normal index use. For production date searches, prefer a range such as
> `hire_date >= '2024-01-01' AND hire_date < '2025-01-01'` over
> `YEAR(hire_date) = 2024`.

### Mathematical functions

```sql
SELECT
    first_name,
    last_name,
    salary AS monthly_salary,
    ROUND(salary * 12, 2) AS annual_salary,
    CEILING(salary / 22) AS estimated_daily_rate_rounded_up,
    FLOOR(salary / 22) AS estimated_daily_rate_rounded_down,
    ABS(salary - 70000) AS difference_from_70000,
    MOD(employee_id, 2) AS employee_id_remainder
FROM employees;
```

### Control flow functions and expressions

`IF()` handles two outcomes, while `CASE` is clearer for multiple outcomes.
`IFNULL()` supplies a replacement when a value is NULL.

```sql
SELECT
    first_name,
    last_name,
    IF(employment_status = 'Active', 'Available', 'Unavailable') AS availability,
    IFNULL(CAST(manager_id AS CHAR), 'No Manager') AS manager_reference,
    CASE
        WHEN salary >= 90000 THEN 'Senior Salary Band'
        WHEN salary >= 60000 THEN 'Mid Salary Band'
        ELSE 'Entry Salary Band'
    END AS salary_band
FROM employees;
```

### `DISTINCT` and `COUNT`

```sql
SELECT DISTINCT department
FROM employees
ORDER BY department;

SELECT
    COUNT(*) AS total_employees,
    COUNT(manager_id) AS employees_with_manager,
    COUNT(DISTINCT department) AS distinct_departments
FROM employees;
```

- `DISTINCT` removes duplicate result rows.
- `COUNT(*)` counts every row.
- `COUNT(manager_id)` counts only rows whose `manager_id` is not NULL.
- `COUNT(DISTINCT department)` counts unique, non-NULL departments.

### Aggregate functions

Aggregate functions calculate one result from multiple rows:

```sql
SELECT
    COUNT(*) AS employee_count,
    SUM(salary) AS total_monthly_payroll,
    ROUND(AVG(salary), 2) AS average_monthly_salary,
    MIN(salary) AS lowest_monthly_salary,
    MAX(salary) AS highest_monthly_salary
FROM employees;
```

---

## Part 4 — `ORDER BY`, `GROUP BY`, and `HAVING`

Use `ORDER BY` to sort individual rows:

```sql
SELECT first_name, last_name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;
```

Use `GROUP BY` with aggregate functions to summarize rows:

```sql
SELECT
    department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS average_monthly_salary
FROM employees
GROUP BY department
ORDER BY average_monthly_salary DESC;
```

Use `HAVING` to filter the grouped results:

```sql
SELECT
    department,
    COUNT(*) AS active_employee_count,
    ROUND(AVG(salary), 2) AS average_active_monthly_salary
FROM employees
WHERE employment_status = 'Active'
GROUP BY department
HAVING COUNT(*) >= 2
   AND AVG(salary) >= 60000
ORDER BY average_active_monthly_salary DESC;
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
4. Display each employee ID as character text, and convert each salary to a
   signed whole number.
5. Display gross monthly salary, estimated annual salary, and monthly salary
   after a 5% increase. Use clear column aliases.
6. Use `IF()` or `CASE` to label each employee as `Active Staff`, `Temporarily
   Unavailable`, or `Former Staff`.
7. Return every distinct department and city combination.
8. Return the total row count, count of non-NULL manager IDs, and count of
   distinct departments in one result.
9. Use character-string functions to combine `first_name` and `last_name`,
   display an uppercase employee label, and count the characters in the full
   name.
10. **WHERE clause:** Return only employees from the Finance department.
11. **Comparison operators:** Find employees whose salary is greater than or
    equal to `60000` and less than `90000`, and whose status is not `Inactive`.
12. **Arithmetic operators:** Calculate a 7% monthly bonus, annual salary, and
    monthly salary plus bonus for every employee.
13. **Logical operators:** Find Active employees who work in IT or Finance, then
    exclude employees located in Makati by using `NOT`.
14. **Wildcards:** Use `%` to find job titles ending in `Manager`, then use `_`
    to find first names whose second character is `a`.
15. **Column aliases:** Display the combined first and last name as `full_name`,
    salary as `monthly_salary`, and salary multiplied by 12 as `annual_salary`.
16. **NULL values:** Write one query for employees without a manager and another
    for employees with a manager. Do not use `= NULL` or `<> NULL`.

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

Then return to the EC2 console and terminate `batch29-30-mariadb-lab`. Verify that
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

### The row count is greater than 30

Run the complete setup script again. It recreates the dedicated demo database and
loads exactly 30 rows.

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

## Salary Benchmark References

- [JobStreet Philippines salary insights for Cloud Engineers](https://ph.jobstreet.com/career-advice/role/cloud-engineer/salary)
- [A7 Recruitment Philippines Salary Guide 2026](https://a7recruitment.com/philippines-salary-guide-2026/)

These references informed the dataset's general monthly salary scale. The sample
values are intentionally varied for SQL practice and must not be treated as
compensation advice or guaranteed market rates.

---

## AWS References

- [Launch a test EC2 instance](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/tutorial-launch-a-test-ec2-instance.html)
- [Install MariaDB on Amazon Linux 2023](https://docs.aws.amazon.com/linux/al2023/ug/ec2-lamp-amazon-linux-2023.html)
- [Configure EC2 security groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/creating-security-group.html)

---

*AWS re/Start Batch 29 and 30 — MySQL Conditional Search and Data Organization*
