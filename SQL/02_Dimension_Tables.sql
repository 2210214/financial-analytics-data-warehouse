/* ============================================================================================================
   Financial Analytics Data Warehouse
   02 - Dimension Tables
   ------------------------------------------------------------------------------------------------------------
   Every dimension carries:
     - a surrogate key (identity PK) decoupled from the source's business key
     - a UNIQUE index on the business key to prevent duplicate loads
     - a "-1 / Unknown" member so Fact tables never have to drop a row for a missing lookup

   Idempotent: safe to re-run on an existing database.
   ============================================================================================================ */

USE Financial_DWH;
GO

-- ------------------------------------------------------------------------------------------------------------
-- Dim_Customer
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Dim_Customer', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Dim_Customer
    (
        Customer_Key    INT IDENTITY(1,1) PRIMARY KEY,
        Customer_ID     VARCHAR(20) NOT NULL,
        First_Name      VARCHAR(50),
        Last_Name       VARCHAR(50),
        Email           VARCHAR(100),
        City            VARCHAR(50),
        Credit_Score    INT,
        Created_At      DATETIME
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Customer_CustomerID' AND object_id = OBJECT_ID(N'dw.Dim_Customer'))
    CREATE UNIQUE INDEX UX_Dim_Customer_CustomerID ON dw.Dim_Customer(Customer_ID);
GO

-- ------------------------------------------------------------------------------------------------------------
-- Dim_Account
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Dim_Account', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Dim_Account
    (
        Account_Key     INT IDENTITY(1,1) PRIMARY KEY,
        Account_ID      VARCHAR(20) NOT NULL,
        Customer_ID     VARCHAR(20),
        Account_Type    VARCHAR(20),
        Balance_USD     DECIMAL(12,2),
        Open_Date       DATETIME
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Account_AccountID' AND object_id = OBJECT_ID(N'dw.Dim_Account'))
    CREATE UNIQUE INDEX UX_Dim_Account_AccountID ON dw.Dim_Account(Account_ID);
GO

-- ------------------------------------------------------------------------------------------------------------
-- Dim_Card
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Dim_Card', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Dim_Card
    (
        Card_Key            INT IDENTITY(1,1) PRIMARY KEY,
        Card_ID             VARCHAR(20) NOT NULL,
        Account_ID          VARCHAR(20),
        Card_Type           VARCHAR(20),
        Expiration_Date     DATETIME
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Card_CardID' AND object_id = OBJECT_ID(N'dw.Dim_Card'))
    CREATE UNIQUE INDEX UX_Dim_Card_CardID ON dw.Dim_Card(Card_ID);
GO

-- ------------------------------------------------------------------------------------------------------------
-- Dim_Merchant
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Dim_Merchant', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Dim_Merchant
    (
        Merchant_Key    INT IDENTITY(1,1) PRIMARY KEY,
        Merchant_ID     VARCHAR(20) NOT NULL,
        Merchant_Name   VARCHAR(100),
        City            VARCHAR(50)
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Merchant_MerchantID' AND object_id = OBJECT_ID(N'dw.Dim_Merchant'))
    CREATE UNIQUE INDEX UX_Dim_Merchant_MerchantID ON dw.Dim_Merchant(Merchant_ID);
GO

-- ------------------------------------------------------------------------------------------------------------
-- Dim_Branch
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Dim_Branch', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Dim_Branch
    (
        Branch_Key      INT IDENTITY(1,1) PRIMARY KEY,
        Branch_ID       VARCHAR(20) NOT NULL,
        Branch_Name     VARCHAR(100),
        Manager_Name    VARCHAR(100),
        City            VARCHAR(50),
        Country         VARCHAR(50)
    );
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Branch_BranchID' AND object_id = OBJECT_ID(N'dw.Dim_Branch'))
    CREATE UNIQUE INDEX UX_Dim_Branch_BranchID ON dw.Dim_Branch(Branch_ID);
GO

-- ------------------------------------------------------------------------------------------------------------
-- Dim_Date
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Dim_Date', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Dim_Date
    (
        Date_Key        INT PRIMARY KEY,
        Full_Date       DATE,
        Year            INT,
        Month           INT,
        Month_Name      VARCHAR(20),
        Quarter         INT,
        Day             INT
    );
END
GO

-- ------------------------------------------------------------------------------------------------------------
-- Seed the "Unknown" (-1) member for every dimension.
-- Guarded so re-running this script doesn't hit the UNIQUE index and error out.
-- ------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dw.Dim_Customer WHERE Customer_Key = -1)
BEGIN
    SET IDENTITY_INSERT dw.Dim_Customer ON;
    INSERT INTO dw.Dim_Customer (Customer_Key, Customer_ID, First_Name, Last_Name, Email, City, Credit_Score, Created_At)
    VALUES (-1, 'UNKNOWN', 'Unknown', 'Unknown', NULL, 'Unknown', NULL, NULL);
    SET IDENTITY_INSERT dw.Dim_Customer OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dw.Dim_Account WHERE Account_Key = -1)
BEGIN
    SET IDENTITY_INSERT dw.Dim_Account ON;
    INSERT INTO dw.Dim_Account (Account_Key, Account_ID, Customer_ID, Account_Type, Balance_USD, Open_Date)
    VALUES (-1, 'UNKNOWN', 'UNKNOWN', 'Unknown', NULL, NULL);
    SET IDENTITY_INSERT dw.Dim_Account OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dw.Dim_Merchant WHERE Merchant_Key = -1)
BEGIN
    SET IDENTITY_INSERT dw.Dim_Merchant ON;
    INSERT INTO dw.Dim_Merchant (Merchant_Key, Merchant_ID, Merchant_Name, City)
    VALUES (-1, 'UNKNOWN', 'Unknown', 'Unknown');
    SET IDENTITY_INSERT dw.Dim_Merchant OFF;
END
GO

IF NOT EXISTS (SELECT 1 FROM dw.Dim_Date WHERE Date_Key = -1)
BEGIN
    INSERT INTO dw.Dim_Date (Date_Key, Full_Date, Year, Month, Month_Name, Quarter, Day)
    VALUES (-1, NULL, NULL, NULL, 'Unknown', NULL, NULL);
END
GO

-- ------------------------------------------------------------------------------------------------------------
-- Static calendar, 2020-2026. Guarded per-day so re-running only fills in dates that don't exist yet
-- (e.g. after moving @End_Date further out).
-- ------------------------------------------------------------------------------------------------------------
DECLARE @Start_Date DATE = '2019-01-01';
DECLARE @End_Date   DATE = '2026-12-31';

WHILE @Start_Date <= @End_Date
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dw.Dim_Date WHERE Date_Key = CONVERT(INT, FORMAT(@Start_Date,'yyyyMMdd')))
    BEGIN
        INSERT INTO dw.Dim_Date (Date_Key, Full_Date, Year, Month, Month_Name, Quarter, Day)
        VALUES
        (
            CONVERT(INT, FORMAT(@Start_Date,'yyyyMMdd')),
            @Start_Date,
            YEAR(@Start_Date),
            MONTH(@Start_Date),
            DATENAME(MONTH,@Start_Date),
            DATEPART(QUARTER,@Start_Date),
            DAY(@Start_Date)
        );
    END
    SET @Start_Date = DATEADD(DAY,1,@Start_Date);
END;
GO
