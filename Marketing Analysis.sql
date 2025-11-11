-- Data Cleaning/Preparation

ALTER TABLE marketing_spend ADD COLUMN geo_locations VARCHAR(255);
SELECT * FROM marketing_spend;

ALTER TABLE marketing_spend
RENAME COLUMN mark_spent TO spend;

UPDATE marketing_spend
SET 
    geo_locations = split_part(campaign_name, '_', 2),
    campaign_name = split_part(campaign_name, '_', 1);

UPDATE marketing_spend
SET
	campaign_name = lower(campaign_name);


ALTER TABLE marketing_spend ADD COLUMN day_type VARCHAR(255);
SELECT * FROM marketing_spend;

UPDATE marketing_spend
SET day_type = CASE
    WHEN EXTRACT(ISODOW FROM c_date) IN (6, 7) THEN 'Weekend'
    ELSE 'Weekday'
END;

UPDATE marketing_spend
SET spend = 0
WHERE spend IS NULL;

SELECT ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend;


-- 2. Exploratory Data Analysis (EDA)
SELECT campaign_name,
       ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY campaign_name
ORDER BY romi_percent DESC;

SELECT
	category, 
	SUM(spend) AS total_spend, 
    SUM(revenue) AS total_revenue,
	ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY category
ORDER BY romi_percent DESC;


-- 3. Time-Based Performance Analysis

-- Daily spend and revenue trend
SELECT c_date,
       SUM(spend) AS total_spend,
       SUM(revenue) AS total_revenue,
       ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY c_date
ORDER BY romi_percent DESC;

-- 4. Conversion Funnel Analysis

WITH funnel AS (
    SELECT
		campaign_id,
		--campaign_name,
        SUM(clicks) AS clicks,
        SUM(leads) AS leads,
        SUM(orders) AS orders,
		SUM(revenue) AS revenue
    FROM marketing_spend
    GROUP BY campaign_id -- campaign_name
)
SELECT campaign_id, 
       ROUND((leads::numeric / clicks) * 100, 2) AS lead_rate,
       ROUND((orders::numeric / leads) * 100, 2) AS conversion_rate,
	   ROUND((revenue::numeric / orders), 2) AS avg_order_value
FROM funnel
ORDER BY avg_order_value DESC; 


5. 

-- ROMI by location and category
SELECT geo_locations,
       ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
WHERE geo_locations IN ('tier1','tier2')
GROUP BY geo_locations
ORDER BY romi_percent DESC;


-- 6. Performance Comparison by Day Type (Weekday vs. Weekend)

SELECT
  day_type,
  SUM(revenue) AS total_revenue,
  SUM(spend) AS total_spend,
  SUM(revenue) - SUM(spend) AS romi_overall,
  AVG(revenue) AS avg_revenue,
  AVG(spend) AS avg_spend,
  AVG(orders) AS avg_orders,
  ROUND((SUM(revenue) / NULLIF(SUM(orders),0)), 2) AS avg_order_value,
  ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY day_type;

7. 

SELECT
  day_type,
  SUM(revenue) AS total_revenue,
  SUM(spend) AS total_spend,
  SUM(revenue) - SUM(spend) AS romi_overall,
  ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY day_type;


----- OVERVIEW

CREATE VIEW vw_romi_summary AS
SELECT campaign_name,
       SUM(spend) AS total_spend,
       SUM(revenue) AS total_revenue,
       ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_ratio
FROM marketing_spend
GROUP BY campaign_name;

SELECT * FROM vw_romi_summary;

CREATE VIEW 





