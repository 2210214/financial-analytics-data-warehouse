/* ============================================================================================================
   Financial Analytics Data Warehouse
   03 - Fact Tables
   ------------------------------------------------------------------------------------------------------------
   Loaded by etl.usp_Load_Facts (see 04_ETL_Stored_Procedures.sql) using LEFT JOIN + ISNULL(...,-1) against
   the dimensions, so an unmatched lookup points at the "Unknown" member instead of dropping the row.

   Idempotent: safe to re-run on an existing database.
   ============================================================================================================ */

USE Financial_DWH;
GO

-- ------------------------------------------------------------------------------------------------------------
-- Fact_Transactions   (grain: one row per transaction)
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Fact_Transactions', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Fact_Transactions
    (
        Transaction_Key     INT IDENTITY(1,1) PRIMARY KEY,
        Transaction_ID      VARCHAR(25) NOT NULL,
        Date_Key            INT NOT NULL,
        Customer_Key        INT NOT NULL,
        Account_Key         INT NOT NULL,
        Merchant_Key        INT NOT NULL,
        Amount_USD          DECIMAL(12,2),

        CONSTRAINT FK_FactTransaction_Date     FOREIGN KEY (Date_Key)     REFERENCES dw.Dim_Date(Date_Key),
        CONSTRAINT FK_FactTransaction_Customer FOREIGN KEY (Customer_Key) REFERENCES dw.Dim_Customer(Customer_Key),
        CONSTRAINT FK_FactTransaction_Account  FOREIGN KEY (Account_Key)  REFERENCES dw.Dim_Account(Account_Key),
        CONSTRAINT FK_FactTransaction_Merchant FOREIGN KEY (Merchant_Key) REFERENCES dw.Dim_Merchant(Merchant_Key)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_FactTransactions_TransactionID' AND object_id = OBJECT_ID(N'dw.Fact_Transactions'))
    CREATE UNIQUE INDEX UX_FactTransactions_TransactionID ON dw.Fact_Transactions(Transaction_ID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactTransactions_DateKey' AND object_id = OBJECT_ID(N'dw.Fact_Transactions'))
    CREATE INDEX IX_FactTransactions_DateKey ON dw.Fact_Transactions(Date_Key);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactTransactions_CustomerKey' AND object_id = OBJECT_ID(N'dw.Fact_Transactions'))
    CREATE INDEX IX_FactTransactions_CustomerKey ON dw.Fact_Transactions(Customer_Key);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactTransactions_AccountKey' AND object_id = OBJECT_ID(N'dw.Fact_Transactions'))
    CREATE INDEX IX_FactTransactions_AccountKey ON dw.Fact_Transactions(Account_Key);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactTransactions_MerchantKey' AND object_id = OBJECT_ID(N'dw.Fact_Transactions'))
    CREATE INDEX IX_FactTransactions_MerchantKey ON dw.Fact_Transactions(Merchant_Key);
GO

-- ------------------------------------------------------------------------------------------------------------
-- Fact_Loans   (grain: one row per loan)
-- ------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dw.Fact_Loans', N'U') IS NULL
BEGIN
    CREATE TABLE dw.Fact_Loans
    (
        Loan_Key        INT IDENTITY(1,1) PRIMARY KEY,
        Loan_ID         VARCHAR(20) NOT NULL,
        Date_Key        INT NOT NULL,
        Customer_Key    INT NOT NULL,
        Loan_Amount     DECIMAL(12,2),
        Interest_Rate   DECIMAL(5,2),

        CONSTRAINT FK_FactLoan_Date     FOREIGN KEY (Date_Key)     REFERENCES dw.Dim_Date(Date_Key),
        CONSTRAINT FK_FactLoan_Customer FOREIGN KEY (Customer_Key) REFERENCES dw.Dim_Customer(Customer_Key)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_FactLoans_LoanID' AND object_id = OBJECT_ID(N'dw.Fact_Loans'))
    CREATE UNIQUE INDEX UX_FactLoans_LoanID ON dw.Fact_Loans(Loan_ID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactLoans_DateKey' AND object_id = OBJECT_ID(N'dw.Fact_Loans'))
    CREATE INDEX IX_FactLoans_DateKey ON dw.Fact_Loans(Date_Key);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FactLoans_CustomerKey' AND object_id = OBJECT_ID(N'dw.Fact_Loans'))
    CREATE INDEX IX_FactLoans_CustomerKey ON dw.Fact_Loans(Customer_Key);
GO
