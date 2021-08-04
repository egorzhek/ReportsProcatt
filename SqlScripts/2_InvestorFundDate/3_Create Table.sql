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
	[PDate] [date] NULL,
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
CREATE TABLE [dbo].[OD_CALENDAR]
(
	[H_DATE] [datetime] NOT NULL,
	[MARKET] [int] NOT NULL,
CONSTRAINT [P_CALENDAR] PRIMARY KEY CLUSTERED
(
	[H_DATE] ASC,
	[MARKET] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[OBLIG_INFO]
(
	[SELF_ID] [int] NOT NULL,
	[SYSNAME] [nvarchar](64) NULL,
	[NAME] [nvarchar](255) NULL,
	[ISSUER] [int] NULL,
	[IssuerName] [nvarchar](255) NULL,
	[NUM_REG] [nvarchar](124) NULL,
	[ISIN] [nvarchar](12) NULL,
	[CFI] [nvarchar](12) NULL,
	[DATE_REG] [datetime] NULL,
	[COUNT_] [numeric](27, 7) NULL,
	[ISSUENUM] [int] NULL,
	[MNEM] [nvarchar](255) NULL,
	[BIRTHDATE] [datetime] NULL,
	[DEATHDATE] [datetime] NULL,
	[MODE] [int] NULL,
	[NOMINAL] [numeric](22, 8) NULL,
	[NOM_TYPE] [smallint] NULL,
	[NOM_VAL] [int] NULL,
	[TYPE_] [int] NULL,
	[IS_MARGIN] [smallint] NULL,
	[IS_MCS] [smallint] NULL,
	[STATUS] [smallint] NULL,
	[IS_EUR_BOND] [int] NULL,
	[IS_SAVE] [int] NULL,
	[IS_CONV] [int] NULL,
	[PERIOD] [int] NULL,
	[PERCENT_] [numeric](22, 8) NULL,
	[DAYS] [int] NULL,
	[PRICE] [numeric](22, 8) NULL,
	[PERIOD_M] [int] NULL,
	[STAVKA] [numeric](22, 8) NULL,
	[IS_GG] [int] NULL,
	[REP_DATE] [datetime] NULL,
	[NKD_MFU] [int] NULL,
	[P_MODEL] [int] NULL,
	[IS_IN] [smallint] NULL,
	[GUARANTOR] [int] NULL,
	[B_DATE] [datetime] NULL,
	[E_DATE] [datetime] NULL,
	[OP_NOLIQUID] [nvarchar](255) NULL,
	[VALUE_] [nvarchar](255) NULL,
CONSTRAINT [PK_OBLIG_INFO] PRIMARY KEY CLUSTERED
(
	[SELF_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO