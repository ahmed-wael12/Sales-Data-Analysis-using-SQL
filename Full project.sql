/*
==========================================================
Project Title: Sales Data Analysis using SQL
Author: Ahmed Wael

Description:
This project performs a comprehensive analysis of sales data
to generate actionable business insights. It focuses on 
understanding sales performance, customer behavior, and 
product trends.

Data Model:
- fact_sales       ? transactional sales data
- dim_customers    ? customer information
- dim_products     ? product details

Skills Demonstrated:
- Exploratory Data Analysis (EDA)
- SQL Aggregations & KPIs
- Joins (Fact & Dimension Tables)
- Window Functions
- Common Table Expressions (CTEs)
- Ranking & Segmentation

==========================================================
*/

-- =========================================
-- 1. DATABASE EXPLORATION
-- Understanding database structure (tables & columns)
-- =========================================

-- List all tables in the database
Select * From INFORMATION_SCHEMA.TABLES;

-- Inspect columns for all tables
Select * From INFORMATION_SCHEMA.COLUMNS;


-- =========================================
-- 2. DIMENSIONS EXPLORATION
-- Exploring key attributes in dimension tables
-- =========================================


-- Identify customer distribution by country
Select Distinct(Country) From dim_customers;

-- Explore product hierarchy and structure
Select Distinct(Category) , Subcategory , product_name
From dim_products;


-- =========================================
-- 3. DATE ANALYSIS
-- Understanding time range of sales and customer ages
-- =========================================


-- Sales date range analysis
Select
Min(Order_date) as First_Order_Date,
Max(Order_date) as Last_Order_Date,
DATEDIFF(Year,Min(Order_date),Max(Order_date)) as Order_Range_Year
From Fact_sales;

-- Customer age distribution
Select 
Min(Birthdate) as Oldest_Birthdate,
DATEDIFF(Year, Min(Birthdate), GetDate()) as Oldest_Age,
Max(Birthdate) as Oldest_Birthdate,
DATEDIFF(Year, Max(Birthdate), GetDate()) as Youngest_Age
From dim_customers;


-- =========================================
-- 4. KPI CALCULATIONS
-- Computing key business performance metrics
-- =========================================


Select Sum(sales_amount) as Total_Sales From Fact_sales;

Select Sum(quantity) as Total_Quatity From Fact_sales;

Select Avg(Price) as Avg_Price From Fact_sales;

Select Count(Distinct order_number) as Total_Orders From Fact_sales;

Select Count(product_key) as Total_Prodacts From dim_products;

Select Count(customer_key) as Total_Customers From dim_customers;

Select Count(Distinct customer_key) as Total_Customers From Fact_sales;


-- =========================================
-- 5. CONSOLIDATED KPI REPORT
-- Combining all KPIs into a single result set
-- =========================================


Select 'Total Sales' as Measure_Name , Sum(sales_amount) as Measure_Value From Fact_sales
Union All
Select 'Total Quantity', Sum(quantity) From Fact_sales
Union All
Select 'Average Price', Avg(Price) From Fact_sales
Union All
Select 'Total Nr. Orders', Count(Distinct order_number) From Fact_sales
Union All
Select 'Total Nr. Products', Count(product_key) From dim_products
Union All
Select 'Total Nr. Customers', Count(customer_key) From dim_customers


-- =========================================
-- 6. DATA DISTRIBUTION ANALYSIS
-- Understanding distribution across dimensions
-- =========================================


-- Customers by country
Select 
Country,
Count(customer_key) as Total_Customers
From dim_customers
Group by Country
Order by Total_Customers Desc;

-- Customers by gender
Select 
Gender,
Count(customer_key) as Total_Customers
From dim_customers
Group by gender
Order by Total_Customers Desc;

-- Products by category
Select 
Category,
Count(product_key) as Total_Products
From dim_products
Group by Category
Order by Total_Products Desc;

-- Average cost per category
Select 
Category,
Avg(Cost) as Total_Costs
From dim_products
Group by Category
Order by Total_Costs Desc;

-- Revenue by category
Select 
p.Category,
Sum(f.sales_amount) as Total_Revenue
From fact_sales f 
Join dim_products p
on f.product_key = p.product_key
Group by p.Category
Order by Total_Revenue Desc;

-- Top customers by revenue 
Select 
c.customer_key,
c.first_name,
c.last_name,
Sum(f.sales_amount) as Total_Revenue
From fact_sales f 
Join dim_customers c
on f.customer_key = c.customer_key
Group by c.customer_key,c.first_name,c.last_name
Order by Total_Revenue Desc;

-- Total sold items by country
Select 
c.country,
Sum(f.quantity) as Total_Sold_Items
From fact_sales f 
Join dim_customers c
on f.customer_key = c.customer_key
Group by c.country
Order by Total_Sold_Items Desc;


-- =========================================
-- 7. RANKING ANALYSIS
-- Identifying top and bottom performers
-- =========================================


-- Top 5 subcategories by revenue
Select Top 5
p.subcategory,
Sum(f.sales_amount) as Total_Revenue
From fact_sales f 
Join dim_products p
on f.product_key = p.product_key
Group by p.subcategory
Order by Total_Revenue Desc;

-- Bottom 5 products by revenue
Select Top 5
p.product_name,
Sum(f.sales_amount) as Total_Revenue
From fact_sales f 
Join dim_products p
on f.product_key = p.product_key
Group by p.product_name
Order by Total_Revenue Asc;

-- Top 10 customers by revenue
Select Top 10
c.customer_key,
c.first_name,
c.last_name,
Sum(f.sales_amount) as Total_Revenue
From fact_sales f 
Join dim_customers c
on f.customer_key = c.customer_key
Group by c.customer_key,c.first_name,c.last_name
Order by Total_Revenue Desc;

-- Customers with lowest number of orders
Select Top 10
c.customer_key,
c.first_name,
c.last_name,
Count(Distinct Order_number) as Total_Order
From fact_sales f 
Join dim_customers c
on f.customer_key = c.customer_key
Group by c.customer_key,c.first_name,c.last_name
Order by Total_Order Asc;


-- =========================================
-- 8. TIME SERIES ANALYSIS
-- Tracking performance over time
-- =========================================


Select 
Year(order_date) as Year,
Month(order_date) as Month,
Sum(sales_amount) as Total_Sales,
Sum(Distinct customer_key) as Total_Customer
From fact_sales
Where Order_date Is Not Null
Group by Year(order_date),Month(order_date)
Order by Year(order_date),Month(order_date);


-- =========================================
-- 9. RUNNING TOTAL & MOVING AVERAGE
-- Using window functions for trend analysis
-- =========================================


Select
order_date,
Total_Sales,
Sum(Total_Sales) Over (Order by Order_date) as Runing_Total_Sales,
AVG_Price,
Avg(AVG_Price) Over (Order by Order_date) as Moving_AVG_Price
From (
Select 
DateTrunc(Year,order_date) as order_date,
Sum(sales_amount) as Total_Sales,
Avg(Price) as AVG_Price
From fact_sales
Where Order_date Is Not Null
Group by DateTrunc(Year,order_date)
)t;


-- =========================================
-- 10. YEAR-OVER-YEAR (YoY) ANALYSIS
-- Measuring product growth trends
-- =========================================


With Yearly_Product_Sales as(
Select 
Year(F.order_date) as Order_Year,
P.product_name as Product_Name,
Sum(F.sales_amount) as Current_Sales
From fact_sales F Join dim_products p
on F.product_key=P.product_key
Where F.order_date Is Not Null
Group by 
Year(F.order_date),P.product_name
)
Select 
Order_Year,
Product_Name,
Current_Sales,
Lag(Current_Sales) Over(Partition by Product_Name Order by Order_Year) as YoY_Analysis,
Current_Sales - Lag(Current_Sales) Over(Partition by Product_Name Order by Order_Year) as Diff_YoY,
Case 
	When Current_Sales - Lag(Current_Sales) Over(Partition by Product_Name Order by Order_Year) > 0
		Then 'Increas'
	When Current_Sales - Lag(Current_Sales) Over(Partition by Product_Name Order by Order_Year) < 0
		Then 'Decrease'
	Else 'No Change'
End as AVG_Change,
Avg(Current_Sales) Over(Partition by Product_Name) as AVG_Sales,
Current_Sales - Avg(Current_Sales) Over(Partition by Product_Name) as Diff_Avg,
Case 
	When Current_Sales - Avg(Current_Sales) Over(Partition by Product_Name) > 0 Then 'Above Averge'
	When Current_Sales - Avg(Current_Sales) Over(Partition by Product_Name) < 0 Then 'Below Averge'
	Else 'Averge'
End as AVG_Change
From Yearly_Product_Sales
Order by Product_Name , Order_Year;


-- =========================================
-- 11. CATEGORY CONTRIBUTION
-- Percentage of total revenue per category
-- =========================================


With Category_Sales as(
Select 
category ,
Sum(sales_amount) as Total_Sales
From fact_sales f Join dim_products p 
On f.product_key = p.product_key
Group by category
)
Select 
category,
Total_Sales,
Concat(Round((Cast(Total_Sales as Float) / Sum(Total_Sales) Over () )* 100 , 2) , '%') as Percentage_of_Total
From Category_Sales
Order by Total_Sales Desc


-- =========================================
-- 12. PRODUCT SEGMENTATION
-- Categorizing products based on cost ranges
-- =========================================


With Product_Segmant as(
Select 
product_key ,
product_name , 
cost ,
Case 
	When Cost < 500 Then 'Less Than 500'
	When Cost Between 500 and 1000 Then '500-1000'
	When cost Between 1000 and 1500 Then '1000-1500'
	Else 'Above 1500'
End as Cost_Range
From dim_products
)
Select 
Cost_Range,
Count(product_key) as Total_Product
From Product_Segmant
Group by Cost_Range
Order by Total_Product Desc;


-- =========================================
-- 13. CUSTOMER SEGMENTATION
-- Classifying customers based on value & lifecycle
-- =========================================


With Customer_Spending as (
Select 
c.customer_key,
Sum(f.sales_amount) as Total_Sales,
Min(Order_Date) as First_Order,
Max(order_date) as last_Order,
DATEDIFF(Month , Min(Order_Date) , Max(order_date) ) as Life_Span
From fact_sales f Join dim_customers c
on f.customer_key=c.customer_key
Group by c.customer_key
)
Select 
customer_key,
Total_Sales,
Life_Span,
Case 
	When Life_Span >=12 And Total_Sales >5000 Then 'VIP'
	When Life_Span >=12 And Total_Sales <=5000 Then 'Regular'
	Else 'New'
End as Customer_Segmant
From Customer_Spending;

-- Customer count per segment

With Customer_Spending as (
Select 
c.customer_key,
Sum(f.sales_amount) as Total_Sales,
Min(Order_Date) as First_Order,
Max(order_date) as last_Order,
DATEDIFF(Month , Min(Order_Date) , Max(order_date) ) as Life_Span
From fact_sales f Join dim_customers c
on f.customer_key=c.customer_key
Group by c.customer_key
)
Select 
Customer_Segmant,
Count(customer_key) as Total_Customers
From (
Select 
customer_key,
Case 
	When Life_Span >=12 And Total_Sales >5000 Then 'VIP'
	When Life_Span >=12 And Total_Sales <=5000 Then 'Regular'
	Else 'New'
End as Customer_Segmant
From Customer_Spending
) t
Group by Customer_Segmant
Order by Total_Customers Desc