-- AWS re/Start Batch 29
-- MySQL Conditional Search and Data Organization Demo
-- Target: MariaDB 10.5+ or MySQL 8.0+
--
-- WARNING: This script recreates the conditional_search_demo database.
-- Run it only in a classroom or disposable MySQL environment.

DROP DATABASE IF EXISTS conditional_search_demo;
CREATE DATABASE conditional_search_demo;
USE conditional_search_demo;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    department VARCHAR(50) NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    employment_status ENUM('Active', 'On Leave', 'Inactive') NOT NULL,
    city VARCHAR(50) NOT NULL,
    manager_id INT NULL,
    hire_date DATE NOT NULL,
    CONSTRAINT chk_employees_salary CHECK (salary >= 0)
);

INSERT INTO employees (
    employee_id,
    employee_name,
    department,
    job_title,
    salary,
    employment_status,
    city,
    manager_id,
    hire_date
)
VALUES
    (1,  'Ana Cruz',         'IT',         'Cloud Engineer',        85000.00, 'Active',   'Manila',      5,    '2022-03-15'),
    (2,  'Ben Santos',       'IT',         'Database Administrator',92000.00, 'Active',   'Quezon City', 5,    '2021-07-01'),
    (3,  'Carla Reyes',      'Finance',    'Accountant',            58000.00, 'On Leave', 'Makati',      7,    '2023-01-10'),
    (4,  'David Lim',        'HR',         'Recruiter',             52000.00, 'Active',   'Pasig',       9,    '2024-02-20'),
    (5,  'Ella Tan',         'IT',         'DevOps Manager',        98000.00, 'Active',   'Makati',      NULL, '2020-11-05'),
    (6,  'Fred Garcia',      'Sales',      'Sales Associate',       45000.00, 'Inactive', 'Manila',      8,    '2019-06-18'),
    (7,  'Grace Lee',        'Finance',    'Finance Manager',       72000.00, 'Active',   'Taguig',      NULL, '2022-09-12'),
    (8,  'Henry Ong',        'Sales',      'Sales Manager',         88000.00, 'Active',   'Pasig',       NULL, '2018-04-25'),
    (9,  'Ivy Ramos',        'HR',         'HR Manager',            81000.00, 'Active',   'Manila',      NULL, '2019-08-14'),
    (10, 'John Flores',      'IT',         'Support Engineer',      48000.00, 'On Leave', 'Quezon City', 5,    '2024-05-06'),
    (11, 'Karen Mendoza',    'IT',         'Systems Administrator', 68000.00, 'Active',   'Taguig',      5,    '2023-06-19'),
    (12, 'Leo Bautista',     'Finance',    'Senior Accountant',     79000.00, 'Active',   'Makati',      7,    '2020-02-11'),
    (13, 'Maria Villanueva', 'HR',         'HR Specialist',         56000.00, 'Active',   'Quezon City', 9,    '2022-12-05'),
    (14, 'Nathan Chua',      'Sales',      'Sales Associate',       47000.00, 'Active',   'Manila',      8,    '2024-07-08'),
    (15, 'Olivia Navarro',   'IT',         'Security Engineer',     95000.00, 'On Leave', 'Pasig',       5,    '2021-09-27'),
    (16, 'Paul Aquino',      'Operations', 'Operations Analyst',    61000.00, 'Active',   'Taguig',      18,   '2023-04-17'),
    (17, 'Queenie Dela Cruz','Marketing',  'Marketing Specialist',  54000.00, 'Active',   'Makati',      20,   '2024-01-22'),
    (18, 'Robert Castillo',  'Operations', 'Operations Manager',    86000.00, 'Active',   'Manila',      NULL, '2019-10-30'),
    (19, 'Sophia Torres',    'Finance',    'Payroll Specialist',    63000.00, 'Inactive', 'Pasig',       7,    '2022-05-16'),
    (20, 'Thomas Yu',        'Marketing',  'Marketing Manager',     83000.00, 'Active',   'Quezon City', NULL, '2020-08-03');

-- ================================================================
-- 1. Validate the dataset
-- ================================================================

SELECT COUNT(*) AS total_employees
FROM employees;

-- Expected result: 20

-- ================================================================
-- 2. Conditional searches with WHERE
-- ================================================================

-- One condition
SELECT *
FROM employees
WHERE department = 'IT';

-- Multiple required conditions
SELECT employee_name, department, salary, employment_status
FROM employees
WHERE department = 'IT'
  AND employment_status = 'Active'
  AND salary >= 80000;

-- Alternative conditions; parentheses make the intent explicit
SELECT employee_name, department, employment_status
FROM employees
WHERE employment_status = 'Active'
  AND (department = 'IT' OR department = 'Finance');

-- Search a numeric range
SELECT employee_name, salary
FROM employees
WHERE salary BETWEEN 50000 AND 80000
ORDER BY salary DESC;

-- Search a list of values
SELECT employee_name, city
FROM employees
WHERE city IN ('Manila', 'Makati', 'Taguig')
ORDER BY city, employee_name;

-- Search part of a string
SELECT employee_name, job_title
FROM employees
WHERE job_title LIKE '%Engineer%';

-- Search for missing values
SELECT employee_name, job_title
FROM employees
WHERE manager_id IS NULL;

-- Use a range instead of YEAR(hire_date) so an index on hire_date can be used
SELECT employee_name, hire_date
FROM employees
WHERE hire_date >= '2024-01-01'
  AND hire_date < '2025-01-01'
ORDER BY hire_date;

-- ================================================================
-- 3. Character strings and string functions
-- ================================================================

-- Character strings are enclosed in single quotes. VARCHAR columns such as
-- employee_name, department, and job_title store variable-length strings.
SELECT
    employee_name,
    CHAR_LENGTH(employee_name) AS name_length,
    SUBSTRING(employee_name, 1, 3) AS first_three_characters,
    CONCAT(UPPER(department), ': ', TRIM(job_title)) AS employee_summary
FROM employees
WHERE LOWER(job_title) LIKE '%engineer%'
ORDER BY employee_name;

-- ================================================================
-- 4. Conversion functions
-- ================================================================

SELECT
    employee_name,
    CAST(employee_id AS CHAR) AS employee_id_text,
    CAST(salary AS SIGNED) AS salary_whole_number,
    CONVERT(hire_date, CHAR) AS hire_date_text
FROM employees
ORDER BY employee_id;

-- ================================================================
-- 5. Date functions
-- ================================================================

SELECT
    employee_name,
    hire_date,
    YEAR(hire_date) AS hire_year,
    MONTHNAME(hire_date) AS hire_month,
    DATEDIFF(CURDATE(), hire_date) AS days_employed,
    TIMESTAMPDIFF(YEAR, hire_date, CURDATE()) AS completed_years
FROM employees
WHERE hire_date < CURDATE()
ORDER BY hire_date;

-- ================================================================
-- 6. Mathematical functions
-- ================================================================

SELECT
    employee_name,
    salary AS annual_salary,
    ROUND(salary / 12, 2) AS monthly_salary,
    CEILING(salary / 12) AS monthly_salary_rounded_up,
    FLOOR(salary / 12) AS monthly_salary_rounded_down,
    ABS(salary - 70000) AS difference_from_70000,
    MOD(employee_id, 2) AS employee_id_remainder
FROM employees
WHERE salary >= 80000
ORDER BY monthly_salary DESC;

-- ================================================================
-- 7. Control flow functions and expressions
-- ================================================================

SELECT
    employee_name,
    IF(employment_status = 'Active', 'Available', 'Unavailable') AS availability,
    IFNULL(CAST(manager_id AS CHAR), 'No Manager') AS manager_reference,
    CASE
        WHEN salary >= 90000 THEN 'Senior Salary Band'
        WHEN salary >= 60000 THEN 'Mid Salary Band'
        ELSE 'Entry Salary Band'
    END AS salary_band
FROM employees
ORDER BY salary DESC;

-- ================================================================
-- 8. DISTINCT and COUNT
-- ================================================================

-- DISTINCT removes duplicate result rows
SELECT DISTINCT department
FROM employees
ORDER BY department;

-- DISTINCT can evaluate a unique combination of multiple columns
SELECT DISTINCT department, city
FROM employees
ORDER BY department, city;

-- COUNT(*) counts rows; COUNT(column) ignores NULL values; and
-- COUNT(DISTINCT column) counts unique non-NULL values.
SELECT
    COUNT(*) AS total_employees,
    COUNT(manager_id) AS employees_with_manager,
    COUNT(*) - COUNT(manager_id) AS employees_without_manager,
    COUNT(DISTINCT department) AS distinct_departments,
    COUNT(DISTINCT city) AS distinct_cities
FROM employees;

-- ================================================================
-- 9. Aggregate functions
-- ================================================================

SELECT
    COUNT(*) AS employee_count,
    SUM(salary) AS total_salary,
    ROUND(AVG(salary), 2) AS average_salary,
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employees;

-- ================================================================
-- 10. Organize data with ORDER BY
-- ================================================================

-- Sort departments alphabetically, then salaries highest to lowest
SELECT employee_name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;

-- ================================================================
-- 11. Summarize data with GROUP BY
-- ================================================================

SELECT
    department,
    COUNT(*) AS employee_count,
    SUM(employment_status = 'Active') AS active_employee_count,
    ROUND(AVG(salary), 2) AS average_salary,
    MIN(salary) AS lowest_salary,
    MAX(salary) AS highest_salary
FROM employees
GROUP BY department
ORDER BY average_salary DESC;

-- ================================================================
-- 12. Filter grouped results with HAVING
-- ================================================================

-- WHERE filters rows before grouping; HAVING filters groups afterward
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

-- ================================================================
-- 13. Practice challenge queries
-- ================================================================

-- Challenge 1: Find active employees in Manila or Makati who earn at
-- least 60000. Sort the highest salary first.

-- Challenge 2: Show each city's employee count and average salary.
-- Return only cities with at least three employees.

-- Challenge 3: Find employees whose job title contains "Manager" and
-- display how many completed years they have worked.

-- Challenge 4: Display each employee ID as character text, and convert
-- each salary to a signed whole number.

-- Challenge 5: Display monthly salary rounded to two decimal places and
-- the employee's salary after a 5 percent increase.

-- Challenge 6: Use IF or CASE to label each employee as Active Staff,
-- Temporarily Unavailable, or Former Staff.

-- Challenge 7: Return every distinct department and city combination.

-- Challenge 8: Return the total row count, the count of non-NULL manager
-- IDs, and the count of distinct departments in one result.

-- Challenge 9: Use character-string functions to display an uppercase
-- employee label and the number of characters in each employee's name.
