# Customer Sales Analysis Queries
# Date: 02/07/2024

/*
This program contains a series of queries to analyze customer and sales data from the retail database. The queries address various business 
questions such as the number of different countries customers come from, the city with the highest number of customers, the average days between ordering
 and shipping, the most expensive order received, and high-spending customers. Additionally, it identifies the sales representatives responsible for 
 high-performing clients, providing insights into customer demographics, sales performance, and payment patterns.

*/
USE retail;

# 1.	How many different countries do the customers come from? (Query 1)
SELECT COUNT(DISTINCT country) AS country_count
FROM customers; 

-- The customers come from 27 different countries 

# 2.	We want to see which city has the highest number of customers. Write a query that will help you answer this question. (Query 2)
SELECT *
FROM customers; 

SELECT city, COUNT(customer_number) AS customer_count
FROM customers
GROUP BY city
ORDER BY customer_count DESC; 

-- NYC and Madrid have the highest number of customers

# 3.	We want to see the average number of days between ordering and shipping. Write a query that will produce a column "days_btwn" to address this concern. Hint: Use the DATEDIFF function. (Query 3)

SELECT AVG(DATEDIFF(shipped_date, order_date)) days_btwn
FROM orders; 

# 4.	Write a query that produces the number of sales representatives (Sales Rep) in each office code. (Query 4)

SELECT *
FROM employees;

SELECT office_code, COUNT(employee_number) AS sales_rep_count
FROM employees
WHERE job_title = 'Sales Rep'
GROUP BY office_code;

# 5.	Provide a yearly breakdown of payment amounts. Which year is attributed with the highest total paid amount? (Query 5)

SELECT *
FROM payments;

SELECT YEAR(payment_date) AS payment_year, SUM(amount) AS total_paid
FROM payments
GROUP BY payment_year
ORDER BY total_paid DESC;

-- 2004 is attributed with the highest total paid amount

# 6.	Write a query to locate the city and its country with the highest average credit limit. Make sure to ROUND the average credit limit to 2 decimal places. (Query 6)
SELECT *
FROM customers;

SELECT city, country, credit_limit, ROUND(AVG(credit_limit),2) AS avg_credit_limit
FROM customers
GROUP BY city, country
ORDER BY avg_credit_limit DESC
LIMIT 1;

-- San Rafael, USA has the highest average credit limit

# 7.	How many customers reside in the city with the highest average credit limit (question 6)? (Query 7)

SELECT *
FROM customers;

SELECT COUNT(customer_number) AS customer_count
FROM customers
WHERE city = "San Rafael"; 

-- 1 customer resides in San Rafael, the city with the highest average credit limit 

# 8.	Give the order number for the most expensive order received. (Query 8)

SELECT *
FROM orderdetails;

SELECT order_number, SUM(quantity_ordered*price_each) AS order_amount
FROM orderdetails
GROUP BY order_number 
ORDER BY order_amount DESC; 

-- order number 10165 is the order the most expensive order received 

# 9.	Find all the information of the customer responsible for the most expensive order in Question 8. You may use more than one SQL query. (Query 9)

SELECT * 
FROM orderdetails 
WHERE order_number = 10165; 

SELECT * 
FROM orders
WHERE order_number = 10165; 

SELECT * 
FROM customers
WHERE customer_number = 148; 

-- The customer responsible for the most expensive order in Question 8 is Dragon Souveniers,Ltd with a contact name of Eric Natividad. Their phone number is +65 221 7555. Their address is Bronz Sok/Bronz Apt. 3/6 Tesvikiye, Singapore, Singapore, 079903. The number of their sales representative number is 1621. And their cresit limit is 103800.00

# 10.	How many customers have spent at least 100K (> 100K) after 2004 (> 2004)? How much did each customer spend in order of highest to lowest paid. (Query 10)

SELECT *
FROM payments;

SELECT customer_number, SUM(amount) AS total_amount
FROM payments
WHERE payment_date >= '2005-01-01' 
GROUP BY customer_number
HAVING total_amount > 100000
ORDER BY total_amount DESC;

-- 2 customers have spent at least 100K (> 100K) after 2004 (> 2004). Customer 141 spent a total of 232133.32 and customer 124 spent 184842.63.

# 11.	The company wants to incentivize sales representatives who exhibit high performance. Write 1-2 queries that will help us identify the name and contact information of the sales representative(s) assigned to the high spender(s) in Question 10. (Query 11)
SELECT customer_number, sales_rep_employee_number
FROM customers
WHERE customer_number IN (124, 141);

-- customer_number = 124 --> sales_rep_employee_number = 1165; customer_number = 141 --> sales_rep_employee_number = 1370 	

SELECT *
FROM employees; 

SELECT *
FROM employees
WHERE employee_number IN (1165, 1370);

-- The sales representative assigned to customer 141, the highest spender in Question 10, is Leslie Jennings, with extension number x3291, email ljennings@classicmodelcars.com, and office code 1
-- The sales rep assigned to customer 124, the second highest spender in Question 10, is Gerard Hernandez, with with extension number x2028, the email ghernande@classicmodelcars.com, and office code 4



