CREATE DATABASE [CacheDB]
 CONTAINMENT = NONE
 ON  PRIMARY
( NAME = N'CacheDB_Data', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER01\MSSQL\DATA\CacheDB.mdf', -- указать местоположение
	SIZE = 10GB , MAXSIZE = UNLIMITED, FILEGROWTH = 10% )
 LOG ON 
( NAME = N'CacheDB_Log', 
FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER01\MSSQL\DATA\CacheDB.ldf', -- указать местоположение
	SIZE = 2GB , MAXSIZE = UNLIMITED, FILEGROWTH = 10%)
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
USE [CacheDB]
GO
CREATE TABLE [dbo].[InvestorDateAssets]
(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Investor_Id] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AssetsValue] [numeric](28, 7) NOT NULL,
CONSTRAINT [PK_InvestorDateAssets] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_InvestorDateAssets_ID] ON [dbo].[InvestorDateAssets]
(
	[Investor_Id] ASC,
	[Date] ASC
)
INCLUDE (AssetsValue)
GO
USE [CacheDB]
GO
CREATE TABLE [dbo].[InvestorContractDateAssets]
(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Investor_Id] [int] NOT NULL,
	[Contract_Id] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AssetsValue] [numeric](28, 7) NOT NULL,
CONSTRAINT [PK_InvestorContractDateAssets] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_InvestorContractDateAssets_ICD] ON [dbo].[InvestorContractDateAssets]
(
	[Investor_Id] ASC,
	[Contract_Id] ASC,
	[Date] ASC
)
INCLUDE (AssetsValue)
GO