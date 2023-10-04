-- SOLUTIONS TO CASE STUDY #2: PIZZA RUNNER

-- C. Ingredient Optimisation

-- 1. What are the standard ingredients for each pizza?
SELECT 
	topping_name
	,pizzas_with_topping
FROM 
	(
	SELECT 
		pt.topping_name
		,COUNT(DISTINCT pr.pizza_id) AS pizzas_with_topping
		,DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT pr.pizza_id) DESC) AS ranking
	FROM CS2_pizza_recipes_clean pr
	LEFT JOIN CS2_pizza_toppings pt
	ON pt.topping_id = pr.topping
	GROUP BY pt.topping_name
	)
WHERE ranking = 1;

-- 2. What was the most commonly added extra?
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
	topping_name
	,count_extra
FROM
	(
	SELECT
		CAST(s.extra AS INT) AS extra
		,pt.topping_name 
		,COUNT(s.extra) AS count_extra
		,DENSE_RANK() OVER (ORDER BY COUNT(s.extra) DESC) AS ranking
	FROM split s
	LEFT JOIN CS2_pizza_toppings pt
	ON pt.topping_id = s.extra
	WHERE 
		s.extra <> ''
	GROUP BY 
		s.extra
	)
WHERE ranking = 1;

-- 3. What was the most common exclusion?
WITH RECURSIVE split(exclusion, string) AS (
	SELECT 
		NULL
		,exclusions||','
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
	topping_name
	,count_exclusion
FROM
	(
	SELECT
		CAST(s.exclusion AS INT) AS exclusion
		,pt.topping_name 
		,COUNT(s.exclusion) AS count_exclusion
		,DENSE_RANK() OVER (ORDER BY COUNT(s.exclusion) DESC) AS ranking
	FROM split s
	LEFT JOIN CS2_pizza_toppings pt
	ON pt.topping_id = s.exclusion
	WHERE 
		s.exclusion <> ''
	GROUP BY 
		s.exclusion
	)
WHERE ranking = 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--     Meat Lovers
--     Meat Lovers - Exclude Beef
--     Meat Lovers - Extra Bacon
--     Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
WITH RECURSIVE 
	split_ext(id, order_id, pizza_id, extras, extra, string) AS (
		SELECT
			ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
			,order_id
			,pizza_id
			,extras
			,NULL
			,extras||','
		FROM CS2_customer_orders_clean
		UNION ALL
		SELECT
			id
			,order_id
			,pizza_id
			,extras	
			,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
			,SUBSTR(string, INSTR(string, ',') + 1) 
		FROM split_ext
		WHERE 
			string <> ''
	),
	split_exc(id, order_id, pizza_id, exclusions, exclusion, string) AS (
		SELECT
			ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
			,order_id
			,pizza_id
			,exclusions
			,NULL
			,exclusions||','
		FROM CS2_customer_orders_clean
		UNION ALL
		SELECT
			id
			,order_id
			,pizza_id
			,exclusions
			,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
			,SUBSTR(string, INSTR(string, ',') + 1) 
		FROM split_exc
		WHERE 
			string <> ''
	)
SELECT 
	final_table.order_id
	,final_table.id AS pizza_in_order
	,final_table.pizza_name||GROUP_CONCAT(final_table.descr, '') AS description
FROM 
	(
	SELECT
		split.order_id
		,split.id 
		,split.pizza_id
		,CASE 
			WHEN pn.pizza_name = 'Meatlovers' THEN 'Meat Lovers' ELSE pn.pizza_name
		END AS pizza_name
		,extra_or_exclusion
		,pt.topping_name
		,CASE 
			WHEN pt.topping_name IS NOT NULL AND split.extra_or_exclusion = 'extra' THEN ' - Extra '||GROUP_CONCAT(pt.topping_name, ', ')
			WHEN pt.topping_name IS NOT NULL AND split.extra_or_exclusion = 'exclusion' THEN ' - Exclude '||GROUP_CONCAT(pt.topping_name, ', ') 
			ELSE ''
		END AS descr
	FROM 
		(
		SELECT 
			order_id
			,id
			,pizza_id
			,'extra' AS extra_or_exclusion
			,extra AS topping
		FROM split_ext 
		WHERE extra IS NOT NULL 
		UNION ALL
		SELECT 
			order_id
			,id 
			,pizza_id 
			,'extra' AS extra_or_exclusion
			,extra AS topping
		FROM split_ext
		WHERE topping IS NULL AND NOT EXISTS (
			SELECT 1 FROM split_ext se_B
			WHERE se_B.order_id = split_ext.order_id AND se_B.id = split_ext.id AND se_B.pizza_id = split_ext.pizza_id AND se_B.extra IS NOT NULL
			)
		UNION ALL 
		SELECT 
			order_id
			,id
			,pizza_id
			,'exclusion' AS extra_or_exclusion
			,exclusion AS topping
		FROM split_exc 
		WHERE exclusion IS NOT NULL 
		UNION ALL
		SELECT 
			order_id
			,id 
			,pizza_id 
			,'exclusion' AS extra_or_exclusion
			,exclusion AS topping
		FROM split_exc
		WHERE topping IS NULL AND NOT EXISTS (
			SELECT 1 FROM split_exc se_B
			WHERE se_B.order_id = split_exc.order_id AND se_B.id = split_exc.id AND se_B.pizza_id = split_exc.pizza_id AND se_B.exclusion IS NOT NULL
			)
		) split
	LEFT JOIN CS2_pizza_names pn 
	ON pn.pizza_id = split.pizza_id
	LEFT JOIN CS2_pizza_toppings pt
	ON pt.topping_id = split.topping
	GROUP BY 
		split.order_id
		,split.id
		,split.pizza_id
		,split.extra_or_exclusion
	ORDER BY 
		split.order_id
		,split.id
		,pn.pizza_id
		,split.extra_or_exclusion
		,split.topping
	) final_table
GROUP BY 
	final_table.order_id
	,final_table.pizza_id
	,final_table.id
ORDER BY order_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--     For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
WITH RECURSIVE 
	split_ext(id, order_id, pizza_id, extras, extra, string) AS (
		SELECT
			ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
			,order_id
			,pizza_id
			,extras
			,NULL
			,extras||','
		FROM CS2_customer_orders_clean
		UNION ALL
		SELECT
			id
			,order_id
			,pizza_id
			,extras	
			,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
			,SUBSTR(string, INSTR(string, ',') + 1) 
		FROM split_ext
		WHERE 
			string <> ''
	),
	split_exc(id, order_id, pizza_id, exclusions, exclusion, string) AS (
		SELECT
			ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
			,order_id
			,pizza_id
			,exclusions
			,NULL
			,exclusions||','
		FROM CS2_customer_orders_clean
		UNION ALL
		SELECT
			id
			,order_id
			,pizza_id
			,exclusions
			,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
			,SUBSTR(string, INSTR(string, ',') + 1) 
		FROM split_exc
		WHERE 
			string <> ''
	)
SELECT
	final_table.order_id
	,final_table.id AS pizza_in_order
	,final_table.pizza_name||': '||GROUP_CONCAT(final_table.end_recipe, ', ') AS recipe
FROM
	(
	SELECT 
		recipe.order_id
		,recipe.id
		,CASE WHEN pn.pizza_name = 'Meatlovers' THEN 'Meat Lovers' ELSE pn.pizza_name END AS pizza_name
		,CASE WHEN COUNT(pt.topping_name) = 1 THEN '' ELSE COUNT(pt.topping_name)||'x ' END || pt.topping_name AS end_recipe
	FROM
		(	
		SELECT 
			order_id
			,id
			,pizza_id
			,'extra' AS status
			,extra AS topping
		FROM split_ext 
		WHERE extra IS NOT NULL 
		UNION ALL
		SELECT 
			order_id
			,id 
			,pizza_id 
			,'extra' AS status
			,extra AS topping
		FROM split_ext
		WHERE topping IS NULL AND NOT EXISTS (
			SELECT 1 FROM split_ext se_B
			WHERE se_B.order_id = split_ext.order_id AND se_B.id = split_ext.id AND se_B.pizza_id = split_ext.pizza_id AND se_B.extra IS NOT NULL
			)
		UNION ALL
		SELECT 
			coc.order_id 
			,coc.id
			,coc.pizza_id 
			,'recipe' AS status
			,prc.topping 
		FROM CS2_customer_orders_clean coc 
		LEFT JOIN CS2_pizza_recipes_clean prc 
		ON prc.pizza_id = coc.pizza_id 
		ORDER BY coc.order_id 
		) recipe
	LEFT OUTER JOIN split_exc se
	ON se.id = recipe.id
	AND se.order_id = recipe.order_id 
	AND se.exclusion = recipe.topping
	AND se.exclusion IS NULL
	LEFT JOIN CS2_pizza_names pn
	ON pn.pizza_id = recipe.pizza_id
	LEFT JOIN CS2_pizza_toppings pt
	ON pt.topping_id = recipe.topping
	WHERE recipe.topping IS NOT NULL
	GROUP BY 
		recipe.order_id
		,recipe.id
		,pn.pizza_name
		,pt.topping_name
	) final_table
GROUP BY 
	final_table.order_id
	,final_table.id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH RECURSIVE 
	split_ext(id, order_id, pizza_id, extras, extra, string) AS (
		SELECT
			ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
			,order_id
			,pizza_id
			,extras
			,NULL
			,extras||','
		FROM CS2_customer_orders_clean
		UNION ALL
		SELECT
			id
			,order_id
			,pizza_id
			,extras	
			,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
			,SUBSTR(string, INSTR(string, ',') + 1) 
		FROM split_ext
		WHERE 
			string <> ''
	),
	split_exc(id, order_id, pizza_id, exclusions, exclusion, string) AS (
		SELECT
			ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id, pizza_id, exclusions, extras ASC) AS id
			,order_id
			,pizza_id
			,exclusions
			,NULL
			,exclusions||','
		FROM CS2_customer_orders_clean
		UNION ALL
		SELECT
			id
			,order_id
			,pizza_id
			,exclusions
			,TRIM(SUBSTR(string, 0, INSTR(string, ',')), ' ')
			,SUBSTR(string, INSTR(string, ',') + 1) 
		FROM split_exc
		WHERE 
			string <> ''
	)
SELECT 
	pt.topping_name
	,COUNT(pt.topping_name) AS times_needed
FROM
	(	
	SELECT 
		order_id
		,id
		,pizza_id
		,'extra' AS status
		,extra AS topping
	FROM split_ext 
	WHERE extra IS NOT NULL 
	UNION ALL
	SELECT 
		order_id
		,id 
		,pizza_id 
		,'extra' AS status
		,extra AS topping
	FROM split_ext
	WHERE topping IS NULL AND NOT EXISTS (
		SELECT 1 FROM split_ext se_B
		WHERE se_B.order_id = split_ext.order_id AND se_B.id = split_ext.id AND se_B.pizza_id = split_ext.pizza_id AND se_B.extra IS NOT NULL
		)
	UNION ALL
	SELECT 
		coc.order_id 
		,coc.id
		,coc.pizza_id 
		,'recipe' AS status
		,prc.topping 
	FROM CS2_customer_orders_clean coc 
	LEFT JOIN CS2_pizza_recipes_clean prc 
	ON prc.pizza_id = coc.pizza_id 
	ORDER BY coc.order_id 
	) recipe
LEFT OUTER JOIN split_exc se
ON se.id = recipe.id
AND se.order_id = recipe.order_id 
AND se.exclusion = recipe.topping
AND se.exclusion IS NULL
LEFT JOIN CS2_pizza_toppings pt
ON pt.topping_id = recipe.topping
WHERE recipe.topping IS NOT NULL
GROUP BY 
	pt.topping_name
ORDER BY 
	times_needed DESC;
	
