# PostgreSQL Portfolio Project: Analyzing Digital Marketing Metrics

## Project Overview
In this project, I analyzed marketing/campaign performance using the Return On Investment Marketing (ROMI) metric. Through this analysis, campaign funds can be allocated effectively to achieve budget efficiency for marketing. This data can be obtained from Kaggle [Download](https://www.kaggle.com/datasets/sinderpreet/analyze-the-marketing-spending/data) 

## Business Problem
Despite consistent marketing spending across multiple campaigns and channels, overall **return on marketing investment (ROMI)** and **conversion rates** have shown inconsistent performance. The company needed to identify:
- Which marketing channels drive the highest revenue efficiency,
- How spending correlates with conversions and order value,
- When customers are most active, and
- Which locations deliver the best ROI.

## Methodology
Using **PostgreSQL** via **pgAdmin 4** to process data, with the following steps:
1. Raw Data
2. Data Preparation & Cleaning
3. EDA (Exploratory Data Analysis)
4. Analytical Query - CTE, Aggregation
5. Visualization
6. Business Recommendations

## Data Processing 

### Data Preparation & Cleaning
This stage aims to clean up data that is invalid and could interfere with data processing, as well as add several columns to support the data analysis process.

In this project, I used several metrics or KPIs to assess the objectives of the analysis, such as:
1. Data Table ```marketing_spend``` From Kaggle [Download](https://www.kaggle.com/datasets/sinderpreet/analyze-the-marketing-spending/data) 
2. ROMI or ROI (%) (Return On Marketing Investment) calculated from ((Revenue - Marketing Spend / Marketing Spend) * 100)
3. Average Order Value ($) (AOV) calculated from (Revenue/Orders)
4. Lead Rate (Leads/Clicks) and Conversion Rate (Orders/Leads)

```sql
ALTER TABLE marketing_spend ADD COLUMN geo_locations VARCHAR(255);
SELECT * FROM marketing_spend;

ALTER TABLE marketing_spend
RENAME COLUMN mark_spent TO spend;

UPDATE marketing_spend
SET 
    geo_locations = split_part(campaign_name, '_', 2),
    campaign_name = split_part(campaign_name, '_', 1);
--
UPDATE marketing_spend
SET
	campaign_name = lower(campaign_name);
--
ALTER TABLE marketing_spend ADD COLUMN day_type VARCHAR(255);
SELECT * FROM marketing_spend;

UPDATE marketing_spend
SET day_type = CASE
    WHEN EXTRACT(ISODOW FROM c_date) IN (6, 7) THEN 'Weekend'
    ELSE 'Weekday'
END;
--
UPDATE marketing_spend
SET spend = 0
WHERE spend IS NULL;
```
### Exploratory Data Analysis (EDA) - Analytical Query - CTE, Aggregation
This stage is an important part of the process. Through this stage, I began analyzing data using PostgreSQL queries in accordance with the predetermined objectives, thereby enabling me to generate appropriate business recommendations. 

**1. Return On Marketing Investment (ROMI)**

  a. ROMI by Category (Marketing Channel)
```sql
SELECT
    category,
    SUM(spend) AS total_spend,
    SUM(revenue) AS total_revenue,
    ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY category
ORDER BY romi_percent DESC;
```
<img width="1033" height="198" alt="eda" src="https://github.com/user-attachments/assets/271a67bc-6cf1-42c5-903b-510fdeea4bed" />

  b. ROMI by Campaign Platform
```sql
SELECT campaign_name,
       ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY campaign_name
ORDER BY romi_percent DESC;
```
<img width="1033" height="171" alt="romi_per_campaign" src="https://github.com/user-attachments/assets/193f3c71-79a2-4d14-b876-6bf8d24ef263" />

Based on data findings from Marketing Channel, Influencers have a significant impact based on total spend and generate an ROI of 154.29%. This is followed by offline media with an ROI of 22.41%, search media generating an ROI of 7.07%, and Social Media generating a negative ROI of -13.68%. 

Breaking it down further by Marketing Platform, the YouTube platform (Social) leads with a ROMI of 277%, followed by the Instagram platform (Social) with a ROMI of 39.91%, the Banner platform (Offline Media) with a ROMI of 22.41%, the Google platform (Search) with a ROMI of 7.07%, and the Facebook platform (Social) with a negative ROMI of -34.13%.

The campaign material used by the Social Media Marketing Channel must be improved to maximize ROMI. The Facebook platform experienced a loss of -34.13%, which resulted in the Social Media Marketing Channel experiencing a loss with a ROMI of -13.68%.

**2. Conversion Funnel**
```sql
WITH funnel AS (
    SELECT
        campaign_id,
        SUM(clicks) AS clicks,
        SUM(leads) AS leads,
        SUM(orders) AS orders,
		SUM(revenue) AS revenue
    FROM marketing_spend
    GROUP BY campaign_id
)
SELECT
      campaign_id, 
      ROUND((leads::numeric / clicks) * 100, 2) AS lead_rate,
      ROUND((orders::numeric / leads) * 100, 2) AS conversion_rate,
      ROUND((revenue::numeric / orders), 2) AS avg_order_value
FROM funnel
ORDER BY avg_order_value DESC;
```
<img width="1033" height="326" alt="conversion_funnel" src="https://github.com/user-attachments/assets/8d9f73fa-f27f-49af-b054-4a730eca0607" />
<img width="1033" height="232" alt="avg_order_value_funnel" src="https://github.com/user-attachments/assets/76e807ac-2ab4-4be6-9bfb-51892660e4aa" />

Based on the findings data grouped by Campaign ID, which resulted in 11 campaigns. The Lead Rate was calculated using (Leads/Clicks) and the Conversion Rate was calculated using (Orders/Leads). The findings from this data show that a high Lead Rate does not always result in a high Conversion Rate, while a low Lead Rate can result in a high Conversion Rate, as shown in Campaign ID 4387490 with an LR of 1.69% and a CR of 21.34%. However, a high Conversion Rate does not necessarily result in high Revenue, as shown in the Second Visualization, where Campaign ID 10934 actually generated the highest AOV with an LR of 2.21%, a CR of 19.27%, and an AOV of $7,999.7.

In this analysis, Average Order Value (AOV) is used to measure the effectiveness of Campaign ID in generating revenue per order. Based on AOV, Campaign ID 10934 ranks first, generating $7,999.7.

**3. Best Geographic Locations by ROMI - Buyer Activity: Weekdays vs Weekends**
  
  a. Geo Locations Performance by ROMI
```sql
SELECT geo_locations,
       category,
       ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
WHERE geo_locations IN ('tier1','tier2')
GROUP BY geo_locations, category
ORDER BY romi_percent DESC;
```
<img width="1033" height="325" alt="geo_locations" src="https://github.com/user-attachments/assets/c6f9d9c9-368e-4eb7-aaa6-b193810f2922" />

  b. Buyer Activity: Weekdays vs Weekends
```sql
SELECT
  day_type,
  SUM(revenue) AS total_revenue,
  SUM(spend) AS total_spend,
  SUM(revenue) - SUM(spend) AS romi_overall,
  AVG(revenue) AS avg_revenue,
  ROUND(((SUM(revenue) - SUM(spend)) / NULLIF(SUM(spend), 0)) * 100, 2) AS romi_percent
FROM marketing_spend
GROUP BY day_type;
```
<img width="1033" height="369" alt="day_type_avg_revenue_spend" src="https://github.com/user-attachments/assets/35dd0aeb-6e74-4075-ae5f-703ce9b208ff" />

Based on average revenue, people tend to be more active in purchasing on weekdays, with an average daily revenue of $141,914.24. Meanwhile, the average revenue generated on weekends is $132,593.55. 

Based on location, Tier 1 generates the best ROMI with a percentage of 35.29%, while Tier 2 locations generate negative ROMI with a percentage of -28.23%.

## Business Recommendations

Return On Marketing Investment (ROMI)

- Campaign material carried out by the Social Media Marketing Channel must be improved to maximize ROMI. The Facebook platform experienced a loss of -34.13%, which resulted in the Social Media Marketing Channel experiencing a loss with a ROMI of -13.68%.
- Evaluate the allocation of the marketing budget to optimize revenue by selecting marketing channels such as influencers through various campaign platforms such as YouTube and Instagram.

Conversion Funnel

- Evaluate Campaign ID materials based on a combination of various marketing channels and campaign platforms (OmniChannel) to maximize the funnel from clicks → leads → orders.
- Optimize marketing budget allocation with profitable marketing channels, such as influencers, by paying attention to the campaign platforms used to maximize revenue from each incoming order.

Customer Preference

- Run campaigns on weekdays when people are more active in making purchases, as evidenced by average revenue data of $141,914.24. Meanwhile, average revenue generated on weekends is $132,593.55.
- Evaluate campaigns run in Tier 2 locations with a ROMI of -28.23% and reduce the marketing budget allocation for those locations. Optimize campaigns run in Tier 1 locations with positive ROMI data of 35.29%.

## Limitations
This analysis focuses exclusively on digital marketing campaigns recorded in the marketing_spend dataset. The calculations assume that all recorded revenue can be directly attributed to the campaigns in question without considering other influences such as organic sales, repeat purchases, or offline promotions. Furthermore, this dataset covers a limited time frame, which may not capture seasonal variations or long-term trends. Therefore, while the ROMI comparison provides useful directional insights, the results should be interpreted with caution and verified through broader data and longer time periods.

## Let's connect!

[LinkedIn - Mufad Luqman Nur Hakim](https://www.linkedin.com/in/mufadluqman/)

[Medium - Mufad Luqman Nur Hakim](mufadluqman.medium.com)
