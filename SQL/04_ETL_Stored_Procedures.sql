/* ============================================================================================================
   Financial Analytics Data Warehouse
   04 - ETL Stored Procedures
   ------------------------------------------------------------------------------------------------------------
   etl.Load_Log            - one row per load step per run: start/end time, rows affected, status, error
   etl.usp_Load_Staging    - truncates and reloads all stg.* tables from the source system
   etl.usp_Load_Dimensions - inserts only NEW business keys into dw.Dim_* (safe to re-run)
   etl.usp_Load_Facts      - inserts only NEW facts by natural key into dw.Fact_* (safe to re-run)
   etl.usp_Run_Full_ETL    - orchestrates the three steps above under one Batch_ID

   Idempotent: the Load_Log table creation is guarded; the procedures use CREATE OR ALTER, which is
   natively idempotent from SQL Server 2016+ onward.
   ============================================================================================================ */

USE Financial_DWH;
GO

IF OBJECT_ID(N'etl.Load_Log', N'U') IS NULL
BEGIN
    CREATE TABLE etl.Load_Log
    (
        Log_ID              INT IDENTITY(1,1) PRIMARY KEY,
        Batch_ID            UNIQUEIDENTIFIER,
        Procedure_Name      VARCHAR(100),
        Step_Name           VARCHAR(100),
        Start_Time          DATETIME,
        End_Time            DATETIME,
        Rows_Affected       INT,
        Status              VARCHAR(20),      -- 'SUCCESS' or 'FAILED'
        Error_Message       VARCHAR(MAX)
    );
END
GO


-- ------------------------------------------------------------------------------------------------------------
-- etl.usp_Load_Staging
-- ------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE etl.usp_Load_Staging
    @Batch_ID UNIQUEIDENTIFIER
AS
BEGIN

    SET NOCOUNT ON;
    BEGIN TRY
        ------------------------------------------------------------
        -- Customers
        ------------------------------------------------------------
        DECLARE @Start DATETIME = GETDATE();
        TRUNCATE TABLE stg.Customers;
        INSERT INTO stg.Customers
        (
            customer_id,
            first_name,
            last_name,
            email,
            city,
            credit_score,
            created_at
        )

        SELECT
            customer_id,
            first_name,
            last_name,
            email,
            city,
            credit_score,
            created_at

        FROM bank.dbo.customers;


        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Rows_Affected,
            Status
        )

        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Customers',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS'
        );
        ------------------------------------------------------------
        -- Accounts
        ------------------------------------------------------------

        SET @Start = GETDATE();
        TRUNCATE TABLE stg.Accounts;
        INSERT INTO stg.Accounts
        (
            account_id,
            customer_id,
            account_type,
            balance_usd,
            open_date
        )

        SELECT
            account_id,
            customer_id,
            account_type,
            balance_usd,
            open_date

        FROM bank.dbo.accounts;
        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Accounts',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Cards
        ------------------------------------------------------------

        SET @Start = GETDATE();


        TRUNCATE TABLE stg.Cards;


        INSERT INTO stg.Cards
        (
            card_id,
            account_id,
            card_type,
            expiration_date
        )

        SELECT
            card_id,
            account_id,
            card_type,
            expiration_date

        FROM bank.dbo.cards;



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Cards',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Merchants
        ------------------------------------------------------------

        SET @Start = GETDATE();


        TRUNCATE TABLE stg.Merchants;


        INSERT INTO stg.Merchants
        (
            merchant_id,
            merchant_name,
            city
        )

        SELECT
            merchant_id,
            merchant_name,
            city

        FROM bank.dbo.merchants;



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Merchants',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Branches
        ------------------------------------------------------------
SET @Start = GETDATE();


        TRUNCATE TABLE stg.Branches;


        INSERT INTO stg.Branches
        (
            branch_id,
            branch_name,
            manager_name,
            city,
            country
        )

        SELECT
            branch_id,
            branch_name,
            manager_name,
            city,
            country

        FROM bank.dbo.branches;



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Branches',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Loans
        ------------------------------------------------------------

        SET @Start = GETDATE();


        TRUNCATE TABLE stg.Loans;


        INSERT INTO stg.Loans
        (
            loan_id,
            customer_id,
            loan_amount,
            interest_rate,
            start_date
        )

        SELECT
            loan_id,
            customer_id,
            loan_amount,
            interest_rate,
            start_date

        FROM bank.dbo.loans;



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Loans',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Transactions
        ------------------------------------------------------------

        SET @Start = GETDATE();


        TRUNCATE TABLE stg.Transactions;


        INSERT INTO stg.Transactions
        (
            transaction_id,
            account_id,
            merchant_id,
            amount_usd,
            transaction_date
        )

        SELECT
            transaction_id,
            account_id,
            merchant_id,
            amount_usd,
            transaction_date

        FROM bank.dbo.transactions;

        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'stg.Transactions',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );

    END TRY



    BEGIN CATCH
        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Status,
            Error_Message
        )

        VALUES
        (
            @Batch_ID,
            'usp_Load_Staging',
            'STAGING_FAILED',
            GETDATE(),
            GETDATE(),
            'FAILED',
            ERROR_MESSAGE()
        );

        THROW;
    END CATCH

END;
GO

-- ------------------------------------------------------------------------------------------------------------
-- etl.usp_Load_Dimensions
-- Loads only NEW business keys into each dimension (NOT EXISTS check) so the procedure is safe to re-run
-- without creating duplicate dimension members.
-- ------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE etl.usp_Load_Dimensions
    @Batch_ID UNIQUEIDENTIFIER
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY
        ------------------------------------------------------------
        -- Dim_Customer
        ------------------------------------------------------------

        DECLARE @Start DATETIME = GETDATE();

        INSERT INTO dw.Dim_Customer
        (
            Customer_ID,
            First_Name,
            Last_Name,
            Email,
            City,
            Credit_Score,
            Created_At
        )

        SELECT

            s.customer_id,
            s.first_name,
            s.last_name,
            s.email,
            s.city,
            s.credit_score,
            s.created_at

        FROM stg.Customers s
        WHERE NOT EXISTS
        (
            SELECT 1

            FROM dw.Dim_Customer d

            WHERE d.Customer_ID = s.customer_id
        );

        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Rows_Affected,
            Status
        )

        VALUES
        (
            @Batch_ID,
            'usp_Load_Dimensions',
            'Dim_Customer',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS'
        );



        ------------------------------------------------------------
        -- Dim_Account
        ------------------------------------------------------------

        SET @Start = GETDATE();


        INSERT INTO dw.Dim_Account
        (
            Account_ID,
            Customer_ID,
            Account_Type,
            Balance_USD,
            Open_Date
        )


        SELECT

            s.account_id,
            s.customer_id,
            s.account_type,
            s.balance_usd,
            s.open_date


        FROM stg.Accounts s

        WHERE NOT EXISTS
        (
            SELECT 1

            FROM dw.Dim_Account d

            WHERE d.Account_ID = s.account_id
        );



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Dimensions',
            'Dim_Account',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );
        ------------------------------------------------------------
        -- Dim_Card
        ------------------------------------------------------------

        SET @Start = GETDATE();


        INSERT INTO dw.Dim_Card
        (
            Card_ID,
            Account_ID,
            Card_Type,
            Expiration_Date
        )

        SELECT

            s.card_id,
            s.account_id,
            s.card_type,
            s.expiration_date


        FROM stg.Cards s


        WHERE NOT EXISTS
        (
            SELECT 1

            FROM dw.Dim_Card d

            WHERE d.Card_ID = s.card_id
        );



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Dimensions',
            'Dim_Card',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Dim_Merchant
        ------------------------------------------------------------

        SET @Start = GETDATE();


        INSERT INTO dw.Dim_Merchant
        (
            Merchant_ID,
            Merchant_Name,
            City
        )


        SELECT

            s.merchant_id,
            s.merchant_name,
            s.city


        FROM stg.Merchants s


        WHERE NOT EXISTS
        (
            SELECT 1 FROM dw.Dim_Merchant d

            WHERE d.Merchant_ID = s.merchant_id
        );



        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Dimensions',
            'Dim_Merchant',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



        ------------------------------------------------------------
        -- Dim_Branch
        ------------------------------------------------------------

        SET @Start = GETDATE();


        INSERT INTO dw.Dim_Branch
        (
            Branch_ID,
            Branch_Name,
            Manager_Name,
            City,
            Country
        )


        SELECT

            s.branch_id,
            s.branch_name,
            s.manager_name,
            s.city,
            s.country


        FROM stg.Branches s


        WHERE NOT EXISTS
        (
            SELECT 1

            FROM dw.Dim_Branch d

            WHERE d.Branch_ID = s.branch_id
        );
        INSERT INTO etl.Load_Log
        VALUES
        (
            @Batch_ID,
            'usp_Load_Dimensions',
            'Dim_Branch',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS',
            NULL
        );



    END TRY



    BEGIN CATCH

        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Status,
            Error_Message
        )

        VALUES
        (
            @Batch_ID,
            'usp_Load_Dimensions',
            'DIMENSIONS_FAILED',
            GETDATE(),
            GETDATE(),
            'FAILED',
            ERROR_MESSAGE()
        );



        THROW;



    END CATCH


END;
GO
-- ------------------------------------------------------------------------------------------------------------
-- etl.usp_Load_Facts
-- Loads only NEW facts (by natural key) using LEFT JOIN + ISNULL(...,-1) so unmatched dimension lookups
-- point at the "Unknown" member instead of silently dropping the row.
-- ------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------
-- etl.usp_Load_Facts
-- Loads new fact records only
-- Uses dimension surrogate keys
-- Unknown member (-1) handles missing lookups
-- Transaction is controlled by usp_Run_Full_ETL
-- ------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE etl.usp_Load_Facts
    @Batch_ID UNIQUEIDENTIFIER
AS
BEGIN

    SET NOCOUNT ON;

    BEGIN TRY
        ------------------------------------------------------------
        -- Fact_Transactions
        ------------------------------------------------------------

        DECLARE @Start DATETIME = GETDATE();

        INSERT INTO dw.Fact_Transactions
        (
            Transaction_ID,
            Date_Key,
            Customer_Key,
            Account_Key,
            Merchant_Key,
            Amount_USD
        )
        SELECT

            t.transaction_id,
            ISNULL(d.Date_Key,-1),
            ISNULL(c.Customer_Key,-1),
            ISNULL(a.Account_Key,-1),
            ISNULL(m.Merchant_Key,-1),
            t.amount_usd
        FROM stg.Transactions t
        LEFT JOIN dw.Dim_Account a
            ON t.account_id = a.Account_ID
        LEFT JOIN dw.Dim_Customer c
            ON a.Customer_ID = c.Customer_ID
        LEFT JOIN dw.Dim_Merchant m
            ON t.merchant_id = m.Merchant_ID
        LEFT JOIN dw.Dim_Date d
            ON CAST(t.transaction_date AS DATE) = d.Full_Date

        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dw.Fact_Transactions f
            WHERE f.Transaction_ID = t.transaction_id
        );

        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Rows_Affected,
            Status
        )

        VALUES

        (
            @Batch_ID,
            'usp_Load_Facts',
            'Fact_Transactions',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS'
        );
        ------------------------------------------------------------
        -- Fact_Loans
        ------------------------------------------------------------
        SET @Start = GETDATE();

        INSERT INTO dw.Fact_Loans
        (
            Loan_ID,
            Date_Key,
            Customer_Key,
            Loan_Amount,
            Interest_Rate
        )
        SELECT
            l.loan_id,
            ISNULL(d.Date_Key,-1),
            ISNULL(c.Customer_Key,-1),
            l.loan_amount,
            l.interest_rate
        FROM stg.Loans l
        LEFT JOIN dw.Dim_Customer c
            ON l.customer_id = c.Customer_ID
        LEFT JOIN dw.Dim_Date d
            ON CAST(l.start_date AS DATE) = d.Full_Date



        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dw.Fact_Loans f
            WHERE f.Loan_ID = l.loan_id
        );

        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Rows_Affected,
            Status
        )

        VALUES

        (
            @Batch_ID,
            'usp_Load_Facts',
            'Fact_Loans',
            @Start,
            GETDATE(),
            @@ROWCOUNT,
            'SUCCESS'
        );

    END TRY
    BEGIN CATCH
        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Status,
            Error_Message
        )

        VALUES (
            @Batch_ID,
            'usp_Load_Facts',
            'FACTS_FAILED',
            GETDATE(),
            GETDATE(),
            'FAILED',
            ERROR_MESSAGE()
        );

        THROW;

    END CATCH

END;
GO
-- ------------------------------------------------------------------------------------------------------------
-- etl.usp_Run_Full_ETL
-- Master ETL Controller
-- Executes:
-- 1) Load Staging
-- 2) Load Dimensions
-- 3) Load Facts
--
-- One Batch_ID connects all log records of the same run
-- Transaction is controlled here
-- ------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE etl.usp_Run_Full_ETL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Batch_ID UNIQUEIDENTIFIER = NEWID();
    DECLARE @Start DATETIME = GETDATE();

    BEGIN TRY

        BEGIN TRANSACTION;

        ------------------------------------------------------------
        -- Step 1 : Load Staging
        ------------------------------------------------------------

        EXEC etl.usp_Load_Staging
            @Batch_ID = @Batch_ID;

        ------------------------------------------------------------
        -- Step 2 : Load Dimensions
        ------------------------------------------------------------

        EXEC etl.usp_Load_Dimensions
            @Batch_ID = @Batch_ID;

        ------------------------------------------------------------
        -- Step 3 : Load Facts
        ------------------------------------------------------------

        EXEC etl.usp_Load_Facts
            @Batch_ID = @Batch_ID;

        COMMIT TRANSACTION;

        ------------------------------------------------------------
        -- Full ETL Success Log
        ------------------------------------------------------------


        INSERT INTO etl.Load_Log
        (
            Batch_ID,
            Procedure_Name,
            Step_Name,
            Start_Time,
            End_Time,
            Status
        )

        VALUES

        (
            @Batch_ID,
            'usp_Run_Full_ETL',
            'FULL_ETL',
            @Start,
            GETDATE(),
            'SUCCESS'
        );

    END TRY

    BEGIN CATCH
     IF @@TRANCOUNT > 0
       ROLLBACK TRANSACTION;
        INSERT INTO etl.Load_Log (Batch_ID, Procedure_Name,Step_Name,Start_Time,  End_Time, Status,Error_Message)
        VALUES ( @Batch_ID,'usp_Run_Full_ETL','FULL_ETL_FAILED', @Start,GETDATE(),'FAILED', ERROR_MESSAGE() );

        THROW;

    END CATCH;

    ------------------------------------------------------------
    -- Show Current Batch Result
    ------------------------------------------------------------

    SELECT * FROM etl.Load_Log
    WHERE Batch_ID = @Batch_ID
    ORDER BY Log_ID;
END;
GO

