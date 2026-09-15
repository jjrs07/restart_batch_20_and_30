-- AWS re/Start Batch 29
-- MySQL Conditional Search and Data Organization Demo
-- Target: MariaDB 10.5+ or MySQL 8.0+
-- Salary values are illustrative gross monthly Philippine pesos (PHP).
--
-- WARNING: This script recreates the conditional_search_demo database.
-- Run it only in a classroom or disposable MySQL environment.

DROP DATABASE IF EXISTS conditional_search_demo;
CREATE DATABASE conditional_search_demo;
USE conditional_search_demo;

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    department VARCHAR(50) NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    salary DECIMAL(10,2) NOT NULL COMMENT 'Illustrative gross monthly salary in PHP',
    employment_status ENUM('Active', 'On Leave', 'Inactive') NOT NULL,
    city VARCHAR(50) NOT NULL,
    manager_id INT NULL,
    hire_date DATE NOT NULL,
    CONSTRAINT chk_employees_salary CHECK (salary >= 0)
);

INSERT INTO employees (
    employee_id,
    first_name,
    last_name,
    department,
    job_title,
    salary,
    employment_status,
    city,
    manager_id,
    hire_date
)
VALUES
    (1,  'Ana',    'Cruz',        'IT',         'Cloud Engineer',         105000.00, 'Active',   'Manila',      5,    '2022-03-15'),
    (2,  'Ben',    'Santos',      'IT',         'Database Administrator', 115000.00, 'Active',   'Quezon City', 5,    '2021-07-01'),
    (3,  'Carla',  'Reyes',       'Finance',    'Accountant',              60000.00, 'On Leave', 'Makati',      7,    '2023-01-10'),
    (4,  'David',  'Lim',         'HR',         'Recruiter',               45000.00, 'Active',   'Pasig',       9,    '2024-02-20'),
    (5,  'Ella',   'Tan',         'IT',         'DevOps Manager',         180000.00, 'Active',   'Makati',      NULL, '2020-11-05'),
    (6,  'Fred',   'Garcia',      'Sales',      'Sales Associate',         35000.00, 'Inactive', 'Manila',      8,    '2019-06-18'),
    (7,  'Grace',  'Lee',         'Finance',    'Finance Manager',        120000.00, 'Active',   'Taguig',      NULL, '2022-09-12'),
    (8,  'Henry',  'Ong',         'Sales',      'Sales Manager',          105000.00, 'Active',   'Pasig',       NULL, '2018-04-25'),
    (9,  'Ivy',    'Ramos',       'HR',         'HR Manager',             100000.00, 'Active',   'Manila',      NULL, '2019-08-14'),
    (10, 'John',   'Flores',      'IT',         'Support Engineer',        55000.00, 'On Leave', 'Quezon City', 5,    '2024-05-06'),
    (11, 'Karen',  'Mendoza',     'IT',         'Systems Administrator',   75000.00, 'Active',   'Taguig',      5,    '2023-06-19'),
    (12, 'Leo',    'Bautista',    'Finance',    'Senior Accountant',       80000.00, 'Active',   'Makati',      7,    '2020-02-11'),
    (13, 'Maria',  'Villanueva',  'HR',         'HR Specialist',           50000.00, 'Active',   'Quezon City', 9,    '2022-12-05'),
    (14, 'Nathan', 'Chua',        'Sales',      'Sales Associate',         38000.00, 'Active',   'Manila',      8,    '2024-07-08'),
    (15, 'Olivia', 'Navarro',     'IT',         'Security Engineer',      125000.00, 'On Leave', 'Pasig',       5,    '2021-09-27'),
    (16, 'Paul',   'Aquino',      'Operations', 'Operations Analyst',      60000.00, 'Active',   'Taguig',      18,   '2023-04-17'),
    (17, 'Queenie','Dela Cruz',   'Marketing',  'Marketing Specialist',    50000.00, 'Active',   'Makati',      20,   '2024-01-22'),
    (18, 'Robert', 'Castillo',    'Operations', 'Operations Manager',     110000.00, 'Active',   'Manila',      NULL, '2019-10-30'),
    (19, 'Sophia', 'Torres',      'Finance',    'Payroll Specialist',      55000.00, 'Inactive', 'Pasig',       7,    '2022-05-16'),
    (20, 'Thomas', 'Yu',          'Marketing',  'Marketing Manager',      100000.00, 'Active',   'Quezon City', NULL, '2020-08-03'),
    (21, 'Ursula', 'Delgado',     'IT',         'Software Engineer',       80000.00, 'Active',   'Cebu City',   5,    '2023-09-11'),
    (22, 'Victor', 'Salazar',     'Sales',      'Account Executive',       65000.00, 'Active',   'Davao City',  8,    '2022-07-18'),
    (23, 'Wendy',  'Co',          'Finance',    'Financial Analyst',       65000.00, 'Active',   'Quezon City', 7,    '2024-03-04'),
    (24, 'Xavier', 'Mercado',     'Operations', 'Logistics Coordinator',   50000.00, 'On Leave', 'Pasig',       18,   '2021-12-13'),
    (25, 'Yvonne', 'Sy',          'Marketing',  'Content Strategist',      58000.00, 'Active',   'Manila',      20,   '2023-08-28'),
    (26, 'Zachary','Go',          'HR',         'Training Specialist',     55000.00, 'Active',   'Makati',      9,    '2022-10-07'),
    (27, 'Angela', 'Dominguez',   'IT',         'Cloud Support Engineer',  70000.00, 'Active',   'Cebu City',   5,    '2024-06-17'),
    (28, 'Brian',  'Velasco',     'Finance',    'Auditor',                 60000.00, 'Inactive', 'Davao City',  7,    '2020-05-21'),
    (29, 'Camille','Padilla',     'Sales',      'Sales Analyst',           55000.00, 'Active',   'Taguig',      8,    '2023-11-06'),
    (30, 'Daniel', 'Soriano',     'Operations', 'Site Reliability Engineer', 130000.00, 'Active', 'Quezon City', 18,   '2021-01-25');

-- ================================================================
-- 1. Validate the dataset
-- ================================================================

SELECT COUNT(*) AS total_employees
FROM employees;

-- Expected result: 30

DESCRIBE employees;

-- Expected columns include first_name and last_name; employee_name is removed.

-- ================================================================
-- 2. Conditional searches with WHERE
-- ================================================================

-- WHERE clause with the comparison operator =
SELECT *
FROM employees
WHERE department = 'IT';

-- Comparison operators: <>, >=, and <
SELECT first_name, last_name, salary, employment_status
FROM employees
WHERE employment_status <> 'Inactive'
  AND salary >= 60000
  AND salary < 90000
ORDER BY salary DESC;

-- Logical operator AND: all conditions must be true
SELECT first_name, last_name, department, salary, employment_status
FROM employees
WHERE department = 'IT'
  AND employment_status = 'Active'
  AND salary >= 80000;

-- Logical operators AND, OR, and NOT; parentheses make the intent explicit
SELECT first_name, last_name, department, employment_status
FROM employees
WHERE NOT employment_status = 'Inactive'
  AND (department = 'IT' OR department = 'Finance');

-- Search a numeric range
SELECT first_name, last_name, salary
FROM employees
WHERE salary BETWEEN 50000 AND 80000
ORDER BY salary DESC;

-- Search a list of values
SELECT first_name, last_name, city
FROM employees
WHERE city IN ('Manila', 'Makati', 'Taguig')
ORDER BY city, last_name, first_name;

-- Wildcard % matches zero or more characters
SELECT first_name, last_name, job_title
FROM employees
WHERE job_title LIKE '%Engineer%';

-- Wildcard _ matches exactly one character; this finds names whose
-- second character is "a"
SELECT first_name, last_name
FROM employees
WHERE first_name LIKE '_a%'
ORDER BY first_name;

-- NULL values require IS NULL or IS NOT NULL, not = NULL
SELECT first_name, last_name, job_title
FROM employees
WHERE manager_id IS NULL;

SELECT first_name, last_name, manager_id
FROM employees
WHERE manager_id IS NOT NULL
ORDER BY manager_id, last_name;

-- Use a range instead of YEAR(hire_date) so an index on hire_date can be used
SELECT first_name, last_name, hire_date
FROM employees
WHERE hire_date >= '2024-01-01'
  AND hire_date < '2025-01-01'
ORDER BY hire_date;

-- Arithmetic operators and column aliases
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
WHERE salary >= 60000
ORDER BY projected_monthly_pay DESC;

-- ================================================================
-- 3. Character strings and string functions
-- ================================================================

-- Character strings are enclosed in single quotes. VARCHAR columns such as
-- first_name, last_name, department, and job_title store variable-length strings.
SELECT
    first_name,
    last_name,
    CONCAT(first_name, ' ', last_name) AS full_name,
    CHAR_LENGTH(CONCAT(first_name, ' ', last_name)) AS full_name_length,
    SUBSTRING(first_name, 1, 3) AS first_three_characters,
    CONCAT(UPPER(department), ': ', TRIM(job_title)) AS employee_summary
FROM employees
WHERE LOWER(job_title) LIKE '%engineer%'
ORDER BY last_name, first_name;

-- ================================================================
-- 4. Conversion functions
-- ================================================================

SELECT
    first_name,
    last_name,
    CAST(employee_id AS CHAR) AS employee_id_text,
    CAST(salary AS SIGNED) AS salary_whole_number,
    CONVERT(hire_date, CHAR) AS hire_date_text
FROM employees
ORDER BY employee_id;

-- ================================================================
-- 5. Date functions
-- ================================================================

SELECT
    first_name,
    last_name,
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
    first_name,
    last_name,
    salary AS monthly_salary,
    ROUND(salary * 12, 2) AS annual_salary,
    CEILING(salary / 22) AS estimated_daily_rate_rounded_up,
    FLOOR(salary / 22) AS estimated_daily_rate_rounded_down,
    ABS(salary - 70000) AS difference_from_70000,
    MOD(employee_id, 2) AS employee_id_remainder
FROM employees
WHERE salary >= 80000
ORDER BY monthly_salary DESC;

-- ================================================================
-- 7. Control flow functions and expressions
-- ================================================================

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
    SUM(salary) AS total_monthly_payroll,
    ROUND(AVG(salary), 2) AS average_monthly_salary,
    MIN(salary) AS lowest_monthly_salary,
    MAX(salary) AS highest_monthly_salary
FROM employees;

-- ================================================================
-- 10. Organize data with ORDER BY
-- ================================================================

-- Sort departments alphabetically, then salaries highest to lowest
SELECT first_name, last_name, department, salary
FROM employees
ORDER BY department ASC, salary DESC;

-- ================================================================
-- 11. Summarize data with GROUP BY
-- ================================================================

SELECT
    department,
    COUNT(*) AS employee_count,
    SUM(employment_status = 'Active') AS active_employee_count,
    ROUND(AVG(salary), 2) AS average_monthly_salary,
    MIN(salary) AS lowest_monthly_salary,
    MAX(salary) AS highest_monthly_salary
FROM employees
GROUP BY department
ORDER BY average_monthly_salary DESC;

-- ================================================================
-- 12. Filter grouped results with HAVING
-- ================================================================

-- WHERE filters rows before grouping; HAVING filters groups afterward
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

-- Challenge 5: Display gross monthly salary, estimated annual salary, and
-- monthly salary after a 5 percent increase. Use clear column aliases.

-- Challenge 6: Use IF or CASE to label each employee as Active Staff,
-- Temporarily Unavailable, or Former Staff.

-- Challenge 7: Return every distinct department and city combination.

-- Challenge 8: Return the total row count, the count of non-NULL manager
-- IDs, and the count of distinct departments in one result.

-- Challenge 9: Use character-string functions to display an uppercase
-- full name from first_name and last_name, plus the number of characters
-- in the combined name.

-- Challenge 10 - WHERE clause: Return only employees from the Finance
-- department.

-- Challenge 11 - Comparison operators: Find employees with a salary greater
-- than or equal to 60000 and less than 90000 whose status is not Inactive.

-- Challenge 12 - Arithmetic operators: Calculate a 7 percent monthly bonus,
-- annual salary, and monthly salary plus bonus for each employee.

-- Challenge 13 - Logical operators: Find Active employees who work in IT or
-- Finance, then exclude employees located in Makati by using NOT.

-- Challenge 14 - Wildcards: Use % to find job titles ending in "Manager" and
-- _ to find first names whose second character is "a".

-- Challenge 15 - Column aliases: Display the combined first and last name as
-- full_name, salary as monthly_salary, and salary times 12 as annual_salary.

-- Challenge 16 - NULL values: Write one query for employees without a manager
-- and another for employees with a manager. Do not use = NULL or <> NULL.
