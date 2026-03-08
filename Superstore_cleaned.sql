--Superstore/postgres@PostgreSQL 18
--Table creation for data import for dta cleaning
CREATE TABLE superstore (
    row_id SERIAL PRIMARY KEY,
    order_id VARCHAR(25),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(20),
    customer_id VARCHAR(15),
    customer_name TEXT,
    segment VARCHAR(20),
    country TEXT,
    city TEXT,
    state TEXT,
    postal_code VARCHAR(10), -- Stored as string to preserve leading zeros
    region VARCHAR(15),
    product_id VARCHAR(25),
    category VARCHAR(25),
    sub_category VARCHAR(25),
    product_name TEXT,
    sales NUMERIC(12, 4),    -- Exact precision for financial data
    quantity INTEGER,
    discount NUMERIC(5, 2),
    profit NUMERIC(12, 4)
);

--Importing csv us

Select * from superstore

--Cleaning of data
--1.Removing Duplicates
--- Check the duplicates

SELECT 
    order_id, product_id, customer_id, order_date, ship_date,
    COUNT(*)
FROM superstore
GROUP BY 
    order_id, product_id, customer_id, order_date, ship_date
HAVING COUNT(*) > 1;

---Remove the duplicates

DELETE FROM superstore
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT 
            row_id,
            ROW_NUMBER() OVER (
                PARTITION BY order_id, product_id, customer_id, order_date, ship_date
                ORDER BY row_id
            ) AS rn
        FROM superstore
    ) t
    WHERE rn > 1
);

--Verify after cleaning

SELECT COUNT(*) FROM superstore;

--(Optional but Best Practice) Prevent Future Duplicates

ALTER TABLE superstore
ADD CONSTRAINT unique_order_product
UNIQUE (order_id, product_id);


--2.Handle NULL Values
--First check which columns contain NULL values.

SELECT *
FROM superstore
WHERE
order_id IS NULL OR
order_date IS NULL OR
sales IS NULL OR
profit IS NULL;

--Replace NULL numeric values with 0

UPDATE superstore
SET sales = COALESCE(sales,0),
    profit = COALESCE(profit,0),
    discount = COALESCE(discount,0);

--Verifying

select * from superstore

--Replace NULL text values with 'Unknown'

UPDATE superstore
SET 
customer_name = COALESCE(customer_name,'Unknown'),
city = COALESCE(city,'Unknown'),
state = COALESCE(state,'Unknown'),
region = COALESCE(region,'Unknown');

--Verifying
select * from superstore

--3.Check and Fix Date Issues
--Find incorrect date records

SELECT *
FROM superstore
WHERE ship_date < order_date;

--Fix shipping date errors

UPDATE superstore
SET ship_date = order_date
WHERE ship_date < order_date;

--Verifying
select * from superstore

--4.Remove Invalid Numeric Values
--Find negative or incorrect sales/profit

SELECT *
FROM superstore
WHERE sales < 0 OR quantity < 0;

--Remove invalid rows

DELETE FROM superstore
WHERE sales < 0 OR quantity < 0;

--5.Standardize Text Data
--Sometimes text fields contain extra spaces or inconsistent casing.
--Remove leading/trailing spaces

UPDATE superstore
SET
customer_name = TRIM(customer_name),
city = TRIM(city),
state = TRIM(state),
category = TRIM(category),
sub_category = TRIM(sub_category);

--Convert categories to consistent format

UPDATE superstore
SET category = INITCAP(category),
    sub_category = INITCAP(sub_category),
    segment = INITCAP(segment),
    region = INITCAP(region);

--Verifying
select * from superstore

--6.Remove Outliers (Optional for Analysis)
---Find extreme profit values.

SELECT *
FROM superstore
WHERE profit > 10000 OR profit < -5000;

--7.Validate Discount Range
---Discount should be between 0 and 1.

SELECT *
FROM superstore
WHERE discount < 0 OR discount > 1;

---Fix it:

UPDATE superstore
SET discount = 0
WHERE discount < 0 OR discount > 1;


--8.Check Final Clean Data

SELECT COUNT(*) FROM superstore;

---Preview cleaned data:

SELECT *
FROM superstore
LIMIT 20;









