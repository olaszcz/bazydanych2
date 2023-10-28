
   -- Tworzenie  tabeli, w której przechowamy dane spe³niaj¹ce kryteria:
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


	-- Po³¹czenie tabel FactCurrencyRate i DimCurrency po kolumnie 'CurrencyKey'
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
    WHERE -- odfiltrowanie rekordów zawieraj¹cych tylko dane sprzed YearsAgo
        f.DateKey < @StartDate
        AND c.CurrencyAlternateKey IN ('GBP', 'EUR'); --wyœwietlanie rekordów dotycz¹cych walut: GBP i EUR
   
    SELECT * FROM FilteredData;
	DROP TABLE  FilteredData;


	
