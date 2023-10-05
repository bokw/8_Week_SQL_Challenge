-- SOLUTIONS TO CASE STUDY #2: PIZZA RUNNER

-- D. Pricing and Ratings

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT 
	SUM(CASE 
		WHEN pn.pizza_name = 'Meatlovers' THEN 12 ELSE 10
	END) AS earnings
FROM CS2_customer_orders_clean coc
INNER JOIN CS2_runner_orders_clean roc
ON roc.order_id = coc.order_id 
AND roc.cancellation IS NULL
LEFT JOIN CS2_pizza_names pn 
ON pn.pizza_id = coc.pizza_id;

-- 2. What if there was an additional $1 charge for any pizza extras?
--        Add cheese is $1 extra
WITH RECURSIVE split(extra, string) AS (
	SELECT 
		NULL
		,extras||','
	FROM CS2_customer_orders_clean
	UNION ALL
	SELECT 
		TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
		,SUBSTR(string, INSTR(string, ',') + 1) 
	FROM split 
	WHERE 
		string <> ''
)
SELECT 
	SUM(earnings) AS earnings_with_extra_charge
FROM
	(
	SELECT 
		COUNT(extra) AS earnings
	FROM split
	WHERE extra IS NOT NULL
	UNION ALL 
	SELECT 
		SUM(CASE 
			WHEN pn.pizza_name = 'Meatlovers' THEN 12 ELSE 10
		END) AS earnings
	FROM CS2_customer_orders_clean coc
	INNER JOIN CS2_runner_orders_clean roc
	ON roc.order_id = coc.order_id 
	AND roc.cancellation IS NULL
	LEFT JOIN CS2_pizza_names pn 
	ON pn.pizza_id = coc.pizza_id
	);

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE TABLE IF NOT EXISTS CS2_runner_ratings (
	order_id INT NOT NULL
	,rating INT NULL
);

INSERT INTO CS2_runner_ratings
	SELECT 
		roc.order_id
		,ABS(RANDOM())%(6-1) + 1 AS rating
	FROM CS2_runner_orders_clean roc
	WHERE roc.cancellation IS NULL;

SELECT * FROM CS2_runner_ratings; 

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--        customer_id
--        order_id
--        runner_id
--        rating
--        order_time
--        pickup_time
--        Time between order and pickup
--        Delivery duration
--        Average speed
--        Total number of pizzas
SELECT DISTINCT 
	coc.customer_id 
	,roc.order_id 
	,roc.runner_id 
	,crr.rating 
	,coc.order_time 
	,roc.pickup_time 
	,ROUND(CAST((JULIANDAY(roc.pickup_time) - JULIANDAY(coc.order_time)) * 24 * 60 AS REAL), 0) AS time_between_order_and_pickup_min
	,roc.duration_min 
	,ROUND(roc.distance_km  / (roc.duration_min / 60.0), 1) AS average_speed_km_h
	,COUNT(coc.id) AS total_number_of_delivered_pizzas
FROM CS2_runner_orders_clean roc 
INNER JOIN CS2_customer_orders_clean coc 
ON coc.order_id = roc.order_id 
INNER JOIN CS2_runner_ratings crr
ON crr.order_id = roc.order_id 
GROUP BY 
	coc.customer_id 
	,roc.order_id 
	,roc.runner_id 
	,crr.rating 
	,coc.order_time 
	,roc.pickup_time 
	,roc.duration_min 
	,roc.distance_km
ORDER BY
	roc.order_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT 
	SUM(balance) AS end_balance
FROM 
	(
	SELECT 
		SUM(roc.distance_km) * -0.3 AS balance
	FROM CS2_runner_orders_clean roc 
	UNION ALL
	SELECT 
		SUM(CASE 
			WHEN coc.pizza_id = 1 THEN 12 ELSE 10
		END) AS balance
	FROM CS2_customer_orders_clean coc
	INNER JOIN CS2_runner_orders_clean roc
	ON roc.order_id = coc.order_id 
	AND roc.cancellation IS NULL
	);

-- E. Bonus question
--If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO CS2_pizza_names 
	VALUES
		(3, 'Supreme');
	
INSERT INTO CS2_pizza_recipes 
	VALUES
		(3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
		
