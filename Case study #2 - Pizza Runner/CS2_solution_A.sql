-- SOLUTIONS TO CASE STUDY #2: PIZZA RUNNER

-- A. Pizza Metrics

-- 1. How many pizzas were ordered?
SELECT 
	COUNT(order_time) AS ordered_pizzas
FROM CS2_customer_orders_clean;

-- 2. How many unique customer orders were made?
SELECT 
	COUNT(DISTINCT order_id) AS unique_orders
FROM CS2_customer_orders_clean;

-- 3. How many successful orders were delivered by each runner?
SELECT 
	runner_id 
	,COUNT(DISTINCT order_id) AS unique_delivered_orders
FROM CS2_runner_orders_clean
WHERE pickup_time IS NOT NULL 
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT 
	pn.pizza_name 
	,COUNT(coc.order_id) AS delivered_pizza_count
FROM CS2_customer_orders_clean coc
INNER JOIN CS2_runner_orders_clean roc
ON roc.order_id = coc.order_id 
AND roc.cancellation IS NULL
LEFT JOIN CS2_pizza_names pn
ON pn.pizza_id = coc.pizza_id 
GROUP BY 
	pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	coc.customer_id 
	,pn.pizza_name 
	,COUNT(coc.order_id) AS pizzas_ordered
FROM CS2_customer_orders_clean coc
LEFT JOIN CS2_pizza_names pn
ON pn.pizza_id = coc.pizza_id 
GROUP BY 
	coc.customer_id 
	,pn.pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT 
	COUNT(order_time) AS max_pizzas_delivered_at_once 
FROM CS2_customer_orders_clean coc
INNER JOIN CS2_runner_orders_clean roc
ON roc.order_id = coc.order_id 
AND roc.cancellation IS NULL
GROUP BY 
	coc.order_id
ORDER BY max_pizzas_delivered_at_once DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	coc.customer_id 
	,COUNT(CASE 
		WHEN coc.exclusions IS NULL AND coc.extras IS NULL THEN coc.order_time 
	END) AS pizzas_with_no_change
	,COUNT(CASE 
		WHEN coc.exclusions IS NOT NULL OR coc.extras IS NOT NULL THEN coc.order_time 
	END) AS pizzas_with_at_least_one_change
FROM CS2_customer_orders_clean coc
INNER JOIN CS2_runner_orders_clean roc
ON roc.order_id = coc.order_id 
AND roc.cancellation IS NULL
GROUP BY 
	coc.customer_id; 

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	COUNT(coc.order_time) AS pizzas_with_exclusions_and_extras
FROM CS2_customer_orders_clean coc
INNER JOIN CS2_runner_orders_clean roc
ON roc.order_id = coc.order_id 
AND roc.cancellation IS NULL
WHERE
	coc.exclusions IS NOT NULL
	AND coc.extras IS NOT NULL;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	STRFTIME('%H', order_time) AS order_hour
	,COUNT(coc.order_id) AS order_count
FROM CS2_customer_orders_clean coc
GROUP BY 
	order_hour
ORDER BY 
	order_hour;

-- 10. What was the volume of orders for each day of the week?
SELECT 
	CASE CAST(STRFTIME('%w', order_time) AS INT)
		WHEN 0 then 'Sunday'
		WHEN 1 then 'Monday'
		WHEN 2 then 'Tuesday'
		WHEN 3 then 'Wednesday'
		WHEN 4 then 'Thursday'
		WHEN 5 then 'Friday'
		WHEN 6 THEN 'Saturday' 
	END AS order_weekday
	,COUNT(coc.order_id) AS order_count
FROM CS2_customer_orders_clean coc
GROUP BY 
	order_weekday
ORDER BY 
	STRFTIME('%w', order_time);
