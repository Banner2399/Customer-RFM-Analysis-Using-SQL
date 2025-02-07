CREATE TABLE SalesData (
    Row_ID INT PRIMARY KEY,
    Order_ID VARCHAR(20),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(20),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(20),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(20),
    Product_ID VARCHAR(20),
    Sub_Category VARCHAR(50),
    Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10, 2)
);

LOAD DATA INFILE 'train.csv'
INTO TABLE SalesData
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

--  Sales Performance Analysis
--  Total Sales by Region and Category
SELECT
	Region,
    Category,
    SUM(Sales) AS Total_Sales
FROM salesdata
GROUP BY Region, Category
ORDER BY Total_Sales DESC;

-- Top 10 Customers by Sales
SELECT
	 Customer_ID,
     Customer_Name,
     SUM(Sales) AS Total_Sales
FROM salesdata
GROUP BY Customer_ID, Customer_Name
ORDER BY Total_Sales DESC
LIMIT 10;

-- Monthly Sales Trend
SELECT
	MONTHNAME(Order_Date) AS Month,
    SUM(Sales) as Monthly_Sales
FROM salesdata
GROUP BY Month 
ORDER BY Month;



-- RFM Scores
-- Calculate Recency, Frequency, Monetary Metrics
with customer_rfm AS (
	SELECT
		Customer_ID,
        Customer_Name,
        -- Recency: Days since last order
        DATEDIFF((SELECT MAX(Order_Date) FROM salesdata), MAX(Order_Date)) AS recency,
		-- Frequency: Distinct order count
        COUNT(DISTINCT Order_ID) AS frequency,
        -- Monetary: Total sales
        SUM(Sales) AS Monetary
	FROM salesdata
    GROUP BY Customer_ID, Customer_Name
),
rfm_scores AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY Recency DESC) AS R_Score,
        NTILE(4) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(4) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM customer_rfm
)
SELECT
    *,
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Score
FROM rfm_scores;
		
-- View for RFM Analysis
CREATE VIEW customer_rfm AS
WITH rfm_Base AS (
    SELECT
        Customer_ID,
        Customer_Name,
        DATEDIFF((SELECT MAX(Order_Date) FROM SalesData), MAX(Order_Date)) AS Recency,
        COUNT(DISTINCT Order_ID) AS Frequency,
        SUM(Sales) AS Monetary
    FROM SalesData
    GROUP BY Customer_ID, Customer_Name
)
SELECT
    *,
    CONCAT(
        NTILE(4) OVER (ORDER BY Recency DESC),
        NTILE(4) OVER (ORDER BY Frequency ASC),
        NTILE(4) OVER (ORDER BY Monetary ASC)
    ) AS rfm_Score
FROM rfm_Base;
