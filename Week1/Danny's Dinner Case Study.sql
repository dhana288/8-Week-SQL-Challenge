/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id,SUM(menu.price) AS total_amount
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
ON sales.product_id=menu.product_id
GROUP BY customer_id
ORDER BY total_amount DESC;


-- 2. How many days has each customer visited the restaurant?

WITH cust_visited AS
(SELECT customer_id, order_date, COUNT(DISTINCT(order_date)) AS no_of_days_visited
FROM dannys_diner.sales
GROUP BY customer_id,order_date)
SELECT customer_id, SUM(no_of_days_visited)
FROM cust_visited
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?

WITH rst_sales AS
(SELECT customer_id,order_date,product_id,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
FROM dannys_diner.sales
ORDER BY ranking)
SELECT customer_id,order_date,rst_sales.product_id,product_name FROM rst_sales
LEFT JOIN dannys_diner.menu
ON rst_sales.product_id=menu.product_id
WHERE ranking=1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH mpi AS
(SELECT sales.product_id,product_name, 
COUNT(sales.product_id) AS no_of_times_purchased
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
GROUP BY product_id,product_name
ORDER BY no_of_times_purchased DESC
LIMIT 1)
SELECT customer_id,sales.product_id,product_name,
COUNT(sales.product_id) AS times_purchased
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
WHERE sales.product_id=(SELECT mpi.product_id FROM mpi)
GROUP BY product_id,product_name,customer_id;


-- 5. Which item was the most popular for each customer?

WITH pop_item AS
(SELECT customer_id,sales.product_id,product_name, COUNT(sales.product_id) AS times_purchased,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(sales.product_id) DESC) 
AS ranking
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
GROUP BY product_id,product_name,customer_id)
SELECT customer_id,product_id,product_name,times_purchased 
FROM pop_item 
WHERE ranking=1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH after_mbr AS
(SELECT sales.customer_id,order_date,sales.product_id,product_name,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS ranking
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON dannys_diner.sales.customer_id=dannys_diner.members.customer_id
AND dannys_diner.sales.order_date>dannys_diner.members.join_date
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id)
SELECT customer_id,product_id,product_name 
FROM after_mbr
WHERE ranking=1;


-- 7. Which item was purchased just before the customer became a member?

WITH before_mbr AS
(SELECT sales.customer_id,order_date,sales.product_id,product_name, 
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS ranking
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON dannys_diner.sales.customer_id=dannys_diner.members.customer_id
AND dannys_diner.sales.order_date<dannys_diner.members.join_date
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id)
SELECT customer_id,product_id,product_name 
FROM before_mbr
WHERE ranking=1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id,COUNT(sales.product_id) AS total_items,
SUM(price) AS total_amount
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON dannys_diner.sales.customer_id=dannys_diner.members.customer_id
AND dannys_diner.sales.order_date<dannys_diner.members.join_date
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
GROUP BY customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH pts AS
(SELECT sales.customer_id,sales.product_id,product_name,
COUNT(sales.product_id) AS total_items, SUM(price) AS total_price, 
CASE WHEN sales.product_id=1 THEN (SUM(price)*10)*2
ELSE (SUM(price)*10)
END AS points
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
GROUP BY product_id,product_name,customer_id)
SELECT customer_id,SUM(points) AS total_points
FROM pts
GROUP BY customer_id;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH dates AS
(SELECT customer_id,join_date,DATE(join_date+6) AS end_date
FROM dannys_diner.members)
SELECT sales.customer_id,
SUM(CASE WHEN menu.product_id=1 THEN 2*10*menu.price
WHEN sales.order_date BETWEEN dates.join_date AND dates.end_date THEN 2 * 10 * menu.price
ELSE 10 * menu.price 
END) AS points
FROM dannys_diner.sales
JOIN dates
  ON sales.customer_id = dates.customer_id
  AND sales.order_date <= '2021-01-31'
JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY customer_id;

---------- Bonus Questions ----------

-- Join All The Things

WITH mem AS
(SELECT sales.customer_id, order_date
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON dannys_diner.sales.customer_id=dannys_diner.members.customer_id
AND dannys_diner.sales.order_date>=dannys_diner.members.join_date)
SELECT customer_id,order_date,product_name,price,
(CASE WHEN customer_id IN (SELECT customer_id FROM mem) AND
                           order_date IN (SELECT order_date FROM mem)
THEN 'Y'
ELSE 'N'
END) AS member
FROM dannys_diner.sales
INNER JOIN  dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id;

-- Rank All The Things

WITH rnk AS
(WITH mem AS
(SELECT sales.customer_id, order_date
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON dannys_diner.sales.customer_id=dannys_diner.members.customer_id
AND dannys_diner.sales.order_date>=dannys_diner.members.join_date)
SELECT customer_id,order_date,product_name,price,
(CASE WHEN customer_id IN (SELECT customer_id FROM mem) AND
                           order_date IN (SELECT order_date FROM mem)
THEN 'Y'
ELSE 'N'
END) AS member
FROM dannys_diner.sales
INNER JOIN  dannys_diner.menu
ON dannys_diner.sales.product_id=dannys_diner.menu.product_id)
SELECT *, 
(CASE WHEN member='Y' 
 THEN RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
 ELSE 'null'
 END) AS ranking FROM rnk;
