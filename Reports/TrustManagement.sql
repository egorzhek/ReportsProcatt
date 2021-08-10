DECLARE @ToDateStr     Nvarchar(50) = @DateToSharp;
DECLARE @FromDateStr   Nvarchar(50) = @DateFromSharp;
DECLARE @InvestorIdStr Nvarchar(50) = @InvestorIdSharp;
DECLARE @ContractIdStr Nvarchar(50) = @ContractIdSharp;

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
	SELECT *
	FROM [CacheDB].[dbo].[Assets_Contracts] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
	UNION
	SELECT *
	FROM [CacheDB].[dbo].[Assets_ContractsLast] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
) AS R
WHERE [Date] >= @StartDate and [Date] <= @EndDate
--ORDER BY [Date]


--select * From #ResInvAssets
--order by [Date];

-----------------------------------------------
-- преобразование на начальную и последнюю дату

-- забыть вводы выводы на первую дату
update #ResInvAssets set
	DailyIncrement_RUR = 0, DailyIncrement_USD = 0,	DailyIncrement_EURO = 0,
	DailyDecrement_RUR = 0,	DailyDecrement_USD = 0,	DailyDecrement_EURO = 0,
	INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
	INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
	INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
where [Date] = @StartDate
and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

-- посчитать последний день обратно
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
and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

-- преобразование на начальную и последнюю дату
-----------------------------------------------

--select * From #ResInvAssets
--where OUTPUT_VALUE_RUR <> 0
--order by [Date];

-- В рублях

-- Итоговая оценка инвестиций

SELECT
	@SItog = VALUE_RUR
FROM #ResInvAssets
where [Date] = @EndDate

SELECT
	@Snach = VALUE_RUR
FROM #ResInvAssets
where [Date] = @StartDate



-- сумма всех выводов средств
SELECT
	@AmountDayMinus_RUR = sum(OUTPUT_VALUE_RUR), -- отрицательное значение
	@AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR),
	@Sum_INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
	@Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
	@Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
	@Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
FROM #ResInvAssets

--select @SItog as '@SItog', @Snach as '@Snach', @OUTPUT_VALUE_RUR as '@OUTPUT_VALUE_RUR', @AmountDayPlus_RUR as '@AmountDayPlus_RUR'

set @InvestResult =
(@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
- (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'

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

		-- начальную дату пропускаем
		if @DateCur = @StartDate
		begin
			set @LastDate = @DateCur
		end
		else
		begin
			-- со второй записи определяем период
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
	--@InvestResult as 'Результат инвестиций',
	--@ResutSum as 'Средневзвешенная сумма вложенных средств',
	--@InvestResult/@ResutSum * 100 as 'Доходность в %',
	--@InvestResult as 'Доходность абсолютная',
	--@StartDate as 'Дата начала',
	--@EndDate as 'Дата завершения',
	--@SumT as 'Количество дней'

Declare @DATE_OPEN date, @NUM Nvarchar(100);

select
	@DATE_OPEN = DATE_OPEN,
	@NUM = NUM
from [CacheDB].[dbo].[Assets_Info] NOLOCK
where [InvestorId] = @InvestorId and [ContractId] = @ContractId;

select
	ActiveDateToName = 'Активы на ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ActiveDateToValue =  CAST(Round(@SItog,2) as Decimal(30,2)),
	ProfitName = 'Доход за период ' + FORMAT(@StartDate,'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ProfitValue = CAST(Round(@InvestResult,2) as Decimal(30,2)),
	ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
	OpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	LS_NUM = '2940000083',
	EndSumAmount = 99999.99,
	FundName = @NUM,
	InvestorName = @NUM,
	ContractNumber = @NUM,
	Fee = 99.99,
	ContractOpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	SuccessFee = 99.99,
	DateFromName = FORMAT(@StartDate,'dd.MM.yyyy')

select ActiveName = 'Активы на ' + FORMAT(@StartDate,'dd.MM.yyyy') , ActiveValue = CAST(Round(@Snach,2) as Decimal(38,2)), Sort = 1
union
select 'Пополнения', CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)), 2
union
select 'Выводы', CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)), 3
union
select 'Дивиденды', @Sum_INPUT_DIVIDENTS_RUR, 4
union
select 'Купоны', @Sum_INPUT_COUPONS_RUR, 5
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



select ActiveName = 'Всего', ActiveValue = CAST(Round(@Sum_INPUT_DIVIDENTS_RUR + @Sum_INPUT_COUPONS_RUR,2) as Decimal(30,2)), Sort = 1, Color = '#FFFFFF'
union
select 'Дивиденды', CAST(Round(@Sum_INPUT_DIVIDENTS_RUR,2) as Decimal(30,2)), 4, '#7FE5F0'
union
select 'Купоны', CAST(Round(@Sum_INPUT_COUPONS_RUR,2) as Decimal(30,2)), 5, '#4CA3DD'
order by 3


-- Дивиденты, купоны - график
select
	[Date],
	[Dividends] = [INPUT_DIVIDENTS_RUR],
	[Coupons] = [INPUT_COUPONS_RUR]
From #ResInvAssets
where INPUT_DIVIDENTS_RUR <> 0 or INPUT_DIVIDENTS_USD <> 0 
order by [Date];

-- Детализация купонов и дивидендов
select
	[Date] = FORMAT([PaymentDateTime],'dd.MM.yyyy'),
	[ToolName] = [ShareName],
	[PriceType] = case when [Type] = 1 then 'Купоны' else 'Дивиденды' end,
	[ContractName] = [ShareName],
	[Price] = CAST(Round([AmountPayments_RUR],2) as Decimal(30,2)),
	[PaymentDateTime]
from [CacheDB].[dbo].[DIVIDENDS_AND_COUPONS_History]
where InvestorId = @InvestorId and ContractId = @ContractId
union all
select
	[Date] =  FORMAT([PaymentDateTime],'dd.MM.yyyy'),
	[ToolName] = [ShareName],
	[PriceType] = case when [Type] = 1 then 'Купоны' else 'Дивиденды' end,
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
			when [Currency] = 1 then N'₽'
			when [Currency] = 2 then N'$'
			when [Currency] = 5 then N'€'
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
			when [Currency] = 1 then N'₽'
			when [Currency] = 2 then N'$'
			when [Currency] = 5 then N'€'
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


-- Прибавляем VALUE_NOM от BAL_ACC 2782
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

-- убираем BAL_ACC 2782
delete from #TrustTree
where BAL_ACC = 2782;


-- Дерево - четыре уровня вложенности
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

-- tree3
select
	ChildId = cast(a.InvestmentId as BigInt),
	TypeId = cast(c.id as BigInt),
	ChildName = i.Investment,
	ValutaId = cast(a.CUR_ID as BigInt),
	PriceName =  CAST(CAST(Round(a.[VALUE_NOM],2) as Decimal(30,2)) as Nvarchar(50)) + ' ' + IsNull(cr.[Symbol], N'?'),
	Ammount = case when c.Id <> 4 then CAST(CAST(Round(a.[AMOUNT],2) as Decimal(30,2)) as Nvarchar(50)) + N' шт.' else N'' end,
	Detail = N'' -- потом доделать +5,43 ₽ (+4,7%)
from #TrustTree as a
inner join [CacheDB].[dbo].[ClassCategories] as cc on a.CLASS = cc.ClassId
inner join [CacheDB].[dbo].[Categories] as c on cc.CategoryId = c.Id
inner join [CacheDB].[dbo].[InvestmentIds] as i on a.InvestmentId = i.Id
left join  [CacheDB].[dbo].[Currencies] as cr on a.CUR_ID = cr.id






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

-- округление и процентирование
update a set
	a.FinRes = dbo.f_Round(a.FinRes, 2),
	a.FinResProcent = dbo.f_Round(a.FinResProcent * 100.000, 2)
from #POSITION_KEEPING_EndDate as a;

select
	Child2Id = a.Id,
	ChildId = b.InvestmentId,
	Child2Name = i.Investment,
	PriceName = CAST(CAST(Round(a.VALUE_NOM,2) as Decimal(30,2)) as Nvarchar(30)) + N' ' + isnull(c.Symbol,N'?'),
	Ammount =  FORMAT(a.Amount, '0.######') + ' шт.',
	Detail =   FORMAT(a.FinRes, '0.######') + N' ' + isnull(c.Symbol,N'?') + ' (' + FORMAT(a.FinResProcent, '0.######') + '%)'
from #POSITION_KEEPING_EndDate as a with(nolock)
inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
inner join [CacheDB].[dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
left join [CacheDB].[dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id


-- tree4 -- потом доделать - четвёртый уровень
--select Child2Id = cast(1 as BigInt), ChildId = cast(4 as BigInt), Child2Name = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '5 шт.', Detail = N'-15,48 ₽ (-11,2%)'
--union
--select Child2Id = cast(2 as BigInt), ChildId = cast(4 as BigInt), Child2Name = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '1 шт.', Detail = N'-15,48 ₽ (-11,2%)'

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