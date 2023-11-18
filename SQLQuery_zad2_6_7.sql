-- Punkt a) - Tworzenie tabeli stg_dimemp i za³adowanie danych
SELECT EMPLOYEEKEY, FIRSTNAME, LASTNAME, TITLE
INTO AdventureWorksDW2019.dbo.stg_dimemp
FROM DimEmployee
WHERE EMPLOYEEKEY BETWEEN 270 AND 275;

-- Punkt b) - Sprawdzenie istnienia tabeli i jej usuniêcie
IF OBJECT_ID('AdventureWorksDW2019.dbo.stg_dimemp', 'U') IS NOT NULL
    DROP TABLE AdventureWorksDW2019.dbo.stg_dimemp;

-- Ponowne utworzenie tabeli i za³adowanie danych
SELECT EMPLOYEEKEY, FIRSTNAME, LASTNAME, TITLE
INTO AdventureWorksDW2019.dbo.stg_dimemp
FROM DimEmployee
WHERE EMPLOYEEKEY BETWEEN 270 AND 275;

-- Punkt c) Utworzenie tabeli scd_dimemp
IF OBJECT_ID('AdventureWorksDW2019.dbo.scd_dimemp', 'U') IS NULL
BEGIN
    CREATE TABLE AdventureWorksDW2019.dbo.scd_dimemp
    (
        EMPLOYEEKEY INT,
        FIRSTNAME NVARCHAR(50),
        LASTNAME NVARCHAR(50),
        TITLE NVARCHAR(50),
        STARTDATE DATETIME,
        ENDDATE DATETIME
    );
END;

-- z uwagi na problem z PrimaryKey proszê dodatkowo uruchomiæ nst. kwerendê:
DROP TABLE AdventureWorksDW2019.dbo.scd_dimemp;
CREATE TABLE AdventureWorksDW2019.dbo.scd_dimemp (
EmployeeKey int ,
FirstName nvarchar(50) not null,
LastName nvarchar(50) not null,
Title nvarchar(50),
StartDate datetime,
EndDate datetime,
PRIMARY KEY(EmployeeKey)
);

-- wpisanie danych do tabeli:
INSERT INTO AdventureWorksDW2019.dbo.scd_dimemp (EMPLOYEEKEY, FIRSTNAME, LASTNAME, TITLE, STARTDATE, ENDDATE)
SELECT EMPLOYEEKEY, FIRSTNAME, LASTNAME, TITLE, STARTDATE, ENDDATE
FROM DimEmployee
WHERE EMPLOYEEKEY BETWEEN 270 AND 275;

--5b.
update STG_DimEmp
set LastName = 'Nowak'
where EmployeeKey = 270;

update STG_DimEmp
set TITLE = 'Senior Design Engineer'
where EmployeeKey = 274;

--5c.
update STG_DimEmp
set FIRSTNAME = 'Ryszard'
where EmployeeKey = 275

SELECT * FROM AdventureWorksDW2019.dbo.scd_dimemp;

SELECT * FROM AdventureWorksDW2019.dbo.stg_dimemp;


--6.SCD - Typ 1 (nadpisanie danych bez tworzenia nowego rekordu).

--7.Opcja "Fail the transformation if changes are detected in a fixed attribute" 
-- mo¿e spowodowaæ zakoñczenie procesu SSIS z b³êdem w przypadku,
-- gdy wykryte zostan¹ zmiany w atrybucie FIRSTNAME.