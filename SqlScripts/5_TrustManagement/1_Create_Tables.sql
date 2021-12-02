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

	[DailyIncrement_RUR] [numeric](38, 10) NULL,
	[DailyIncrement_USD] [numeric](38, 10) NULL,
	[DailyIncrement_EURO] [numeric](38, 10) NULL,

	[DailyDecrement_RUR] [numeric](38, 10) NULL,
	[DailyDecrement_USD] [numeric](38, 10) NULL,
	[DailyDecrement_EURO] [numeric](38, 10) NULL,

	[INPUT_DIVIDENTS_RUR] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_USD] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_EURO] [numeric](38, 10) NULL,

	[INPUT_COUPONS_RUR] [numeric](38, 10) NULL,
	[INPUT_COUPONS_USD] [numeric](38, 10) NULL,
	[INPUT_COUPONS_EURO] [numeric](38, 10) NULL,

	[INPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[INPUT_VALUE_USD] [numeric](38, 10) NULL,
	[INPUT_VALUE_EURO] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_USD] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_EURO] [numeric](38, 10) NULL,

CONSTRAINT [PK_Assets_Contracts] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[Date] ASC
)ON YEAR_Partition_Scheme ([Date])
)
GO
CREATE NONCLUSTERED INDEX [IX_Assets_Contracts_Date]
ON [dbo].[Assets_Contracts] ([Date])
INCLUDE ([USDRATE],[EURORATE])
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

	[DailyIncrement_RUR] [numeric](38, 10) NULL,
	[DailyIncrement_USD] [numeric](38, 10) NULL,
	[DailyIncrement_EURO] [numeric](38, 10) NULL,

	[DailyDecrement_RUR] [numeric](38, 10) NULL,
	[DailyDecrement_USD] [numeric](38, 10) NULL,
	[DailyDecrement_EURO] [numeric](38, 10) NULL,

	[INPUT_DIVIDENTS_RUR] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_USD] [numeric](38, 10) NULL,
	[INPUT_DIVIDENTS_EURO] [numeric](38, 10) NULL,

	[INPUT_COUPONS_RUR] [numeric](38, 10) NULL,
	[INPUT_COUPONS_USD] [numeric](38, 10) NULL,
	[INPUT_COUPONS_EURO] [numeric](38, 10) NULL,

	[INPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[INPUT_VALUE_USD] [numeric](38, 10) NULL,
	[INPUT_VALUE_EURO] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_RUR] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_USD] [numeric](38, 10) NULL,
	[OUTPUT_VALUE_EURO] [numeric](38, 10) NULL,

CONSTRAINT [PK_Assets_ContractsLast] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Assets_ContractsLast_Date]
ON [dbo].[Assets_ContractsLast] ([Date])
INCLUDE ([USDRATE],[EURORATE])
GO
CREATE TABLE [dbo].[Assets_Info]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[DATE_OPEN] [date] NOT NULL,
	[NUM] [NVarchar](100) NOT NULL,
	[DATE_CLOSE] [date] NULL,
	[strategyguid] [uniqueidentifier] NULL,
	[laststrategyupdate] [datetime] NULL,
CONSTRAINT [PK_Assets_Info] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[DATE_OPEN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Assets_Info_NUM] ON [dbo].[Assets_Info]
(
	[NUM] ASC
)
GO
CREATE NONCLUSTERED INDEX [IX_Assets_Info_strategyguid] ON [dbo].[Assets_Info]
(
	[strategyguid] ASC
)
GO
CREATE TABLE [dbo].[DIVIDENDS_AND_COUPONS_History]
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
	[USDRATE] [numeric](38, 10) NULL,
	[EURORATE] [numeric](38, 10) NULL,
	[AmountPayments_RUR] [numeric](38, 10) NULL,
	[AmountPayments_USD] [numeric](38, 10) NULL,
	[AmountPayments_EURO] [numeric](38, 10) NULL,
CONSTRAINT [PK_DIVIDENDS_AND_COUPONS_History] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[WIRING] ASC,
	[TYPE_] ASC,
	[PaymentDateTime] ASC
)ON YEAR_Partition_Scheme_Time ([PaymentDateTime])
)
GO
CREATE TABLE [dbo].[DIVIDENDS_AND_COUPONS_History_Last]
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
	[USDRATE] [numeric](38, 10) NULL,
	[EURORATE] [numeric](38, 10) NULL,
	[AmountPayments_RUR] [numeric](38, 10) NULL,
	[AmountPayments_USD] [numeric](38, 10) NULL,
	[AmountPayments_EURO] [numeric](38, 10) NULL,
CONSTRAINT [PK_DIVIDENDS_AND_COUPONS_History_Last] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[WIRING] ASC,
	[TYPE_] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[Operations_History_Contracts]
(
	[Id] BigInt Identity(1,1),
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[Date] [datetime] NOT NULL,
	[Type] [int] NULL,
	[T_Name] NVarchar(300),
	[ISIN] NVarchar(50),
	[Investment] NVarchar(300),
	[Price] [numeric](38, 7) NULL,
	[Amount] [numeric](38, 7) NULL,
	[Value_Nom] [numeric](38, 7) NULL,
	[Currency] [int] NULL,
	[Fee] [numeric](38, 7),
	[PaperId] [int] NULL,
CONSTRAINT [PK_Operations_History_Contracts] PRIMARY KEY CLUSTERED
(
	[Id] ASC,
	[Date] ASC
)ON YEAR_Partition_Scheme_Time ([Date])
)
GO
CREATE NONCLUSTERED INDEX [IX_Operations_History_Contracts]
ON [dbo].[Operations_History_Contracts] ([InvestorId],[ContractId])
GO
CREATE NONCLUSTERED INDEX [IX_Operations_History_Contracts_PaperId]
ON [dbo].[Operations_History_Contracts] ([PaperId])
GO
CREATE TABLE [dbo].[Operations_History_Contracts_Last]
(
	[Id] BigInt Identity(1,1),
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[Date] [datetime] NOT NULL,
	[Type] [int] NULL,
	[T_Name] NVarchar(300),
	[ISIN] NVarchar(50),
	[Investment] NVarchar(300),
	[Price] [numeric](38, 7) NULL,
	[Amount] [numeric](38, 7) NULL,
	[Value_Nom] [numeric](38, 7) NULL,
	[Currency] [int] NULL,
	[Fee] [numeric](38, 7),
	[PaperId] [int] NULL,
CONSTRAINT [PK_Operations_History_Contracts_Last] PRIMARY KEY CLUSTERED
(
	[Id] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_Operations_History_Contracts_Last]
ON [dbo].[Operations_History_Contracts_Last] ([InvestorId],[ContractId])
GO
CREATE NONCLUSTERED INDEX [IX_Operations_History_Contracts_Last_PaperId]
ON [dbo].[Operations_History_Contracts_Last] ([PaperId])
GO
CREATE TABLE [dbo].[InvestmentIds]
(
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Investment] [nvarchar](500) NOT NULL,
	[RecordDate] [datetime2](7) NULL,
CONSTRAINT [PK__InvestmentIds__Id] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
CONSTRAINT [AK_Investment] UNIQUE NONCLUSTERED
(
	[Investment] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[InvestmentIds] ADD
CONSTRAINT [DF_InvestmentIds_RecordDate]
DEFAULT (sysdatetime()) FOR [RecordDate]
GO
CREATE TABLE [dbo].[PortFolio_Daily_Before]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[WIRING_ID] [int] NOT NULL,
	[WIRDATE] [date] NOT NULL,
	[S_DATE] [datetime] NOT NULL,
	[NUM] [NVarchar](200) NULL,
	[Value] [numeric](38, 10) NULL,
CONSTRAINT [PK_PortFolio_Daily_Before] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[WIRING_ID] ASC,
	[WIRDATE] ASC
)ON YEAR_Partition_Scheme ([WIRDATE])
)
GO
CREATE TABLE [dbo].[PortFolio_Daily]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[PortfolioDate] [date] NOT NULL,
	[Id] BigInt Identity(1,1),
	[InvestmentId] BigInt NULL,
	[VALUE_ID] [int] NULL,
	[BAL_ACC] [int] NULL,
	[CLASS] [int] NULL,
	[AMOUNT] [numeric](38, 10) NULL,
	[S_BAL_SUMMA_RUR] [numeric](38, 10)NULL,
	[NOMINAL] [numeric](38, 10) NULL,
	[RUR_PRICE] [numeric](38, 10) NULL,
	[Nom_Price] [numeric](38, 10) NULL,
	[VALUE_RUR] [numeric](38, 10) NULL,
	[VALUE_NOM] [numeric](38, 10) NULL,
	[CUR_ID] [int] NULL,
	[CUR_NAME] [Nvarchar](200) NULL,
	[RATE] [numeric](38, 10) NULL,
	[RATE_DATE] [datetime] NULL,
	[BAL_SUMMA] [numeric](38, 10) NULL,
	[RecordDate] DateTime2 CONSTRAINT DF_PortFolio_Daily_RecordDate Default SysDateTime(),
CONSTRAINT [PK_PortFolio_Daily] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[PortfolioDate] ASC,
	[Id] ASC
)ON YEAR_Partition_Scheme ([PortfolioDate])
)
GO
CREATE NONCLUSTERED INDEX [IX_PortFolio_Daily_CP]
ON [dbo].[PortFolio_Daily] ([ContractId],[PortfolioDate])
GO
CREATE NONCLUSTERED INDEX [IX_PortFolio_Daily_IP]
ON [dbo].[PortFolio_Daily] ([InvestorId],[PortfolioDate])
GO
CREATE TABLE [dbo].[PortFolio_Daily_Last]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[PortfolioDate] [date] NOT NULL,
	[Id] BigInt Identity(1,1),
	[InvestmentId] BigInt NULL,
	[VALUE_ID] [int] NULL,
	[BAL_ACC] [int] NULL,
	[CLASS] [int] NULL,
	[AMOUNT] [numeric](38, 10) NULL,
	[S_BAL_SUMMA_RUR] [numeric](38, 10)NULL,
	[NOMINAL] [numeric](38, 10) NULL,
	[RUR_PRICE] [numeric](38, 10) NULL,
	[Nom_Price] [numeric](38, 10) NULL,
	[VALUE_RUR] [numeric](38, 10) NULL,
	[VALUE_NOM] [numeric](38, 10) NULL,
	[CUR_ID] [int] NULL,
	[CUR_NAME] [Nvarchar](200) NULL,
	[RATE] [numeric](38, 10) NULL,
	[RATE_DATE] [datetime] NULL,
	[BAL_SUMMA] [numeric](38, 10) NULL,
	[RecordDate] DateTime2 CONSTRAINT DF_PortFolio_Daily_Last_RecordDate Default SysDateTime(),
CONSTRAINT [PK_PortFolio_Daily_Last] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[PortfolioDate] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_PortFolio_Daily_Last_CP]
ON [dbo].[PortFolio_Daily_Last] ([ContractId],[PortfolioDate])
GO
CREATE NONCLUSTERED INDEX [IX_PortFolio_Daily_Last_IP]
ON [dbo].[PortFolio_Daily_Last] ([InvestorId],[PortfolioDate])
GO
CREATE TABLE [dbo].[Categories]
(
	Id Int NOT NULL,
	CategoryName Nvarchar(100),
CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT INTO [dbo].[Categories](Id, CategoryName) VALUES (1, N'Акции')
GO
INSERT INTO [dbo].[Categories](Id, CategoryName) VALUES (2, N'Облигации')
GO
INSERT INTO [dbo].[Categories](Id, CategoryName) VALUES (3, N'Вексели')
GO
INSERT INTO [dbo].[Categories](Id, CategoryName) VALUES (4, N'Денежные средства')
GO
INSERT INTO [dbo].[Categories](Id, CategoryName) VALUES (5, N'Фонды')
GO
INSERT INTO [dbo].[Categories](Id, CategoryName) VALUES (6, N'Деривативы')
GO
CREATE TABLE [dbo].[ClassCategories]
(
	ClassId Int NOT NULL,
	CategoryId Int NOT NULL,
CONSTRAINT [PK_ClassCategories] PRIMARY KEY CLUSTERED
(
	[ClassId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (1, 1)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (2, 2)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (3, 3)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (4, 6)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (5, 6)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (7, 1)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (10, 5)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (100, 4)
GO
INSERT INTO [dbo].[ClassCategories] (ClassId, CategoryId ) VALUES (101, 4)
GO
CREATE TABLE [dbo].[Currencies]
(
	Id Int NOT NULL,
	CurrencyName Nvarchar(50) NOT NULL,
	Symbol Nvarchar(10) NOT NULL,
	ShortName Nvarchar(10) NOT NULL,
CONSTRAINT [PK_Currencies] PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (1, N'Российский рубль', N'₽', N'RUB')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (2, N'Доллар', N'$', N'USD')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (5, N'Евро', N'€', N'EUR')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (6, N'Фунт стерлингов', N'£', N'GBP')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (10, N'Канадский доллар', N'С$', N'CAD')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (15, N'Йена', N'¥', N'JPY')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (17, N'Норвежская крона', N'kr', N'NOK')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (18, N'Шведская крона', N'SEK', N'SEK')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (19, N'Швейцарский франк', N'₣', N'CHF')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (2464116, N'Гонконгский доллар', N'HK$', N'HKD')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (13376767, N'Австралийский доллар', N'A$', N'AUD')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (13657213, N'Белорусский рубль', N'Br', N'BYN')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (13912287, N'Китайский Юань', N'元', N'CNY')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (24609515, N'Новый израильский шекель', N'₪', N'ILS')
GO
INSERT INTO [dbo].[Currencies] (Id, CurrencyName, Symbol, ShortName)
VALUES (24646045, N'Новый тайваньский доллар', N'NT$', N'TWD')
GO
CREATE TABLE [dbo].[POSITION_KEEPING]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[ShareId] [int] NOT NULL,
	[Fifo_Date] [date] NOT NULL,
	[Id] BigInt Identity(1,1),
	[ISIN] [nvarchar](12) NULL,
	[Class] [int] NULL,
	[InstrumentId] [bigint] NOT NULL,
	[CUR_ID] [int] NULL,
	[Oblig_Date_end] [date] NULL,
	[Oferta_Date] [date] NULL,
	[Oferta_Type] [nvarchar](300) NULL,
	[IsActive] [bit] NULL,
	[In_Wir] [int] NULL,
	[In_Date] [date] NULL,
	[Ic_NameId] [bigint] NULL,
	[Il_Num] [int] NULL,
	[In_Dol] [int] NULL,
	[Ir_Trans] [nvarchar](300) NULL,
	[Amount] [decimal](20, 7) NULL,
	[In_Summa] [decimal](20, 7) NULL,
	[In_Eq] [decimal](20, 7) NULL,
	[In_Comm] [decimal](20, 7) NULL,
	[In_Price] [decimal](20, 7) NULL,
	[In_Price_eq] [decimal](20, 7) NULL,
	[IN_PRICE_UKD] [decimal](20, 7) NULL,
	[Today_PRICE] [decimal](20, 7) NULL,
	[Value_NOM] [decimal](20, 7) NULL,
	[Dividends] [decimal](20, 7) NULL,
	[UKD] [decimal](20, 7) NULL,
	[NKD] [decimal](20, 7) NULL,
	[Amortizations] [decimal](20, 7) NULL,
	[Coupons] [decimal](20, 7) NULL,
	[Out_Wir] [int] NULL,
	[Out_Date] [datetime] NULL,
	[Od_Id] [int] NULL,
	[Oc_NameId] [bigint] NULL,
	[Ol_Num] [int] NULL,
	[Out_Dol] [int] NULL,
	[OutPrice] [decimal](20,7),
	[Out_Summa] [decimal](20, 7) NULL,
	[Out_Eq] [decimal](20, 7) NULL,
	[RecordDate] DateTime2 CONSTRAINT DF_POSITION_KEEPING_RecordDate Default SysDateTime(),
CONSTRAINT [PK_POSITION_KEEPING] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[ShareId] ASC,
	[Fifo_Date] ASC,
	[Id] ASC
)ON YEAR_Partition_Scheme ([Fifo_Date])
)
GO
CREATE NONCLUSTERED INDEX [IX_POSITION_KEEPING_Fifo_Date] ON [dbo].[POSITION_KEEPING]
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[Fifo_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
GO
CREATE TABLE [dbo].[POSITION_KEEPING_Last]
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[ShareId] [int] NOT NULL,
	[Fifo_Date] [date] NOT NULL,
	[Id] BigInt Identity(1,1),
	[ISIN] [nvarchar](12) NULL,
	[Class] [int] NULL,
	[InstrumentId] [bigint] NOT NULL,
	[CUR_ID] [int] NULL,
	[Oblig_Date_end] [date] NULL,
	[Oferta_Date] [date] NULL,
	[Oferta_Type] [nvarchar](300) NULL,
	[IsActive] [bit] NULL,
	[In_Wir] [int] NULL,
	[In_Date] [date] NULL,
	[Ic_NameId] [bigint] NULL,
	[Il_Num] [int] NULL,
	[In_Dol] [int] NULL,
	[Ir_Trans] [nvarchar](300) NULL,
	[Amount] [decimal](20, 7) NULL,
	[In_Summa] [decimal](20, 7) NULL,
	[In_Eq] [decimal](20, 7) NULL,
	[In_Comm] [decimal](20, 7) NULL,
	[In_Price] [decimal](20, 7) NULL,
	[In_Price_eq] [decimal](20, 7) NULL,
	[IN_PRICE_UKD] [decimal](20, 7) NULL,
	[Today_PRICE] [decimal](20, 7) NULL,
	[Value_NOM] [decimal](20, 7) NULL,
	[Dividends] [decimal](20, 7) NULL,
	[UKD] [decimal](20, 7) NULL,
	[NKD] [decimal](20, 7) NULL,
	[Amortizations] [decimal](20, 7) NULL,
	[Coupons] [decimal](20, 7) NULL,
	[Out_Wir] [int] NULL,
	[Out_Date] [datetime] NULL,
	[Od_Id] [int] NULL,
	[Oc_NameId] [bigint] NULL,
	[Ol_Num] [int] NULL,
	[Out_Dol] [int] NULL,
	[OutPrice] [decimal](20,7),
	[Out_Summa] [decimal](20, 7) NULL,
	[Out_Eq] [decimal](20, 7) NULL,
	[RecordDate] DateTime2 CONSTRAINT DF_POSITION_KEEPING_Last_RecordDate Default SysDateTime(),
CONSTRAINT [PK_POSITION_KEEPING_Last] PRIMARY KEY CLUSTERED
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[ShareId] ASC,
	[Fifo_Date] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_POSITION_KEEPING_Fifo_Date_Last] ON [dbo].[POSITION_KEEPING_Last]
(
	[InvestorId] ASC,
	[ContractId] ASC,
	[Fifo_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE SEQUENCE ApplCycle
   AS int
    START WITH 500
    INCREMENT BY 1
    MINVALUE 500
    MAXVALUE 2100000000
    CYCLE;
GO