/* ============================================================================================================
   Financial Analytics Data Warehouse
   05 - Reporting Views (rpt schema — the layer BI tools connect to)
   ------------------------------------------------------------------------------------------------------------
   CREATE OR ALTER is natively idempotent for views — safe to re-run.
   ============================================================================================================ */

USE Financial_DWH;
GO

CREATE OR ALTER VIEW rpt.vw_Customer_Analysis
AS
WITH Transaction_Agg AS
(
    SELECT
        Customer_Key,
        COUNT(DISTINCT Transaction_ID) AS Total_Transactions,
        SUM(Amount_USD) AS Total_Transaction_Amount,
        AVG(Amount_USD) AS Average_Transaction_Amount
    FROM dw.Fact_Transactions
    WHERE Customer_Key <> -1
    GROUP BY Customer_Key
),
Loan_Agg AS
(
    SELECT
        Customer_Key,
        COUNT(DISTINCT Loan_ID) AS Total_Loans,
        SUM(Loan_Amount) AS Total_Loan_Amount,
        AVG(Loan_Amount) AS Average_Loan_Amount
    FROM dw.Fact_Loans
    WHERE Customer_Key <> -1
    GROUP BY Customer_Key
)
SELECT
    c.Customer_Key,
    c.Customer_ID,
    CONCAT(c.First_Name, ' ', c.Last_Name) AS Customer_Name,
    c.City,
    c.Credit_Score,

    ISNULL(t.Total_Transactions, 0) AS Total_Transactions,
    ISNULL(t.Total_Transaction_Amount, 0) AS Total_Transaction_Amount,
    ISNULL(t.Average_Transaction_Amount, 0) AS Average_Transaction_Amount,

    ISNULL(l.Total_Loans, 0) AS Total_Loans,
    ISNULL(l.Total_Loan_Amount, 0) AS Total_Loan_Amount,
    ISNULL(l.Average_Loan_Amount, 0) AS Average_Loan_Amount

FROM dw.Dim_Customer c

LEFT JOIN Transaction_Agg t
    ON c.Customer_Key = t.Customer_Key

LEFT JOIN Loan_Agg l
    ON c.Customer_Key = l.Customer_Key

WHERE c.Customer_Key <> -1;
GO


CREATE OR ALTER VIEW rpt.vw_Transaction_Analysis
AS
SELECT
    d.Year, d.Month, d.Month_Name,
    COUNT(ft.Transaction_ID)   AS Total_Transactions,
    SUM(ft.Amount_USD)         AS Total_Transaction_Amount,
    AVG(ft.Amount_USD)         AS Average_Transaction_Amount,
    MAX(ft.Amount_USD)         AS Highest_Transaction,
    MIN(ft.Amount_USD)         AS Lowest_Transaction
FROM dw.Fact_Transactions ft
INNER JOIN dw.Dim_Date d ON ft.Date_Key = d.Date_Key
WHERE d.Date_Key <> -1
GROUP BY d.Year, d.Month, d.Month_Name;
GO

CREATE OR ALTER VIEW rpt.vw_Loan_Analysis
AS
SELECT
    d.Year, d.Month, d.Month_Name,
    COUNT(fl.Loan_ID)          AS Total_Loans,
    SUM(fl.Loan_Amount)        AS Total_Loan_Amount,
    AVG(fl.Loan_Amount)        AS Average_Loan_Amount,
    AVG(fl.Interest_Rate)      AS Average_Interest_Rate,
    MAX(fl.Loan_Amount)        AS Highest_Loan,
    MIN(fl.Loan_Amount)        AS Lowest_Loan
FROM dw.Fact_Loans fl
INNER JOIN dw.Dim_Date d ON fl.Date_Key = d.Date_Key
WHERE d.Date_Key <> -1
GROUP BY d.Year, d.Month, d.Month_Name;
GO

CREATE OR ALTER VIEW rpt.vw_Customer_Loan_Analysis
AS
SELECT
    c.Customer_Key, c.Customer_ID,
    CONCAT(c.First_Name,' ',c.Last_Name) AS Customer_Name,
    c.City, c.Credit_Score,
    COUNT(fl.Loan_ID)          AS Total_Loans,
    SUM(fl.Loan_Amount)        AS Total_Loan_Amount,
    AVG(fl.Loan_Amount)        AS Average_Loan_Amount,
    MAX(fl.Loan_Amount)        AS Highest_Loan_Amount,
    AVG(fl.Interest_Rate)      AS Average_Interest_Rate
FROM dw.Dim_Customer c
INNER JOIN dw.Fact_Loans fl ON c.Customer_Key = fl.Customer_Key
WHERE c.Customer_Key <> -1
GROUP BY c.Customer_Key, c.Customer_ID, c.First_Name, c.Last_Name, c.City, c.Credit_Score;
GO

CREATE OR ALTER VIEW rpt.vw_Merchant_Analysis
AS
SELECT
    m.Merchant_Key, m.Merchant_ID, m.Merchant_Name, m.City,
    COUNT(ft.Transaction_ID)   AS Total_Transactions,
    SUM(ft.Amount_USD)         AS Total_Transaction_Amount,
    AVG(ft.Amount_USD)         AS Average_Transaction_Amount,
    MAX(ft.Amount_USD)         AS Highest_Transaction,
    MIN(ft.Amount_USD)         AS Lowest_Transaction
FROM dw.Dim_Merchant m
INNER JOIN dw.Fact_Transactions ft ON m.Merchant_Key = ft.Merchant_Key
WHERE m.Merchant_Key <> -1
GROUP BY m.Merchant_Key, m.Merchant_ID, m.Merchant_Name, m.City;
GO

CREATE OR ALTER VIEW rpt.vw_Customer_Segmentation
AS
SELECT
    Customer_Key, Customer_ID, Customer_Name, City, Credit_Score,
    Total_Transactions, Total_Transaction_Amount, Total_Loans, Total_Loan_Amount,
    CASE
        WHEN Total_Loan_Amount >= 1000000 AND Total_Transaction_Amount >= 50000 THEN 'VIP Customer'
        WHEN Total_Loan_Amount >= 500000  OR  Total_Transaction_Amount >= 50000 THEN 'High Value Customer'
        WHEN Total_Loan_Amount >= 100000  OR  Total_Transaction_Amount >= 10000 THEN 'Medium Value Customer'
        ELSE 'Low Activity Customer'
    END AS Customer_Segment
FROM rpt.vw_Customer_Analysis;
GO

CREATE OR ALTER VIEW rpt.vw_Risk_Analysis
AS
SELECT
    Customer_Key, Customer_ID, Customer_Name, City, Credit_Score,
    Total_Loans, Total_Loan_Amount, Total_Transactions, Total_Transaction_Amount,
    CASE
        WHEN Credit_Score < 500 AND Total_Loan_Amount >= 1000000 THEN 'High Risk'
        WHEN (Credit_Score BETWEEN 500 AND 700) OR (Total_Loan_Amount BETWEEN 500000 AND 999999.99) THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Level
FROM rpt.vw_Customer_Analysis;
GO

CREATE OR ALTER VIEW rpt.vw_Executive_KPIs
AS
SELECT
    (SELECT COUNT(*) FROM dw.Dim_Customer WHERE Customer_Key <> -1)                    AS Total_Customers,
    (SELECT COUNT(*) FROM dw.Fact_Transactions)                                        AS Total_Transactions,
    (SELECT SUM(Amount_USD) FROM dw.Fact_Transactions)                                 AS Total_Transaction_Amount,
    (SELECT AVG(Amount_USD) FROM dw.Fact_Transactions)                                 AS Average_Transaction_Amount,
    (SELECT COUNT(*) FROM dw.Fact_Loans)                                               AS Total_Loans,
    (SELECT SUM(Loan_Amount) FROM dw.Fact_Loans)                                       AS Total_Loan_Amount,
    (SELECT AVG(Loan_Amount) FROM dw.Fact_Loans)                                       AS Average_Loan_Amount,
    (SELECT COUNT(*) FROM rpt.vw_Customer_Segmentation WHERE Customer_Segment = 'VIP Customer') AS VIP_Customers,
    (SELECT COUNT(*) FROM rpt.vw_Risk_Analysis WHERE Risk_Level = 'High Risk')          AS High_Risk_Customers;
GO





