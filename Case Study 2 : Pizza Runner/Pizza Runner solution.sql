--------------------- -- A. Pizza Metrics -- ---------------------

-- 1. How many pizzas were ordered?

SELECT COUNT(order_id) AS pizzas_ordered 
FROM pizza_runner.customer_orders_temp;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT(order_id)) AS unique_customers_orders 
FROM pizza_runner.customer_orders_temp;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id,COUNT(runner_id) AS successful_orders FROM pizza_runner.runner_orders_temp
WHERE cancellation=''
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?

WITH pizza_delivered AS
(SELECT customer_orders_temp.pizza_id,pizza_name,cancellation 
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.runner_orders_temp
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
LEFT JOIN pizza_runner.pizza_names
ON pizza_runner.customer_orders_temp.pizza_id=pizza_runner.pizza_names.pizza_id)
SELECT pizza_id,pizza_name,COUNT(pizza_id) AS pizzas_delivered 
FROM pizza_delivered
WHERE cancellation=''
GROUP BY pizza_id,pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id,customer_orders_temp.pizza_id,pizza_name, COUNT(customer_orders_temp.pizza_id) AS pizzas_ordered
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.pizza_names
ON pizza_runner.customer_orders_temp.pizza_id=pizza_runner.pizza_names.pizza_id
GROUP BY customer_id,pizza_id,pizza_name
ORDER BY customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?

SELECT customer_orders_temp.order_id,COUNT(pizza_id) AS pizzas_delivered
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.runner_orders_temp 
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation=''
GROUP BY order_id
ORDER BY pizzas_delivered DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

WITH pizzas_delivered AS
(SELECT customer_id,pizza_id,exclusions,extras 
FROM pizza_runner.customer_orders_temp 
LEFT JOIN pizza_runner.runner_orders_temp 
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation='')
SELECT customer_id,
COUNT(CASE WHEN exclusions='' OR extras='' THEN 1
END) AS no_of_changed_pizzas,
COUNT(CASE WHEN exclusions<>'' AND extras<>'' THEN 1
END) AS no_of_unchanged_pizzas
FROM pizzas_delivered
GROUP BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT COUNT(pizza_id) AS pizzas_with_exclusions_and_extras
FROM pizza_runner.customer_orders_temp 
LEFT JOIN pizza_runner.runner_orders_temp 
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation='' AND exclusions<>'' AND extras<>'';

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(HOUR FROM order_time) AS hours,COUNT(order_id) AS pizzas_ordered
FROM pizza_runner.customer_orders_temp
GROUP BY hours
ORDER BY hours;

-- 10. What was the volume of orders for each day of the week?

SELECT DAYNAME(order_time) AS day, COUNT(order_id) AS orders
FROM pizza_runner.customer_orders_temp
GROUP BY day
ORDER BY orders DESC;

--------------------- -- B. Runner and Customer Experience -- ---------------------

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT WEEK(registration_date+2) AS week, COUNT(runner_id) AS runners_signed_up
FROM pizza_runner.runners
GROUP BY week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id,
ROUND(AVG(TIMESTAMPDIFF(SECOND,order_time,pickup_time)/60),2) AS avg_time
FROM pizza_runner.runner_orders_temp
INNER JOIN pizza_runner.customer_orders_temp
ON 
pizza_runner.runner_orders_temp.order_id=pizza_runner.customer_orders_temp.order_id
WHERE cancellation=''
GROUP BY runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH pizzas_ordered AS
(SELECT customer_orders_temp.order_id,
COUNT(customer_orders_temp.order_id) AS pizza_count,
TIMESTAMPDIFF(SECOND,order_time,pickup_time)/60 AS total_time
FROM pizza_runner.runner_orders_temp
LEFT JOIN pizza_runner.customer_orders_temp
ON 
pizza_runner.runner_orders_temp.order_id=pizza_runner.customer_orders_temp.order_id
WHERE cancellation=''
GROUP BY customer_orders_temp.order_id,total_time)
SELECT pizza_count,ROUND(AVG(total_time),2) AS avg_time
FROM pizzas_ordered
GROUP BY pizza_count;

-- 4. What was the average distance travelled for each customer?

SELECT customer_id,ROUND(AVG(distance),2) AS avg_distance
FROM pizza_runner.runner_orders_temp
LEFT JOIN pizza_runner.customer_orders_temp
ON 
pizza_runner.runner_orders_temp.order_id=pizza_runner.customer_orders_temp.order_id
WHERE cancellation='' 
GROUP BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) AS max_delivery_time,MIN(duration) AS min_delivery_time,
MAX(duration)-MIN(duration) AS time_diff
FROM pizza_runner.runner_orders_temp
WHERE duration<>0;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT runner_id,order_id,ROUND(AVG(distance/(duration/60)),2) AS avg_speed
FROM pizza_runner.runner_orders_temp
WHERE distance<>0
GROUP BY runner_id,order_id
ORDER BY runner_id;

-- 7. What is the successful delivery percentage for each runner?

WITH deliveries AS
(SELECT runner_id, COUNT(*) AS total_deliveries,
COUNT(CASE WHEN cancellation='' THEN 1
      END) AS success_deliveries
FROM pizza_runner.runner_orders_temp
GROUP BY runner_id)
SELECT runner_id,(success_deliveries/total_deliveries)*100 AS success_delivery_per
FROM deliveries;

--------------------- -- C. Ingredient Optimisation -- ---------------------

-- 1. What are the standard ingredients for each pizza?

CREATE TABLE standard_pizzas 
(pizza_id INT,
standard_toppings INT);

INSERT INTO standard_pizzas
(pizza_id,standard_toppings)
VALUES 
(1,1),
(1,2),
(1,3),
(1,4),
(1,5),
(1,6),
(1,8),
(1,10),
(2,4),
(2,6),
(2,7),
(2,9),
(2,11),
(2,12);

SELECT pizza_name,GROUP_CONCAT(topping_name) AS standard_ingredients
FROM pizza_runner.standard_pizzas 
LEFT JOIN pizza_runner.pizza_names
ON pizza_runner.standard_pizzas.pizza_id=pizza_runner.pizza_names.pizza_id
LEFT JOIN pizza_runner.pizza_toppings
ON pizza_runner.standard_pizzas.standard_toppings=
pizza_runner.pizza_toppings.topping_id
GROUP BY pizza_name;

-- 2. What was the most commonly added extra?

CREATE TABLE numbers_ext (num INT);

INSERT INTO numbers_ext 
(num)
VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16);

WITH add_extra AS
(WITH extras AS
(SELECT n.num,SUBSTRING_INDEX(SUBSTRING_INDEX(all_extras,',', num), ',', -1) AS each_extra
FROM 
(
 SELECT GROUP_CONCAT(extras SEPARATOR ',') AS all_extras,
 LENGTH(GROUP_CONCAT(extras SEPARATOR ',')) - 
 LENGTH(REPLACE(GROUP_CONCAT(extras SEPARATOR ','), ',', ''))+1 AS count_ext
FROM pizza_runner.customer_orders_temp) c
JOIN pizza_runner.numbers_ext n
ON n.num<=c.count_ext)
SELECT each_extra,topping_name,COUNT(each_extra) AS times_added  FROM extras
LEFT JOIN pizza_runner.pizza_toppings
ON extras.each_extra=pizza_runner.pizza_toppings.topping_id
WHERE each_extra<>''
GROUP BY each_extra,topping_name
ORDER BY times_added DESC)
SELECT topping_name AS most_added_extra FROM add_extra
LIMIT 1;

-- 3. What was the most common exclusion?

CREATE TABLE numbers_exc (num INT);

INSERT INTO numbers_exc 
(num)
VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15);

WITH most_exclusion AS
(WITH exclusions AS
(SELECT num, SUBSTRING_INDEX(SUBSTRING_INDEX(all_exclusions,',',num),',',-1) AS each_exclusion
FROM
(SELECT GROUP_CONCAT(exclusions SEPARATOR ',') AS all_exclusions,
LENGTH(GROUP_CONCAT(exclusions SEPARATOR ','))-
LENGTH(REPLACE(GROUP_CONCAT(exclusions SEPARATOR ','),',',''))+1 AS count_exc
FROM pizza_runner.customer_orders_temp) c
JOIN pizza_runner.numbers_exc n
ON n.num<=c.count_exc)
SELECT each_exclusion,topping_name,COUNT(each_exclusion) AS times_added FROM exclusions
JOIN pizza_runner.pizza_toppings
ON exclusions.each_exclusion=pizza_runner.pizza_toppings.topping_id
WHERE each_exclusion<>''
GROUP BY each_exclusion,topping_name
ORDER BY times_added DESC)
SELECT topping_name AS most_common_exclusion FROM most_exclusion
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT order_id,pizza_names.pizza_id,pizza_name,exclusions,extras,
CASE WHEN customer_orders_temp.pizza_id=1 AND exclusions='' AND extras='' 
THEN 'Meat Lovers'
WHEN customer_orders_temp.pizza_id=2 AND exclusions='' AND extras='' 
THEN 'Veg Lovers'
WHEN customer_orders_temp.pizza_id=1 AND exclusions=4 AND extras='' 
THEN 'Meat Lovers - Exclude Cheese' 
WHEN customer_orders_temp.pizza_id=2 AND exclusions=4 AND extras='' 
THEN 'Veg Lovers - Exclude Cheese' 
WHEN customer_orders_temp.pizza_id=1 AND exclusions='' AND extras=1 
THEN 'Meat Lovers - Extra Bacon' 
WHEN customer_orders_temp.pizza_id=2 AND exclusions='' AND extras=1 
THEN 'Veg Lovers - Extra Bacon'
WHEN customer_orders_temp.pizza_id=1 AND exclusions=4 AND extras='1, 5' 
THEN 'Meat Lovers - Exclude Cheese, Extra Bacon,Chicken'
WHEN customer_orders_temp.pizza_id=1 AND exclusions='2, 6' AND extras='1, 4'
THEN 'Meat Lovers - Exclude - BBQ Sauce,mushrooms, Extra - Bacon,Cheese'
END AS order_item
FROM pizza_runner.pizza_names  
INNER JOIN pizza_runner.customer_orders_temp
ON pizza_runner.pizza_names.pizza_id=pizza_runner.customer_orders_temp.pizza_id;

--------------------- -- D. Pricing and Ratings -- ---------------------

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

WITH total_revenue AS
(SELECT pizza_id,
SUM(CASE WHEN pizza_id=1 THEN 12
ELSE 10
END) AS revenue
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.runner_orders_temp
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation=''
GROUP BY pizza_id)
SELECT CONCAT('$ ',SUM(revenue)) AS total_revenue FROM total_revenue;

-- 2. What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra

WITH total_revenue AS
(WITH t_revenue AS
(SELECT pizza_id,extras,
SUBSTRING_INDEX(extras,',',1) AS extra1,
SUBSTRING_INDEX(extras,',',-1) AS extra2
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.runner_orders_temp
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation='')
SELECT *,
CASE WHEN pizza_id=1 AND extras='' THEN 12
WHEN pizza_id=2 AND extras='' THEN 10
WHEN pizza_id=1 AND extras<>'' AND (extra1<>4 AND extra2<>4) THEN 13
WHEN pizza_id=2 AND extras<>'' AND (extra1<>4 AND extra2<>4) THEN 11
WHEN pizza_id=1 AND extras<>'' AND (extra1=4 OR extra2=4) THEN 14
WHEN pizza_id=2 AND extras<>'' AND (extra1=4 OR extra2=4) THEN 12
END AS revenue
FROM t_revenue)
SELECT CONCAT('$ ',SUM(revenue)) AS total_revenue FROM total_revenue;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

CREATE TABLE ratings 
(order_id INT,
 rating INT,
 comments VARCHAR(20));
 
 INSERT INTO ratings
 (order_id,rating,comments)
 VALUES
 (1,3,'good!!'),
 (2,4,'fab service'),
 (3,4,'great service'),
 (4,3,'could be better'),
 (5,4,'excellent'),
 (7,3,'nice'),
 (8,4,'good service'),
 (10,4,'great!');

SELECT * FROM pizza_runner.ratings;

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

WITH success_orders AS
(SELECT 
customer_orders_temp.order_id,customer_id,COUNT(pizza_id) AS no_of_pizzas,order_time,ROUND((AVG(distance/(duration/60))),2) AS avg_speed
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.runner_orders_temp
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation=''
GROUP BY customer_orders_temp.order_id,customer_id,order_time)
SELECT success_orders.order_id,customer_id,runner_id,rating,order_time,pickup_time,
ROUND(((TIMESTAMPDIFF(SECOND,order_time,pickup_time))/60),2) AS time_diff,
duration,avg_speed,no_of_pizzas
FROM success_orders
LEFT JOIN pizza_runner.runner_orders_temp
ON success_orders.order_id=pizza_runner.runner_orders_temp.order_id
LEFT JOIN pizza_runner.ratings
ON success_orders.order_id=pizza_runner.ratings.order_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

WITH revenue AS
(WITH billing AS
(SELECT customer_orders_temp.order_id,
SUM(CASE WHEN pizza_id=1 THEN 12
ELSE 10
END) AS bill
FROM pizza_runner.customer_orders_temp
LEFT JOIN pizza_runner.runner_orders_temp
ON pizza_runner.customer_orders_temp.order_id=pizza_runner.runner_orders_temp.order_id
WHERE cancellation=''
GROUP BY order_id)
SELECT bill,distance*0.30 AS runner_payment 
FROM billing 
LEFT JOIN pizza_runner.runner_orders_temp
ON billing.order_id=pizza_runner.runner_orders_temp.order_id)
SELECT CONCAT('$ ',SUM(bill)-SUM(runner_payment)) AS net_income FROM revenue;

--------------------- -- BONUS QUESTION --------------------- --

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

INSERT INTO pizza_names 
VALUES(3, 'Supreme');

ALTER TABLE pizza_recipes MODIFY toppings VARCHAR(50);

INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_runner.pizza_names;
SELECT * FROM pizza_runner.pizza_recipes;
