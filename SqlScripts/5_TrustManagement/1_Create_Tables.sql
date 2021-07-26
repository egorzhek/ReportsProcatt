USE [CacheDB]
GO
CREATE TABLE [dbo].[Assets_Contracts]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[Date] [date] NOT NULL,

	[USDRATE] [numeric](38, 10) NULL,
	[EURORATE] [numeric](38, 10) NULL,

	[VALUE_RUR] [numeric](38, 10) NULL,
	[VALUE_USD] [numeric](38, 10) NULL,
	[VALUE_EURO] [numeric](38, 10) NULL,

	[INPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[INPUT_VALUE_USD] [numeric](38, 10) NULL,
	[INPUT_VALUE_EURO] [numeric](38, 10) NULL,

	[OUTPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_USD] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_EURO] [numeric](38, 10) NULL,

	[INPUT_DIVIDENTS_RUR] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_USD] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_EURO] [numeric](38, 10) NULL,

	[INPUT_COUPONS_RUR] [numeric](38, 10) NULL,
	[INPUT_COUPONS_USD] [numeric](38, 10) NULL,
	[INPUT_COUPONS_EURO] [numeric](38, 10) NULL,

CONSTRAINT [PK_Assets_Contracts] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[Date] ASC
)ON YEAR_Partition_Scheme ([Date])
)
GO
CREATE TABLE [dbo].[Assets_ContractsLast]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[Date] [date] NOT NULL,

	[USDRATE] [numeric](38, 10) NULL,
	[EURORATE] [numeric](38, 10) NULL,

	[VALUE_RUR] [numeric](38, 10) NULL,
	[VALUE_USD] [numeric](38, 10) NULL,
	[VALUE_EURO] [numeric](38, 10) NULL,

	[INPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[INPUT_VALUE_USD] [numeric](38, 10) NULL,
	[INPUT_VALUE_EURO] [numeric](38, 10) NULL,

	[OUTPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_USD] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_EURO] [numeric](38, 10) NULL,

	[INPUT_DIVIDENTS_RUR] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_USD] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_EURO] [numeric](38, 10) NULL,

	[INPUT_COUPONS_RUR] [numeric](38, 10) NULL,
	[INPUT_COUPONS_USD] [numeric](38, 10) NULL,
	[INPUT_COUPONS_EURO] [numeric](38, 10) NULL,

CONSTRAINT [PK_Assets_ContractsLast] PRIMARY KEY CLUSTERED 
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[Assets_Info]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[DATE_OPEN] [date] NOT NULL,
	[NUM] [NVarchar](100) NOT NULL,
	[DATE_CLOSE] [date] NULL,
CONSTRAINT [PK_Assets_Info] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[DATE_OPEN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[Assets_Contracts_History]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[WIRING] [int] NOT NULL,
	[TYPE_] [smallint] NOT NULL,
	[PaymentDateTime] [datetime] NOT NULL,
	[Type] [int] NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[AmountPayments] [numeric](38, 10) NULL,
	[ShareName] NVarchar(300),
CONSTRAINT [PK_Assets_Contracts_History] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[WIRING] ASC,
	[TYPE_] ASC,
	[PaymentDateTime] ASC
)ON YEAR_Partition_Scheme_Time ([PaymentDateTime])
)
GO
CREATE TABLE [dbo].[Assets_Contracts_History_Last]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[WIRING] [int] NOT NULL,
	[TYPE_] [smallint] NOT NULL,
	[PaymentDateTime] [datetime] NOT NULL,
	[Type] [int] NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[AmountPayments] [numeric](38, 10) NULL,
	[ShareName] NVarchar(300),
CONSTRAINT [PK_Assets_Contracts_History_Last] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[WIRING] ASC,
	[TYPE_] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO