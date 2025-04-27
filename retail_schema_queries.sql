# Retail Schema Analysis and Reporting Queries
# Date: 02/28/2024
# Tharina Messeroux

/*
This SQL script contains a series of queries for analyzing various aspects of the retail database. The queries cover topics such as sales representatives,
customer orders, product performance, shipping times, and payment analysis. Specific tasks include counting sales representatives, tracking customer assignments,
identifying low-order products, checking shipping delays, and evaluating high-spending customers. The script also provides insights into sales performance,
customer credit usage, and location data across different tables in the retail schema.
*/
USE retail; 

-- 1.	How many sales representatives have information recorded in the retail schema? (Query 1)

SELECT *
FROM employees; 

SELECT COUNT(job_title)
FROM employees
WHERE job_title = "Sales Rep"; 

-- There are 17 sales representatives have information recorded in the retail schema

-- 2.	Are all sales representatives assigned to customers? (Query 2)
SELECT *
FROM employees; 

SELECT *
FROM customers; 

SELECT DISTINCT c.sales_rep_employee_number
FROM employees AS e 
INNER JOIN customers AS c
ON e.employee_number = c.sales_rep_employee_number; 

-- No, not all sales representatives are assigned to customers, there were 2 sales representatives without ssigned customers. We know that because, there were only 15 rows returned (know from action output/log) with the inner join employees and customer tables by employee number, while there are 17 sales rep in the company 

-- 3.	Write a query that will provide a count of customers assigned to all sales representatives in the retail schema. 
	-- Create a column that will show the full name of the employees and 
    -- sort the table in descending count of customers. (Hint: look up CONCAT) (Query 3)
    
SELECT *
FROM employees; 

SELECT *
FROM customers; 

SELECT CONCAT(e.first_name, ' ', e.last_name) AS sales_rep_full_name, COUNT(c.customer_number) AS cust_count
FROM employees AS e 
LEFT JOIN customers AS c
ON e.employee_number = c.sales_rep_employee_number
GROUP BY sales_rep_full_name
ORDER BY cust_count DESC; 
    
-- 4.	Which product(s) has the smallest number of orders recorded in the database? Give the name of the product(s) and not the id number. (Query 4)
SELECT *
FROM products; 

SELECT *
FROM orderdetails; 

SELECT p.product_name, COUNT(o.quantity_ordered) AS orders_num
FROM products AS p
INNER JOIN orderdetails AS o
ON p.product_code = o.product_code
GROUP BY product_name
ORDER BY orders_num; 

-- Products 1957 Ford Thunderbird and 1952 Citroen-15CV have the smallest number of orders recorded in the database with 24 orders 

-- 5.	We need to identify the customer(s) whose order was shipped after the required date. Write a query that will help us contact those customer(s); 
-- make sure to include the required and shipped date information. (Query 5)

SELECT *
FROM orders; 

SELECT *
FROM customers; 

SELECT o.required_date, o.shipped_date, c.customer_number,c.customer_name, c.phone
FROM orders AS o
INNER JOIN customers AS c
ON o.customer_number = c.customer_number
WHERE shipped_date > required_date;

-- The oder of customer 148  was shipped after the required date

-- 6.	Provide a breakdown of product lines and the counts of orders that were cancelled. 
	-- Sort the table in descending count of cancelled orders. (Query 6)

SELECT *
FROM orders; 

SELECT *
FROM orderdetails; 

SELECT *
FROM product_lines; 

SELECT *
FROM products; 

SELECT p.product_line, o.status, COUNT(o.status) AS order_status
FROM product_lines AS p_l
INNER JOIN products AS p
ON p_l.product_line = p.product_line
INNER JOIN orderdetails AS od
ON p.product_code = od.product_code
INNER JOIN orders AS o
ON o.order_number = od.order_number
WHERE status = "Cancelled"
GROUP BY product_line
ORDER BY order_status DESC; 

-- 7.	List the top two customers who have the longest average duration between order date and shipped date. 
-- Your query should only output the top two only. (Hint: DATEDIFF() function) (Query 7)

SELECT *
FROM orders; 

SELECT *
FROM customers; 

SELECT c.customer_number, AVG(DATEDIFF(o.shipped_date, o.order_date)) AS avg_diff_order_ship_time
FROM orders AS o
INNER JOIN customers AS c
ON o.customer_number = c.customer_number
GROUP BY customer_number
ORDER BY avg_diff_order_ship_time DESC
LIMIT 2;

-- The top two customers who have the longest average duration between order date and shipped date are customers 148, and 177

-- 8.	The company wants to estimate shipping times. 
	-- Write a query that creates a variable called "shipped_time" that takes the value 
		-- "Early" if the order is shipped before the required date, 
        -- "On Time" if the order is shipped on the required date, 
        -- "Late" if the order is shipped after the required date and
        -- "N/A" otherwise. 
        -- Provide a count of orders in each shipped_time group. (Query 8)
        
SELECT *
FROM orders; 

SELECT *
FROM customers; 

SELECT COUNT(order_number), 
CASE
	WHEN shipped_date < required_date THEN 'Early'
    WHEN shipped_date = required_date THEN 'On Time' 
    WHEN shipped_date > required_date THEN 'Late'
    ELSE 'N/A'
END AS shipped_time
FROM orders AS o
INNER JOIN customers AS c
ON o.customer_number = c.customer_number
GROUP BY shipped_time; 
-- Count of orders in each shipped_time group: 303 in "Early", 8 in "On Time", 1 in "Late", 14 in "N/A"

-- 9.	Find the information of the customer (customer name and number) responsible for the most expensive order.
	-- Your query should only output the top customer with the order and the amount spent.
    -- (You have attempted this using multiple SQL queries in HW 4) (Query 9)
SELECT *
FROM orders; 

SELECT *
FROM orderdetails; 

SELECT *
FROM customers; 

SELECT c.customer_name, c.customer_number, SUM(od.price_each * od.quantity_ordered) AS order_price
FROM customers AS c
INNER JOIN orders AS o
ON c.customer_number = o.customer_number
INNER JOIN orderdetails od 
ON o.order_number = od.order_number
GROUP BY c.customer_number
ORDER BY order_price DESC
LIMIT 1;
-- The customer 141, named Euro+Shopping Channel is responsible for the most expensive order.

-- 10.	The company wants to incentivize sales representatives who exhibit high performance.
	-- Write a query that will help us identify the sales representative(s) assigned to the customers who have spent at least 100K (≥ 100K) after 2004 (> 2004). 
    -- (You have attempted this using multiple SQL queries in HW 4) (Query 10)

SELECT e.employee_number, e.first_name, e.last_name, SUM(od.price_each * od.quantity_ordered) AS total_spent
FROM employees AS e
INNER JOIN customers AS c
ON e.employee_number = c.sales_rep_employee_number
JOIN orders AS o
ON c.customer_number = o.customer_number
INNER JOIN orderdetails AS od 
ON o.order_number = od.order_number
WHERE o.order_date > 2004
GROUP BY e.employee_number
HAVING total_spent >= 100000;

-- 11.	Write a query that creates a categorical variable that shows whether the customer has spent above, below, or till their credit limit. 
-- Be sure to select all relevant columns. (Query 11)

SELECT *
FROM payments; 

SELECT c.customer_number, c.customer_name, SUM(p.amount) as total_amount, c.credit_limit,  
CASE 
	   WHEN SUM(p.amount) < c.credit_limit THEN 'Below'
	   WHEN SUM(p.amount) = c.credit_limit THEN 'At Credit Limit'
	   WHEN SUM(p.amount) > c.credit_limit THEN 'Above'
	   ELSE 'N/A'
    END AS credit_limit_category 
FROM payments AS p
INNER JOIN customers AS c
ON c.customer_number = p.customer_number
GROUP BY c.credit_limit, c.customer_number, c.customer_name; 

-- 12.	Write a query that lists all cities that appear in the tables in this schema. (Query 12)

SELECT city
FROM customers
UNION
SELECT city 
FROM offices;

