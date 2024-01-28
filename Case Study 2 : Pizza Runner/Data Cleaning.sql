CREATE TABLE customer_orders_temp AS
(SELECT ROW_NUMBER() OVER() AS record_id, order_id,customer_id,pizza_id,
 CASE WHEN exclusions IS NULL OR exclusions='null' THEN ''
 ELSE exclusions
 END AS exclusions,
 CASE WHEN extras IS NULL OR extras='null' THEN ''
 ELSE extras
 END AS extras,
 order_time
 FROM customer_orders);
 

CREATE TABLE runner_orders_temp AS
(SELECT order_id,runner_id,
 CASE WHEN pickup_time IS NULL OR pickup_time='null' THEN ''
 ELSE pickup_time
 END AS pickup_time,
 CASE WHEN distance IS NULL OR distance='null' THEN ''
 WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
 ELSE distance
 END AS distance,
 CASE WHEN duration IS NULL OR duration='null' THEN ''
 WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
 WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
 WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
 ELSE duration
 END AS duration,
 CASE WHEN cancellation IS NULL OR cancellation='null' THEN ''
 ELSE cancellation
 END AS cancellation
FROM runner_orders);

SET SQL_MODE='ALLOW_INVALID_DATES';
ALTER TABLE runner_orders_temp 
MODIFY COLUMN pickup_time TIMESTAMP,
MODIFY COLUMN distance FLOAT(4,2),
MODIFY COLUMN duration INT;
