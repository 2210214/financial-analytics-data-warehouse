# Data Dictionary — Financial Analytics Data Warehouse

## Schema Layers

| Schema | Purpose |
|---|---|
| `stg` | Landing zone. Truncate-and-reload copy of the source system, no transformations. |
| `dw`  | Conformed Star Schema — Dimension and Fact tables. Source of truth for analysis. |
| `etl` | Orchestration objects: stored procedures and the load log. Not business data. |
| `rpt` | Reporting views. This is the layer BI tools (Power BI, Tableau, Excel) connect to. |

## Dimensions

| Table | Grain | Business Key | Notes |
|---|---|---|---|
| `dw.Dim_Customer` | One row per customer | `Customer_ID` | Includes a `-1` "Unknown" member |
| `dw.Dim_Account` | One row per account | `Account_ID` | Includes a `-1` "Unknown" member |
| `dw.Dim_Card` | One row per card | `Card_ID` | |
| `dw.Dim_Merchant` | One row per merchant | `Merchant_ID` | Includes a `-1` "Unknown" member |
| `dw.Dim_Branch` | One row per branch | `Branch_ID` | |
| `dw.Dim_Date` | One row per calendar day, 2020–2026 | `Date_Key` (`yyyyMMdd`) | Includes a `-1` "Unknown" member |

## Facts

| Table | Grain | Measures | Foreign Keys |
|---|---|---|---|
| `dw.Fact_Transactions` | One row per transaction | `Amount_USD` | Date_Key, Customer_Key, Account_Key, Merchant_Key |
| `dw.Fact_Loans` | One row per loan | `Loan_Amount`, `Interest_Rate` | Date_Key, Customer_Key |

**Unknown member pattern:** if a source transaction/loan has no matching dimension row (e.g. a
merchant not yet in the source `merchants` table), its foreign key is set to `-1` instead of the
row being dropped. Run the checks at the bottom of `Financial_Analytics_DWH.sql` (Section 8) to see
how many rows landed on `-1` — a non-zero count flags a source data quality issue, not a warehouse bug.

## Reporting Views (`rpt` schema)

| View | Answers |
|---|---|
| `vw_Customer_Analysis` | Per-customer transaction and loan totals |
| `vw_Transaction_Analysis` | Monthly transaction volume and value |
| `vw_Loan_Analysis` | Monthly loan volume, value, and interest rate |
| `vw_Customer_Loan_Analysis` | Per-customer loan detail |
| `vw_Merchant_Analysis` | Per-merchant transaction volume and value |
| `vw_Customer_Segmentation` | Customers bucketed into VIP / High / Medium / Low Activity |
| `vw_Risk_Analysis` | Customers bucketed into High / Medium / Low credit risk |
| `vw_Executive_KPIs` | Single-row headline metrics for a dashboard summary page |

## ETL Objects (`etl` schema)

| Object | Purpose |
|---|---|
| `etl.Load_Log` | One row per load step per run: start/end time, rows affected, status, error message |
| `etl.usp_Load_Staging` | Truncates and reloads all `stg.*` tables from the source system |
| `etl.usp_Load_Dimensions` | Inserts only new business keys into `dw.Dim_*` (safe to re-run) |
| `etl.usp_Load_Facts` | Inserts only new facts by natural key into `dw.Fact_*` (safe to re-run) |
| `etl.usp_Run_Full_ETL` | Orchestrates the three steps above under one `Batch_ID` |

## Segmentation & Risk Logic

**Customer Segment** (`vw_Customer_Segmentation`):
- VIP Customer: Total_Loan_Amount ≥ 1,000,000 **and** Total_Transaction_Amount ≥ 50,000
- High Value Customer: Total_Loan_Amount ≥ 500,000 **or** Total_Transaction_Amount ≥ 50,000
- Medium Value Customer: Total_Loan_Amount ≥ 100,000 **or** Total_Transaction_Amount ≥ 10,000
- Low Activity Customer: everyone else

**Risk Level** (`vw_Risk_Analysis`):
- High Risk: Credit_Score < 500 **and** Total_Loan_Amount ≥ 1,000,000
- Medium Risk: Credit_Score between 500–700 **or** Total_Loan_Amount between 500,000–999,999.99
- Low Risk: everyone else

> These thresholds are currently hard-coded in the view definitions. A natural next iteration is
> moving them into a small `dw.Dim_Config` table so they can change without altering SQL code.
