-- AWS re/Start — Batch 29 and 30
-- Lab 08: Retrieving Data from Multiple Tables
-- Tested design target: MariaDB 10.5 or later
--
-- WARNING:
-- This script drops and recreates a database named multi_table_demo.
-- Run it only in a classroom or disposable MariaDB environment.

DROP DATABASE IF EXISTS multi_table_demo;
CREATE DATABASE multi_table_demo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE multi_table_demo;

-- ============================================================
-- Section 1 — Create the related tables
-- ============================================================

CREATE TABLE departments (
    department_id   INT PRIMARY KEY,
    department_name VARCHAR(60) NOT NULL UNIQUE,
    office_city     VARCHAR(60) NOT NULL,
    monthly_budget  DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_departments_budget
        CHECK (monthly_budget > 0)
) ENGINE = InnoDB;

CREATE TABLE employees (
    employee_id     INT PRIMARY KEY,
    first_name      VARCHAR(40) NOT NULL,
    last_name       VARCHAR(40) NOT NULL,
    email           VARCHAR(120) NOT NULL UNIQUE,
    department_id   INT NULL,
    job_title       VARCHAR(80) NOT NULL,
    hire_date       DATE NOT NULL,
    monthly_salary  DECIMAL(10,2) NOT NULL,
    city            VARCHAR(60) NOT NULL,
    manager_id      INT NULL,
    CONSTRAINT fk_employees_department
        FOREIGN KEY (department_id)
        REFERENCES departments (department_id),
    CONSTRAINT chk_employees_salary
        CHECK (monthly_salary > 0),
    INDEX idx_employees_department (department_id),
    INDEX idx_employees_manager (manager_id),
    INDEX idx_employees_city (city)
) ENGINE = InnoDB;

CREATE TABLE projects (
    project_id      INT PRIMARY KEY,
    project_name    VARCHAR(100) NOT NULL UNIQUE,
    department_id   INT NULL,
    project_status  ENUM('Planned', 'Active', 'On Hold', 'Completed') NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NULL,
    project_budget  DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_projects_department
        FOREIGN KEY (department_id)
        REFERENCES departments (department_id),
    CONSTRAINT chk_projects_budget
        CHECK (project_budget > 0),
    CONSTRAINT chk_projects_dates
        CHECK (end_date IS NULL OR end_date >= start_date),
    INDEX idx_projects_department (department_id)
) ENGINE = InnoDB;

CREATE TABLE employee_projects (
    employee_id   INT NOT NULL,
    project_id    INT NOT NULL,
    project_role  VARCHAR(80) NOT NULL,
    hours_per_week DECIMAL(4,1) NOT NULL,
    assigned_date DATE NOT NULL,
    PRIMARY KEY (employee_id, project_id),
    CONSTRAINT fk_employee_projects_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees (employee_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_employee_projects_project
        FOREIGN KEY (project_id)
        REFERENCES projects (project_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_employee_projects_hours
        CHECK (hours_per_week > 0 AND hours_per_week <= 40),
    INDEX idx_employee_projects_project (project_id)
) ENGINE = InnoDB;

CREATE TABLE contractors (
    contractor_id INT PRIMARY KEY,
    first_name    VARCHAR(40) NOT NULL,
    last_name     VARCHAR(40) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    specialty     VARCHAR(80) NOT NULL,
    city          VARCHAR(60) NOT NULL,
    agency_name   VARCHAR(100) NOT NULL,
    daily_rate    DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_contractors_rate
        CHECK (daily_rate > 0),
    INDEX idx_contractors_city (city)
) ENGINE = InnoDB;

-- ============================================================
-- Section 2 — Load departments and 30 employees
-- ============================================================

INSERT INTO departments
    (department_id, department_name, office_city, monthly_budget)
VALUES
    (1, 'Engineering',     'Makati',          600000.00),
    (2, 'Finance',         'Taguig',          400000.00),
    (3, 'Human Resources', 'Quezon City',     250000.00),
    (4, 'Sales',           'Manila',          500000.00),
    (5, 'Operations',      'Pasig',           450000.00),
    (6, 'Research',        'Cebu City',       300000.00),
    (7, 'Legal',           'Mandaluyong',     220000.00);

INSERT INTO employees
    (employee_id, first_name, last_name, email, department_id,
     job_title, hire_date, monthly_salary, city, manager_id)
VALUES
    (1,  'Ana',     'Cruz',        'ana.cruz@example.test',        1, 'Engineering Manager',      '2018-03-12', 135000.00, 'Makati',      NULL),
    (2,  'Miguel',  'Santos',      'miguel.santos@example.test',   1, 'Cloud Engineer',           '2020-06-15',  95000.00, 'Quezon City', 1),
    (3,  'Paolo',   'Garcia',      'paolo.garcia@example.test',    1, 'DevOps Engineer',          '2021-02-08',  85000.00, 'Manila',      1),
    (4,  'Carla',   'Reyes',       'carla.reyes@example.test',     1, 'Systems Engineer',         '2022-09-19',  78000.00, 'Pasig',       1),
    (5,  'John',    'Lim',         'john.lim@example.test',        1, 'Junior Developer',         '2024-01-22',  62000.00, 'Caloocan',    1),
    (6,  'Liza',    'Navarro',     'liza.navarro@example.test',    2, 'Finance Manager',          '2017-11-06', 125000.00, 'Taguig',      NULL),
    (7,  'Mark',    'Bautista',    'mark.bautista@example.test',   2, 'Senior Accountant',        '2019-07-01',  82000.00, 'Makati',      6),
    (8,  'Nina',    'Flores',      'nina.flores@example.test',     2, 'Financial Analyst',        '2021-10-11',  70000.00, 'Manila',      6),
    (9,  'Carlo',   'Mendoza',     'carlo.mendoza@example.test',   2, 'Payroll Specialist',       '2023-04-17',  65000.00, 'Taguig',      6),
    (10, 'Bea',     'Ramos',       'bea.ramos@example.test',       3, 'HR Manager',               '2018-08-20', 110000.00, 'Quezon City', NULL),
    (11, 'Grace',   'Aquino',      'grace.aquino@example.test',    3, 'Talent Acquisition Lead',  '2020-05-25',  72000.00, 'Pasig',       10),
    (12, 'Dennis',  'Villanueva',  'dennis.v@example.test',        3, 'HR Coordinator',           '2023-06-05',  58000.00, 'Manila',      10),
    (13, 'Sofia',   'Castillo',    'sofia.castillo@example.test',  4, 'Sales Director',           '2016-09-14', 130000.00, 'Manila',      NULL),
    (14, 'Ramon',   'Torres',      'ramon.torres@example.test',    4, 'Sales Manager',            '2019-03-18',  90000.00, 'Makati',      13),
    (15, 'Camille', 'Diaz',        'camille.diaz@example.test',    4, 'Account Executive',        '2021-12-06',  68000.00, 'Cebu City',   13),
    (16, 'Leo',     'Fernandez',   'leo.fernandez@example.test',   4, 'Sales Representative',     '2022-07-04',  60000.00, 'Davao City',  13),
    (17, 'Ivy',     'Morales',     'ivy.morales@example.test',     4, 'Sales Associate',          '2024-02-12',  55000.00, 'Manila',      13),
    (18, 'Omar',    'Salazar',     'omar.salazar@example.test',    5, 'Operations Manager',       '2017-05-29', 120000.00, 'Pasig',       NULL),
    (19, 'Trisha',  'Gonzales',    'trisha.g@example.test',        5, 'Supply Chain Analyst',      '2020-11-16',  88000.00, 'Taguig',      18),
    (20, 'Noel',    'Perez',       'noel.perez@example.test',      5, 'Business Analyst',          '2021-08-09',  74000.00, 'Quezon City', 18),
    (21, 'Aira',    'Domingo',     'aira.domingo@example.test',    5, 'Logistics Coordinator',    '2023-01-23',  62000.00, 'Pasig',       18),
    (22, 'Victor',  'Hernandez',   'victor.h@example.test',        6, 'Research Director',        '2016-04-11', 140000.00, 'Cebu City',   NULL),
    (23, 'Maya',    'Rodriguez',   'maya.rodriguez@example.test',  6, 'Senior Data Scientist',    '2019-09-30', 100000.00, 'Davao City',  22),
    (24, 'Ethan',   'Sy',          'ethan.sy@example.test',        6, 'Machine Learning Engineer','2020-12-14',  92000.00, 'Makati',      22),
    (25, 'Chloe',   'Tan',         'chloe.tan@example.test',       6, 'Research Analyst',         '2022-03-21',  76000.00, 'Cebu City',   22),
    (26, 'Jessa',   'Villareal',   'jessa.v@example.test',         5, 'Procurement Specialist',   '2023-08-07',  59000.00, 'Manila',      18),
    (27, 'Allan',   'De Leon',     'allan.deleon@example.test',    4, 'Sales Operations Analyst', '2022-11-28',  64000.00, 'Taguig',      13),
    (28, 'Rina',    'Mercado',     'rina.mercado@example.test',    3, 'Learning Specialist',      '2021-06-07',  61000.00, 'Quezon City', 10),
    (29, 'Kevin',   'Ong',         'kevin.ong@example.test',       1, 'Database Administrator',   '2020-01-13',  88000.00, 'Makati',      1),
    (30, 'Pia',     'Alonzo',      'pia.alonzo@example.test',   NULL, 'Business Consultant',     '2024-04-01',  80000.00, 'Baguio',      NULL);

ALTER TABLE employees
    ADD CONSTRAINT fk_employees_manager
    FOREIGN KEY (manager_id)
    REFERENCES employees (employee_id);

-- ============================================================
-- Section 3 — Load projects and the many-to-many assignments
-- ============================================================

INSERT INTO projects
    (project_id, project_name, department_id, project_status,
     start_date, end_date, project_budget)
VALUES
    (101, 'Cloud Migration',        1, 'Active',    '2025-01-06', NULL,         950000.00),
    (102, 'Data Warehouse',         2, 'Active',    '2025-02-03', NULL,         700000.00),
    (103, 'Hiring Portal',          3, 'Completed', '2024-05-13', '2025-01-31',350000.00),
    (104, 'CRM Upgrade',            4, 'Active',    '2025-03-10', NULL,         620000.00),
    (105, 'Inventory Automation',   5, 'Active',    '2025-01-20', NULL,         780000.00),
    (106, 'AI Prototype',           6, 'On Hold',   '2025-04-07', NULL,         880000.00),
    (107, 'Compliance Review',      7, 'Planned',   '2025-07-01', NULL,         210000.00),
    (108, 'Customer Analytics',     4, 'Active',    '2025-02-17', NULL,         510000.00),
    (109, 'Disaster Recovery',      1, 'Active',    '2025-03-03', NULL,         640000.00),
    (110, 'Vendor Consolidation',   5, 'Planned',   '2025-08-04', NULL,         300000.00),
    (111, 'Enterprise Architecture',NULL,'Planned', '2025-09-01', NULL,         450000.00);

INSERT INTO employee_projects
    (employee_id, project_id, project_role, hours_per_week, assigned_date)
VALUES
    (1,  101, 'Project Sponsor',          5.0, '2025-01-06'),
    (2,  101, 'Cloud Lead',              20.0, '2025-01-06'),
    (3,  101, 'Automation Engineer',     20.0, '2025-01-06'),
    (4,  101, 'Systems Engineer',        15.0, '2025-01-13'),
    (29, 101, 'Database Lead',           15.0, '2025-01-13'),
    (3,  109, 'Recovery Automation',     10.0, '2025-03-03'),
    (4,  109, 'Infrastructure Engineer', 12.0, '2025-03-03'),
    (29, 109, 'Database Recovery Lead',  12.0, '2025-03-03'),
    (6,  102, 'Project Sponsor',          4.0, '2025-02-03'),
    (7,  102, 'Finance Data Owner',      12.0, '2025-02-03'),
    (8,  102, 'Financial Analyst',       15.0, '2025-02-10'),
    (20, 102, 'Business Analyst',        10.0, '2025-02-10'),
    (10, 103, 'Product Owner',            6.0, '2024-05-13'),
    (11, 103, 'Recruitment Specialist',  18.0, '2024-05-13'),
    (12, 103, 'Content Coordinator',     12.0, '2024-05-20'),
    (13, 104, 'Project Sponsor',          5.0, '2025-03-10'),
    (14, 104, 'Sales Lead',              15.0, '2025-03-10'),
    (17, 104, 'User Tester',              8.0, '2025-03-17'),
    (27, 104, 'Process Analyst',         15.0, '2025-03-10'),
    (13, 108, 'Executive Sponsor',        4.0, '2025-02-17'),
    (15, 108, 'Account Data Owner',      10.0, '2025-02-24'),
    (23, 108, 'Data Science Lead',       18.0, '2025-02-17'),
    (27, 108, 'Sales Analyst',           12.0, '2025-02-24'),
    (18, 105, 'Project Sponsor',          5.0, '2025-01-20'),
    (19, 105, 'Supply Chain Lead',       18.0, '2025-01-20'),
    (21, 105, 'Logistics Analyst',       15.0, '2025-01-27'),
    (26, 105, 'Procurement Analyst',     12.0, '2025-01-27'),
    (22, 106, 'Research Sponsor',         5.0, '2025-04-07'),
    (23, 106, 'Data Science Lead',       20.0, '2025-04-07'),
    (24, 106, 'ML Engineer',             20.0, '2025-04-07'),
    (25, 106, 'Research Analyst',        15.0, '2025-04-14'),
    (7,  110, 'Finance Reviewer',         5.0, '2025-08-04'),
    (18, 110, 'Operations Sponsor',       5.0, '2025-08-04'),
    (26, 110, 'Procurement Lead',        15.0, '2025-08-04');

-- Project 107 intentionally has no employee assignments.
-- Project 111 intentionally has no department and no employee assignments.
-- Several employees intentionally have no project assignment.

INSERT INTO contractors
    (contractor_id, first_name, last_name, email, specialty,
     city, agency_name, daily_rate)
VALUES
    (201, 'Andre',  'Velasco',  'andre.velasco@contractor.test', 'Cloud Security',       'Makati',      'SecureWorks PH', 6500.00),
    (202, 'Bianca', 'Yu',       'bianca.yu@contractor.test',     'Data Engineering',     'Taguig',      'DataCraft',      6200.00),
    (203, 'Cedric', 'Go',       'cedric.go@contractor.test',     'UX Design',            'Manila',      'PixelWorks',     4800.00),
    (204, 'Diane',  'Pascual',  'diane.p@contractor.test',       'Quality Assurance',    'Cebu City',   'TestLab PH',     4500.00),
    (205, 'Enzo',   'Rivera',   'enzo.rivera@contractor.test',   'Network Engineering',  'Iloilo City', 'NetPro',         5600.00),
    (206, 'Faith',  'Lopez',    'faith.lopez@contractor.test',   'Business Analysis',    'Baguio',      'ProcessWorks',   5000.00),
    (207, 'Gino',   'Chua',     'gino.chua@contractor.test',     'Database Performance', 'Pasig',       'DB Experts',     6800.00),
    (208, 'Hazel',  'Soriano',  'hazel.s@contractor.test',       'Technical Writing',    'Bacolod',     'ClearDocs',      4200.00);

-- ============================================================
-- Section 4 — Validate the dataset
-- ============================================================

SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'projects', COUNT(*) FROM projects
UNION ALL
SELECT 'employee_projects', COUNT(*) FROM employee_projects
UNION ALL
SELECT 'contractors', COUNT(*) FROM contractors;

-- Expected counts:
-- departments = 7
-- employees = 30
-- projects = 11
-- employee_projects = 34
-- contractors = 8

-- ============================================================
-- Section 5 — INNER JOIN: matching rows from two tables
-- ============================================================

SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    e.job_title,
    e.monthly_salary
FROM employees AS e
INNER JOIN departments AS d
    ON d.department_id = e.department_id
ORDER BY d.department_name, e.last_name, e.first_name;

-- Employee 30 is excluded because department_id is NULL.

-- ============================================================
-- Section 6 — INNER JOIN: four related tables
-- ============================================================

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

-- ============================================================
-- Section 7 — LEFT JOIN: preserve every department
-- ============================================================

SELECT
    d.department_id,
    d.department_name,
    COUNT(e.employee_id) AS employee_count
FROM departments AS d
LEFT JOIN employees AS e
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY d.department_id;

-- The Legal department appears with an employee_count of 0.

-- Find employees who have no project assignment.
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title
FROM employees AS e
LEFT JOIN employee_projects AS ep
    ON ep.employee_id = e.employee_id
WHERE ep.project_id IS NULL
ORDER BY e.employee_id;

-- ============================================================
-- Section 8 — RIGHT JOIN: preserve every employee
-- ============================================================

SELECT
    d.department_name,
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.job_title
FROM departments AS d
RIGHT JOIN employees AS e
    ON e.department_id = d.department_id
ORDER BY e.employee_id;

-- Employee 30 appears even though no department matches.
-- Reversing the table order and using LEFT JOIN can express the same result.

-- ============================================================
-- Section 9 — FULL OUTER JOIN concept, emulated in MariaDB
-- ============================================================

-- MariaDB 10.5 does not implement the FULL OUTER JOIN keyword.
-- Combine:
--   1. every department with matching employees, and
--   2. employees that did not match a department.

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

-- The anti-match WHERE condition prevents matched rows from being duplicated.

-- ============================================================
-- Section 10 — UNION and UNION ALL
-- ============================================================

-- UNION removes duplicate city values.
SELECT city
FROM employees
UNION
SELECT city
FROM contractors
ORDER BY city;

-- UNION ALL preserves every occurrence, including duplicates.
SELECT city
FROM employees
UNION ALL
SELECT city
FROM contractors
ORDER BY city;

-- Add a source label when the origin of each row matters.
SELECT
    'Employee' AS worker_type,
    first_name,
    last_name,
    city
FROM employees
UNION ALL
SELECT
    'Contractor' AS worker_type,
    first_name,
    last_name,
    city
FROM contractors
ORDER BY city, worker_type, last_name, first_name;

-- ============================================================
-- Section 11 — INTERSECT
-- ============================================================

-- Return cities present in both tables.
SELECT city
FROM employees
INTERSECT
SELECT city
FROM contractors
ORDER BY city;

-- INTERSECT removes duplicates unless ALL is requested.

-- ============================================================
-- Section 12 — MINUS concept, implemented with EXCEPT
-- ============================================================

-- Return employee cities that do not appear in contractors.
SELECT city
FROM employees
EXCEPT
SELECT city
FROM contractors
ORDER BY city;

-- Oracle calls the preceding set operation MINUS.
-- MariaDB 10.5 uses EXCEPT. Do not run the following Oracle syntax here:
--
-- SELECT city FROM employees
-- MINUS
-- SELECT city FROM contractors;
--
-- MariaDB 10.6.1+ accepts MINUS only when SQL_MODE=ORACLE is enabled.

-- Equivalent anti-set query using NOT EXISTS:
SELECT DISTINCT e.city
FROM employees AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM contractors AS c
    WHERE c.city = e.city
)
ORDER BY e.city;

-- ============================================================
-- Section 13 — Aggregate data after joining tables
-- ============================================================

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

-- Projects 107 and 111 remain visible with zero assignments.

-- ============================================================
-- Section 14 — Practice challenges (no completed queries)
-- ============================================================

-- 1. INNER JOIN employees and departments. Return only Finance employees.
-- 2. Join employees, employee_projects, and projects. Show every employee
--    assigned to an Active project.
-- 3. Use a four-table join to show employee, department, project, and role.
-- 4. Use LEFT JOIN to return all projects, including unassigned projects.
-- 5. Use RIGHT JOIN between employee_projects and projects to return every
--    project, including projects with no assigned employees.
-- 6. Emulate FULL OUTER JOIN between departments and employees.
-- 7. Use UNION to list unique cities from employees and contractors.
-- 8. Use UNION ALL to count how many total worker records occur in each city.
-- 9. Use INTERSECT to find cities shared by employees and contractors.
-- 10. Use EXCEPT to implement the MINUS concept and find contractor-only cities.
-- 11. Find employees with no project assignment.
-- 12. Find departments with no employees.
-- 13. Return each project and its assignment count, including zero.
-- 14. Explain why moving a right-table filter from ON to WHERE can change a
--     LEFT JOIN into the practical equivalent of an INNER JOIN.
-- 15. Explain why omitting a join condition can create a Cartesian product.
