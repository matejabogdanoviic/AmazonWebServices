
--Show list od all users and their emails
--Retrieve the result with the full name of the Users
SELECT 
    u.UserId,
    CONCAT(u.FirstName, ' ', u.LastName) AS FullName,
    STRING_AGG(am.AmazonEmail, ', ') AS LinkedAmazonEmails
FROM Users u
JOIN PaymentMethods pm ON u.UserId = pm.UserId
JOIN AmazonPayAccounts am ON pm.PaymentMethodId = am.PaymentMethodId
GROUP BY u.UserId, u.FirstName, u.LastName;


-- For each product, get the highest sold price from OrderItems.
--If there is no sales , show 0
SELECT 
    p.ProductId,
    p.ProductName,
   ISNULL(ca.MaxPrice,0)
FROM Products p
CROSS APPLY (
    SELECT MAX(oi.UnitPrice) AS MaxPrice
    FROM OrderItems oi
    WHERE oi.ProductId = p.ProductId
) ca
ORDER BY ca.MaxPrice DESC;



--Select Top 5 most sold products 
SELECT TOP 5 
    p.ProductName,
    SUM(oi.Quantity) AS TotalSold
FROM OrderItems oi
JOIN Products p ON oi.ProductId = p.ProductId
GROUP BY p.ProductName
ORDER BY TotalSold DESC;


--Select all state provinces where the StreetAddress starts with '7' and the StateProvince name ends with 'Z'
SELECT StreetAddress,StateProvince 
FROM UserAddresses
WHERE StreetAddress like '7%' 
AND StateProvince like '%Z'
ORDER BY StreetAddress;



-- Find Top 3 best-selling products per category ranked by total quantity sold
WITH ProductSales AS (
    SELECT 
        p.ProductId,
        p.ProductName,
        pc.CategoryName,
        SUM(oi.Quantity) AS TotalQuantitySold,
        RANK() OVER (PARTITION BY pc.CategoryId ORDER BY SUM(oi.Quantity) DESC) AS SalesRank
    FROM Products p
    JOIN ProductCategories pc ON p.CategoryId = pc.CategoryId
    JOIN OrderItems oi ON p.ProductId = oi.ProductId
    GROUP BY p.ProductId, p.ProductName, pc.CategoryName, pc.CategoryId
)
SELECT
    ProductId,
    ProductName,
    CategoryName,
    TotalQuantitySold,
    SalesRank
FROM ProductSales
WHERE SalesRank <= 3
ORDER BY SalesRank;


-- Retrieve the first and last names of users who linked an Amazon Pay account in June 2024.
-- Display their user ID, payment method type, and the date when the Amazon Pay account was linked.
-- Show only the 3 most recent links, ordered by LinkedDateTime descending.

--Index to speed up filtering 
CREATE NONCLUSTERED INDEX idx_AmazonPayAccounts_LinkedDateTime ON AmazonPayAccounts(LinkedDateTime);
CREATE NONCLUSTERED INDEX idx_PaymentMethods_UserId ON PaymentMethods(UserId);

SELECT top 3 u.UserId AS id,u.FirstName,u.LastName,pay.PaymentMethodId,pay.PaymentType,am.LinkedDateTime
FROM PaymentMethods pay
JOIN Users u
ON pay.UserId=u.UserId
JOIN AmazonPayAccounts am
ON pay.PaymentMethodId=am.PaymentMethodId
WHERE MONTH(am.LinkedDateTime) = 6
ORDER BY LinkedDateTime DESC;


--Create User Spending Leaderboard,limited to top 10 users with completed payments
WITH cte AS (
        SELECT u.UserId,CONCAT(u.FirstName,' ',u.LastName) AS full_name,COUNT(o.OrderId) as total_orders,
SUM(p.Amount) AS total_amount FROM Orders o
JOIN Users u
ON o.UserId = u.UserId
JOIN Payments p
ON o.OrderId = p.OrderId
WHERE p.PaymentStatus = 'Completed'
GROUP BY u.UserID,u.FirstName, u.LastName
) 

SELECT TOP 10 * FROM cte
order by total_amount desc;



-- Show  total quantity of all items, total value of the order (quantity * unit price), the name of the most expensive product in that order
--Show top 15 rows and order them by total value in descending order.

SELECT TOP 15
    o.OrderId,
    SUM(oi.Quantity) AS TotalQuantity,
    ROUND(SUM(oi.Quantity * oi.UnitPrice), 2) AS TotalValue,
    (
        SELECT TOP 1 p.ProductName
        FROM OrderItems oi2
        JOIN Products p ON oi2.ProductId = p.ProductId
        WHERE oi2.OrderId = o.OrderId
        ORDER BY oi2.UnitPrice DESC
    ) AS MostExpensiveProductName
FROM Orders o
JOIN OrderItems oi ON o.OrderId = oi.OrderId
GROUP BY o.OrderId
ORDER BY TotalValue DESC;



-- Analyze delivery times per shipping zone.
-- Displays the total number of delivered packages and the average delivery duration (in days)
-- between the shipped and delivered timestamps for each shipping zone.
-- Only includes packages with both shipped and delivered dates available.
-- Results are ordered from the slowest to the fastest delivery zones.
SELECT 
    sz.ZoneName,
    Count(p.PackageId) AS TotalPackages,
    AVG(DATEDIFF(DAY, p.ShippedDateTime, p.DeliveredDateTime)) AS AvgDeliveryDays
FROM Packages p
JOIN Orders o 
ON p.OrderId = o.OrderId
JOIN ShippingZones sz 
ON o.ShippingZoneId = sz.ShippingZoneId
WHERE p.ShippedDateTime IS NOT NULL AND p.DeliveredDateTime IS NOT NULL
GROUP BY sz.ZoneName
ORDER BY AvgDeliveryDays DESC;


-- Classify products based on their unit price: if greater than 50.00 then 'High_Cost', else 'Low_Cost
-- in more then one way

SELECT ProductName, UnitPrice,
          Case When UnitPrice>50.00 THEN 'High_Cost'
		  ELSE 'Low_Cost' END AS Cost_Category
	FROM Products
	ORDER BY UnitPrice DESC;
 
 --2nd Way (shorter syntax :)
 SELECT ProductName, UnitPrice,
          IIF(UnitPrice>50,'High_Cost','Low_Cost')
	FROM Products
	ORDER BY UnitPrice DESC;




--Create a Procedure to retrieve all Transactions where DebitCard And CreditCard Failed

GO
CREATE PROCEDURE sp_PaymentCardFailed
   @PaymentStatus VARCHAR(100)
   AS
BEGIN
 SELECT OrderId,PaymentMethod,
 PaymentStatus
 FROM Payments
WHERE PaymentStatus = @PaymentStatus 
AND PaymentMethod IN ('DebitCard', 'CreditCard');
 END;
 GO

-- EXEC sp_PaymentCardFailed @PaymentStatus='Failed';


 --Write a procedure that retrieves all the users who had at least one Payments with 'Pending' PaymentStatus between StartDate and EndDate
 GO
 CREATE OR ALTER PROCEDURE sp_GetUserSpendingInPeriod
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT 
        u.UserId,
        CONCAT(u.FirstName, ' ', u.LastName) AS FullName,
        SUM(p.Amount) AS TotalSpent
    FROM Users u
    JOIN Orders o 
	ON u.UserId = o.UserId
    JOIN Payments p 
	ON o.OrderId = p.OrderId
      AND CAST(o.OrderDateTime AS DATE) BETWEEN @StartDate AND @EndDate
      AND p.PaymentStatus='Pending'
    GROUP BY u.UserId, u.FirstName, u.LastName;
END;
GO

--EXEC sp_GetUserSpendingInPeriod @StartDate = '2025-01-01', @EndDate = '2025-04-25';



--Create a View to retrieve top 100 products with stock quantity less than 10
GO
CREATE OR ALTER VIEW vw_ProductsLowStock AS
SELECT TOP 100
    ProductId,
    ProductName,
    StockQuantity
FROM Products
WHERE StockQuantity < 10
ORDER BY StockQuantity ASC;
GO

--SELECT * FROM vw_ProductsLowStock;

