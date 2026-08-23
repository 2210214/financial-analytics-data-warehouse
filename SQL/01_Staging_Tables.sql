/* ============================================================================================================
   Financial Analytics Data Warehouse
   01 - Staging Tables
   ------------------------------------------------------------------------------------------------------------
   Mirrors the source (bank.dbo.*) structure exactly. No business logic here — staging exists purely to
   decouple the warehouse load from the source system's availability and to give the ETL a stable landing zone.
   Loaded/truncated by etl.usp_Load_Staging (see 04_ETL_Stored_Procedures.sql).

   Idempotent: safe to re-run on an existing database.
   ============================================================================================================ */

USE Financial_DWH;
GO

IF OBJECT_ID(N'stg.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Customers
    (
        customer_id     VARCHAR(20),
        first_name      VARCHAR(50),
        last_name       VARCHAR(50),
        email           VARCHAR(100),
        city            VARCHAR(50),
        credit_score    INT,
        created_at      DATETIME
    );
END
GO

IF OBJECT_ID(N'stg.Accounts', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Accounts
    (
        account_id      VARCHAR(20),
        customer_id     VARCHAR(20),
        account_type    VARCHAR(20),
        balance_usd     DECIMAL(12,2),
        open_date       DATETIME
    );
END
GO

IF OBJECT_ID(N'stg.Cards', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Cards
    (
        card_id             VARCHAR(20),
        account_id          VARCHAR(20),
        card_type           VARCHAR(20),
        expiration_date     DATETIME
    );
END
GO

IF OBJECT_ID(N'stg.Merchants', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Merchants
    (
        merchant_id     VARCHAR(20),
        merchant_name   VARCHAR(100),
        city            VARCHAR(50)
    );
END
GO

IF OBJECT_ID(N'stg.Branches', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Branches
    (
        branch_id       VARCHAR(20),
        branch_name     VARCHAR(100),
        manager_name    VARCHAR(100),
        city            VARCHAR(50),
        country         VARCHAR(50)
    );
END
GO

IF OBJECT_ID(N'stg.Loans', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Loans
    (
        loan_id         VARCHAR(20),
        customer_id     VARCHAR(20),
        loan_amount     DECIMAL(12,2),
        interest_rate   DECIMAL(5,2),
        start_date      DATETIME
    );
END
GO

IF OBJECT_ID(N'stg.Transactions', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Transactions
    (
        transaction_id      VARCHAR(25),
        account_id          VARCHAR(20),
        merchant_id         VARCHAR(20),
        amount_usd          DECIMAL(12,2),
        transaction_date    DATETIME
    );
END
GO
