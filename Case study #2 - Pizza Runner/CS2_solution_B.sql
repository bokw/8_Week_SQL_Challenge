-- SOLUTIONS TO CASE STUDY #2: PIZZA RUNNER

-- B. Runner and customer experience

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
	'Week ' || STRFTIME('%W', registration_date) AS week
	,COUNT(runner_id) AS runner_count
FROM CS2_runners 
GROUP BY
	STRFTIME('%W', registration_date)
ORDER BY week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH order_time AS (
	SELECT DISTINCT
		roc.order_id 
		,roc.runner_id 
		,roc.pickup_time 
		,coc.order_time 
	FROM CS2_runner_orders_clean roc
	INNER JOIN CS2_customer_orders_clean coc 
	ON coc.order_id = roc.order_id
	WHERE roc.pickup_time IS NOT NULL
)

SELECT 
	runner_id
	,ROUND(AVG(CAST((JULIANDAY(pickup_time) - JULIANDAY(order_time)) * 24 * 60 AS REAL)), 0) AS average_time_order_to_pickup_min
FROM order_time
GROUP BY 
	runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH orders_table AS (
	SELECT DISTINCT 
		coc.order_id
		,COUNT(coc.pizza_id) AS pizzas_per_order
		,ROUND(CAST((JULIANDAY(pickup_time) - JULIANDAY(order_time)) * 24 * 60 AS REAL), 0) AS order_to_pickup
	FROM CS2_customer_orders_clean coc 
	INNER JOIN CS2_runner_orders_clean roc 
	ON roc.order_id = coc.order_id
	WHERE roc.pickup_time IS NOT NULL
	GROUP BY coc.order_id
)

SELECT
	pizzas_per_order
	,COUNT(order_id) AS order_count
	,ROUND(AVG(order_to_pickup), 0) AS average_order_to_pickup
	,ROUND(order_to_pickup / pizzas_per_order, 0) AS average_time_per_pizza
FROM orders_table
GROUP BY pizzas_per_order;

-- 4. What was the average distance travelled for each customer?
SELECT DISTINCT 
	coc.customer_id  
	,ROUND(AVG(roc.distance_km), 2) AS average_distance
FROM CS2_customer_orders_clean coc 
INNER JOIN CS2_runner_orders_clean roc 
ON roc.order_id = coc.order_id
WHERE roc.pickup_time IS NOT NULL
GROUP BY coc.customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH orders_table AS (
	SELECT DISTINCT 
		coc.order_id
		,ROUND(CAST((JULIANDAY(pickup_time) - JULIANDAY(order_time)) * 24 * 60 AS REAL), 0) AS order_to_pickup
	FROM CS2_customer_orders_clean coc 
	INNER JOIN CS2_runner_orders_clean roc 
	ON roc.order_id = coc.order_id
	WHERE roc.pickup_time IS NOT NULL
	GROUP BY coc.order_id
)

SELECT 
	MAX(order_to_pickup) - MIN(order_to_pickup) AS diff_min_and_max_delivery_time
FROM orders_table;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	roc.order_id 
	,roc.runner_id 
	,roc.distance_km 
	,ROUND(roc.distance_km  / (roc.duration_min / 60.0), 1) AS average_speed_km_h
FROM CS2_runner_orders_clean roc 
WHERE roc.pickup_time IS NOT NULL
ORDER BY runner_id, average_speed_km_h;

-- 7. What is the successful delivery percentage for each runner?
SELECT 
	roc.runner_id 
	,COUNT(CASE WHEN roc.cancellation IS NULL THEN roc.order_id END) * 100.0 / COUNT(roc.order_id) AS successful_delivery_rate
FROM CS2_runner_orders_clean roc 
GROUP BY 
	roc.runner_id;
