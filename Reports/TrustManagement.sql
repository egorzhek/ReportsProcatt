DECLARE @ToDateStr     Nvarchar(50) = @DateToSharp;
DECLARE @FromDateStr   Nvarchar(50) = @DateFromSharp;
DECLARE @InvestorIdStr Nvarchar(50) = @InvestorIdSharp;
DECLARE @ContractIdStr Nvarchar(50) = @ContractIdSharp;
DECLARE @Valuta        Nvarchar(10) = @ValutaSharp;

if @Valuta is null set @Valuta = 'RUB';

DECLARE
    @InvestorId int = CAST(@InvestorIdStr as Int),
    @ContractId int = CAST(@ContractIdStr as Int),
    @StartDate Date = CONVERT(Date, @FromDateStr, 103),
    @EndDate Date = CONVERT(Date, @ToDateStr, 103);

declare @MinDate date, @MaxDate date

Declare @SItog numeric(30,10), @AmountDayMinus_RUR numeric(30,10), @Snach numeric(30,10), @AmountDayPlus_RUR numeric(30,10),
@Sum_INPUT_VALUE_RUR  numeric(30,10),
@Sum_OUTPUT_VALUE_RUR numeric(30,10),
@Sum_INPUT_COUPONS_RUR numeric(30,10),
@Sum_INPUT_DIVIDENTS_RUR numeric(30,10),
@InvestResult numeric(30,10);

SELECT
	@MinDate = min([Date]),
	@MaxDate = max([Date])
FROM
(
	SELECT [Date]
	FROM [CacheDB].[dbo].[Assets_Contracts] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
	UNION
	SELECT [Date]
	FROM [CacheDB].[dbo].[Assets_ContractsLast] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
) AS R

if @StartDate is null set @StartDate = @MinDate;
if @StartDate < @MinDate set @StartDate = @MinDate;
if @StartDate > @MaxDate set @StartDate = @MinDate;

if @EndDate is null    set @EndDate = @MaxDate;
if @EndDate > @MaxDate set @EndDate = @MaxDate;
if @EndDate < @MinDate set @EndDate = @MaxDate;

BEGIN TRY
	DROP TABLE #ResInvAssets
END TRY
BEGIN CATCH
END CATCH;


SELECT *
INTO #ResInvAssets
FROM
(
	SELECT
		InvestorId, ContractId, Date,
		USDRATE, EURORATE,
		VALUE_RUR =
		case
			when @Valuta = 'RUB' then VALUE_RUR
			when @Valuta = 'USD' then VALUE_USD
			when @Valuta = 'EUR' then VALUE_EURO
			else VALUE_RUR
		end,
			VALUE_USD, VALUE_EURO,
		DailyIncrement_RUR =
		case
			when @Valuta = 'RUB' then DailyIncrement_RUR
			when @Valuta = 'USD' then DailyIncrement_USD
			when @Valuta = 'EUR' then DailyIncrement_EURO
			else DailyIncrement_RUR
		end,
			DailyIncrement_USD, DailyIncrement_EURO,
		DailyDecrement_RUR =
		case
			when @Valuta = 'RUB' then DailyDecrement_RUR
			when @Valuta = 'USD' then DailyDecrement_USD
			when @Valuta = 'EUR' then DailyDecrement_EURO
			else DailyDecrement_RUR
		end,
			DailyDecrement_USD, DailyDecrement_EURO,
		INPUT_DIVIDENTS_RUR =
		case
			when @Valuta = 'RUB' then INPUT_DIVIDENTS_RUR
			when @Valuta = 'USD' then INPUT_DIVIDENTS_USD
			when @Valuta = 'EUR' then INPUT_DIVIDENTS_EURO
			else INPUT_DIVIDENTS_RUR
		end,
			INPUT_DIVIDENTS_USD, INPUT_DIVIDENTS_EURO,
		INPUT_COUPONS_RUR =
		case
			when @Valuta = 'RUB' then INPUT_COUPONS_RUR
			when @Valuta = 'USD' then INPUT_COUPONS_USD
			when @Valuta = 'EUR' then INPUT_COUPONS_EURO
			else INPUT_COUPONS_RUR
		end,
			INPUT_COUPONS_USD, INPUT_COUPONS_EURO,
		INPUT_VALUE_RUR =
		case
			when @Valuta = 'RUB' then INPUT_VALUE_RUR
			when @Valuta = 'USD' then INPUT_VALUE_USD
			when @Valuta = 'EUR' then INPUT_VALUE_EURO
			else INPUT_VALUE_RUR
		end,
			INPUT_VALUE_USD, INPUT_VALUE_EURO,
		OUTPUT_VALUE_RUR =
		case
			when @Valuta = 'RUB' then OUTPUT_VALUE_RUR
			when @Valuta = 'USD' then OUTPUT_VALUE_USD
			when @Valuta = 'EUR' then OUTPUT_VALUE_EURO
			else OUTPUT_VALUE_RUR
		end,
			OUTPUT_VALUE_USD, OUTPUT_VALUE_EURO
	FROM [CacheDB].[dbo].[Assets_Contracts] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
	UNION
	SELECT
		InvestorId, ContractId, Date,
		USDRATE, EURORATE,
		VALUE_RUR =
		case
			when @Valuta = 'RUB' then VALUE_RUR
			when @Valuta = 'USD' then VALUE_USD
			when @Valuta = 'EUR' then VALUE_EURO
			else VALUE_RUR
		end,
			VALUE_USD, VALUE_EURO,
		DailyIncrement_RUR =
		case
			when @Valuta = 'RUB' then DailyIncrement_RUR
			when @Valuta = 'USD' then DailyIncrement_USD
			when @Valuta = 'EUR' then DailyIncrement_EURO
			else DailyIncrement_RUR
		end,
			DailyIncrement_USD, DailyIncrement_EURO,
		DailyDecrement_RUR =
		case
			when @Valuta = 'RUB' then DailyDecrement_RUR
			when @Valuta = 'USD' then DailyDecrement_USD
			when @Valuta = 'EUR' then DailyDecrement_EURO
			else DailyDecrement_RUR
		end,
			DailyDecrement_USD, DailyDecrement_EURO,
		INPUT_DIVIDENTS_RUR =
		case
			when @Valuta = 'RUB' then INPUT_DIVIDENTS_RUR
			when @Valuta = 'USD' then INPUT_DIVIDENTS_USD
			when @Valuta = 'EUR' then INPUT_DIVIDENTS_EURO
			else INPUT_DIVIDENTS_RUR
		end,
			INPUT_DIVIDENTS_USD, INPUT_DIVIDENTS_EURO,
		INPUT_COUPONS_RUR =
		case
			when @Valuta = 'RUB' then INPUT_COUPONS_RUR
			when @Valuta = 'USD' then INPUT_COUPONS_USD
			when @Valuta = 'EUR' then INPUT_COUPONS_EURO
			else INPUT_COUPONS_RUR
		end,
			INPUT_COUPONS_USD, INPUT_COUPONS_EURO,
		INPUT_VALUE_RUR =
		case
			when @Valuta = 'RUB' then INPUT_VALUE_RUR
			when @Valuta = 'USD' then INPUT_VALUE_USD
			when @Valuta = 'EUR' then INPUT_VALUE_EURO
			else INPUT_VALUE_RUR
		end,
			INPUT_VALUE_USD, INPUT_VALUE_EURO,
		OUTPUT_VALUE_RUR =
		case
			when @Valuta = 'RUB' then OUTPUT_VALUE_RUR
			when @Valuta = 'USD' then OUTPUT_VALUE_USD
			when @Valuta = 'EUR' then OUTPUT_VALUE_EURO
			else OUTPUT_VALUE_RUR
		end,
			OUTPUT_VALUE_USD, OUTPUT_VALUE_EURO
	FROM [CacheDB].[dbo].[Assets_ContractsLast] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
) AS R
WHERE [Date] >= @StartDate and [Date] <= @EndDate
--ORDER BY [Date]


--select * From #ResInvAssets
--order by [Date];

-----------------------------------------------
-- �������������� �� ��������� � ��������� ����

-- ������ ����� ������ �� ������ ����
update #ResInvAssets set
	DailyIncrement_RUR = 0, DailyIncrement_USD = 0,	DailyIncrement_EURO = 0,
	DailyDecrement_RUR = 0,	DailyDecrement_USD = 0,	DailyDecrement_EURO = 0,
	INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
	INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
	INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
where [Date] = @StartDate
and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- ����� � ������ ���� � ���� ����

-- ��������� ��������� ���� �������
update a set 
VALUE_RUR = VALUE_RUR - DailyIncrement_RUR - DailyDecrement_RUR,
VALUE_USD = VALUE_USD - DailyIncrement_USD - DailyDecrement_USD,
VALUE_EURO = VALUE_EURO - DailyIncrement_EURO - DailyDecrement_EURO,

DailyIncrement_RUR = 0, DailyIncrement_USD = 0,	DailyIncrement_EURO = 0,
DailyDecrement_RUR = 0,	DailyDecrement_USD = 0,	DailyDecrement_EURO = 0,
INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
from #ResInvAssets as a
where [Date] = @EndDate
and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- ����� � ������ ���� � ���� ����

-- �������������� �� ��������� � ��������� ����
-----------------------------------------------

--select * From #ResInvAssets
--where OUTPUT_VALUE_RUR <> 0
--order by [Date];

-- � ������

-- �������� ������ ����������

SELECT
	@SItog = VALUE_RUR
FROM #ResInvAssets
where [Date] = @EndDate

SELECT
	@Snach = VALUE_RUR
FROM #ResInvAssets
where [Date] = @StartDate



-- ����� ���� ������� �������
SELECT
	@AmountDayMinus_RUR = sum(OUTPUT_VALUE_RUR), -- ������������� ��������
	@AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR),
	@Sum_INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
	@Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
	@Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
	@Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
FROM #ResInvAssets

--select @SItog as '@SItog', @Snach as '@Snach', @OUTPUT_VALUE_RUR as '@OUTPUT_VALUE_RUR', @AmountDayPlus_RUR as '@AmountDayPlus_RUR'

set @InvestResult =
(@SItog - @AmountDayMinus_RUR) -- �����, ������ ��� ������������� ��������
- (@Snach + @AmountDayPlus_RUR) --as '��������� ����������'

/*
		SELECT --*
			[Date],
			[AmountDayPlus_RUR] = INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR,
			[AmountDayMinus_RUR] = OUTPUT_VALUE_RUR
		FROM #ResInvAssets
		where (
			[Date] in (@StartDate, @EndDate) or
			(
				INPUT_VALUE_RUR <> 0 or OUTPUT_VALUE_RUR <> 0 or
				INPUT_DIVIDENTS_RUR <> 0 or INPUT_COUPONS_RUR <> 0
			)
		)
		order by [Date]
*/
	declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
		@SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0

	declare obj_cur cursor local fast_forward for
		-- 
		SELECT --*
			[Date],
			[AmountDayPlus_RUR] = INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR,
			[AmountDayMinus_RUR] = OUTPUT_VALUE_RUR
		FROM #ResInvAssets
		where (
			[Date] in (@StartDate, @EndDate) or
			(
				INPUT_VALUE_RUR <> 0 or OUTPUT_VALUE_RUR <> 0 or
				INPUT_DIVIDENTS_RUR <> 0 or INPUT_COUPONS_RUR <> 0
			)
		)
		order by [Date]
	open obj_cur
	fetch next from obj_cur into
		@DateCur, @AmountDayPlus_RUR, @AmountDayMinus_RUR
	while(@@fetch_status = 0)
	begin
		set @Counter += 1;

		-- ��������� ���� ����������
		if @DateCur = @StartDate
		begin
			set @LastDate = @DateCur
		end
		else
		begin
			-- �� ������ ������ ���������� ������
			set @T = DATEDIFF(DAY, @LastDate, @DateCur);
			if @DateCur = @EndDate set @T = @T + 1;

			set @ResutSum += @T * (@Snach + @SumAmountDay_RUR)

			set @LastDate = @DateCur
			set @SumAmountDay_RUR = @SumAmountDay_RUR + @AmountDayPlus_RUR + @AmountDayMinus_RUR

			set @SumT += @T;
		end

		fetch next from obj_cur into
			@DateCur, @AmountDayPlus_RUR, @AmountDayMinus_RUR
	end
	close obj_cur
	deallocate obj_cur


	if @SumT > 0
	begin
		set @ResutSum = @ResutSum/@SumT
	end

	--select
	--@InvestResult as '��������� ����������',
	--@ResutSum as '���������������� ����� ��������� �������',
	--@InvestResult/@ResutSum * 100 as '���������� � %',
	--@InvestResult as '���������� ����������',
	--@StartDate as '���� ������',
	--@EndDate as '���� ����������',
	--@SumT as '���������� ����'

Declare @DATE_OPEN date, @NUM Nvarchar(100);

select
	@DATE_OPEN = DATE_OPEN,
	@NUM = NUM
from [CacheDB].[dbo].[Assets_Info] NOLOCK
where [InvestorId] = @InvestorId and [ContractId] = @ContractId;

select
	ActiveDateToName = '������ �� ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ActiveDateToValue =  CAST(Round(@SItog,2) as Decimal(30,2)),
	ProfitName = '����� �� ������ ' + FORMAT(@StartDate,'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ProfitValue = CAST(Round(@InvestResult,2) as Decimal(30,2)),
	ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
	OpenDate = @DATE_OPEN,
	LS_NUM = '2940000083',
	EndSumAmount = 99999.99,
	FundName = @NUM,
	InvestorName = @NUM,
	ContractNumber = @NUM,
	Fee = 99.99,
	ContractOpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	SuccessFee = 99.99,
	DateFromName = FORMAT(@StartDate,'dd.MM.yyyy'),
	ParamValuta = @Valuta;

select ActiveName = '������ �� ' + FORMAT(@StartDate,'dd.MM.yyyy') , ActiveValue = CAST(Round(@Snach,2) as Decimal(38,2)), Sort = 1
union
select '����������', CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)), 2
union
select '������', CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)), 3
union
select '���������', @Sum_INPUT_DIVIDENTS_RUR, 4
union
select '������', @Sum_INPUT_COUPONS_RUR, 5
order by 3


if exists
(
	select top 1 1 from #ResInvAssets
)
begin
	SELECT
		[Date], [RATE] = VALUE_RUR
	FROM #ResInvAssets
	order by [Date]
end
else
begin
	select [Date] = cast(GETDATE() as date), [RATE] = 0
end



select ActiveName = '������ �� ' + FORMAT(@StartDate,'dd.MM.yyyy') , ActiveValue = CAST(Round(@Snach,2) as Decimal(38,2)),
[InVal] = CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)), 
[OutVal] = CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)), 
[Dividends] = @Sum_INPUT_DIVIDENTS_RUR, 
[Coupons] = @Sum_INPUT_COUPONS_RUR


-- ���������, ������ - ������
select
	[Date],
	[Dividends] = [INPUT_DIVIDENTS_RUR],
	[Coupons] = [INPUT_COUPONS_RUR]
From #ResInvAssets
where INPUT_DIVIDENTS_RUR <> 0 or INPUT_DIVIDENTS_USD <> 0 
order by [Date];

-- ����������� ������� � ����������
select
	[Date] = FORMAT([PaymentDateTime],'dd.MM.yyyy'),
	[ToolName] = [ShareName],
	[PriceType] = case when [Type] = 1 then '������' else '���������' end,
	[ContractName] = [ShareName],
	[Price] = CAST(Round([AmountPayments_RUR],2) as Decimal(30,2)),
	[PaymentDateTime]
from [CacheDB].[dbo].[DIVIDENDS_AND_COUPONS_History]
where InvestorId = @InvestorId and ContractId = @ContractId
union all
select
	[Date] =  FORMAT([PaymentDateTime],'dd.MM.yyyy'),
	[ToolName] = [ShareName],
	[PriceType] = case when [Type] = 1 then '������' else '���������' end,
	[ContractName] = [ShareName],
	[Price] = CAST(Round([AmountPayments_RUR],2) as Decimal(30,2)),
	[PaymentDateTime]
from [CacheDB].[dbo].[DIVIDENDS_AND_COUPONS_History_Last]
where InvestorId = @InvestorId and ContractId = @ContractId
order by [PaymentDateTime];


select
	[Date] = FORMAT([Date], 'dd.MM.yyyy'),
	[OperName] = T_Name,
	[ISIN],
	[ToolName] = Investment,
	[Price] = CAST(Round([Price],2) as Decimal(30,2)),
	[PaperAmount] = CAST(Round([Amount],2) as Decimal(30,2)),
	[Valuta] =
		case
			when [Currency] = 1 then N'?'
			when [Currency] = 2 then N'$'
			when [Currency] = 5 then N'�'
			else N'?'
		end,
	[Cost] = CAST(Round([Value_Nom],2) as Decimal(30,2)),
	[Fee] = CAST(Round([Fee],2) as Decimal(30,2)),
	[Status] = N''
from [CacheDB].[dbo].[Operations_History_Contracts]
where InvestorId = @InvestorId and ContractId = @ContractId
union
select
	[Date] = FORMAT([Date], 'dd.MM.yyyy'),
	[OperName] = T_Name,
	[ISIN],
	[ToolName] = Investment,
	[Price] = CAST(Round([Price],2) as Decimal(30,2)),
	[PaperAmount] = CAST(Round([Amount],2) as Decimal(30,2)),
	[Valuta] =
		case
			when [Currency] = 1 then N'?'
			when [Currency] = 2 then N'$'
			when [Currency] = 5 then N'�'
			else N'?'
		end,
	[Cost] = CAST(Round([Value_Nom],2) as Decimal(30,2)),
	[Fee] = CAST(Round([Fee],2) as Decimal(30,2)),
	[Status] = N''
from [CacheDB].[dbo].[Operations_History_Contracts_Last]
where InvestorId = @InvestorId and ContractId = @ContractId
order by [Date];


BEGIN TRY
	drop table #TrustTree;
END TRY
BEGIN CATCH
END CATCH;


select *
INTO #TrustTree
from
(
	select * 
	from [CacheDB].[dbo].[PortFolio_Daily] with(nolock)
	where InvestorId = @InvestorId and ContractId = @ContractId
	and PortfolioDate = @EndDate
	union all
	select * 
	from [CacheDB].[dbo].[PortFolio_Daily_Last] with(nolock)
	where InvestorId = @InvestorId and ContractId = @ContractId
	and PortfolioDate = @EndDate
) as r;


-- ���������� VALUE_NOM �� BAL_ACC 2782
UPDATE T SET
	T.VALUE_NOM = T.VALUE_NOM + R.VALUE_NOM
FROM
(
	select
		VALUE_ID, VALUE_NOM = SUM(VALUE_NOM)
	from #TrustTree
	where BAL_ACC = 2782
	GROUP BY VALUE_ID
) AS R
JOIN #TrustTree AS T ON R.VALUE_ID = T.VALUE_ID AND (T.BAL_ACC <> 2782 OR T.BAL_ACC IS NULL);

-- ������� BAL_ACC 2782
delete from #TrustTree
where BAL_ACC = 2782;


-- ������ - ������ ������ �����������
-- tree1
select
	ValutaId = cast(CUR_ID as BigInt),
	ValutaName = CUR_NAME
from #TrustTree
GROUP BY CUR_ID, CUR_NAME
ORDER BY CUR_ID;

-- tree2
select
	TypeId = cast(c.id as BigInt),
	TypeName = c.CategoryName,
	ValutaId = cast(a.CUR_ID as BigInt)
from #TrustTree as a
inner join [CacheDB].[dbo].[ClassCategories] as cc on a.CLASS = cc.ClassId
inner join [CacheDB].[dbo].[Categories] as c on cc.CategoryId = c.Id
group by c.id, c.CategoryName, a.CUR_ID



--------------------------------
--- ������ ������ 3
BEGIN TRY
	DROP TABLE #StartDaily;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #EndDaily;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #StartPostions;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #EndPostions;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #SumStart;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #ShareDates;
END TRY
BEGIN CATCH
END CATCH

CREATE TABLE #ShareDates
(
	InvestorId Int,
	ContractId Int,
	ShareId Int,
	[Date] Date,
	In_Summa decimal(28,10),
	Out_Summa decimal(28,10)
)



-- ��������� ����
select *
into #StartDaily
from
(
	select *
	from PortFolio_Daily as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.PortfolioDate = @StartDate
	union all
	select *
	from PortFolio_Daily_Last as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.PortfolioDate = @StartDate
) as res


-- �������� ����
select *
into #EndDaily
from
(
	select *
	from PortFolio_Daily as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.PortfolioDate = @EndDate
	union all
	select *
	from PortFolio_Daily_Last as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.PortfolioDate = @EndDate
) as res


-- ������� �� ������
select *
into #StartPostions
from
(
	select *
	from POSITION_KEEPING as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.Fifo_Date = @StartDate
	union all
	select *
	from POSITION_KEEPING_Last as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.Fifo_Date = @StartDate
) as res


-- ������� �� �����
select *, RowNumber = ROW_NUMBER() over( order by Id)
into #EndPostions
from
(
	select *
	from POSITION_KEEPING as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.Fifo_Date = @EndDate
	union all
	select *
	from POSITION_KEEPING_Last as df with(nolock)
	where
	df.InvestorId = @InvestorId
	and df.ContractId = @ContractId
	and df.Fifo_Date = @EndDate
) as res


CREATE TABLE #SumStart
(
	[RowNumber] Int NULL,
	[IsActive] [bit] NULL,
	[In_Wir] [int] NULL,
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[ShareId] [int] NOT NULL,
	[StartDate] [date] NULL,
	[In_Date] [date] NULL,
	[IsIndate] [int] NOT NULL,
	[SumStart] [numeric](38, 10) NULL,
	[Amount] [decimal](38, 10) NULL,
	[SumEnd] [decimal](38, 10) NULL,
	[SumInput] [decimal](38, 10) NULL,
	[SumOutput] [decimal](38, 10) NULL,
	[InvestResult] [decimal](38, 10) NULL,
	[ResutSumForProcent] [decimal](38, 10) NULL,
	[InvestResultProcent] [decimal](38, 10) NULL
);

-- ������ ����� �� ����� �������
insert into #SumStart
(
	[IsActive], [In_Wir], [InvestorId], [ContractId],
	[ShareId], [StartDate], [In_Date], [IsIndate],
	[SumStart], [Amount], RowNumber
)
select
	IsActive = 1,
	In_Wir = NULL,
	aa.InvestorId,
	aa.ContractId,
	ShareId = aa.VALUE_ID,
	StartDate = NULL,
	In_Date = NULL,
	IsIndate = 0,
	SumStart = NULL,
	Amount = NULL,
	RowNumber = ROW_NUMBER() over( order by Id)
from #EndDaily as aa
cross apply
(
	select top 1
		ShareId
	from #EndPostions as bb
	where bb.ShareId = aa.VALUE_ID
) as cc
where aa.AMOUNT > 0;

--select *
update a set
	SumStart = isnull(b.VALUE_NOM,0) + isnull(bb.VALUE_NOM,0),
	Amount = isnull(b.AMOUNT,0) + isnull(bb.AMOUNT,0)
from #SumStart as a
outer apply
(
	select
		VALUE_NOM = sum(n.VALUE_NOM),
		AMOUNT = sum(n.AMOUNT)
	from #StartDaily as n
	where n.VALUE_ID = a.ShareId
) as b
outer apply
(
	select
		VALUE_NOM = sum(nn.VALUE_NOM),
		AMOUNT = sum(nn.AMOUNT)
	from #EndPostions as nn
	where nn.ShareId = a.ShareId
	and nn.In_Date = @StartDate
) as bb;


update a
	set a.SumEnd = isnull(c.VALUE_NOM,0)
from #SumStart as a
outer apply
(
	select
		VALUE_NOM = sum(b.VALUE_NOM)
	from #EndDaily as b
	where b.AMOUNT > 0
	and b.InvestorId = a.InvestorId
	and b.ContractId = a.ContractId
	and b.VALUE_ID = a.ShareId
) as c;

update a set
	SumInput = isnull(b.SumInput, 0)
from #SumStart as a
outer apply
(
	select
		SumInput = sum(bb.In_Summa)
	from #EndPostions as bb
	where
	bb.InvestorId = a.InvestorId
	and bb.ContractId = a.ContractId
	and bb.ShareId = a.ShareId
	and bb.In_Date > @StartDate
	and bb.In_Date <= @EndDate
) as b;

update a set
	SumOutput = isnull(b.SumOutput,0)
from #SumStart as a
outer apply
(
	select
		SumOutput = isnull(sum(bb.Out_Summa),0) - isnull(sum(bb.Amortizations),0)
	from #EndPostions as bb
	where
	bb.InvestorId = a.InvestorId
	and bb.ContractId = a.ContractId
	and bb.ShareId = a.ShareId
	and bb.Out_Date >= @StartDate
	and bb.Out_Date <= @EndDate
) as b;

-- ��������� SumInput
update a set 
	InvestResult = (SumEnd + SumOutput) - (SumStart + SumInput)
from #SumStart as a;


-- ��������� InvestResult

insert into #ShareDates
(
	InvestorId,
	ContractId,
	ShareId,
	[Date],
	In_Summa,
	Out_Summa
)
select
	InvestorId = isnull(aa.InvestorId, bb.InvestorId),
	ContractId = isnull(aa.ContractId, bb.ContractId),
	ShareId = isnull(aa.ShareId, bb.ShareId),
	[Date] = isnull(aa.[Date], bb.[Date]),
	In_Summa = isnull(aa.In_Summa, 0),
	Out_Summa = isnull(bb.Out_Summa, 0)
from
(
	select
		InvestorId, ContractId, ShareId, [Date] = In_Date, In_Summa = sum(In_Summa)
	from
	(
		select InvestorId, ContractId, ShareId, In_Date, Out_Date = cast(Out_Date as Date), In_Summa = sum(In_Summa), Out_Summa = sum(Out_Summa)
		from #EndPostions
		group by InvestorId, ContractId, ShareId, In_Date, cast(Out_Date as Date)
	) as a
	group by InvestorId, ContractId, ShareId, In_Date
) as aa
full join
(
	select
		InvestorId, ContractId, ShareId, [Date] = Out_Date, Out_Summa = sum(Out_Summa)
	from
	(
		select InvestorId, ContractId, ShareId, In_Date, Out_Date = cast(Out_Date as Date), In_Summa = sum(In_Summa), Out_Summa = sum(Out_Summa)
		from #EndPostions
		group by InvestorId, ContractId, ShareId, In_Date, cast(Out_Date as Date)
	) as a
	group by InvestorId, ContractId, ShareId, Out_Date
) as bb
	on aa.InvestorId = bb.InvestorId and aa.ContractId = bb.ContractId and aa.ShareId = bb.ShareId and aa.[Date] = bb.[Date]
where aa.In_Summa > 0 or bb.Out_Summa > 0;


	declare @ShareId Int, @Snach2 numeric(28,10),
		@AmountDayPlus numeric(28,10), @AmountDayMinus numeric(28,10), @DateCCur date, @DateCCur2 date,
		@Countter Int, @LastDDate date, @TT Int, @ResutSSum numeric(28,10), @SumAmountDDay numeric(28,10),
		@SumTT numeric(28,10)
	
	declare share_cur cursor local fast_forward for
        -- 
        select ShareId from #SumStart

    open share_cur
    fetch next from share_cur into
        @ShareId
    while(@@fetch_status = 0)
    begin
			set @Snach2 = NULL;

			select
				@Snach2 = SumStart
			from #SumStart
			where ShareId = @ShareId;

			if @Snach2 is null set @Snach2 = 0;

			set @LastDDate = @StartDate;

			set @Countter = 0;
			set @ResutSSum = 0;
			set @SumAmountDDay = 0;
			set @SumTT = 0;
			set @DateCCur2 = NULL;

			declare obj_cur cursor local fast_forward for
				SELECT
					[Date], In_Summa, -Out_Summa
				FROM #ShareDates
				where ShareId = @ShareId
				and [Date] > @StartDate and [Date] <= @EndDate
				order by [Date]
			open obj_cur
			fetch next from obj_cur into
				@DateCCur, @AmountDayPlus, @AmountDayMinus
			while(@@fetch_status = 0)
			begin
				set @DateCCur2 = @DateCCur;

				set @Countter += 1;
        
				-- ��������� ���� ����������
				if @DateCCur = @StartDate
				begin
					set @LastDDate = @DateCCur
				end
				else
				begin
					-- �� ������ ������ ��������� ������
					set @TT = DATEDIFF(DAY, @LastDDate, @DateCCur);
					if @DateCCur = @EndDate set @TT = @TT + 1;
            
					set @ResutSSum += @TT * (@Snach2 + @SumAmountDDay)
            
					set @LastDDate = @DateCCur
					set @SumAmountDDay = @SumAmountDDay + @AmountDayPlus + @AmountDayMinus
            
					set @SumTT += @TT;
				end
        
				fetch next from obj_cur into
					@DateCCur, @AmountDayPlus, @AmountDayMinus
			end
			close obj_cur
			deallocate obj_cur

			-- �������� �� ���������� ���
			if @DateCCur2 is not null
			begin
				if @DateCCur2 < @EndDate
				begin
					set @TT = DATEDIFF(DAY, @DateCCur2, @EndDate);
					set @TT = @TT + 1;
            
					set @ResutSSum += @TT * (@Snach2 + @SumAmountDDay)

					set @SumTT += @TT;
				end
			end
    
			set @ResutSSum = @ResutSSum/nullif(@SumTT,0)


			update a set
				ResutSumForProcent = isnull(@ResutSSum,0),
				InvestResultProcent = isnull(InvestResult/nullif(@ResutSSum,0),0) * 100.000
			from #SumStart as a
			where a.ShareId = @ShareId



        
        fetch next from share_cur into
            @ShareId
    end
    close share_cur
    deallocate share_cur

	-- ���������
	--select * from #SumStart
--- ������ ������ 3
--------------------------------


-- tree3
select
	ChildId = cast(a.InvestmentId as BigInt),
	TypeId = cast(c.id as BigInt),
	ChildName = i.Investment,
	ValutaId = cast(a.CUR_ID as BigInt),
	PriceName =  CAST(CAST(Round(a.[VALUE_NOM],2) as Decimal(30,2)) as Nvarchar(50)) + ' ' + IsNull(cr.[Symbol], N'?'),
	Ammount = case when c.Id <> 4 then CAST(CAST(Round(a.[AMOUNT],2) as Decimal(30,2)) as Nvarchar(50)) + N' ��.' else N'' end,
	Detail = CAST(CAST(Round(rst.InvestResult,2) as Decimal(30,2)) as Nvarchar(50)) + ' ' + IsNull(cr.[Symbol], N'?')
		+ ' (' + CAST(CAST(Round(rst.InvestResultProcent,2) as Decimal(30,2)) as Nvarchar(50)) + '%)'
from #TrustTree as a
inner join [CacheDB].[dbo].[ClassCategories] as cc on a.CLASS = cc.ClassId
inner join [CacheDB].[dbo].[Categories] as c on cc.CategoryId = c.Id
inner join [CacheDB].[dbo].[InvestmentIds] as i on a.InvestmentId = i.Id
left join  [CacheDB].[dbo].[Currencies] as cr on a.CUR_ID = cr.id
left join #SumStart as rst on a.VALUE_ID = rst.ShareId





begin try
	drop table #POSITION_KEEPING_EndDate;
end try
begin catch
end catch

begin try
	drop table #POSITION_KEEPING_StartDate;
end try
begin catch
end catch


CREATE TABLE #POSITION_KEEPING_EndDate
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[ShareId] [int] NOT NULL,
	[Fifo_Date] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
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
	[Coupons] [decimal](30, 9) NULL,
	[Out_Wir] [int] NULL,
	[Out_Date] [datetime] NULL,
	[Od_Id] [int] NULL,
	[Oc_NameId] [bigint] NULL,
	[Ol_Num] [int] NULL,
	[Out_Dol] [int] NULL,
	[Out_Summa] [decimal](20, 7) NULL,
	[Out_Eq] [decimal](20, 7) NULL,
	[RecordDate] [datetime2](7) NULL,
	[OutPrice] [decimal](20, 7) NULL,
	[FinRes] [decimal](28, 10) NULL,
	[FinResProcent] [decimal](28, 10) NULL
);

CREATE TABLE #POSITION_KEEPING_StartDate
(
	[InvestorId] [int] NOT NULL,
	[ContractId] [int] NOT NULL,
	[ShareId] [int] NOT NULL,
	[Fifo_Date] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
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
	[Coupons] [decimal](30, 9) NULL,
	[Out_Wir] [int] NULL,
	[Out_Date] [datetime] NULL,
	[Od_Id] [int] NULL,
	[Oc_NameId] [bigint] NULL,
	[Ol_Num] [int] NULL,
	[Out_Dol] [int] NULL,
	[Out_Summa] [decimal](20, 7) NULL,
	[Out_Eq] [decimal](20, 7) NULL,
	[RecordDate] [datetime2](7) NULL,
	[OutPrice] [decimal](20, 7) NULL
);

INSERT INTO #POSITION_KEEPING_EndDate
(
	[InvestorId], [ContractId], [ShareId], [Fifo_Date],
	[Id], [ISIN], [Class], [InstrumentId],
	[CUR_ID], [Oblig_Date_end], [Oferta_Date], [Oferta_Type],
	[IsActive], [In_Wir], [In_Date], [Ic_NameId],
	[Il_Num], [In_Dol], [Ir_Trans], [Amount],
	[In_Summa], [In_Eq], [In_Comm], [In_Price],
	[In_Price_eq], [IN_PRICE_UKD], [Today_PRICE], [Value_NOM],
	[Dividends], [UKD], [NKD], [Amortizations],
	[Coupons], [Out_Wir], [Out_Date], [Od_Id],
	[Oc_NameId], [Ol_Num], [Out_Dol], [Out_Summa],
	[Out_Eq], [RecordDate], [OutPrice]
)
select
	[InvestorId], [ContractId], [ShareId], [Fifo_Date],
	[Id], [ISIN], [Class], [InstrumentId],
	[CUR_ID], [Oblig_Date_end], [Oferta_Date], [Oferta_Type],
	[IsActive], [In_Wir], [In_Date], [Ic_NameId],
	[Il_Num], [In_Dol], [Ir_Trans], [Amount],
	[In_Summa], [In_Eq], [In_Comm], [In_Price],
	[In_Price_eq], [IN_PRICE_UKD], [Today_PRICE], [Value_NOM],
	[Dividends], [UKD], [NKD], [Amortizations],
	[Coupons], [Out_Wir], [Out_Date], [Od_Id],
	[Oc_NameId], [Ol_Num], [Out_Dol], [Out_Summa],
	[Out_Eq], [RecordDate], [OutPrice]
from
(
	select * 
	from [CacheDB].[dbo].[POSITION_KEEPING] as a with(nolock)
	where a.InvestorId = @InvestorId and a.ContractId = @ContractId
	and Fifo_Date = @EndDate
	union all
	select * 
	from [CacheDB].[dbo].[POSITION_KEEPING_Last] as a with(nolock)
	where a.InvestorId = @InvestorId and a.ContractId = @ContractId
	and Fifo_Date = @EndDate
) as r


INSERT INTO #POSITION_KEEPING_StartDate
(
	[InvestorId], [ContractId], [ShareId], [Fifo_Date],
	[Id], [ISIN], [Class], [InstrumentId],
	[CUR_ID], [Oblig_Date_end], [Oferta_Date], [Oferta_Type],
	[IsActive], [In_Wir], [In_Date], [Ic_NameId],
	[Il_Num], [In_Dol], [Ir_Trans], [Amount],
	[In_Summa], [In_Eq], [In_Comm], [In_Price],
	[In_Price_eq], [IN_PRICE_UKD], [Today_PRICE], [Value_NOM],
	[Dividends], [UKD], [NKD], [Amortizations],
	[Coupons], [Out_Wir], [Out_Date], [Od_Id],
	[Oc_NameId], [Ol_Num], [Out_Dol], [Out_Summa],
	[Out_Eq], [RecordDate], [OutPrice]
)
select
	[InvestorId], [ContractId], [ShareId], [Fifo_Date],
	[Id], [ISIN], [Class], [InstrumentId],
	[CUR_ID], [Oblig_Date_end], [Oferta_Date], [Oferta_Type],
	[IsActive], [In_Wir], [In_Date], [Ic_NameId],
	[Il_Num], [In_Dol], [Ir_Trans], [Amount],
	[In_Summa], [In_Eq], [In_Comm], [In_Price],
	[In_Price_eq], [IN_PRICE_UKD], [Today_PRICE], [Value_NOM],
	[Dividends], [UKD], [NKD], [Amortizations],
	[Coupons], [Out_Wir], [Out_Date], [Od_Id],
	[Oc_NameId], [Ol_Num], [Out_Dol], [Out_Summa],
	[Out_Eq], [RecordDate], [OutPrice]
from
(
	select * 
	from [CacheDB].[dbo].[POSITION_KEEPING] as a with(nolock)
	where a.InvestorId = @InvestorId and a.ContractId = @ContractId
	and Fifo_Date = @StartDate
	union all
	select * 
	from [CacheDB].[dbo].[POSITION_KEEPING_Last] as a with(nolock)
	where a.InvestorId = @InvestorId and a.ContractId = @ContractId
	and Fifo_Date = @StartDate
) as r

update a
	set FinRes =
	case
		when Class in (1,7,10)
			then isnull(Out_Summa,0) + isnull(Dividends,0) - isnull(In_Summa,0)
		when Class in (2)
			then isnull(Out_Summa,0) + isnull(a.Amortizations,0)  + isnull(a.Coupons,0) + isnull(a.NKD,0) - isnull(a.In_Summa,0) - isnull(a.UKD,0)
		else 0
	end,
	FinResProcent =
	case
		when Class in (1,7,10)
			then isnull(Out_Summa,0) + isnull(Dividends,0) - isnull(In_Summa,0)
		when Class in (2)
			then isnull(Out_Summa,0) + isnull(a.Amortizations,0)  + isnull(a.Coupons,0) + isnull(a.NKD,0) - isnull(a.In_Summa,0) - isnull(a.UKD,0)
		else 0
	end
	/
	nullif(
	case
		when Class in (1,7,10)
			then isnull(In_Summa,0)
		when Class in (2)
			then isnull(Out_Summa,0) + isnull(a.UKD,0)
		else NULL
	end, 0)
from #POSITION_KEEPING_EndDate as a
where IsActive = 0;

update a
	set
	FinRes = 
	case
		when b.id is not null and a.Class in (1,7,10) then
			isnull(a.Value_NOM,0)
			+ isnull(a.Dividends,0)
				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.Dividends,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)

		when b.id is null     and a.Class in (1,7,10) then
			isnull(a.Value_NOM,0) + isnull(a.Dividends,0) - isnull(a.In_Summa,0)


		when b.id is not null and a.Class in (2) then
			isnull(a.Value_NOM,0)
			+ isnull(a.Amortizations,0)
			+ isnull(a.Coupons,0)
			+ isnull(a.NKD,0)
				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.Amortizations,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.Coupons,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.NKD,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
		
		when b.id is null     and a.Class in (2) then
			isnull(a.Value_NOM,0)
			+ isnull(a.Amortizations,0)
			+ isnull(a.Coupons,0)
			+ isnull(a.NKD,0)
				- isnull(a.In_Summa,0)
				- isnull(a.UKD,0)

		else 0
	end,
	FinResProcent =
	case
		when b.id is not null and a.Class in (1,7,10) then
			isnull(a.Value_NOM,0)
			+ isnull(a.Dividends,0)
				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.Dividends,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)

		when b.id is null     and a.Class in (1,7,10) then
			isnull(a.Value_NOM,0) + isnull(a.Dividends,0) - isnull(a.In_Summa,0)


		when b.id is not null and a.Class in (2) then
			isnull(a.Value_NOM,0)
			+ isnull(a.Amortizations,0)
			+ isnull(a.Coupons,0)
			+ isnull(a.NKD,0)
				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.Amortizations,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.Coupons,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
				- isnull(isnull(b.NKD,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
		
		when b.id is null     and a.Class in (2) then
			isnull(a.Value_NOM,0)
			+ isnull(a.Amortizations,0)
			+ isnull(a.Coupons,0)
			+ isnull(a.NKD,0)
				- isnull(a.In_Summa,0)
				- isnull(a.UKD,0)

		else 0
	end
	/
	nullif(
	case
		when b.id is not null and a.Class in (1,7,10) then
			isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
			+ isnull(isnull(b.Dividends,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)

		when b.id is null     and a.Class in (1,7,10) then
			isnull(a.In_Summa,0)


		when b.id is not null and a.Class in (2) then
			isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
			+ isnull(isnull(b.Amortizations,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
			+ isnull(isnull(b.Coupons,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
			+ isnull(isnull(b.NKD,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)

		when b.id is null     and a.Class in (2) then
			isnull(a.In_Summa,0) + isnull(a.UKD,0)

		else NULL
	end, 0)
from #POSITION_KEEPING_EndDate as a
outer apply
(
	select top 1 *
	From #POSITION_KEEPING_StartDate as bb
	where bb.IsActive = 1
	and bb.In_Wir = a.In_Wir
) as b
where a.IsActive = 1;

-- ���������� � ���������������
update a set
	a.FinRes = dbo.f_Round(a.FinRes, 2),
	a.FinResProcent = dbo.f_Round(a.FinResProcent * 100.000, 2)
from #POSITION_KEEPING_EndDate as a;

-- tree4
select
	Child2Id = a.Id,
	ChildId = b.InvestmentId,
	Child2Name = i.Investment,
	PriceName = CAST(CAST(Round(a.VALUE_NOM,2) as Decimal(30,2)) as Nvarchar(30)) + N' ' + isnull(c.Symbol,N'?'),
	Ammount =  FORMAT(a.Amount, '0.######') + ' ��.',
	Detail =   FORMAT(a.FinRes, '0.######') + N' ' + isnull(c.Symbol,N'?') + ' (' + FORMAT(a.FinResProcent, '0.######') + '%)'
from #POSITION_KEEPING_EndDate as a with(nolock)
inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
inner join [CacheDB].[dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
left join [CacheDB].[dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id

declare @CategoryId Int, @IsActive Int


declare obj_cur cursor local fast_forward for
	select Id, IsActive = 0
	from Categories nolock
	union all
	select Id, IsActive = 1
	from Categories nolock
	order by Id, IsActive desc
open obj_cur
fetch next from obj_cur into
	@CategoryId, @IsActive
while(@@fetch_status = 0)
begin
	if @CategoryId <> 2
	begin
		select
			cc.CategoryId,
			cg.CategoryName,
			[IsActive] = isnull(a.IsActive,0),
			InvestmentId = b.InvestmentId,
			Investment = i.Investment,
			PriceName = CAST(CAST(Round(a.VALUE_NOM,2) as Decimal(30,2)) as Nvarchar(30)) + N' ' + isnull(c.Symbol,N'?'),
			a.Amount,
			Ammount2 =  FORMAT(a.Amount, '0.######') + ' ��.',
			Detail =   FORMAT(a.FinRes, '0.######') + N' ' + isnull(c.Symbol,N'?') + ' (' + FORMAT(a.FinResProcent, '0.######') + '%)',
			Valuta = isnull(c.Symbol,N'?'),
			a.ShareId,
			a.InvestorId,
			a.ContractId,
			a.Fifo_Date,
			a.ISIN,
			a.In_Wir,
			a.In_Date,
			a.Ic_NameId,
			a.In_Dol,
			a.Ir_Trans,
			a.In_Summa,
			a.In_Eq,
			a.In_Comm,
			a.In_Price,
			a.Il_Num,
			a.In_Price_eq,
			a.Today_PRICE,
			a.Value_NOM,
			a.Dividends,
			a.FinRes,
			a.FinResProcent,
			a.CUR_ID,
			a.Oferta_Date,
			a.Oblig_Date_end,
			a.Oferta_Type,
			a.UKD,
			a.NKD,
			a.Amortizations,
			a.Coupons,
			a.Out_Date,
			a.Out_Summa,
			a.OutPrice
		from #POSITION_KEEPING_EndDate as a with(nolock)
		inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
		inner join [CacheDB].[dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
		inner join [dbo].[ClassCategories] as cc with(nolock) on a.Class = cc.ClassId and cc.CategoryId = @CategoryId
		inner join [dbo].[Categories] as cg on cc.CategoryId = cg.Id
		left join [CacheDB].[dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id
		where isnull(a.IsActive,0) = @IsActive
	end
	else
	begin
		select
			cc.CategoryId,
			cg.CategoryName,
			[IsActive] = isnull(a.IsActive,0),
			InvestmentId = b.InvestmentId,
			Investment = i.Investment,
			PriceName = CAST(CAST(Round(a.VALUE_NOM,2) as Decimal(30,2)) as Nvarchar(30)) + N' ' + isnull(c.Symbol,N'?'),
			a.Amount,
			Ammount2 =  FORMAT(a.Amount, '0.######') + ' ��.',
			Detail =   FORMAT(a.FinRes, '0.######') + N' ' + isnull(c.Symbol,N'?') + ' (' + FORMAT(a.FinResProcent, '0.######') + '%)',
			Valuta = isnull(c.Symbol,N'?'),
			a.ShareId,
			a.InvestorId,
			a.ContractId,
			a.Fifo_Date,
			a.ISIN,
			a.In_Wir,
			a.In_Date,
			a.Ic_NameId,
			a.In_Dol,
			a.Ir_Trans,
			a.In_Summa,
			a.In_Eq,
			a.In_Comm,
			a.In_Price,
			a.Il_Num,
			a.In_Price_eq,
			a.Today_PRICE,
			a.Value_NOM,
			a.Dividends,
			a.FinRes,
			a.FinResProcent,
			a.CUR_ID,
			Oferta_Date = OFE.B_DATE,
			Oblig_Date_end = OBL.DEATHDATE,
			Oferta_Type = case when OFE.O_TYPE = 1 then 'Put' when OFE.O_TYPE = 2 then 'Call' else '' end,
			a.UKD,
			a.NKD,
			a.Amortizations,
			a.Coupons,
			a.Out_Date,
			a.Out_Summa,
			a.OutPrice
		from #POSITION_KEEPING_EndDate as a with(nolock)
		inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
		inner join [CacheDB].[dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
		inner join [dbo].[ClassCategories] as cc with(nolock) on a.Class = cc.ClassId and cc.CategoryId = @CategoryId
		inner join [dbo].[Categories] as cg on cc.CategoryId = cg.Id
		left join [CacheDB].[dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id
		outer apply
		(
			select top(1)
				DEATHDATE = case when Datepart(YEAR, OI.DEATHDATE) = 9999 then NULL else OI.DEATHDATE end
			FROM OBLIG_INFO as OI
			where OI.SELF_ID = a.ShareId
			order by OI.DEATHDATE desc
		) as OBL
		outer apply
		(
			select top(1)
				OO.B_DATE, OO.O_TYPE
			FROM [dbo].[OBLIG_OFERTS] as OO
			where OO.SHARE = a.ShareId
			order by OO.B_DATE desc
		) as OFE
		where isnull(a.IsActive,0) = @IsActive
	end
	
	fetch next from obj_cur into
		@CategoryId, @IsActive
end
close obj_cur
deallocate obj_cur





BEGIN TRY
	drop table #TrustTree;
END TRY
BEGIN CATCH
END CATCH;

BEGIN TRY
	DROP TABLE #ResInvAssets
END TRY
BEGIN CATCH
END CATCH;

begin try
	drop table #POSITION_KEEPING_EndDate;
end try
begin catch
end catch

begin try
	drop table #POSITION_KEEPING_StartDate;
end try
begin catch
end catch




BEGIN TRY
	DROP TABLE #StartDaily;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #EndDaily;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #StartPostions;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #EndPostions;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #SumStart;
END TRY
BEGIN CATCH
END CATCH

BEGIN TRY
	DROP TABLE #ShareDates;
END TRY
BEGIN CATCH
END CATCH