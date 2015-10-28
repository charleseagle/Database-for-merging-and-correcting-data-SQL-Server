--Create a database of spectrascopy

CREATE DATABASE [Spectroscopy] 
    ON (NAME = 'Spectroscopy_Data', FILENAME = N'E:\SQL_Server_Practice\Spectroscopy_Data.mdf', SIZE = 5, FILEGROWTH = 8) -- SIZE = 120, 
    LOG ON (NAME = 'Spectroscopy_Log', FILENAME = N'E:\SQL_Server_Practice\Spectroscopy_Log.ldf' , SIZE = 2, FILEGROWTH = 96);
GO

ALTER DATABASE [Spectroscopy] 
SET RECOVERY SIMPLE, 
    ANSI_NULLS ON, 
    ANSI_PADDING ON, 
    ANSI_WARNINGS ON, 
    ARITHABORT ON, 
    CONCAT_NULL_YIELDS_NULL ON, 
    QUOTED_IDENTIFIER ON, 
    NUMERIC_ROUNDABORT OFF, 
    PAGE_VERIFY CHECKSUM, 
    ALLOW_SNAPSHOT_ISOLATION OFF;
GO

USE [Spectroscopy];
GO

-- Create table to store error information
CREATE TABLE [dbo].[ErrorLog](
    [ErrorLogID] [int] IDENTITY (1, 1) NOT NULL,
    [ErrorTime] [datetime] NOT NULL CONSTRAINT [DF_ErrorLog_ErrorTime] DEFAULT (GETDATE()),
    [UserName] [sysname] NOT NULL, 
    [ErrorNumber] [int] NOT NULL, 
    [ErrorSeverity] [int] NULL, 
    [ErrorState] [int] NULL, 
    [ErrorProcedure] [nvarchar](126) NULL, 
    [ErrorLine] [int] NULL, 
    [ErrorMessage] [nvarchar](4000) NOT NULL
) ON [PRIMARY];
GO

ALTER TABLE [dbo].[ErrorLog] WITH CHECK ADD 
    CONSTRAINT [PK_ErrorLog_ErrorLogID] PRIMARY KEY CLUSTERED 
    (
        [ErrorLogID]
    )  ON [PRIMARY];
GO
-- uspPrintError prints error information about the error that caused 
-- execution to jump to the CATCH block of a TRY...CATCH construct. 
-- Should be executed from within the scope of a CATCH block otherwise 
-- it will return without printing any error information.
CREATE PROCEDURE [dbo].[uspPrintError] 
AS
BEGIN
    SET NOCOUNT ON;

    -- Print error information. 
    PRINT 'Error ' + CONVERT(varchar(50), ERROR_NUMBER()) +
          ', Severity ' + CONVERT(varchar(5), ERROR_SEVERITY()) +
          ', State ' + CONVERT(varchar(5), ERROR_STATE()) + 
          ', Procedure ' + ISNULL(ERROR_PROCEDURE(), '-') + 
          ', Line ' + CONVERT(varchar(5), ERROR_LINE());
    PRINT ERROR_MESSAGE();
END;
GO

-- uspLogError logs error information in the ErrorLog table about the 
-- error that caused execution to jump to the CATCH block of a 
-- TRY...CATCH construct. This should be executed from within the scope 
-- of a CATCH block otherwise it will return without inserting error 
-- information. 
CREATE PROCEDURE [dbo].[uspLogError] 
    @ErrorLogID [int] = 0 OUTPUT -- contains the ErrorLogID of the row inserted
AS                               -- by uspLogError in the ErrorLog table
BEGIN
    SET NOCOUNT ON;

    -- Output parameter value of 0 indicates that error 
    -- information was not logged
    SET @ErrorLogID = 0;

    BEGIN TRY
        -- Return if there is no error information to log
        IF ERROR_NUMBER() IS NULL
            RETURN;

        -- Return if inside an uncommittable transaction.
        -- Data insertion/modification is not allowed when 
        -- a transaction is in an uncommittable state.
        IF XACT_STATE() = -1
        BEGIN
            PRINT 'Cannot log error since the current transaction is in an uncommittable state. ' 
                + 'Rollback the transaction before executing uspLogError in order to successfully log error information.';
            RETURN;
        END

        INSERT [dbo].[ErrorLog] 
            (
            [UserName], 
            [ErrorNumber], 
            [ErrorSeverity], 
            [ErrorState], 
            [ErrorProcedure], 
            [ErrorLine], 
            [ErrorMessage]
            ) 
        VALUES 
            (
            CONVERT(sysname, CURRENT_USER), 
            ERROR_NUMBER(),
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_PROCEDURE(),
            ERROR_LINE(),
            ERROR_MESSAGE()
            );

        -- Pass back the ErrorLogID of the row inserted
        SET @ErrorLogID = @@IDENTITY;
    END TRY
    BEGIN CATCH
        PRINT 'An error occurred in stored procedure uspLogError: ';
        EXECUTE [dbo].[uspPrintError];
        RETURN -1;
    END CATCH
END;
GO

--create a schema
CREATE SCHEMA [2H] AUTHORIZATION [dbo];
GO

--DROP SCHEMA Spectra;

-- Create tables
CREATE TABLE [2H].[UV](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[NIR](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[MIR](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

--DROP TABLE Spectra.UV;
CREATE TABLE [2H].[MNIR](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[UV_Al](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[NIR_Al](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[MIR_Al](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[MNIR_Al](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[FIR_50](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[FIR_35](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[FIR_23](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [2H].[FIR_12](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO


-- Load data
BULK INSERT [Spectroscopy].[2H].[UV] FROM N'E:\SQL_Server_Practice\2H\_2HU1.SP_xy.ASC'
WITH (
   CODEPAGE='ACP',
   DATAFILETYPE = 'char',
   FIELDTERMINATOR= '\t',
   ROWTERMINATOR = '\n' ,
   KEEPIDENTITY,
   TABLOCK   
);

SELECT * FROM [2H].[UV];

TRUNCATE TABLE [2H].[UV];

BULK INSERT [Spectroscopy].[2H].[UV_Al] FROM N'E:\SQL_Server_Practice\2H\_2H_AL_U.SP_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[NIR] FROM N'E:\SQL_Server_Practice\2H\_2HN1.SP_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[NIR_Al] FROM N'E:\SQL_Server_Practice\2H\_2H_AL_N.SP_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[MNIR] FROM N'E:\SQL_Server_Practice\2H\_MNIR.DPT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[MNIR_Al] FROM N'E:\SQL_Server_Practice\2H\_2H_NIR_Al.DPT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[MIR] FROM N'E:\SQL_Server_Practice\2H\_MMIR.DPT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[MIR_Al] FROM N'E:\SQL_Server_Practice\2H\_2H_MIR_Al_5.DPT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[FIR_50] FROM N'E:\SQL_Server_Practice\2H\_50.CUT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[FIR_35] FROM N'E:\SQL_Server_Practice\2H\_35.CUT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[FIR_23] FROM N'E:\SQL_Server_Practice\2H\_23.CUT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

BULK INSERT [Spectroscopy].[2H].[FIR_12] FROM N'E:\SQL_Server_Practice\2H\_12.CUT_xy.asc'
WITH (
   KEEPIDENTITY,
   TABLOCK   
);

-- Add Primary Keys
USE Spectroscopy;
GO

ALTER TABLE [2H].[FIR_12] WITH CHECK ADD 
    CONSTRAINT [PK_FIR_12_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO

-- Add Indexes

CREATE INDEX [IX_FIR_12_Frequency] ON [2H].[FIR_12]([Frequency]) ON [PRIMARY];
GO

ALTER TABLE [2H].[FIR_12]
    DROP CONSTRAINT PK_FIR_12_Frequency

ALTER TABLE [2H].[FIR_23] WITH CHECK ADD 
    CONSTRAINT [PK_FIR_23_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO

CREATE INDEX [IX_FIR_23_Frequency] ON [2H].[FIR_23]([Frequency], [Intensity]) ON [PRIMARY];
GO

DROP INDEX [2H].[FIR_35].[IX_FIR_35_Frequency];

ALTER TABLE [2H].[FIR_35] WITH CHECK ADD 
    CONSTRAINT [PK_FIR_35_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO

CREATE INDEX [IX_FIR_35_Frequency] ON [2H].[FIR_35]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[FIR_50] WITH CHECK ADD 
    CONSTRAINT [PK_FIR_50_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO

CREATE INDEX [IX_FIR_50_Frequency] ON [2H].[FIR_50]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[MIR] WITH CHECK ADD 
    CONSTRAINT [PK_MIR_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO

CREATE INDEX [IX_MIR_Frequency] ON [2H].[MIR]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[MIR_Al] WITH CHECK ADD 
    CONSTRAINT [PK_MIR_Al_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_MIR_Al_Frequency] ON [2H].[MIR_Al]([Frequency], [Intensity]) ON [PRIMARY];
GO


ALTER TABLE [2H].[MNIR] WITH CHECK ADD 
    CONSTRAINT [PK_MNIR_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_MNIR_Frequency] ON [2H].[MNIR]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[MNIR_Al] WITH CHECK ADD 
    CONSTRAINT [PK_MNIR_Al_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_MNIR_Al_Frequency] ON [2H].[MNIR_Al]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[NIR] WITH CHECK ADD 
    CONSTRAINT [PK_NIR_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_NIR_Frequency] ON [2H].[NIR]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[NIR_Al] WITH CHECK ADD 
    CONSTRAINT [PK_NIR_Al_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_NIR_Al_Frequency] ON [2H].[NIR_Al]([Frequency], [Intensity]) ON [PRIMARY];
GO


ALTER TABLE [2H].[UV] WITH CHECK ADD 
    CONSTRAINT [PK_UV_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_UV_Frequency] ON [2H].[UV]([Frequency], [Intensity]) ON [PRIMARY];
GO

ALTER TABLE [2H].[UV_Al] WITH CHECK ADD 
    CONSTRAINT [PK_UV_Al_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_UV_Al_Frequency] ON [2H].[UV_Al]([Frequency], [Intensity]) ON [PRIMARY];
GO



CREATE TABLE [Spectroscopy].[2H].[FIR_MERGE](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO



INSERT INTO [2H].[FIR_MERGE]
SELECT * FROM [2H].[FIR_35]
UNION 
SELECT * FROM [2H].[FIR_23]
UNION 
SELECT * FROM [2H].[FIR_12]
UNION 
SELECT * FROM [2H].[FIR_50];

--ALTER TABLE [2H].[FIR_MERGE] WITH CHECK ADD 
--    CONSTRAINT [PK_FIR_MERGE_Frequency] PRIMARY KEY CLUSTERED 
--    (
--        [Frequency]
--    )  ON [PRIMARY];
--GO
--ALTER TABLE [2H].[FIR_MERGE]
--DROP CONSTRAINT [PK_FIR_MERGE_Frequency];

CREATE INDEX [IX_FIR_MERGE_Frequency] ON [2H].[FIR_MERGE]([Frequency], [Intensity]) ON [PRIMARY];
GO


SELECT * FROM [2H].[FIR_MERGE];


CREATE TABLE [Spectroscopy].[2H].[UV_Corrected](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

CREATE TABLE [Spectroscopy].[2H].[NIR_Corrected](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO


--DROP TABLE [Spectroscopy].[2H].[MIR_Corrected]

CREATE TABLE [Spectroscopy].[2H].[MIR_Corrected](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

TRUNCATE TABLE [2H].[NIR_Corrected];

INSERT INTO [Spectroscopy].[2H].[UV_Corrected]
SELECT [2H].[UV].Frequency, [2H].[UV].Intensity/[2H].[UV_Al].Intensity AS Intensity FROM [2H].[UV], [2H].[UV_Al] WHERE [2H].[UV].Frequency = [2H].[UV_Al].Frequency;

ALTER TABLE [2H].[UV_Corrected] WITH CHECK ADD 
    CONSTRAINT [PK_UV_Corrected_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_UV_Corrected_Frequency] ON [2H].[UV_Corrected]([Frequency], [Intensity]) ON [PRIMARY];
GO


INSERT INTO [Spectroscopy].[2H].[NIR_Corrected]
SELECT [2H].[NIR].Frequency, [2H].[NIR].Intensity/[2H].[NIR_Al].Intensity AS Intensity FROM [2H].[NIR], [2H].[NIR_Al] WHERE [2H].[NIR].Frequency = [2H].[NIR_Al].Frequency;

ALTER TABLE [2H].[NIR_Corrected] WITH CHECK ADD 
    CONSTRAINT [PK_NIR_Corrected_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_NIR_Corrected_Frequency] ON [2H].[NIR_Corrected]([Frequency], [Intensity]) ON [PRIMARY];
GO
--SELECT * FROM [2H].[MIR_Corrected]

INSERT INTO [Spectroscopy].[2H].[MIR_Corrected]
SELECT [2H].[MIR].Frequency, [2H].[MIR].Intensity/[2H].[MIR_Al].Intensity AS Intensity FROM [2H].[MIR], [2H].[MIR_Al] WHERE [2H].[MIR].Frequency = [2H].[MIR_Al].Frequency;

ALTER TABLE [2H].[MIR_Corrected] WITH CHECK ADD 
    CONSTRAINT [PK_MIR_Corrected_Frequency] PRIMARY KEY CLUSTERED 
    (
        [Frequency]
    )  ON [PRIMARY];
GO
CREATE INDEX [IX_MIR_Corrected_Frequency] ON [2H].[MIR_Corrected]([Frequency], [Intensity]) ON [PRIMARY];
GO

CREATE TABLE [Spectroscopy].[2H].[MERGE](
    [Frequency] [float] NOT NULL,
    [Intensity] [float] NOT NULL
) ON [PRIMARY];
GO

SELECT * FROM [2H].[MERGE];

TRUNCATE TABLE [2H].[MERGE];

INSERT INTO [2H].[MERGE]
SELECT * FROM [2H].[FIR_MERGE]
UNION ALL
SELECT * FROM [2H].[MIR_Corrected]
UNION ALL
SELECT * FROM [2H].[NIR_Corrected]
UNION ALL
SELECT * FROM [2H].[UV_Corrected];

CREATE INDEX [IX_MERGE_Frequency] ON [2H].[MERGE]([Frequency], [Intensity]) ON [PRIMARY];
GO