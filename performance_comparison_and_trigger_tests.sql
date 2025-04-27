# Retail SQL Performance Comparison and Trigger Implementation
# Date: 04/24/2024
# Tharina Messeroux

/*
This SQL script includes performance comparisons for various queries involving indexed vs. non-indexed variables, inner joins vs. outer joins, and the impact of
unnecessary clauses. It also explores pivot table queries and tests the performance of filtering operations. Additionally, the script demonstrates trigger usage
for data validation in the "customers" table, including checks for customer age, zip code length, state formatting, and valid state entries within the US. The script
ends with test data insertions to ensure the triggers are functioning correctly.
*/

USE retail; 
# 1. Is grouping by an indexed variable faster than grouping by a non-indexed variable? 
-- In the products table product line is indexed. Write a query that counts the number of products for each product line. Drop the index and re-run this query.
--  Compare the performance of the two queries. 
-- Hint: You must DROP both the products table FK constraint and then the product line index. You can run SHOW INDEX FROM products; 
-- to confirm the product line index was dropped.

EXPLAIN ANALYZE
SELECT product_line, COUNT(*) AS product_line_count
FROM products
GROUP BY product_line; 

/*
 -> Group aggregate: count(0)  (cost=23 rows=7) (actual time=0.562..0.648 rows=7 loops=1) 
	-> Covering index scan on products using product_line  (cost=12 rows=110) (actual time=0.526..0.61 rows=110 loops=1)
 */
 
ALTER TABLE products DROP FOREIGN KEY products_ibfk_1; 
DROP INDEX product_line ON products;

EXPLAIN ANALYZE
SELECT product_line, COUNT(*) AS product_line_count
FROM products
GROUP BY product_line; 

/*
-> Table scan on <temporary>  (actual time=0.316..0.318 rows=7 loops=1)
     -> Aggregate using temporary table  (actual time=0.315..0.315 rows=7 loops=1)
         -> Table scan on products  (cost=12 rows=110) (actual time=0.123..0.194 rows=110 loops=1)
*/


-- Grouping by an indexed variable slower than grouping by a non-indexed variable

# 2. Does an inner join execute faster than an outer join? 

-- Produce a query that lists all customer names who have placed an order. Formulate one query using an inner join and one using a left join and compare performance. 
-- Be sure that both versions of the query produce the same result set to ensure you’re evaluating comparable queries. Compare the performance of the two queries.


SELECT * 
FROM customers; 

SELECT * 
FROM orders; 

# EXPLAIN ANALYZE
SELECT DISTINCT c.customer_name
FROM customers AS c
INNER JOIN orders AS o 
ON c.customer_number = o.customer_number;

/*
-> Table scan on <temporary>  (cost=67.5..71.4 rows=122) (actual time=0.495..0.517 rows=98 loops=1) 
	-> Temporary table with deduplication  (cost=67.4..67.4 rows=122) (actual time=0.494..0.494 rows=98 loops=1)
		-> Nested loop inner join  (cost=...
*/


#EXPLAIN ANALYZE
SELECT DISTINCT c.customer_name
FROM customers AS c
LEFT JOIN orders AS o 
ON c.customer_number = o.customer_number; 

#-> Table scan on <temporary>  (cost=68.8..72.8 rows=122) (actual time=0.708..0.719 rows=98 loops=1)
#     -> Temporary table with deduplication  (cost=68.8..68.8 rows=122) (actual time=0.706..0.706 rows=98 loops=1)
#         -> Nested loop inner join  (cost=...


-- Inner Joins execute faster than outer joins 

# 3. How does adding an unnecessary clause affect performance? 
-- Write a simple query to select all fields in the products table. Write another query that  selects all fields and filters for buy_price > 0 (note each product has a buy price greater 
-- than 0). Compare the performance of the two queries. 

EXPLAIN ANALYZE
SELECT *
FROM products;

/*
 -> Table scan on products  (cost=12 rows=110) (actual time=0.0493..0.17 rows=110 loops=1)
*/

EXPLAIN ANALYZE
SELECT *
FROM products
WHERE buy_price > 0; 

/*
-> Filter: (products.buy_price > 0.00)  (cost=12 rows=36.7) (actual time=0.377..0.505 rows=110 loops=1)
  -> Table scan on products  (cost=12 rows=110) (actual time=0.0275..0.141 rows=110 loops=1)
 */

-- Adding an unnecessary clause affect slows down performance, the second one with the where statement was faster 

# Please answer the following questions on Pivot Tables – USE sakila

USE sakila; 

# 4. Using only one query, generate the following output. 
-- Total films represent the  number of films within each category. 
-- The remaining variables represent the  number of films for each rating within each category.  
-- Does summing across all film rating columns (G + PG + PG 13 + NC 17 + R) equal the total number of films within each category? Why or why not? 
-- Hint: First create a CTE then apply your CASE expression. 

SELECT *
FROM category; 

WITH film_num AS (
    SELECT
        c.name AS category,
        f.rating, COUNT(*) AS category_num
    FROM
        film AS f
    INNER JOIN
        film_category AS fc 
        ON f.film_id = fc.film_id
    INNER JOIN
        category AS c 
        ON fc.category_id = c.category_id
    GROUP BY
        c.name, f.rating
)

SELECT
    category,
    SUM(CASE 
		WHEN rating = 'G' THEN category_num 
        ELSE 0 END) AS G,
    SUM(CASE 
		WHEN rating = 'PG' THEN category_num 
        ELSE 0 END) AS PG,
    SUM(CASE
		WHEN rating = 'PG-13' THEN category_num 
        ELSE 0 END) AS PG_13,
    SUM(CASE 
		WHEN rating = 'NC-17' THEN category_num 
        ELSE 0 END) AS NC_17,
    SUM(CASE 
		WHEN rating = 'R' THEN category_num 
        ELSE 0 END) AS R,
    SUM(category_num) AS total_films
FROM
    film_num
GROUP BY
    category;

-- Yes, summing across all film rating columns (G + PG + PG-13 + NC-17 + R) should equal the total number of films within each category. 

# 5. Using three or less queries generate the following output. Total rented represents the total number of movies rented for each category. 
-- For each rental identify if the film was a short term, average, or long-term rental or not returned yet. 
-- To identify the length of a film rental, compare the time rented to the average rental time in days across all rentals. 
-- Does summing across all rental length categories (Short Rental + Average Rental + Long Rental + Not Returned) equal the total number of films rented within each category? Why or why not? 
-- category_name total_rented short_rental average_rental long_rental not_returned
--  Hint: I recommend using a CTE and a temporary table to generate the output in two queries. 
-- Use DATEDIFF to find the time rented comparing return date and rental date. If rental date is NULL then the film has not been returned yet. 
-- Make sure average rental time is calculated in days by using the ROUND feature. category_name total_films 

#DROP TABLE rental_stats; 
    
    CREATE TEMPORARY TABLE rental_stats AS (
WITH rental_period AS 
(SELECT c.name AS category_name,
		r.rental_id,
        DATEDIFF(r.return_date, r.rental_date) AS rental_length,
        ROUND(AVG(DATEDIFF(r.return_date, r.rental_date)) OVER(), 0) AS avg_rental_days
FROM category AS c
INNER JOIN film_category AS f_c
	ON c.category_id = f_c.category_id
INNER JOIN film AS f
	ON f_c.film_id = f.film_id
INNER JOIN inventory AS i
	ON f.film_id = i.film_id
INNER JOIN rental AS r
	ON i.inventory_id = r.inventory_id)

SELECT category_name, COUNT(rental_id) AS rental_num,
CASE
	WHEN rental_length < avg_rental_days THEN "Short Rental"
    WHEN rental_length = avg_rental_days THEN "Average Rental"
	WHEN rental_length > avg_rental_days THEN "Long Rental"
	ELSE 'Not Returned'
END AS rental_length_cat
FROM rental_period
GROUP BY rental_length_cat, category_name);

SELECT category_name, rental_num,
SUM(CASE
	WHEN rental_length_cat = "Short Rental" THEN rental_num
    ELSE 0
    END)
AS short_rental,
SUM(CASE
	WHEN rental_length_cat = "Average Rental" THEN rental_num
    ELSE 0
    END)
AS average_rental,
SUM(CASE
	WHEN rental_length_cat = "Long Rental" THEN rental_num
    ELSE 0
    END)
AS long_rental,
SUM(CASE
	WHEN rental_length_cat = "Not Returned" THEN rental_num
    ELSE 0
    END)
AS not_returned
FROM rental_stats
GROUP BY category_name;


# Please answer the following questions on Triggers –
 USE library; 

# 6. In the customers table:
-- a. Customers must be 18 years or older to join the library
	-- i. Hint: NOW() returns the current date compare this with the customers entered date of birth.
-- b. All customer zip codes entered must be of length 5
-- c. All states must be upper case. Rather than output an error message have
	-- MySQL correct the data entry and store the state entered as upper case.
-- d. Limit customers to states within the US
	-- i. Hint: Test to see if the state entered is contained in a list of the US 50 states.
   
# DROP TRIGGER before_customer_insert_update; 

DELIMITER //
CREATE TRIGGER before_customer_insert_update
BEFORE INSERT ON customers
FOR EACH ROW
BEGIN
    -- a. Check if the customer is 18 years or older
    IF DATEDIFF(NOW(), NEW.dob) < 6570 THEN -- 18 years = 6570 days 
        SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = 'Customer must be 18 years or older to join the library';
    END IF;

    -- b. Check if the zip code length is 5
    IF LENGTH(NEW.zip_code) != 5 THEN
        SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = 'Zip code entered must be 5 characters long';
    END IF;

    -- c. Convert state to upper case
    SET NEW.state = UPPER(NEW.state);

     -- d. Check if the state is within the US
    IF NEW.state NOT IN ('AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA',
						'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
                        'NM', 'NY', 'NC','ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT',
                        'VA', 'WA', 'WV', 'WI', 'WY') THEN
        SIGNAL SQLSTATE 'HY000'
        SET MESSAGE_TEXT = 'Customers must be from the United States';
    END IF;
END

//

DELIMITER ;

-- 7. Test EACH condition by entering invalid data values one at a time to ensure that the trigger works correctly. You should have 4 data entry tests in total. 

    -- a. Check if the customer is 18 years or older
INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
VALUES ('Thara', 'Messeroux', '2010-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '01883', 'Westfield', 'CA');

/*
0	721	19:18:25	INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
 VALUES ('Thara', 'Messeroux', '2010-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '01883', 'Westfield', 'CA')	Error Code: 1644. Customer must be 18 years or older to join the library	0.015 sec
*/
    -- b. Check if the zip code length is 5
INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
VALUES ('Thara', 'Messeroux', '1995-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '018', 'Westfield', 'CA');

/*
0	722	19:18:52	INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
 VALUES ('Thara', 'Messeroux', '1995-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '018', 'Westfield', 'CA')	Error Code: 1644. Zip code entered must be 5 characters long	0.000 sec

*/
    -- c. Convert state to upper case
INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
VALUES ('Thara', 'Messeroux', '1995-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '01886', 'Westfield', 'ca');

SELECT *
FROM customers; 

/*
	library_card_id	first_name	last_name	dob	gender	email	address	zip_code	city	state
	1000	Alice	Johndon	1990-05-15	Female	alice.johnson@gmail.com	123 Elm Street	12345	New York	NY
	1001	Bob	Smith	1985-09-23	Male	bob.smith@gmail.com	456 Oak Avenue	67890	New York	NY
	1002	Carol	Davis	1978-10-03	Female	carol.davis@gmail.com	789 Maple Road	54321	New York	NY
	1003	David	Wilson	1985-11-28	Male	david.wilson@gmail.com	101 Pine Lane	87123	New York	NY
	1004	Emily	Anderson	1980-07-02	Female	emily.anderson@gmail.com	222 Cedar Street	76544	New York	NY
	1005	Thara	Messeroux	1995-09-17	Female	tharamesseroux@email.com	1 shary Rd	01886	Westfield	CA
										
*/

     -- d. Check if the state is within the US
INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
VALUES ('Thara', 'Messeroux', '1995-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '01886', 'Westfield', 'CR');

/*
0	698	18:57:03	INSERT INTO customers (first_name, last_name, dob, gender, email, address, zip_code, city, state)
 VALUES ('Thara', 'Messeroux', '1995-09-17', 'Female', 'tharamesseroux@email.com', '1 shary Rd', '01886', 'Westfield', 'CR')	Error Code: 1644. Customers must be from the United States	0.000 sec
*/