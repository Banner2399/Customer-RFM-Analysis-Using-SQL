-- RFM Table with Scores and Segments
CREATE TABLE RFM_Customers (
    Customer_ID VARCHAR(20) PRIMARY KEY,
    Customer_Name VARCHAR(100),
    Recency INT,
    Frequency INT,
    Monetary DECIMAL(10,2),
    R_Score INT,
    F_Score INT,
    M_Score INT,
    RFM_Score VARCHAR(3),
    Customer_Segment VARCHAR(50)
);

-- Populating RFM Data with Segmentation
INSERT INTO rfm_customers
WITH rfm_base AS (
	SELECT
		Customer_ID,
        Customer_Name,
        DATEDIFF((SELECT MAX(Order_Date) FROM SalesData), MAX(Order_Date)) AS recency,
        COUNT(DISTINCT Order_ID) AS frequency,
        SUM(Sales) AS monetary
	FROM salesdata
    GROUP BY Customer_ID, Customer_Name
),
rfm_scores AS (
	SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT
	Customer_ID,
    Customer_Name,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score , f_score , m_score) AS RFM_Score,
    CASE
        WHEN (R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4) THEN 'Champions'
        WHEN (R_Score >= 3 AND F_Score >= 3 AND M_Score >= 3) THEN 'Loyal Customers'
        WHEN (R_Score >= 4 AND F_Score <= 2 AND M_Score <= 2) THEN 'New Customers'
        WHEN (R_Score >= 3 AND F_Score >= 3 AND M_Score <= 3) THEN 'Potential Loyalists'
        WHEN (R_Score >= 2 AND F_Score <= 3 AND M_Score <= 3) THEN 'At Risk'
        WHEN (R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4) THEN 'Cant Lose Them'
        WHEN (R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2) THEN 'Lost Customers'
        ELSE 'Need Attention'
    END AS Customer_Segment
FROM rfm_scores;

-- Creating a Value Rating System
ALTER TABLE rfm_customers
ADD COLUMN value_rating VARCHAR(20) GENERATED ALWAYS AS (
	CASE
        WHEN Monetary > 5000 THEN 'Platinum'
        WHEN Monetary BETWEEN 2000 AND 5000 THEN 'Gold'
        WHEN Monetary BETWEEN 1000 AND 1999 THEN 'Silver'
        ELSE 'Bronze'
	END
) STORED;

-- Analysis Queries
-- Customer Segmentation Overview
SELECT
	Customer_Segment,
    value_rating,
    COUNT(*) AS Customer_Count,
     ROUND(AVG(Monetary), 2) as avg_spend,
     ROUND(AVG(Monetary), 2) as total_value
FROM rfm_customers
GROUP BY Customer_Segment, value_rating
ORDER BY total_value DESC;
    

-- High Value Customer Details
SELECT 
	Customer_Name,
	Customer_Segment,
	value_rating,
    Monetary,
	RFM_Score
FROM rfm_customers
WHERE Customer_Segment IN ('Champions', 'Loyal Customers')
AND value_rating IN ('Platinum', 'Gold')
ORDER BY Monetary DESC;

-- Analyzing at-risk customers
SELECT * FROM rfm_customers
WHERE Customer_Segment = 'At-Risk'
AND value_rating IN ('Gold', 'Platinum');

