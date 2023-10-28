
   -- Tworzenie  tabeli, w kt�rej przechowamy dane spe�niaj�ce kryteria:
    CREATE TABLE FilteredData (
        CurrencyKey INT,
        DateKey INT, 
        AverageRate FLOAT,
		Date DATE,
        CurrencyAlternateKey NVARCHAR(3)
    );

	 DECLARE @StartDate INT  
	 DECLARE @YearsAgo INT

	SET @YearsAgo = 12
	SET @StartDate = CONVERT(INT, FORMAT(DATEADD(YEAR, -@YearsAgo, GETDATE()), 'yyyyMMdd'))


	-- Po��czenie tabel FactCurrencyRate i DimCurrency po kolumnie 'CurrencyKey'
	INSERT INTO FilteredData
    SELECT
        f.CurrencyKey,
        f.DateKey,
        f.AverageRate,
		f.Date,
        c.CurrencyAlternateKey
    FROM
        AdventureWorksDW2019.dbo.FactCurrencyRate f
    INNER JOIN
        AdventureWorksDW2019.dbo.DimCurrency c ON f.CurrencyKey = c.CurrencyKey
    WHERE -- odfiltrowanie rekord�w zawieraj�cych tylko dane sprzed YearsAgo
        f.DateKey < @StartDate
        AND c.CurrencyAlternateKey IN ('GBP', 'EUR'); --wy�wietlanie rekord�w dotycz�cych walut: GBP i EUR
   
    SELECT * FROM FilteredData;
	DROP TABLE  FilteredData;


	
