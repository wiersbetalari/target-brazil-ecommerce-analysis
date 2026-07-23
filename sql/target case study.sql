create database target;

use target;

desc customers;

SELECT
MIN(order_purchase_timestamp) AS first_order,
MAX(order_purchase_timestamp) AS last_order,
DATEDIFF(
MAX(order_purchase_timestamp),
MIN(order_purchase_timestamp)
) AS days_of_data
FROM orders;



# Count the Cities & States of customers who ordered during the given period.

SELECT
COUNT(DISTINCT c.customer_city) AS city_count,
COUNT(DISTINCT c.customer_state) AS state_count
FROM customers c;



-- SECTION 2 — Growth Analysis 

# Is there a growing trend in the no. of orders placed over the past years?

SELECT
YEAR(order_purchase_timestamp) AS order_year,
COUNT(*) AS total_orders
FROM orders
GROUP BY YEAR(order_purchase_timestamp)
ORDER BY order_year;

# Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

SELECT
DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS month_year,
COUNT(*) AS total_orders
FROM orders
GROUP BY month_year
ORDER BY month_year;


# During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
-- 0-6 hrs : Dawn
-- 7-12 hrs : Mornings
-- 13-18 hrs : Afternoon
-- 19-23 hrs : Night

SELECT
CASE
WHEN HOUR(order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
WHEN HOUR(order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
WHEN HOUR(order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
ELSE 'Night'
END AS order_period,
COUNT(*) AS total_orders
FROM orders
GROUP BY order_period
ORDER BY total_orders DESC;

# Get the month on month no. of orders placed in each state.

SELECT
YEAR(o.order_purchase_timestamp) AS year,
MONTH(o.order_purchase_timestamp) AS month,
c.customer_state,
COUNT(*) AS total_orders
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY
YEAR(o.order_purchase_timestamp),
MONTH(o.order_purchase_timestamp),
c.customer_state
ORDER BY
c.customer_state,year,month;


# How are the customers distributed across all the states?

SELECT
customer_state,
COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM customers
GROUP BY customer_state
ORDER BY unique_customers DESC;


# Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).

with sale_2018 as(
select 
year(order_purchase_timestamp) as year,
sum(payment_value) as cost_of_orders
from payments p
join orders o
on p.order_id = o.order_id
where year(order_purchase_timestamp) = 2018 and 
(month(order_purchase_timestamp) between 1 and 8)
group by year(order_purchase_timestamp)),

sale_2017 as(
select 
year(order_purchase_timestamp) as year,
sum(payment_value) as cost_of_orders
from payments p
join orders o
on p.order_id = o.order_id
where year(order_purchase_timestamp) = 2017 and 
(month(order_purchase_timestamp) between 1 and 8)
group by year(order_purchase_timestamp)
)

SELECT
    s1.cost_of_orders AS sales_2018,
    s2.cost_of_orders AS sales_2017,
    ((s1.cost_of_orders - s2.cost_of_orders) / s2.cost_of_orders) * 100 
        AS percentage_growth
FROM sale_2018 s1
CROSS JOIN sale_2017 s2;


# Calculate the Total & Average value of order price for each state.

select
c.customer_state,
sum(price) as total_price,
avg(price) as average_price
from order_items oi 
join orders o
on oi.order_id = o.order_id
join customers c
on o.customer_id = c.customer_id
group by customer_state
order by total_price desc,average_price desc;

# Calculate the Total & Average value of order freight for each state.

select
c.customer_state,
sum(freight_value) as total_freight,
avg(freight_value) as average_freight
from order_items oi 
join orders o
on oi.order_id = o.order_id
join customers c
on o.customer_id = c.customer_id
group by customer_state
order by total_freight desc,average_freight desc;

-- Analysis based on sales, freight and delivery time.
-- Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
-- Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
# Do this in a single query.
# time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
# diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date


select
order_id,
order_delivered_customer_date,
order_purchase_timestamp,
order_estimated_delivery_date,
datediff(order_delivered_customer_date,order_purchase_timestamp) as time_to_deliver,
datediff(order_delivered_customer_date,order_estimated_delivery_date) as diff_estimated_delivery
from orders;


# Find out the top 5 states with the highest & lowest average freight value.

with top as
(
select
c.customer_state,
avg(oi.freight_value) as avg_freight_value_top,
row_number()over(order by avg(oi.freight_value) desc) as rn
from order_items oi
join orders o
on oi.order_id = o.order_id
join customers c
on o.customer_id = c.customer_id
group by c.customer_state
limit 5),

bottom as
(select
c.customer_state,
avg(oi.freight_value) as avg_freight_value_bottom,
row_number()over(order by avg(oi.freight_value)) as rn
from order_items oi
join orders o
on oi.order_id = o.order_id
join customers c
on o.customer_id = c.customer_id
group by c.customer_state
limit 5)

select 
t.customer_state as top_state,
t.avg_freight_value_top,
b.customer_state as bottom_state,
b.avg_freight_value_bottom
from top t
join bottom b
on t.rn = b.rn;

# Find out the top 5 states with the highest & lowest average delivery time.

select
c.customer_state,
avg(datediff(order_delivered_customer_date,order_purchase_timestamp)) as avg_delivery_date_highest
from orders o
join customers c
on o.customer_id = c.customer_id
group by c.customer_state
order by avg_delivery_date_highest desc
limit 5;


SELECT
c.customer_state,
AVG(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp)) AS avg_delivery_date_lowest
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_delivery_date_lowest
LIMIT 5;


# Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
-- You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state


select
c.customer_state,
avg(datediff(order_delivered_customer_date,order_estimated_delivery_date)) as delivery
from orders o 
join customers c
on o.customer_id = c.customer_id
group by c.customer_state
order by delivery
limit 5;

-- Analysis based on the payments:
#Find the month on month no. of orders placed using different payment types.

select
date_format(order_purchase_timestamp, "%Y-%m") as month,
p.payment_type,
count(distinct o.order_id) as no_of_orders_placed
from orders o
join payments p
on o.order_id = p.order_id
group by month,payment_type
order by month,payment_type;


#Find the no. of orders placed on the basis of the payment installments that have been paid.

SELECT
payment_installments,
COUNT(DISTINCT order_id) AS no_of_orders
FROM payments
GROUP BY payment_installments
ORDER BY payment_installments;








