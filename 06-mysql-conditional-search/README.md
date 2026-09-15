# MySQL Conditional Search and Data Organization

**AWS re/Start — Batch 29**<br>
**Duration:** 35–45 minutes<br>
**Format:** Follow along in MySQL Workbench or the MySQL command-line client.

---

## Learning Objectives

By the end of this activity, you will be able to:

1. Filter records with `WHERE`, `AND`, `OR`, `BETWEEN`, `IN`, `LIKE`, and `IS NULL`
2. Use string, date, numeric, NULL-handling, and conditional functions
3. Sort results with `ORDER BY`
4. Summarize records with aggregate functions and `GROUP BY`
5. Filter grouped results with `HAVING`

---

## Before You Start

| Item | Requirement |
|---|---|
| Database | MySQL 8.0 or later |
| Client | MySQL Workbench or the `mysql` command-line client |
| Access | Permission to create and drop a database |
| Script | [`employee-search-demo.sql`](employee-search-demo.sql) |

> **Warning:** The script drops and recreates a database named
> `conditional_search_demo`. Run it only in a classroom or disposable MySQL
> environment. Do not reuse that database name for production data.

---

## Activity Architecture

```text
conditional_search_demo database
└── employees table (20 rows)
    ├── WHERE filters individual rows
    ├── functions calculate or transform values
    ├── GROUP BY creates summary groups
    ├── HAVING filters the groups
    └── ORDER BY sorts the final result
```

The examples use one table so the focus stays on query logic rather than joins.
The data includes different departments, salaries, cities, employment statuses,
hire dates, and NULL manager values so each condition returns a useful result.

---

## Part 1 — Create the Demo Data

### Option A: MySQL Workbench

1. Open `employee-search-demo.sql` in MySQL Workbench.
2. Connect to your classroom MySQL instance.
3. Run the script one section at a time.

### Option B: MySQL command line

From this lab folder, run:

```bash
mysql -u root -p < employee-search-demo.sql
```

Enter the password when prompted. Do not include a password directly in the
command because it may be stored in shell history or exposed in the process list.

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

After completing the activity, remove only the demo database:

```sql
DROP DATABASE IF EXISTS conditional_search_demo;
```

**Checkpoint:** This query should return no rows:

```sql
SELECT SCHEMA_NAME
FROM INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME = 'conditional_search_demo';
```

---

## Troubleshooting

### `ERROR 1046: No database selected`

Select the demo database before running the queries:

```sql
USE conditional_search_demo;
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

*AWS re/Start Batch 29 — MySQL Conditional Search and Data Organization*
