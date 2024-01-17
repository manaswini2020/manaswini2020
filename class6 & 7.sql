(
SELECT 
street_address, city, state, postal_code
FROM 
customers
WHERE 
street_address IS NOT NULL
)
UNION ALL
(
SELECT 
street_address, city, state, postal_code
FROM 
dealerships
WHERE 
street_address IS NOT NULL
)
ORDER BY 1;



SELECT c.email,
CASE WHEN state IN ('CA','FL')THEN 100
WHEN state in('TX') THEN 75
ELSE 50
END AS outdoor_percentage,c.customer_id
FROM customers c;

SELECT *,
CASE WHEN state IN ('CA','FL')THEN 100
WHEN state in('TX') THEN 75
ELSE 50
END AS outdoor_percentage
FROM customers;

SELECT COUNT(*)
FROM (SELECT c.email,
CASE WHEN state IN ('CA','FL')THEN 100
WHEN state in('TX') THEN 75
ELSE 50
END AS outdoor_percentage,c.customer_id
FROM customers c) customers_plus
WHERE outdoor_percentage>=75;

SELECT COUNT(DISTINCT state)
FROM customers;

SELECT count(customer_id),d.state
 FROM customers c join dealerships d on c.dealership_id=d.dealership_id
 SELECT c.email,
CASE WHEN state IN ('CA','FL')THEN 100
WHEN state in('TX') THEN 75
ELSE 50
END AS outdoor_percentage,c.customer_id
FROM customers c;


SELECT COUNT(*)
FROM customers
GROUP BY state
order by COUNT(*) DESC;

SELECT COUNT(*) ,To_CHAR(date_added,'YYYY') AS year
FROM customers
GROUP BY year
ORDER BY 2;
/* we can also use date_prt,date trunc*/


SELECT To_CHAR(date_added,'YYYY') AS year,gender,COUNT(*)
FROM customers
GROUP BY year,gender
ORDER BY 1,2;

SELECT c.customer_id,date_part('year',date_added) AS year
FROM customers c;

SELECT date_part('year',date_added) AS year,gender,count(*)
FROM customers
GROUP BY GROUPING SETS(
(date_part('year',date_added),(date_part('year',date_added),gender)))
ORDER BY 1,2;

SELECT date_part('year',date_added) AS year,gender,count(*)
FROM customers
GROUP BY GROUPING SETS(
(year,(year,gender)))
ORDER BY 1,2;

SELECT 
PERCENTILE_CONT(0.1) ,PERCENTILE_CONT(0.25),PERCENTILE_CONT(0.5),PERCENTILE_CONT(0.75),PERCENTILE_CONT(0.90)
WITHIN GROUP (ORDER BY base_msrp) 
AS median
FROM 
products;

--class 7 continued here after 6th clss
SELECT customer_id,title,first_name,last_name,gender,
COUNT(*) OVER (PARTITION BY gender ORDER BY customer_id) 
as total_customers,
SUM(CASE WHEN title IS NOT NULL THEN 1 ELSE 0 END) OVER 
(PARTITION BY gender ORDER BY customer_id) as total_customers_title
FROM customers
ORDER BY customer_id;


SELECT customer_id,title, first_name, last_name, gender,
COUNT(*) OVER w as total_customers,
SUM(CASE WHEN title IS NOT NULL THEN 1 ELSE 0 END) OVER w as 
total_customers_title
FROM customers
WINDOW w AS (PARTITION BY gender ORDER BY customer_id)
ORDER BY customer_id;




SELECT * FROM customers;
/*Management would like to see the first 10 customers from each 
state-city combination in terms of date_added.*/
SELECT customer_id,first_name,last_name,date_added::DATE,state,city,
RANK()OVER(PARTITION BY state,city ORDER BY date_added::DATE) AS cust_rank
FROM customers;
--ORDER BY cust_rank,state;
WITH ranked_state_city AS(
	SELECT customer_id,first_name,last_name,date_added::DATE,state,city,
RANK()OVER(PARTITION BY state,city ORDER BY date_added) AS cust_rank
FROM customers
)
SELECT *
FROM ranked_state_city
WHERE cust_rank<=10;
/*: Management would like to pick 2 people at random from each 
of groups consisting of the first 10 customers from each state-city 
combination (first in terms of date_added). */
WITH ranked_st_city AS(
	SELECT customer_id,first_name,last_name,date_added::DATE,state,city,
RANK()OVER W1 AS cust_rank,
RANK()OVER W2 AS lucky_rank
FROM customers
WINDOW W1 AS (PARTITION BY state,city ORDER BY date_added),
	W2 AS (PARTITION BY state,city ORDER BY random())
),
top10 AS (SELECT *
FROM ranked_st_city
WHERE cust_rank<=10),
top10_luckyRankNum AS(SELECT *,
ROW_NUMBER() OVER (PARTITION BY state,city ORDER BY lucky_rank)AS lucky_rank_num
FROM top10)
SELECT * FROM top10_luckyRankNum
WHERE lucky_rank_num<=2;
						 
--OR
WITH ranked_st_city AS(
	SELECT customer_id,first_name,last_name,date_added::DATE,state,city,
RANK()OVER W1 AS cust_rank,
RANK()OVER W2 AS lucky_rank
FROM customers
WINDOW W1 AS (PARTITION BY state,city ORDER BY date_added),
	W2 AS (PARTITION BY state,city ORDER BY random())
),
top10 AS (SELECT *
FROM ranked_st_city
WHERE cust_rank<=10),
top10_luckyRankNum AS(SELECT *,
ROW_NUMBER() OVER (PARTITION BY state,city ORDER BY lucky_rank)AS lucky_rank_num
FROM top10)
SELECT * FROM top10_luckyRankNum
WHERE lucky_rank_num<=2;
						 
						 

--or
WITH ranked_st_city AS(
	SELECT customer_id,first_name,last_name,date_added::DATE,state,city,
RANK()OVER W1 AS cust_rank,
RANK()OVER W2 AS lucky_rank
FROM customers
WINDOW W1 AS (PARTITION BY state,city ORDER BY date_added),
	W2 AS (PARTITION BY state,city ORDER BY random())
),
top10 AS (SELECT *
FROM ranked_st_city
WHERE cust_rank<=10)
SELECT * FROM(
SELECT ROW_NUMBER()OVER(PARTITION BY state,city ORDER BY lucky_rank) AS r,t.*
FROM top10 t)x
WHERE x.r<=2;


/*Management would like to be provided for each month, sales 
across all dealerships in California (CA), sales the month prior, sales two 
months prior, sales one month forward, and sales two months forward. */
SELECT*FROM dealerships;
SELECT *FROM sales;

/*first step:Assemble data,from the dealership and sales table*/
SELECT s.*,d.state
FROM sales s
LEFT JOIN dealerships d ON d.dealership_id = s.dealership_id
WHERE d.state IN ('CA');

--next step: group sales by month
WITH ca_sales AS(SELECT date_trunc('month',sales_transaction_date)::DATE as yyyymm,
SUM(sales_amount) AS monthly_sales
FROM sales s
LEFT JOIN dealerships d ON d.dealership_id = s.dealership_id
WHERE d.state IN ('CA')
GROUP BY yyyymm
ORDER BY yyyymm)
SELECT *,
LAG(monthly_sales,1) OVER w AS lag1,
LAG(monthly_sales,2)  OVER w AS lag2,
LEAD(monthly_sales,1) OVER w AS lead1,
LEAD(monthly_sales,2) OVER w AS lead2
FROM ca_sales
WINDOW w AS (ORDER BY yyyymm);


/*Management would like to be provided the 14-day rolling 
average of sales (over time) … using the last 13 days of available data and 
the current day*/

--first step: build daily sales table...column? day/date sales
WITH daily_sales AS (SELECT sales_transaction_date::DATE AS day, SUM(sales_amount) AS total_sales
FROM sales
GROUP BY 1
ORDER BY 1)
SELECT *,
AVG(total_sales) OVER(ORDER BY day
					 ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS sales_moving_average_14
FROM daily_sales;

/*nice to null out the 1st 13 rows under the sales_moving_average_14 column*/
WITH daily_sales AS (SELECT sales_transaction_date::DATE AS day, SUM(sales_amount) AS total_sales
FROM sales
GROUP BY 1
ORDER BY 1),
moving_average_calc_14 AS (SELECT *,
AVG(total_sales) OVER(ORDER BY day
					 ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) AS sales_moving_average_14,
ROW_NUMBER() OVER (ORDER BY day) AS row_number
FROM daily_sales
ORDER BY 1)
SELECT day,total_sales,CASE WHEN row_number>=14 THEN sales_moving_average_14 ELSE NULL END AS sales_14,row_number
FROM moving_average_calc_14;
				
/*EXERCISE:b:What if you really wanted a 14-day rolling average? */
WITH daily_sales AS (SELECT sales_transaction_date::DATE AS day, SUM(sales_amount) AS total_sales
FROM sales
GROUP BY 1
ORDER BY 1),
moving_average_calc_14 AS (SELECT *,
AVG(total_sales) OVER(ORDER BY day
					 RANGE BETWEEN '13 days' PRECEDING AND CURRENT ROW) AS sales_moving_average_14,
ROW_NUMBER() OVER (ORDER BY day) AS row_number,
LAST_VALUE(day) OVER w -FIRST_VALUE(day) OVER w AS day_number
FROM daily_sales
WINDOW w AS (ORDER BY day)						   
ORDER BY 1)
SELECT day,total_sales,CASE WHEN day_number>=14 THEN sales_moving_average_14 ELSE NULL END AS sales_14,
row_number,day_number
FROM moving_average_calc_14;

/*Management would like to provide a daily goal to its employees 
to achieve a daily sales of at least 
¾ * (the maximum daily sales over the last 14 sales days)
Write a query to provide the daily goal/target for days after Jan 1st 2020*/
WITH daily_sales AS (SELECT sales_transaction_date::DATE AS day,sum(sales_amount) AS total_sales
FROM sales
GROUP BY 1
ORDER BY 1)
SELECT *,
(3.0/4)*MAX(total_sales) OVER w AS goal
FROM daily_sales
WINDOW w AS (ORDER BY day ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING)
ORDER BY day;

/*part b*/

WITH daily_sales AS (SELECT sales_transaction_date::DATE AS day,sum(sales_amount) AS total_sales
FROM sales
GROUP BY 1
ORDER BY 1),
daily_goals AS(
SELECT *,
(3.0/4)*MAX(total_sales) OVER w AS goal
FROM daily_sales
WINDOW w AS (ORDER BY day ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING)
ORDER BY day)
SELECT * FROM daily_goals
WHERE total_sales>=goal AND day>='2020-01-01';

/*part c*/

WITH daily_sales AS (SELECT sales_transaction_date::DATE AS day,sum(sales_amount) AS total_sales
FROM sales
GROUP BY 1
ORDER BY 1)
SELECT *,
(3.0/4)*MAX(total_sales) OVER w AS goal,
NTILE(10)OVER(ORDER BY total_sales DESC) AS daily_decile
FROM daily_sales
WINDOW w AS (ORDER BY day ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING)
ORDER BY day;













