-- Data cleaning
-- CS2_customer_orders cleanup
CREATE VIEW CS2_customer_orders_clean AS 
SELECT 
	order_id 
	,customer_id 
	,pizza_id 
	,CASE 
		WHEN exclusions IN ('null', '') THEN NULL 
		ELSE exclusions 
	END AS exclusions 
	,CASE 
		WHEN extras IN ('null', '') THEN NULL
		ELSE extras
	END AS extras
	,order_time 
FROM CS2_customer_orders;

-- CS2_runner_orders cleanup
CREATE VIEW CS2_runner_orders_clean AS 
SELECT 
	order_id 
	,runner_id 
	,CASE 
		WHEN pickup_time IN ('null') THEN NULL
		ELSE pickup_time
	END AS pickup_time
	,CASE 
		WHEN distance IN ('null') THEN NULL
		WHEN distance LIKE '%km%' THEN CAST(TRIM(distance, 'km ') AS FLOAT)
		ELSE distance
	END AS distance_km
	,CASE 
		WHEN duration IN ('null') THEN NULL
		WHEN duration LIKE '%min%' THEN CAST(TRIM(duration, 'minutes ') AS FLOAT)
		ELSE duration
	END AS duration_min
	,CASE 
		WHEN cancellation IN ('null', '') THEN NULL
		ELSE cancellation
	END AS cancellation
FROM CS2_runner_orders;
