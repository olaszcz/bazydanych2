/*8. Napisz kwerend� SQL, kt�ra zwr�ci t� sam� analiz� co zrobiony wcze�niej pakiet SSIS.
a) poka� jedynie dni (wraz z liczb� zam�wie�) w kt�rych by�o mniej ni� 100 zam�wie�,*/

USE AdventureWorksDW2019
GO
SELECT COUNT(OrderDate) AS COUNT_ORDER, OrderDate FROM dbo.FactInternetSales GROUP BY OrderDate HAVING COUNT(OrderDate) < 100;

/* b) dla ka�dego dnia wy�wietl 3 produkty, kt�rych cena jednostkowa (UnitPrice) by�a najwi�ksza. */

WITH Products_TAB AS (SELECT ProductKey, OrderDate, UnitPrice, ROW_NUMBER() OVER (PARTITION BY OrderDate ORDER BY UnitPrice DESC) AS RowNum FROM dbo.FactInternetSales)
SELECT ProductKey, OrderDate, UnitPrice FROM Products_TAB WHERE RowNum <= 3;
