SELECT 
current_date, -- this is a keyword in PostgreSQL
EXTRACT(year FROM current_date) AS year,
EXTRACT(month FROM current_date) AS month,
EXTRACT(day FROM current_date) AS day,
/* below: dow starts at 0 (Sunday) and goes up to 6 (Saturday)*/
EXTRACT(dow FROM current_date) AS day_of_week, 
/* below: isodow starts at 1 (Monday) and goes up to 7 (Sunday) */
EXTRACT(isodow FROM current_date) AS iso_day_of_week, 
EXTRACT(week FROM current_date) AS week_of_year,
EXTRACT(quarter FROM current_date) AS quarter;


SELECT INTERVAL '5 days';
SELECT TIMESTAMP '2023-03-01 00:00:00' - TIMESTAMP '2023-02-01 00:00:00' AS days_in_feb;

SELECT TIMESTAMP '2023-03-03 00:00:00' + INTERVAL '7 days' AS new_date;

SELECT DATE '2023-03-03' + 7 AS new_date;

SELECT DATE '2023-03-01' - DATE '2023-02-01' AS days_in_feb;

SELECT EXTRACT (year from sales_transaction_date) AS year, 
EXTRACT(quarter FROM sales_transaction_date)AS quarter,
COUNT(1) AS number_of_sales,sum(sales_amount)
FROM sales
WHERE EXTRACT(YEAR FROM sales_transaction_date) in (2020,2021)
GROUP BY 1,2
ORDER BY 1,2;




SELECT to_char(c.date_added,'YYYY "Q"Q') AS year_quarter,
COUNT(1)AS number_new_customers
FROM customers c
WHERE EXTRACT(YEAR FROM date_added) in (2020,2021) 
GROUP BY 1
ORDER BY 1;


WITH quarterly_sales AS(
	SELECT to_char(s.sales_transaction_date,'YYYY "Q"Q') AS year_quarter,
COUNT(1),SUM(sales_amount)
FROM sales s
WHERE EXTRACT(YEAR FROM s.sales_transaction_date) in (2020,2021) 
GROUP BY 1
ORDER BY 1
),
WITH new_customers AS(
SELECT to_char(c.date_added,'YYYY "Q"Q')AS year_quarter,
COUNT(1) AS number_new_customers
FROM customers c
WHERE EXTRACT(year FROM c.date_added)IN (2020,2021)
GROUP BY 1
order by 1
)
SELECT * FROM 
new_customers c join quarterly_sales s on c.year_quarter = s.year_quarter;





SELECT to_char(s.sales_transaction_date,'YYYY "Q"Q') AS year_quarter,
COUNT(1),SUM(sales_amount),count(distinct c.customer_id)
FROM sales s join customers c on s.customer_id=c.customer_id
WHERE EXTRACT(YEAR FROM s.sales_transaction_date) in (2020,2021) 
GROUP BY 1
ORDER BY 1;

CREATE EXTENSION cube; 
CREATE EXTENSION earthdistance;



SELECT s.customer_id 
from sales s 
cross join customers c  
cross join dealerships d;








select * from customers;
select * from dealerships;
select * from sales;


CREATE TEMP TABLE customer_points AS(
SELECT customer_id,point(longitude,latitude)AS lng_lat
FROM customers
	WHERE longitude IS NOT NULL AND latitude IS NOT NULL
);

SELECT *FROM customer_points LIMIT 2;

CREATE TEMP TABLE dealership_points AS (
SELECT dealership_id,POINT(longitude,latitude)AS lng_lat
FROM dealerships);
SELECT * FROM dealership_points LIMIT 2;

CREATE TEMP TABLE customer_dealership_distance AS(
SELECT c.customer_id,d.dealership_id,c.lng_lat<@> d.lng_lat AS distance
FROM customer_points c CROSS JOIN dealership_points d);

CREATE TEMP TABLE closest_dealersips AS(SELECT DISTINCT ON(customer_id)customer_id,dealership_id,distance
from customer_dealership_distance
ORDER BY customer_id,distance);
SELECT * FROM closest_dealerships LIMIT 5;

/*summary statistics*/

SELECT AVG(distance),
PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY distance)AS median_mist, 
PERCENTILE_DISC(0.1) WITHIN GROUP(ORDER BY distance)AS p10,
PERCENTILE_DISC(0.25) WITHIN GROUP(ORDER BY distance)AS p25,
PERCENTILE_DISC(0.75) WITHIN GROUP(ORDER BY distance)AS p75,
PERCENTILE_DISC(0.9) WITHIN GROUP(ORDER BY distance)AS p90
FROM closest_dealerships;


WITH ranked AS(SELECT customer_id,dealership_id,distance,
RANK()OVER (PARTITION BY dealership_id ORDER BY distance) AS cust_rank,
ROW_NUMBER()OVER (PARTITION BY dealership_id ORDER BY distance) AS cust_row
from closest_dealerships)
SELECT * FROM ranked WHERE cust_row<=3 ;

SELECT ARRAY['Lemon', 'Bat Limited Edition'] AS example_purchased_products;

SELECT product_type, ARRAY_AGG(DISTINCT model) AS models 
FROM products 
GROUP BY 1;

SELECT product_type, ARRAY_AGG(model) AS models 
FROM products 
GROUP BY 1;

SELECT UNNEST(ARRAY[123, 456, 789]) AS example_ids;
SELECT (ARRAY[123, 456, 789])[1] AS example_id;


SELECT STRING_TO_ARRAY('hello there how are you?', ' ');
SELECT ARRAY_TO_STRING(
ARRAY['Lemon', 'Bat Limited Edition'], ', '
) AS example_purchased_products;


SELECT customer_id,
ARRAY_AGG(email_subject ORDER BY sent_date )AS email_sequence
from emails
GROUP BY 1;

CREATE TEMP TABLE email_sequences AS(
	SELECT customer_id,
ARRAY_AGG(email_subject ORDER BY sent_date )AS email_sequence
from emails
GROUP BY 1
);

CREATE TEMP TABLE top_three AS(SELECT email_sequence,COUNT(1)
FROM email_sequences
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3);

ALTER TABLE top_three
ADD COLUMN id SERIAL PRIMARY KEY;

SELECT id,count,email_sequence from top_three;

