USE [CacheDB]
GO
CREATE TABLE [dbo].[InvestorFundDate]
(
	[Investor] [int] NOT NULL,
	[FundId] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AmountDay] [numeric](38, 10) NOT NULL,
	[SumAmount] [numeric](38, 10) NULL,
	[RATE] [numeric](38, 10) NULL,
	[USDRATE] [numeric](38, 10) NULL,
	[EVRORATE] [numeric](38, 10) NULL,
	[VALUE_RUR] [numeric](38, 10) NULL,
	[VALUE_USD] [numeric](38, 10) NULL,
	[VALUE_EVRO] [numeric](38, 10) NULL,
	[AmountDayPlus] [numeric](38, 10) NULL,
	[AmountDayPlus_RUR] [numeric](38, 10) NULL,
	[AmountDayPlus_USD] [numeric](38, 10) NULL,
	[AmountDayPlus_EVRO] [numeric](38, 10) NULL,
	[AmountDayMinus] [numeric](38, 10) NULL,
	[AmountDayMinus_RUR] [numeric](38, 10) NULL,
	[AmountDayMinus_USD] [numeric](38, 10) NULL,
	[AmountDayMinus_EVRO] [numeric](38, 10) NULL,
	[LS_NUM] NVarChar(120),
CONSTRAINT [PK_InvestorFundDate] PRIMARY KEY CLUSTERED
(
	[Investor] ASC,
	[FundId] ASC,
	[Date] ASC
)ON YEAR_Partition_Scheme ([Date])
)
GO
CREATE TABLE [dbo].[InvestorFundDateLast]
(
	[Investor] [int] NOT NULL,
	[FundId] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AmountDay] [numeric](38, 10) NOT NULL,
	[SumAmount] [numeric](38, 10) NULL,
	[RATE] [numeric](38, 10) NULL,
	[USDRATE] [numeric](38, 10) NULL,
	[EVRORATE] [numeric](38, 10) NULL,
	[VALUE_RUR] [numeric](38, 10) NULL,
	[VALUE_USD] [numeric](38, 10) NULL,
	[VALUE_EVRO] [numeric](38, 10) NULL,
	[AmountDayPlus] [numeric](38, 10) NULL,
	[AmountDayPlus_RUR] [numeric](38, 10) NULL,
	[AmountDayPlus_USD] [numeric](38, 10) NULL,
	[AmountDayPlus_EVRO] [numeric](38, 10) NULL,
	[AmountDayMinus] [numeric](38, 10) NULL,
	[AmountDayMinus_RUR] [numeric](38, 10) NULL,
	[AmountDayMinus_USD] [numeric](38, 10) NULL,
	[AmountDayMinus_EVRO] [numeric](38, 10) NULL,
	[LS_NUM] NVarChar(120),
CONSTRAINT [PK_InvestorFundDateLast] PRIMARY KEY CLUSTERED 
(
	[Investor] ASC,
	[FundId] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[FundNames]
(
	[Id] int NOT NULL,
	[Name] Nvarchar(300) NULL,
CONSTRAINT [PK_FundNames] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[ProcessorErrors]
(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Error] [nvarchar](max) NULL,
	[RecordDate] [datetime2] NOT NULL,
	[ContractId] [int] NULL,
	[Investor_id] [int] NULL,
CONSTRAINT [PK__ProcessorErrors__tid] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ProcessorErrors] ADD
CONSTRAINT [DF__ProcessorErrors__RecordDate]
DEFAULT SYSDATETIME() FOR [RecordDate]
GO