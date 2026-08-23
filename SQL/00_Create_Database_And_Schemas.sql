/* ============================================================================================================
   Financial Analytics Data Warehouse
   00 - Create Database & Schemas
   ------------------------------------------------------------------------------------------------------------
   Layered schema design:
     stg  -> raw landing zone, one-to-one copy of the source system, truncate-and-reload
     dw   -> conformed Star Schema (Dimensions + Facts), the single source of truth for analysis
     etl  -> orchestration objects: stored procedures and load logging (not business data)
     rpt  -> reporting layer: views consumed by BI tools (Power BI / Tableau / Excel)

   Idempotent: safe to re-run on an existing database.
   ============================================================================================================ */

IF DB_ID(N'Financial_DWH') IS NULL
BEGIN
    CREATE DATABASE Financial_DWH;
END
GO

USE Financial_DWH;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'stg')
    EXEC('CREATE SCHEMA stg');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'dw')
    EXEC('CREATE SCHEMA dw');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'etl')
    EXEC('CREATE SCHEMA etl');
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'rpt')
    EXEC('CREATE SCHEMA rpt');
GO
