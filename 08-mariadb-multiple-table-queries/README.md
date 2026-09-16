# Retrieving Data from Multiple Tables with MariaDB

**AWS re/Start — Batch 29 and 30**<br>
**Duration:** 75–90 minutes<br>
**Format:** Independent, self-paced AWS Management Console and MariaDB command-line activity<br>
**Region:** `us-east-2` (Ohio)

---

## Learning Objectives

By the end of this activity, you will be able to:

1. Explain how primary keys and foreign keys relate tables.
2. Use table aliases and qualified column names in multi-table queries.
3. Retrieve matching rows with `INNER JOIN`.
4. Preserve unmatched rows with `LEFT JOIN` and `RIGHT JOIN`.
5. Join three or more tables through a many-to-many junction table.
6. Explain the `FULL OUTER JOIN` concept and implement its MariaDB equivalent.
7. Combine compatible result sets with `UNION` and `UNION ALL`.
8. Return common rows with `INTERSECT`.
9. Implement the `MINUS` concept with MariaDB's `EXCEPT` operator.
10. Recognize missing join conditions, duplicate rows, ambiguous columns, and
    outer-join filters that produce incorrect results.

---

## Before You Start

| Item | Requirement |
|---|---|
| AWS access | A sandbox account that permits EC2 and security-group operations |
| Region | `us-east-2` (Ohio) for all AWS resources |
| Compute | One disposable Amazon Linux 2023 EC2 instance |
| Database | MariaDB 10.5 or later |
| Database access | Local access through `sudo mariadb`; TCP/3306 is not required |
| Activity file | [`multiple-table-demo.sql`](multiple-table-demo.sql) |

> **Warning:** The SQL script drops and recreates a database named
> `multi_table_demo`. Use only a classroom or disposable MariaDB environment.

### Recommended prerequisite path

If you have just completed
[Lab 06 — MySQL Conditional Search](../06-mysql-conditional-search/), reuse its
EC2 instance **before** performing that lab's cleanup. Confirm MariaDB is running:

```bash
sudo systemctl is-active mariadb
mysql --version
```

Expected evidence:

```text
active
mysql  Ver ... Distrib 10.5...-MariaDB
```

If you need a new instance, follow **Part 0 — Build the EC2 and MariaDB
Prerequisites** in Lab 06. Apply the same safeguards:

- Allow SSH on TCP/22 only from your current public IP address.
- Do not expose MariaDB/MySQL port `3306` to the internet.
- Use an encrypted `gp3` EBS volume.
- Terminate the disposable instance after the activity.

---

## MariaDB Compatibility Notes

This activity teaches both SQL concepts and the syntax actually supported by the
MariaDB 10.5 environment used in these labs.

| Requested concept | MariaDB 10.5 syntax used in this lab | Support note |
|---|---|---|
| Union without duplicates | `UNION` | Supported |
| Union with duplicates | `UNION ALL` | Supported |
| Intersection | `INTERSECT` | Supported since MariaDB 10.3 |
| Minus or set difference | `EXCEPT` | `MINUS` is Oracle terminology |
| Inner join | `INNER JOIN` | Supported |
| Left outer join | `LEFT JOIN` | Supported |
| Right outer join | `RIGHT JOIN` | Supported |
| Full outer join | `LEFT JOIN` + `UNION ALL` + unmatched `RIGHT JOIN` rows | No native `FULL OUTER JOIN` keyword in MariaDB 10.5 |

### Why the lab uses `EXCEPT` instead of `MINUS`

`MINUS` and `EXCEPT` express the same set-difference idea: return rows from the
first result set that are absent from the second. MariaDB 10.5 supports
`EXCEPT`. MariaDB introduced `MINUS` only in version 10.6.1, and only as an
Oracle-compatible synonym when `SQL_MODE=ORACLE` is enabled.

Do not change the server's SQL mode merely to make one keyword work. Learn the
portable concept and use the syntax supported by the current database engine.

```sql
-- MariaDB 10.5: runnable
SELECT city FROM employees
EXCEPT
SELECT city FROM contractors;

-- Oracle terminology: do not run on MariaDB 10.5
-- SELECT city FROM employees
-- MINUS
-- SELECT city FROM contractors;
```

### Why the lab emulates `FULL OUTER JOIN`

MariaDB 10.5 supports `INNER`, `LEFT`, and `RIGHT` joins but does not implement a
native `FULL OUTER JOIN` keyword. The correct classroom equivalent combines:

1. All rows preserved by a `LEFT JOIN`.
2. Only the unmatched rows from the opposite side.
3. `UNION ALL` to combine the two parts.

The second query must filter to unmatched rows. Without that anti-match filter,
matched rows appear twice.

---

## Activity Architecture

```text
departments (1) ───────────────< employees (many)
      |                              |
      |                              |
      v                              v
projects (many) >── employee_projects ──< employees
                         junction table

contractors
    └── independent worker list used for set operations
```

Relationships:

- One department can have many employees.
- One department can own many projects.
- One employee can join many projects.
- One project can have many employees.
- `employee_projects` resolves the many-to-many employee/project relationship.
- `contractors` is intentionally independent so its result sets can be compared
  with employee result sets.

The sample data deliberately includes:

- A department with no employees.
- An employee with no department.
- Employees with no project assignment.
- Projects with no assigned employees.
- A project with no owning department.
- Cities shared by employees and contractors.
- Cities present in only one worker table.

These unmatched records make the outer joins and set operations observable.

---

## Part 1 — Get and Load the Activity

### Step 1: Get the repository

On the EC2 instance:

```bash
git clone https://github.com/jjrs07/restart_batch_29_and_30.git
cd restart_batch_29_and_30/08-mariadb-multiple-table-queries
```

If the repository already exists, update it instead of cloning a duplicate:

```bash
cd ~/restart_batch_29_and_30
git pull --ff-only
cd 08-mariadb-multiple-table-queries
```

Confirm the activity files:

```bash
ls -l README.md multiple-table-demo.sql
```

### Step 2: Load the database

```bash
sudo mariadb < multiple-table-demo.sql
```

The script creates the database, tables, keys, indexes, sample records, and
demonstration queries. It prints several result sets by design.

Open the MariaDB client for individual practice:

```bash
sudo mariadb multi_table_demo
```

### Step 3: Verify the tables and row counts

```sql
SHOW TABLES;

SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'projects', COUNT(*) FROM projects
UNION ALL
SELECT 'employee_projects', COUNT(*) FROM employee_projects
UNION ALL
SELECT 'contractors', COUNT(*) FROM contractors;
```

Expected counts:

| Table | Rows |
|---|---:|
| `departments` | 7 |
| `employees` | 30 |
| `projects` | 11 |
| `employee_projects` | 34 |
| `contractors` | 8 |

Checkpoint:

```sql
SHOW CREATE TABLE employee_projects\G
```

Identify:

- The two-column primary key.
- The foreign key to `employees`.
- The foreign key to `projects`.
- Why the table represents a many-to-many relationship.

---

## Part 2 — Join Two or More Tables

### 1. Use table aliases and qualified columns

Both `employees` and `departments` contain a column named `department_id`.
Qualify shared column names with their table aliases:

```sql
SELECT
    e.employee_id,
    e.first_name,
    e.last_name,
    d.department_name
FROM employees AS e
INNER JOIN departments AS d
    ON d.department_id = e.department_id;
```

- `e` is the alias for `employees`.
- `d` is the alias for `departments`.
- The `ON` clause defines how rows relate.

### 2. `INNER JOIN`

An inner join returns only rows whose join condition matches on both sides.

```sql
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    e.job_title
FROM employees AS e
INNER JOIN departments AS d
    ON d.department_id = e.department_id
ORDER BY d.department_name, e.last_name;
```

Employee 30 does not appear because that record has no department.

### 3. Join four tables

Move through the relationship chain from employees to projects:

```sql
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    p.project_name,
    ep.project_role,
    ep.hours_per_week
FROM employees AS e
INNER JOIN departments AS d
    ON d.department_id = e.department_id
INNER JOIN employee_projects AS ep
    ON ep.employee_id = e.employee_id
INNER JOIN projects AS p
    ON p.project_id = ep.project_id
ORDER BY p.project_name, employee_name;
```

Follow each join one step at a time:

```text
employee -> department
employee -> employee_projects
employee_projects -> project
```

### 4. `LEFT JOIN`

A left join preserves every row from the table written on the left.

```sql
SELECT
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM departments AS d
LEFT JOIN employees AS e
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_id;
```

The Legal department remains visible with an employee count of `0`.

Use `LEFT JOIN` plus a `NULL` test to find anti-matches:

```sql
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name
FROM employees AS e
LEFT JOIN employee_projects AS ep
    ON ep.employee_id = e.employee_id
WHERE ep.project_id IS NULL
ORDER BY e.employee_id;
```

### 5. `RIGHT JOIN`

A right join preserves every row from the table written on the right.

```sql
SELECT
    d.department_name,
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name
FROM departments AS d
RIGHT JOIN employees AS e
    ON e.department_id = d.department_id
ORDER BY e.employee_id;
```

Employee 30 remains visible with a `NULL` department. The same logic can usually
be expressed as a `LEFT JOIN` by reversing the table order. Teams often
standardize on left joins for readability, but understanding right joins is
still important when reading existing SQL.

### 6. Emulate `FULL OUTER JOIN`

```sql
SELECT
    d.department_id,
    d.department_name,
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name
FROM departments AS d
LEFT JOIN employees AS e
    ON e.department_id = d.department_id

UNION ALL

SELECT
    d.department_id,
    d.department_name,
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name
FROM departments AS d
RIGHT JOIN employees AS e
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL
ORDER BY department_id, employee_id;
```

Observe both unmatched cases:

- The Legal department has no employee.
- Employee 30 has no department.

---

## Part 3 — Set Operators

Set operators combine the output of complete `SELECT` statements. The queries
on both sides must return the same number of columns in compatible positions.

### 1. `UNION`

Return each city only once:

```sql
SELECT city FROM employees
UNION
SELECT city FROM contractors
ORDER BY city;
```

`UNION` applies duplicate removal to the combined result.

### 2. `UNION ALL`

Keep every city occurrence:

```sql
SELECT city FROM employees
UNION ALL
SELECT city FROM contractors
ORDER BY city;
```

`UNION ALL` normally does less duplicate-removal work and preserves repeated
rows. Use it when duplicates are meaningful or when the inputs are already
known to be distinct.

Add a constant column when the source matters:

```sql
SELECT 'Employee' AS worker_type, first_name, last_name, city
FROM employees
UNION ALL
SELECT 'Contractor', first_name, last_name, city
FROM contractors
ORDER BY city, worker_type, last_name;
```

### 3. `INTERSECT`

Return cities appearing in both tables:

```sql
SELECT city FROM employees
INTERSECT
SELECT city FROM contractors
ORDER BY city;
```

### 4. `MINUS` concept with `EXCEPT`

Return employee cities that do not appear in the contractor table:

```sql
SELECT city FROM employees
EXCEPT
SELECT city FROM contractors
ORDER BY city;
```

Reverse the inputs to answer the opposite business question:

```sql
SELECT city FROM contractors
EXCEPT
SELECT city FROM employees
ORDER BY city;
```

Set difference is directional:

```text
A EXCEPT B is not the same as B EXCEPT A
```

Equivalent anti-set logic can also be written with `NOT EXISTS`:

```sql
SELECT DISTINCT e.city
FROM employees AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM contractors AS c
    WHERE c.city = e.city
)
ORDER BY e.city;
```

---

## Part 4 — Join and Aggregate

Outer joins are useful when a summary must retain zero-count parent rows:

```sql
SELECT
    p.project_id,
    p.project_name,
    p.project_status,
    COUNT(ep.employee_id) AS assigned_employee_count,
    COALESCE(SUM(ep.hours_per_week), 0) AS total_hours_per_week
FROM projects AS p
LEFT JOIN employee_projects AS ep
    ON ep.project_id = p.project_id
GROUP BY p.project_id, p.project_name, p.project_status
ORDER BY assigned_employee_count DESC, p.project_name;
```

Why use `COUNT(ep.employee_id)` instead of `COUNT(*)`?

- The left join creates one result row even when a project has no assignment.
- `COUNT(*)` would count that preserved row.
- `COUNT(ep.employee_id)` ignores the `NULL` generated for the missing match.

---

## Practice Challenges

Write and run queries for these requirements. The SQL file repeats the tasks but
does not include completed answers.

1. Join employees and departments. Return only Finance employees.
2. Join employees, assignments, and projects. Return employees assigned to an
   `Active` project.
3. Use four tables to display employee, department, project, role, and weekly
   hours.
4. Return every project, including projects with no assigned employees.
5. Use `RIGHT JOIN` between assignments and projects to return every project,
   including projects with no assigned employees.
6. Emulate a full outer join between departments and employees.
7. Use `UNION` to return unique employee and contractor cities.
8. Use `UNION ALL` and `GROUP BY` to count all worker records per city.
9. Use `INTERSECT` to return cities shared by employees and contractors.
10. Use `EXCEPT` to implement the `MINUS` concept and return contractor-only
    cities.
11. Return employees who have no project assignment.
12. Return departments that have no employees.
13. Return every project with its assignment count, including zero.
14. Compare a right-table filter placed inside `ON` with the same filter placed
    in `WHERE` after a `LEFT JOIN`. Explain the difference.
15. Intentionally omit one join condition, observe the row count, and then stop
    the query. Explain why a Cartesian product occurred.

For every query, verify:

- The returned rows.
- The column headings.
- Whether unmatched rows should be preserved.
- Whether duplicates are meaningful.
- Whether the result answers the stated business question.

---

## Troubleshooting

### `ERROR 1052: Column ... is ambiguous`

More than one joined table contains the same column name. Qualify it:

```sql
-- Ambiguous
SELECT department_id FROM employees e JOIN departments d
    ON d.department_id = e.department_id;

-- Clear
SELECT e.department_id FROM employees e JOIN departments d
    ON d.department_id = e.department_id;
```

### The result contains far too many rows

Check for a missing or incorrect `ON` condition. Without a relationship
condition, every row from one input can combine with every row from another.

Estimate the risk before running a suspected Cartesian product:

```sql
SELECT
    (SELECT COUNT(*) FROM employees) AS employee_rows,
    (SELECT COUNT(*) FROM projects) AS project_rows,
    (SELECT COUNT(*) FROM employees) *
    (SELECT COUNT(*) FROM projects) AS possible_combinations;
```

### A `LEFT JOIN` stopped returning unmatched rows

A filter on the right-hand table in `WHERE` can reject the generated `NULL`
rows:

```sql
-- This removes projects without an Active assignment match.
SELECT p.project_name, ep.employee_id
FROM projects p
LEFT JOIN employee_projects ep
    ON ep.project_id = p.project_id
WHERE ep.hours_per_week >= 10;
```

When the filter is part of the relationship, place it in `ON`:

```sql
SELECT p.project_name, ep.employee_id
FROM projects p
LEFT JOIN employee_projects ep
    ON ep.project_id = p.project_id
   AND ep.hours_per_week >= 10;
```

### `MINUS` returns a syntax error

MariaDB 10.5 does not implement the `MINUS` keyword. Use `EXCEPT`, which expresses
the same set-difference operation in this environment.

### `FULL OUTER JOIN` returns a syntax error

Use the two-query emulation shown in Part 2. Include the anti-match condition in
the second query so matched rows are not returned twice.

### `INTERSECT` or `EXCEPT` is not recognized

Check the actual server version:

```sql
SELECT VERSION();
```

This lab requires MariaDB 10.5 or later. Do not assume that a command named
`mysql` means the server is MySQL; MariaDB commonly provides a compatible client
command.

### A foreign-key insert fails

Insert parent rows before child rows:

```text
departments before employees and projects
employees and projects before employee_projects
```

Do not disable foreign-key checks to hide incorrect data. Fix the missing parent
record or incorrect key.

### The joined result has duplicate employees

Duplicates can be correct. An employee assigned to two projects should appear
twice in an employee-to-project result. Decide whether the business question
needs:

- One row per assignment.
- One row per employee using `DISTINCT`.
- One summary row per employee using `GROUP BY`.

---

## Validation Checklist

- [ ] MariaDB is active and version 10.5 or later.
- [ ] Five tables exist in `multi_table_demo`.
- [ ] Row counts match the expected values.
- [ ] The two-table inner join excludes the employee without a department.
- [ ] The four-table join returns project assignments and roles.
- [ ] The left join preserves the Legal department.
- [ ] The right join preserves employee 30.
- [ ] The full-join emulation shows both unmatched cases without duplicating
      matched rows.
- [ ] `UNION` removes duplicate cities.
- [ ] `UNION ALL` preserves duplicate cities.
- [ ] `INTERSECT` returns shared cities.
- [ ] `EXCEPT` demonstrates the `MINUS` concept.
- [ ] Projects 107 and 111 appear with zero assignments.

---

## Clean Up

Inside MariaDB, delete the activity database:

```sql
DROP DATABASE IF EXISTS multi_table_demo;
EXIT;
```

Confirm that it no longer exists. The command should return no output:

```bash
sudo mariadb --batch --skip-column-names -e \
  "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'multi_table_demo';"
```

If the EC2 instance was created only for this activity:

1. Terminate the instance.
2. Confirm it reaches the `Terminated` state.
3. Confirm the disposable EBS volume is deleted.
4. Delete the lab-only security group after its network interfaces disappear.
5. Delete the lab key pair and securely remove its private key if it will not be
   reused.

> **Cost point:** Stopping an instance stops compute charges, but retained EBS
> volumes can continue to incur storage charges. Terminate disposable resources
> and verify cleanup.

---

## Key Takeaways

- A join combines columns from related tables.
- A set operator combines compatible rows from complete query results.
- `INNER JOIN` keeps matches; outer joins preserve selected unmatched rows.
- Multi-table joins should follow declared key relationships.
- Junction tables represent many-to-many relationships.
- `UNION` removes duplicates; `UNION ALL` preserves them.
- `INTERSECT` returns common rows.
- MariaDB 10.5 uses `EXCEPT` for the `MINUS` concept.
- MariaDB 10.5 requires an emulation for `FULL OUTER JOIN`.
- Missing join conditions and misplaced filters can return valid SQL with
  incorrect business results.

---

## Reference Documentation

- [MariaDB JOIN syntax](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/joins-subqueries/joins/join-syntax)
- [MariaDB joining tables guide](https://mariadb.com/docs/server/mariadb-quickstart-guides/mariadb-join-guide)
- [MariaDB UNION](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/set-operations/union)
- [MariaDB INTERSECT](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/set-operations/intersect)
- [MariaDB EXCEPT](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/set-operations/except)
- [MariaDB MINUS compatibility](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/set-operations/minus)

---

*AWS re/Start Batch 29 and 30 — Retrieving Data from Multiple Tables*
