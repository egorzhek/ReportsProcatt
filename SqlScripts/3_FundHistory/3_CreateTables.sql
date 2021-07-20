USE [CacheDB]
GO
CREATE TABLE [dbo].[FundHistory]
(
	Investor Int not null,
	FundId Int not null,
	W_ID Int not null,
	W_Date DateTime not null,
	Order_NUM NVarchar(200) NULL,
	WALK Int not null,
	TYPE smallint not null,
	RATE_RUR numeric(30, 10),
	Amount numeric(30, 10),
	VALUE_RUR numeric(30, 10),
	Fee_RUR numeric(30, 10),
CONSTRAINT [PK_FundHistory] PRIMARY KEY CLUSTERED
(
	[Investor] ASC,
	[FundId] ASC,
	[W_ID] ASC,
	[W_Date] ASC
)ON YEAR_Partition_Scheme_Time ([W_Date])
)
GO
CREATE TABLE [dbo].[FundHistoryLast]
(
	Investor Int not null,
	FundId Int not null,
	W_ID Int not null,
	W_Date DateTime not null,
	Order_NUM NVarchar(200) NULL,
	WALK Int not null,
	TYPE smallint not null,
	RATE_RUR numeric(30, 10),
	Amount numeric(30, 10),
	VALUE_RUR numeric(30, 10),
	Fee_RUR numeric(30, 10),
CONSTRAINT [PK_FundHistoryLast] PRIMARY KEY CLUSTERED
(
	[Investor] ASC,
	[FundId] ASC,
	[W_ID] ASC,
	[W_Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO