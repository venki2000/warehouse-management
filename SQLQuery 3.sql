--SELECT *
--  FROM [project].[dbo].[WH_Data]

-- The first row's product type data is wrong, I made added S to its beginning intentionally to feed the data into sql wizard to treat the entire column as nvarchar data type, Because before it was trating the entire column as 
-- float data type and writter null in the cell which has both numbers and letters in it.

    -- I changed the cell value back to its original after I fed the data, using the below code.
  update WH_Data
  set Part_Number = 698147
  where Order_Number =6207689 and Qty_Shipped = 2 and Product_Type='Shirts'


  -- Just checking if the DATA Got updated
  select *
  from WH_Data
  where Order_Number =6207689 and Qty_Shipped = 2 and Product_Type='Shirts'

 --1.)ndicate how many SKUs are needed to account for 80% of the picking activity.
 -- first let's find out how many orders are there 
  select count(Order_number)
 from wh_data 
  -- So there are 23152 orders, Now create the table as they asked for


WITH CTE_OrderCounts AS (
    SELECT 
        Part_number,
        COUNT(Order_number) AS No_of_Orders,
        CAST(COUNT(Order_number) AS DECIMAL(18, 5)) / 23152 AS Percentage_of_total_Orders
    FROM 
        WH_Data
    GROUP BY 
        Part_Number
)
SELECT 
    Part_number,
    No_of_Orders,
    FORMAT(Percentage_of_total_Orders, 'P5') AS Percentage_of_total_Orders,
    FORMAT(SUM(Percentage_of_total_Orders) OVER (ORDER BY Percentage_of_total_Orders DESC), 'P5') AS Cumulative_Percentage
FROM 
    CTE_OrderCounts
ORDER BY 
    No_of_Orders DESC;

	
	-- By finding the cumulative percentage, we can conclude how many sku's accounts for 80% orders
-- Total number of sku's 5384, Number of sku's accounts for 80% of orders = 1375, By dividing 1375/5384 we will get value 
   
  SELECT FORMAT(CAST((1375 * 1.0 / 5385) AS DECIMAL(18, 5)) * 100, '0.000') + '%' AS Percentage_of_sku_ordered;


  -- So 25.534 % sku's accounts for 80% of orders

  -- Indicate how many SKUs are needed to account for 80% of the demand (Quantity
--shipped).
--i. What percentage of all SKUs ordered is this?

-- let's find out total quantity shipped for all items

select sum(Qty_Shipped) as Grand_Total
from wh_data
-- So the grand total is 75542

WITH CTE_Demand_Profile as(
select Part_Number,cast(sum(Qty_shipped)/75542.0 as decimal(18,5)) as total_QTY_Shipped
from WH_data
group by Part_number

)

select Part_Number,total_QTY_Shipped, format(cast(SUM(Total_qty_Shipped) OVER (ORDER BY total_qty_shipped DESC) as decimal(18,5))* 100,'0.000')+'%' AS Cumulative_Percentage
from CTE_Demand_Profile
order by total_QTY_Shipped desc

-- From this table we've found that 672 sku's accoundts for 80% of demand 
-- so 
SELECT FORMAT(CAST((672 * 1.0 / 5385) AS DECIMAL(18, 5)) * 100, '0.000') + '%' AS Percentage_of_sku_accounts_for_eightyPercent_Demand

-- 12.47 % of sku's account's for 80% of orders shipped from the warehouse

-- Lines per order profile

-- now lets find out the lines per order profile, we can do that by grouping orders and counts of orders

select Order_Number,count(order_number) as No_of_lines
from WH_Data
group by Order_Number
order by count(Order_number) desc

--b.Change the profile from part a to display only the orders with 25 lines or less.

select Order_Number,count(order_number) as No_of_lines
from WH_Data
group by Order_Number
having count(Order_number)<=25
order by count(Order_number) desc

--percentage of orders contains only one line, total no of orders 12302
select Order_Number,count(order_number) as No_of_lines
from WH_Data
group by Order_Number
having count(Order_number)<=1

-- AS we can see there are 7096 orders with only one line, but we can make it to look more clear by wriitign different set of codes

with CTE_oneline as(
select Order_Number,count(order_number) as No_of_lines
from WH_Data
group by Order_Number
having count(Order_number)<=1
)
select no_of_lines,count(Order_number) as Total_no_of_orders
from CTE_oneline
group by No_of_lines

--how might we handle these orders differently than orders with multiple lines? 

-- I will directly contact with customers to deliver those promptly to avoid storing it.

--What percentage of orders contains only one item,here we can find out the no of orders that has only one item shippedselect Order_Number,count(order_number) as No_of_lines
WITH cte_line AS (
    SELECT 
        Order_Number,
        COUNT(order_number) AS No_of_lines,
        SUM(Qty_Shipped) AS Quantity_shipped
    FROM 
        WH_Data
    GROUP BY 
        Order_Number
    HAVING 
        COUNT(Order_number) <= 1 AND 
        SUM(Qty_Shipped) <= 1
)

SELECT 
    FORMAT(CAST(COUNT(order_number) AS DECIMAL(18, 5)) * 100.0 / NULLIF((SELECT COUNT(distinct(order_number)) FROM WH_Data), 0), '0.000') + '%' AS Percentage_of_sku_accounts_for_one_item_shipped
FROM 
    cte_line;


-- order quantity profile
with CTE_ORder_Qty_profile
as
(
SELECT 
    Order_number,
    CASE 
        WHEN Shipped_Per_Carton_Fraction >= 1 AND Shipped_Per_Carton_Fraction % 1 = 0 THEN 'Full Cases'
        WHEN Shipped_Per_Carton_Fraction < 1 THEN 'Eaches'
        ELSE 'Mixed Cases'
    END AS Shipped_Case_Type
FROM 
    (
        SELECT 
            Order_number,
            CAST((qty_shipped * 1.0 / Pieces_per_carton) AS DECIMAL(10, 2)) AS Shipped_Per_Carton_Fraction
        FROM 
            WH_Data
    ) AS subquery

)

select shipped_Case_type,count(shipped_Case_type) as Frequency
from CTE_ORder_Qty_profile
group by shipped_case_type


--- Item family profile 

select product_type, count(Order_Number)
from wh_data
group by Product_Type

-- By executing the above we will only be able to find total number of order than invovled in specific product type, as a result that includes the overlapping too. so we've find the no of order than involved in one of items

SELECT 
    Product_Type,
    COUNT(Order_Number) AS Order_Count
FROM 
    WH_Data
WHERE 
    Order_Number NOT IN (
        SELECT 
            Order_Number
        FROM 
            WH_Data
        GROUP BY 
            Order_Number
        HAVING 
            COUNT(DISTINCT Product_Type) > 1
    )
GROUP BY 
    Product_Type;

	--- a.Unit Load Profile for SKU 495770.
select *
from WH_Data
where Part_Number='495770'

-- As you can see all the cartoon size is 30 and product type is shirt

-- Create temporary table
CREATE TABLE #temp_Unit_load (
    -- Define columns based on the structure of WH_Data table
    -- Adjust column names and data types as needed
    Order_Number INT,
    Part_Number nvarchar(50),
    Product_Type VARCHAR(50),
    Qty_Shipped INT,
    Pieces_per_carton INT,
    -- Add more columns as needed
);

-- Insert data into temporary table
INSERT INTO #temp_Unit_load (Order_Number, Part_Number, Product_Type, Qty_Shipped, Pieces_per_carton)
SELECT Order_Number, Part_Number, Product_Type, Qty_Shipped, Pieces_per_carton
FROM WH_Data
WHERE Part_Number = '495770'

with CTE_Cartoonsize as
(
SELECT Qty_Shipped,count(order_number) as no_of_times
from  #temp_Unit_load 
   group by Qty_Shipped
)
select no_of_times,Qty_Shipped,(cast((qty_Shipped*1.0/30) as decimal(10,2))) as Case_type
from CTE_Cartoonsize


-- since most of the quantities shipped on a batch size of 10, its better to have sku size of 30 instead of 30 in here.