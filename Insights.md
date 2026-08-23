# Financial Analytics Data Warehouse — Key Insights

**Dataset:** Synthetic Retail Banking Dataset  
**Analysis Period:** January 2019 – December 2025  
**Customers:** 50,000  
**Transactions:** 64,623  
**Loans:** 30,000  

All figures below are derived from the final SQL reporting layer (`rpt.*`) after ETL and data-quality validation were completed.

---

## 1. Executive Summary

The Financial Analytics Data Warehouse contains **50,000 customers**, **64,623 transactions**, and **30,000 loans** covering the period from **2019 through 2025**.

The dataset contains **$323,093,643.23** in total transaction value, with an average transaction amount of **$4,999.67**.

The loan portfolio contains **$4,502,670,498.10** in total loan amount, with an average loan amount of **$150,089.02**.

Customer analysis shows that **Medium Value Customers** represent **48.82% of the customer base** but account for **85.14% of total loan value**, making this the largest concentration of the loan portfolio.

Risk analysis shows that **37.65% of customers are classified as Medium Risk**, while only **1 customer** is classified as High Risk.

After correcting the date-dimension matching logic, **zero fact records were assigned to the Unknown member**, confirming complete dimension matching across the validated fact tables.

---

## 2. Customer Value Concentration

| Customer Segment | Customers | % of Customers | Total Loan Amount | % of Total Loans |
|---|---:|---:|---:|---:|
| Low Activity Customer | 24,781 | 49.56% | $217,610,089.24 | 4.83% |
| Medium Value Customer | 24,409 | 48.82% | $3,833,717,086.53 | 85.14% |
| High Value Customer | 810 | 1.62% | $451,343,322.33 | 10.02% |
| VIP Customer | 0 | 0.00% | — | — |
| **Total** | **50,000** | **100.00%** | **$4,502,670,498.10** | **100.00%** |

### Key Finding

**Medium Value Customers represent 48.82% of the customer base but account for 85.14% of total loan value, making this segment the primary concentration of the bank's loan portfolio.**

The High Value segment is much smaller, representing only **1.62% of customers**, but contributes **10.02% of total loan value**.

### Business Implication

The Medium Value segment should receive particular attention because it combines a large customer population with a disproportionately large share of the loan portfolio.

Potential actions include:

- Monitoring loan exposure within this segment.
- Developing targeted retention and cross-selling strategies.
- Monitoring customers moving between value segments.
- Evaluating customers with exceptionally high loan exposure.

---

## 3. Risk Distribution

| Risk Level | Customers | % of Customers |
|---|---:|---:|
| Low Risk | 31,173 | 62.35% |
| Medium Risk | 18,826 | 37.65% |
| High Risk | 1 | 0.002% |
| **Total** | **50,000** | **100.00%** |

### Key Finding

**37.65% of customers are classified as Medium Risk, while only 1 customer falls into the High Risk category.**

The identified High Risk customer is:

- **Customer:** Erica Baker
- **City:** Mooremouth
- **Credit Score:** 385
- **Total Loans:** 6
- **Total Loan Amount:** $1,123,514.67
- **Risk Level:** High Risk

### Business Implication

Although the High Risk population is extremely small, the identified customer has substantial loan exposure of more than **$1.12 million**.

Risk monitoring should therefore consider both the **number of customers** and their **total loan exposure**.

The Medium Risk population contains **18,826 customers**, making it the main group for proactive credit-risk monitoring.

---

## 4. Transaction Trends

The warehouse contains **64,623 transactions** with a total transaction value of:

**$323,093,643.23**

The average transaction amount is:

**$4,999.67**

### First vs. Last Month

| Metric | January 2019 | December 2025 | Change |
|---|---:|---:|---:|
| Transactions | 799 | 769 | -3.75% |
| Transaction Value | $3,967,821.96 | $3,790,406.09 | -4.47% |
| Average Transaction | $4,965.98 | $4,929.01 | -0.74% |

### Key Finding

**Transaction volume declined by 3.75% from January 2019 to December 2025, while total transaction value declined by 4.47%.**

The average transaction amount changed by only approximately **-0.74%**, indicating that the long-term change was relatively modest rather than being driven by a major shift in transaction size.

### Monthly Activity

The highest monthly transaction count was:

**840 transactions — December 2022**

The lowest monthly transaction count was:

**676 transactions — February 2025**

### Business Implication

Transaction activity appears relatively stable throughout the analyzed period rather than showing sustained long-term growth.

Potential growth opportunities include:

- Increasing customer transaction frequency.
- Increasing customer engagement.
- Activating low-activity customers.
- Increasing transaction value while maintaining appropriate risk controls.

---

## 5. Merchant Concentration

The Top 10 merchants generated a combined transaction value of:

**$1,382,499.01**

Total transaction value across all merchants was:

**$323,093,643.23**

Therefore, the Top 10 merchant concentration is:

**0.428%**

### Top 10 Merchants

| Rank | Merchant | Transaction Value |
|---:|---|---:|
| 1 | Lynch-Howard | $149,092.41 |
| 2 | Davis Ltd | $145,732.22 |
| 3 | Rogers, Bell and Mccormick | $140,445.84 |
| 4 | Small, Walker and Coleman | $140,235.34 |
| 5 | Lee, Stewart and Boyd | $137,067.28 |
| 6 | Ramirez Inc | $135,946.77 |
| 7 | Johnson-Allen | $134,877.93 |
| 8 | Peters, King and Smith | $134,168.35 |
| 9 | White-Medina | $132,712.12 |
| 10 | Martinez, Mcneil and Hernandez | $132,220.75 |

### Key Finding

**The top 10 merchants account for only 0.428% of total transaction value, indicating very low merchant concentration and a highly distributed transaction base.**

### Business Implication

The bank is not materially dependent on a small group of merchants for transaction activity.

This indicates low merchant-level concentration risk and a broadly distributed transaction base.

---

## 6. Data Quality Finding

The final post-load validation produced the following results:

| Data Quality Check | Unknown Records |
|---|---:|
| Fact_Transactions → Unknown Customer | 0 |
| Fact_Transactions → Unknown Account | 0 |
| Fact_Transactions → Unknown Merchant | 0 |
| Fact_Transactions → Unknown Date | 0 |
| Fact_Loans → Unknown Customer | 0 |
| Fact_Loans → Unknown Date | 0 |

### Key Finding

**Zero transaction and loan fact records were assigned to the Unknown member across customer, account, merchant, and date lookups.**

This confirms that the final ETL load successfully matched the fact records to their corresponding dimension members.

### Previous Data Quality Issue

During the initial validation, the warehouse identified:

- **9,266 transactions** with an Unknown Date.
- **4,393 loans** with an Unknown Date.

The issue was caused by a mismatch between the source datetime values and the date-dimension matching logic.

After correcting the date matching logic, the final validation returned:

- **0 Unknown Transaction Dates**
- **0 Unknown Loan Dates**

This demonstrates that the issue was investigated and resolved rather than being silently ignored.

---

## 7. ETL Performance & Load Validation

The final ETL execution completed successfully with the following staging load volumes:

| Staging Table | Rows Loaded |
|---|---:|
| Customers | 50,000 |
| Accounts | 75,000 |
| Cards | 100,000 |
| Merchants | 5,000 |
| Branches | 500 |
| Loans | 30,000 |
| Transactions | 64,623 |

Final warehouse row counts:

| Warehouse Table | Rows |
|---|---:|
| Dim_Customer | 50,001* |
| Dim_Account | 75,001* |
| Dim_Card | 100,000 |
| Dim_Merchant | 5,001* |
| Dim_Branch | 500 |
| Dim_Date | 2,558 |
| Fact_Transactions | 64,623 |
| Fact_Loans | 30,000 |

\*The additional row represents the **Unknown (-1) member** where applicable.

The latest full ETL batch completed with:

**Status: SUCCESS**

No ETL error messages were recorded for the successful batch.

---

## 8. Executive KPI Snapshot

| KPI | Value |
|---|---:|
| Total Customers | **50,000** |
| Total Transactions | **64,623** |
| Total Transaction Amount | **$323,093,643.23** |
| Average Transaction Amount | **$4,999.67** |
| Total Loans | **30,000** |
| Total Loan Amount | **$4,502,670,498.10** |
| Average Loan Amount | **$150,089.02** |
| VIP Customers | **0** |
| High Risk Customers | **1** |

---

## 9. Overall Business Takeaways

### 1. Loan exposure is highly concentrated in the Medium Value segment

Nearly half of the customer base (**48.82%**) represents **85.14% of total loan value**.

### 2. Medium Risk is the main risk-management population

**18,826 customers (37.65%)** are classified as Medium Risk, making this group much more significant for proactive monitoring than the extremely small High Risk population.

### 3. The identified High Risk customer requires attention

Only **1 customer** is classified as High Risk, but that customer has **$1.12 million** in total loans and a credit score of **385**.

### 4. Transaction activity is relatively stable

From January 2019 to December 2025, transaction volume declined by only **3.75%**, while average transaction size changed by approximately **-0.74%**.

### 5. Merchant concentration is very low

The Top 10 merchants account for only **0.428%** of total transaction value, indicating a highly diversified merchant base.

### 6. Final ETL data quality is clean

All tested customer, account, merchant, and date lookups successfully matched after the date-dimension correction, with **zero Unknown records** in the final validation.

---

## 10. SQL Sources

The insights in this document are based on the final SQL Server reporting layer:

- `rpt.vw_Executive_KPIs`
- `rpt.vw_Customer_Analysis`
- `rpt.vw_Customer_Segmentation`
- `rpt.vw_Risk_Analysis`
- `rpt.vw_Transaction_Analysis`
- `rpt.vw_Merchant_Analysis`

ETL and data-quality validation were performed using:

- `etl.usp_Run_Full_ETL`
- `etl.Load_Log`
- `06_Run_ETL_And_Validate.sql`
- `07_Sample_Analysis_Queries.sql`

The warehouse uses an **idempotent ETL design**, a **Star Schema**, **Unknown Member handling**, and a dedicated **reporting layer** for BI consumption.