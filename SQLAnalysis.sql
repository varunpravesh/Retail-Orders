SELECT * FROM ordersNew


-- Top 10 Highest Revenue Generating Products
SELECT TOP 10 sub_category AS Product,category AS Product_Category,SUM(total_sales) AS Total_Revenue FROM ordersNew
GROUP BY sub_category,category
ORDER BY SUM(total_sales) DESC



-- Top 5 Highest Selling Products in Each Region
WITH Top5Products(Region,Product,Product_Category,NumberofProductsSold,ProductRank) AS 
(
SELECT region AS Region,sub_category AS Product,category AS Product_Category,COUNT(sub_category) AS NumberofProductsSold,
RANK() OVER(PARTITION BY region ORDER BY COUNT(sub_category) DESC) AS ProductRank
FROM ordersNew
GROUP BY region,sub_category,category
)

SELECT Region,Product,Product_Category,NumberofProductsSold FROM Top5Products
WHERE ProductRank < 6


-- Month over Month growth comparison for 2022 and 2023
WITH MoMSales(Year,Month,MonthlySales,PrevMonthSales) AS
(
SELECT YEAR(order_date) AS Year,MONTH(order_date) AS Month, SUM(total_sales) AS MonthlySales,
LAG(SUM(total_sales),1) OVER (PARTITION BY YEAR(order_date) ORDER BY MONTH(order_date)) AS PrevMonthSales
FROM ordersNew
GROUP BY YEAR(order_date),MONTH(order_date)
)

SELECT Year,Month,MonthlySales,PrevMonthSales,
	   ((MonthlySales - PrevMonthSales) / PrevMonthSales) * 100 AS MoMGrowth
FROM MoMSales
		

-- Highest sale month in each Category
WITH SaleMonthCategory(Category,Month,MonthName,Year,Revenue,RankCol) AS 
(
SELECT category AS Category,MONTH(order_date) AS Month,FORMAT(order_date,'MMMM') AS MonthName,YEAR(order_date) AS Year, SUM(total_sales) AS Revenue,
RANK() OVER (PARTITION BY category,YEAR(order_date) ORDER BY SUM(total_sales) DESC) AS RankCol FROM ordersNew
GROUP BY category,MONTH(order_date),FORMAT(order_date,'MMMM'),YEAR(order_date)
)

SELECT Category,MonthName,Year,Revenue FROM SaleMonthCategory
WHERE RankCol = 1

-- Which Product has the highest growth by profit in 2023 compared to 2022
WITH ProfitbyYear(Product,Year,YearlyProfit,PrevYearProfit,YoYGrowth) AS
(
SELECT sub_category AS Product,YEAR(order_date) AS Year, SUM(total_profit) AS YearlyProfit,
	LAG(SUM(total_profit),1) OVER (PARTITION BY sub_category ORDER BY YEAR(order_date)) AS PrevYearProfit,
	((SUM(total_profit) - LAG(SUM(total_profit),1) OVER (PARTITION BY sub_category ORDER BY YEAR(order_date))) /
	LAG(SUM(total_profit),1) OVER (PARTITION BY sub_category ORDER BY YEAR(order_date))) * 100  AS YoYGrowth
FROM ordersNew
GROUP BY sub_category,YEAR(order_date)
)

SELECT TOP 1 Product,YoYGrowth FROM ProfitbyYear
WHERE YoYGrowth IS NOT NULL
ORDER BY YoYGrowth DESC
