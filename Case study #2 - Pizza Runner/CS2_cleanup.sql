-- Data cleaning
-- CS2_customer_orders cleanup
CREATE VIEW CS2_customer_orders_clean AS 
SELECT 
	ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
	,order_id 
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

-- CS2_pizza_recipes cleanup
CREATE VIEW CS2_pizza_recipes_clean AS
WITH split(pizza_id, topping, string) AS (
	SELECT 
		pizza_id
		,NULL
		,toppings||','
	FROM CS2_pizza_recipes
	UNION ALL
	SELECT
		pizza_id 
		,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
		,SUBSTR(string, INSTR(string, ',') + 1) 
	FROM split 
	WHERE 
		string <> ''
)

SELECT 
	pizza_id
	,CAST(topping AS INT) AS topping
FROM split
WHERE 
	topping <> ''
ORDER BY 
	pizza_id ASC;
