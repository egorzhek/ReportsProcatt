USE [CacheDB]
GO
CREATE TABLE [dbo].[InvestorDateAssets]
(
	[Investor_Id] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AssetsValue] [numeric](28, 7) NOT NULL,
CONSTRAINT [PK_InvestorDateAssets] PRIMARY KEY CLUSTERED
(
	[Investor_Id] ASC,
	[Date] ASC
)ON YEAR_Partition_Scheme ([Date])
)
GO
CREATE TABLE [dbo].[InvestorDateAssetsLast]
(
	[Investor_Id] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AssetsValue] [numeric](28, 7) NOT NULL,
CONSTRAINT [PK_InvestorDateAssetsLast] PRIMARY KEY CLUSTERED
(
	[Investor_Id] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[InvestorContractDateAssets]
(
	[Investor_Id] [int] NOT NULL,
	[Contract_Id] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AssetsValue] [numeric](28, 7) NOT NULL,
CONSTRAINT [PK_InvestorContractDateAssets] PRIMARY KEY CLUSTERED
(
	[Investor_Id] ASC,
	[Contract_Id] ASC,
	[Date] ASC
)ON YEAR_Partition_Scheme ([Date])
)
GO
CREATE TABLE [dbo].[InvestorContractDateAssetsLast]
(
	[Investor_Id] [int] NOT NULL,
	[Contract_Id] [int] NOT NULL,
	[Date] [date] NOT NULL,
	[AssetsValue] [numeric](28, 7) NOT NULL,
CONSTRAINT [PK_InvestorContractDateAssetsLast] PRIMARY KEY CLUSTERED
(
	[Investor_Id] ASC,
	[Contract_Id] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO