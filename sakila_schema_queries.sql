# Sakila Database Queries for Customer, Staff, and Film Analysis
# Date: 03/05/2024
# Tharina Messeroux

/*
This SQL script contains a series of queries designed to extract valuable insights from the Sakila database. The queries address multiple aspects of the system, 
including customer country origin, staff management, sales, store locations, film categories, and rental activity. Key tasks include listing unique customer countries,
 counting them, adding staff details, creating temporary tables for sales and film category analysis, and generating reports on the most popular films, actors, and
 customers with the highest rental activity. The script provides a comprehensive analysis for managing and optimizing the operations of a film rental store system.
*/
USE sakila;

-- 1. Write a SQL query to list the unique countries the customers come from. (Query 1)
SELECT * 
FROM country;

SELECT * 
FROM customer;

SELECT * 
FROM city;

SELECT * 
FROM address;

SELECT DISTINCT country
FROM country AS co
INNER JOIN city AS ci 
ON co.country_id = ci.country_id
INNER JOIN address AS a
ON ci.city_id = a.city_id
INNER JOIN customer AS cus
ON a.address_id = cus.address_id;

-- 2. Using Question 1's query as a CTE, provide a count of unique countries the customers come from. (Query 2)

WITH countries_unique AS (
    SELECT DISTINCT co.country
    FROM country AS co
    INNER JOIN city AS ci 
    ON co.country_id = ci.country_id
    INNER JOIN address AS a 
    ON ci.city_id = a.city_id
    INNER JOIN customer AS cus 
    ON a.address_id = cus.address_id
)
SELECT COUNT(*) AS countries_unique_count
FROM countries_unique;

-- The customers come from 108 unique countries 

-- 3. It looks like your information has not been added to the staff table. Write queries  to add your information to the staff table with address_id = 10 
-- and store_id = 1 and to check if the table has been updated. (Query 3)

SELECT * 
FROM staff; 

INSERT INTO staff (first_name, last_name, address_id, email, store_id, active, username, password, last_update)
VALUES ('Thalia', 'France', 10,'thalia.france@gmail.com', 1, 1, 'Thalia', '8cb2237d0679ca88db6464eac60da96345513964', CURRENT_TIMESTAMP);

SELECT * 
FROM staff;

-- 4. Since you are the new manager, write a query that creates a column 'manager_id' after staff_id and put yourself as the manager of both stores in the store table. 
-- Check to see if that executed correctly. (Query 4)

SELECT * 
FROM store;

ALTER TABLE store
ADD COLUMN manager_id INT UNSIGNED NOT NULL AFTER staff_id;

UPDATE store
SET manager_id = 3
WHERE staff_id = 1 OR staff_id = 2;

SELECT * 
FROM store;

-- 5. Write a query that creates a temporary table called 'sales' that gives the store id, full name of the employee and their total sales. (Query 5)

SELECT * 
FROM staff;

SELECT * 
FROM payment;

CREATE TEMPORARY TABLE sales AS
SELECT s.store_id, CONCAT(s.first_name, ' ', s.last_name) AS full_name, SUM(p.amount) AS total_payment
FROM staff AS s
INNER JOIN payment AS p 
ON s.staff_id = p.staff_id
GROUP BY s.store_id, s.staff_id;

SELECT * 
FROM sales;

-- 6. Create a view to get the location of each store_id in the format "city, country". (Query 6)

SELECT * 
FROM country; 

SELECT * 
FROM city; 

SELECT * 
FROM store; 

CREATE VIEW locations AS
SELECT sto.store_id,
       CONCAT(c.city, ', ', co.country) AS store_location
FROM store AS sto
INNER JOIN address AS a 
ON sto.address_id = a.address_id
INNER JOIN city AS c
ON a.city_id = c.city_id
INNER JOIN country AS co
 ON c.country_id = co.country_id;
 
SELECT * 
FROM locations; 
 
-- 7. Combine the outputs of questions 5 and 6 to get the store location, full name of the employee and their total sales to the nearest dollar in descending order. (Query 7)

SELECT * 
FROM sales;

SELECT * 
FROM locations; 

SELECT s.store_id, full_name, ROUND(total_payment), store_location
FROM sales AS s
INNER JOIN locations AS l
ON s.store_id = l.store_id
ORDER BY total_payment DESC;

-- 8. Write a query that creates a temporary table of film category (category_id and name) and average running time (to 2 decimal places). 
-- Order by shortest to longest average running time. (Query 8)
SELECT * 
FROM film_category; 

SELECT * 
FROM film;

SELECT * 
FROM category;

CREATE TEMPORARY TABLE film_category_temporary AS
SELECT f_c.category_id, c.name AS category_name, ROUND(AVG(f.length), 2) AS avg_running_time
FROM film_category AS f_c
INNER JOIN film AS f 
ON f_c.film_id = f.film_id
INNER JOIN category AS c 
ON f_c.category_id = c.category_id
GROUP BY f_c.category_id, c.name
ORDER BY avg_running_time;

SELECT * 
FROM film_category_temporary;

-- 9. Using the output from question 8, write a query that lists the movies names, their running time and average category running time. 
-- Include a column that shows whether the movie is longer, shorter or the same as average. 
-- Leave a 10min wiggle room i.e., mark a movie as same as average if the absolute difference between the movie duration and average category run time is less than 10 mins (average run time ±10 mins). (Query 9)

SELECT f.title AS movie_name, f.length AS movie_running_time, f_c_t.avg_running_time AS avg_category_running_time,
    CASE
        WHEN ABS(f.length - f_c_t.avg_running_time) <= 10 THEN 'Same as Average'
        WHEN f.length > f_c_t.avg_running_time THEN 'Longer than Average'
        ELSE 'Shorter than Average'
    END AS compare_length_avg
FROM film AS f
INNER JOIN film_category_temporary AS f_c_t
ON f.film_id = f_c_t.category_id;
 
-- 10.Write a query that lists the full names (first_name, last_name) of actors (in alphabetical order) that appear in the film 'ALI FOREVER' using joins. (Query 11)

SELECT *
FROM actor; 

SELECT *
FROM film; 

SELECT *
FROM film_actor; 

SELECT CONCAT(a.first_name, ' ', a.last_name) AS full_name
FROM actor AS a
INNER JOIN film_actor AS f_a
ON a.actor_id = f_a.actor_id
INNER JOIN film AS f
ON f_a.film_id = f.film_id
WHERE f.title = 'ALI FOREVER'
ORDER BY a.last_name, a.first_name;

-- 11.Perform query 11 again without joins, this time using subqueries. (HINT: multiple subqueries). (Query 12)

SELECT CONCAT((SELECT first_name 
				FROM actor 
                WHERE actor_id = f_a.actor_id), ' ', (SELECT last_name 
													  FROM actor 
                                                      WHERE actor_id = f_a.actor_id)) AS full_name
FROM film_actor AS f_a
WHERE f_a.film_id = (SELECT film_id 
					 FROM film 
                     WHERE title = 'ALI FOREVER')
ORDER BY (SELECT last_name 
			FROM actor 
            WHERE actor_id = f_a.actor_id), 
		(SELECT first_name 
        FROM actor 
        WHERE actor_id = f_a.actor_id);

-- 12.Give the name(s) of customer(s) attributed with the highest number of rentals since August 2005 (2005-08-01)? Be sure to consider all ties! (Query 13)

SELECT *
FROM customer;

SELECT *
FROM rental;  

SELECT COUNT(*)
FROM rental
WHERE rental_date >= '2005-08-01'
GROUP BY customer_id
ORDER BY COUNT(*) DESC;

SELECT c.first_name, c.last_name
FROM customer AS c
INNER JOIN rental AS r 
ON c.customer_id = r.customer_id
INNER JOIN inventory AS i 
ON r.inventory_id = i.inventory_id
WHERE r.rental_date >= '2005-08-01'
GROUP BY c.customer_id
HAVING COUNT(*) = (
        SELECT COUNT(*)
        FROM rental
        WHERE rental_date >= '2005-08-01'
        GROUP BY customer_id
        ORDER BY COUNT(*) DESC
        LIMIT 1
    );
    
-- Helen Harris the customer attributed with the highest number of rentals since August 2005 (2005-08-01)
