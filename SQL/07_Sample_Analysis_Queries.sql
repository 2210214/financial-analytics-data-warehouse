/* ============================================================================================================
   Financial Analytics Data Warehouse
   07 - Sample Analysis Queries
   ------------------------------------------------------------------------------------------------------------
   Run these manually, on demand, against the rpt.* views. Not part of the build/ETL process.
   ============================================================================================================ */

USE Financial_DWH;
GO

-- Customer count per segment
SELECT Customer_Segment, COUNT(*) AS Number_Of_Customers
FROM rpt.vw_Customer_Segmentation
GROUP BY Customer_Segment;
GO

-- Spread of transaction and loan totals across customers
SELECT
    MIN(Total_Transaction_Amount) AS Min_Transaction,
    MAX(Total_Transaction_Amount) AS Max_Transaction,
    AVG(Total_Transaction_Amount) AS Avg_Transaction,
    MIN(Total_Loan_Amount) AS Min_Loan,
    MAX(Total_Loan_Amount) AS Max_Loan,
    AVG(Total_Loan_Amount) AS Avg_Loan
FROM rpt.vw_Customer_Analysis;
GO

-- Top 10 customers by total loan amount
SELECT TOP 10 Customer_Name, Total_Transaction_Amount, Total_Loan_Amount
FROM rpt.vw_Customer_Analysis
ORDER BY Total_Loan_Amount DESC;
GO

-- Executive KPI snapshot
SELECT * FROM rpt.vw_Executive_KPIs;
GO

-- Latest ETL run status
SELECT TOP 20 * FROM etl.Load_Log ORDER BY Log_ID DESC;
GO
