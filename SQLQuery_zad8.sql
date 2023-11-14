/*8. Napisz kwerendê SQL, która zwróci tê sam¹ analizê co zrobiony wczeœniej pakiet SSIS.
a) poka¿ jedynie dni (wraz z liczb¹ zamówieñ) w których by³o mniej ni¿ 100 zamówieñ,*/

USE AdventureWorksDW2019
GO
SELECT COUNT(OrderDate) AS COUNT_ORDER, OrderDate FROM dbo.FactInternetSales GROUP BY OrderDate HAVING COUNT(OrderDate) < 100;

/* b) dla ka¿dego dnia wyœwietl 3 produkty, których cena jednostkowa (UnitPrice) by³a najwiêksza. */

WITH Products_TAB AS (SELECT ProductKey, OrderDate, UnitPrice, ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC) AS RowNum FROM dbo.FactInternetSales)
SELECT ProductKey, OrderDate, UnitPrice FROM Products_TAB WHERE RowNum <= 3;
