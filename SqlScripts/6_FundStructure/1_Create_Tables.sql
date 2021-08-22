USE [CacheDB]
GO
CREATE TABLE [dbo].[FundStructure]
(
	[Contract_Id] [int] NOT NULL,
	[PortfolioDate] [date] NOT NULL,
	[Id] BigInt Identity(1,1),
	[Investor_Id] [int] NULL,
	[Investment_id] bigint NULL,
	[VALUE_ID] [int] NULL,
	[BAL_ACC] [int] NULL,
	[CLASS] [int] NULL,
	[AMOUNT] [numeric](28, 10) NULL,
	[BAL_SUMMA_RUR] [numeric](28, 10) NULL,
	[Bal_Delta] [numeric](28, 10) NULL,
	[NOMINAL] [numeric](28, 10) NULL,
	[RUR_PRICE] [numeric](28, 10) NULL,
	[Nom_Price] [numeric](28, 10) NULL,
	[VALUE_RUR] [numeric](28, 10) NULL,
	[VALUE_NOM] [numeric](28, 10) NULL,
	[CUR_ID] [int] NULL,
	[RATE] [numeric](28, 10) NULL,
	[RATE_DATE] [datetime] NULL,
	[RecordDate] DateTime2 CONSTRAINT DF_FundStructure_RecordDate Default SysDateTime(),
CONSTRAINT [PK_FundStructure] PRIMARY KEY CLUSTERED
(
	[Contract_Id] ASC,
	[PortfolioDate] ASC,
	[Id] ASC
)ON YEAR_Partition_Scheme ([PortfolioDate])
)
GO
CREATE TABLE [dbo].[FundStructure_Last]
(
	[Contract_Id] [int] NOT NULL,
	[PortfolioDate] [date] NOT NULL,
	[Id] BigInt Identity(1,1),
	[Investor_Id] [int] NULL,
	[Investment_id] bigint NULL,
	[VALUE_ID] [int] NULL,
	[BAL_ACC] [int] NULL,
	[CLASS] [int] NULL,
	[AMOUNT] [numeric](28, 10) NULL,
	[BAL_SUMMA_RUR] [numeric](28, 10) NULL,
	[Bal_Delta] [numeric](28, 10) NULL,
	[NOMINAL] [numeric](28, 10) NULL,
	[RUR_PRICE] [numeric](28, 10) NULL,
	[Nom_Price] [numeric](28, 10) NULL,
	[VALUE_RUR] [numeric](28, 10) NULL,
	[VALUE_NOM] [numeric](28, 10) NULL,
	[CUR_ID] [int] NULL,
	[RATE] [numeric](28, 10) NULL,
	[RATE_DATE] [datetime] NULL,
	[RecordDate] DateTime2 CONSTRAINT DF_FundStructure_Last_RecordDate Default SysDateTime(),
CONSTRAINT [PK_FundStructure_Last] PRIMARY KEY CLUSTERED
(
	[Contract_Id] ASC,
	[PortfolioDate] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO