# Library Database Creation and Data Management
# Tharina Messeroux 

/*
This programs creates a library database, defining tables for customers, authors, books, and checkouts with appropriate relationships and constraints.
It populates the tables with sample data for customers, authors, books, and checkouts. The script also demonstrates operations such as deleting a customer
from the database and updating an author's ID, ensuring referential integrity is maintained across child tables. Key features include auto-incrementing IDs,
foreign key constraints, and examples of performing basic CRUD operations.
*/
DROP DATABASE library; 
CREATE DATABASE library; 
USE library; 

-- Create customers table 
CREATE TABLE customers 
(
	library_card_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    dob DATE, 
    gender VARCHAR(255), 
    email VARCHAR(255), 
    address VARCHAR(255), 
    zip_code CHAR (5), 
    city VARCHAR(255), 
    state CHAR(2) 
); 

-- library card IDs start at 1000 and increase
ALTER TABLE customers AUTO_INCREMENT = 1000;

-- Create authors table 
CREATE TABLE authors 
(
	author_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
	first_name VARCHAR(255),
    last_name VARCHAR(255),
    gender VARCHAR(255), 
    email VARCHAR(255),
    website VARCHAR(255),
    nationality VARCHAR(255)
); 

-- Create books table 

CREATE TABLE books 
(
	isbn BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, 
    num_copies TINYINT UNSIGNED DEFAULT 1,
    title VARCHAR(255),
    author_id INT UNSIGNED,
    publication_year YEAR,
    genre VARCHAR(255),
    page_length SMALLINT UNSIGNED,
    INDEX (genre), 
    
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
      ON UPDATE CASCADE
	  ON DELETE CASCADE
      ); 

ALTER TABLE books AUTO_INCREMENT = 9780000;

-- Creating chekouts table 
CREATE TABLE checkouts 
(
	book_copy_id TINYINT UNSIGNED, 
    checkout_date DATETIME,
	isbn BIGINT UNSIGNED, 
    library_card_id INT UNSIGNED, 
    return_date DATETIME, 
    PRIMARY KEY (checkout_date, book_copy_id, isbn),
	FOREIGN KEY (library_card_id) REFERENCES customers(library_card_id)
    ON UPDATE CASCADE
	ON DELETE CASCADE, 
	FOREIGN KEY (isbn) REFERENCES books(isbn)
    ON UPDATE CASCADE
	ON DELETE CASCADE
); 

-- Populating the tables 
 
-- Insert data for customers
INSERT INTO customers (library_card_id, first_name, last_name, gender, dob, email, address, city, state, zip_code) 
VALUES 
(1010, 'Ria', 'Royer', 'female', '1995-02-04', 'riaroyer@gmail.com', '1 Sherry Ln', 'Cambridge', 'MA', '2138'),
(1011, 'Andres', 'Hong', 'male', '2000-06-17', 'andreshong@gmail.com', '456 Messer St', 'Cambridge', 'MA', '2139'),
(1012, 'Thara', 'Lalwani', 'female', '2002-09-24', 'tharalalwani@gmail.com', '4749 Hasgden St', 'Cambridge', 'MA', '2140'),
(1013, 'Yves', 'Girard', 'male', '1987-06-12', 'yvesgirard@gmail.com', '65 Miller Ave', 'Cambridge', 'MA', '2141'),
(1014, 'Sophie', 'Gilbert', 'female', '1999-07-28', 'sophiegilbert@gmail.com', '98 Nurma St', 'Cambridge', 'MA', '2142');

-- Insert data for authors
INSERT INTO authors (author_id, first_name, last_name, gender, email, nationality, website) 
VALUES 
(16784, 'Jay', 'Shetty', 'male', 'jay.shetty@book.edu', 'British', 'www.jayshetty.com'),
(16785, 'Suzanne', 'Collins', 'female', 'suzanne.collins@books.edu', 'American', 'www.suzannecollins.com'),
(16786, 'Malala', 'Yousafzai', 'female', 'malala.yousafzai@books.edu', 'Pakistani', 'www.malalayousafzai.com'),
(16787, 'Jenny', 'Han', 'female', 'jenny.han@books.edu', 'American', 'www.jennyhan.com'),
(16788, 'Danny', 'Laferriere', 'male', 'danny.laferriere@books.edu', 'Haitian-Canadian', 'www.sdannylaferriere.com');

-- Insert data for books
INSERT INTO books (isbn, author_id, title, genre, page_length, publication_year, num_copies) 
VALUES 
('9780008355562', 16784, 'Think Like a Monk', 'Nonfiction', 328, 2020, 4),
('9781407132099', 16785, 'Catching Fire', 'Science Fiction', 391, 2009, 3),
('9780316280570', 16786, 'I am Malala', 'Autobiography', 288, 2013, 5),
('9780576750571', 16787, 'The Summer I Turned Pretty', 'Romance', 288, 2009, 5),
('9782897140557', 16788, 'Laudeur du Café', 'Novel', 196, 1991, 2),
('9781407375099', 16784, '8 Rules of Love', 'Nonfiction', 256, 2023, 5),
('9780316483530', 16785, 'Mockingjay', 'Science Fiction', 429, 2010, 4),
('9780576857261', 16785, 'The Ballad of Songbirds and Snakes', 'Science Fiction', 434, 2020, 5),
('9782897957387', 16785, 'The Hunger Games', 'Science Fiction', 417, 2008, 3),
('9782897854734', 16788, 'LEnigme du retour', 'Novel', 234, 2009, 4);

-- Insert data for checkouts
INSERT INTO checkouts (checkout_date, isbn, book_copy_id, return_date, library_card_id) 
VALUES 
('2023-10-12', '9780008355562', 2, '2023-11-12', 1010),
('2023-10-13', '9781407132099', 3, '2023-12-13', 1011),
('2023-10-14', '9780316280570', 4, '2023-10-24', 1012),
('2023-10-15', '9780576750571', 5, '2023-12-15', 1013),
('2023-10-16', '9782897140557', 1, '2023-11-16', 1014),
('2023-10-17', '9781407375099', 4, '2023-12-01', 1010),
('2023-10-18', '9780316483530', 3, '2023-11-18', 1011),
('2023-10-19', '9780576857261', 3, '2023-12-19', 1012),
('2023-10-20', '9782897957387', 2, '2023-11-20', 1013),
('2023-10-21', '9782897854734', 4, '2023-12-21', 1014);

-- Delete 1 Customer from your customers table. Write a query (queries) to demonstrate the Customer has been correctly removed from all applicable child tables.

SELECT * 
FROM customers; 

SELECT * 
FROM checkouts; 

-- Deleting customer 10 from customers table 
DELETE 
FROM customers
WHERE library_card_id = 1010;

SELECT * 
FROM customers; 

SELECT * 
FROM checkouts; 

-- Update 1 author_id from the authors table. Write a query (queries) to demonstrate the new author_id value has been correctly changed in all applicable child tables.
SELECT * 
FROM authors; 

SELECT * 
FROM books; 

UPDATE authors 
SET author_id = 30000 
WHERE author_id = 16784;

SELECT * 
FROM authors; 

SELECT * 
FROM books; 
