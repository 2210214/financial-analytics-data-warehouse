/* ============================================================================================================
   Financial Analytics Data Warehouse
   06 - Run ETL & Post-Load Validation
   ------------------------------------------------------------------------------------------------------------
   Run this after 00-05 have been executed at least once. Safe to run every time — the ETL procedures
   themselves are idempotent (no duplicate rows on re-run).
   ============================================================================================================ */

USE Financial_DWH;
GO

EXEC etl.usp_Run_Full_ETL;
GO

-- Row counts across every table
SELECT 'Dim_Customer' AS Table_Name, COUNT(*) AS Row_Count FROM dw.Dim_Customer
UNION ALL SELECT 'Dim_Account', COUNT(*) FROM dw.Dim_Account
UNION ALL SELECT 'Dim_Card', COUNT(*) FROM dw.Dim_Card
UNION ALL SELECT 'Dim_Merchant', COUNT(*) FROM dw.Dim_Merchant
UNION ALL SELECT 'Dim_Branch', COUNT(*) FROM dw.Dim_Branch
UNION ALL SELECT 'Dim_Date', COUNT(*) FROM dw.Dim_Date
UNION ALL SELECT 'Fact_Transactions', COUNT(*) FROM dw.Fact_Transactions
UNION ALL SELECT 'Fact_Loans', COUNT(*) FROM dw.Fact_Loans;
GO

-- Rows that landed on the "-1 Unknown" member point at a data quality gap in the source system,
-- not a warehouse bug — investigate the source if any of these are non-zero.
SELECT 'Fact_Transactions -> Unknown Customer' AS Check_Name, COUNT(*) AS Row_Count FROM dw.Fact_Transactions WHERE Customer_Key = -1
UNION ALL SELECT 'Fact_Transactions -> Unknown Account',  COUNT(*) FROM dw.Fact_Transactions WHERE Account_Key = -1
UNION ALL SELECT 'Fact_Transactions -> Unknown Merchant', COUNT(*) FROM dw.Fact_Transactions WHERE Merchant_Key = -1
UNION ALL SELECT 'Fact_Transactions -> Unknown Date',     COUNT(*) FROM dw.Fact_Transactions WHERE Date_Key = -1
UNION ALL SELECT 'Fact_Loans -> Unknown Customer',        COUNT(*) FROM dw.Fact_Loans WHERE Customer_Key = -1
UNION ALL SELECT 'Fact_Loans -> Unknown Date',            COUNT(*) FROM dw.Fact_Loans WHERE Date_Key = -1;
GO










