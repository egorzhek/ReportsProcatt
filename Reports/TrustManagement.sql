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
@InvestResult numeric(30,10),
@Sum_INPUT_VALUE_RUR1 numeric(30,10),
@Sum_OUTPUT_VALUE_RUR1 numeric(30,10);

SELECT
	@MinDate = min([Date]),
	@MaxDate = max([Date])
FROM
(
	SELECT [Date]
	FROM [dbo].[Assets_Contracts] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
	UNION
	SELECT [Date]
	FROM [dbo].[Assets_ContractsLast] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
) AS R

if @StartDate is null set @StartDate = @MinDate;
if @StartDate < @MinDate set @StartDate = @MinDate;
if @StartDate > @MaxDate set @StartDate = @MinDate;

if @EndDate is null    set @EndDate = @MaxDate;
if @EndDate > @MaxDate set @EndDate = @MaxDate;
if @EndDate < @MinDate set @EndDate = @MaxDate;

declare @PortfolioDateMax Date

select
	@PortfolioDateMax = max(PortfolioDate)
from
(
	select PortfolioDate = max(PortfolioDate)
	from [dbo].[PortFolio_Daily] pd with(nolock)
	inner join Assets_Info ai on pd.ContractId=ai.ContractId and ai.DATE_CLOSE>=@EndDate
	where pd.InvestorId = @InvestorId and pd.ContractId = @ContractId
	union all
	select PortfolioDate = max(PortfolioDate)
	from [dbo].[PortFolio_Daily_Last] pdl with(nolock)
	inner join Assets_Info ai on pdl.ContractId=ai.ContractId and ai.DATE_CLOSE>=@EndDate
	where pdl.InvestorId = @InvestorId and pdl.ContractId = @ContractId
) as res

if @PortfolioDateMax is not null
begin
	if @EndDate > @PortfolioDateMax
	begin
		set @EndDate = @PortfolioDateMax;
	end
end

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
	FROM [dbo].[Assets_Contracts] NOLOCK
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
	FROM [dbo].[Assets_ContractsLast] NOLOCK
	WHERE InvestorId = @InvestorId and ContractId = @ContractId
) AS R
WHERE [Date] >= @StartDate and [Date] <= @EndDate
--ORDER BY [Date]


--select * From #ResInvAssets
--order by [Date];

-----------------------------------------------
-- преобразование на начальную и последнюю дату

SELECT
	@Sum_INPUT_VALUE_RUR1 = sum(INPUT_VALUE_RUR),
	@Sum_OUTPUT_VALUE_RUR1 = sum(OUTPUT_VALUE_RUR),
	@Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
	@Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
FROM #ResInvAssets
-- забыть вводы выводы на первую дату
update #ResInvAssets set
	VALUE_RUR = CASE WHEN @StartDate=@MinDate THEN  VALUE_RUR
						 ELSE VALUE_RUR - DailyIncrement_RUR - DailyDecrement_RUR
						 END,
	VALUE_USD = VALUE_USD - DailyIncrement_USD - DailyDecrement_USD,
	VALUE_EURO = VALUE_EURO - DailyIncrement_EURO - DailyDecrement_EURO,

	DailyIncrement_RUR = 0, DailyIncrement_USD = 0,	DailyIncrement_EURO = 0,
	DailyDecrement_RUR = 0,	DailyDecrement_USD = 0,	DailyDecrement_EURO = 0,
	INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
	INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
	INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
where [Date] = @StartDate
and (DailyDecrement_RUR <> 0 or DailyIncrement_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

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
and (DailyDecrement_RUR <> 0 or DailyIncrement_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

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
	@AmountDayPlus_RUR = sum(INPUT_VALUE_RUR),
	@Sum_INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
	@Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR)
	--@Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
	--@Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
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
			[AmountDayPlus_RUR] = INPUT_VALUE_RUR + INPUT_COUPONS_RUR + INPUT_DIVIDENTS_RUR,
			[AmountDayMinus_RUR] = OUTPUT_VALUE_RUR
		FROM #ResInvAssets
		where (
			[Date] in (@StartDate, @EndDate) or
			(
				INPUT_VALUE_RUR <> 0 or OUTPUT_VALUE_RUR <> 0  or INPUT_DIVIDENTS_RUR <> 0 or INPUT_COUPONS_RUR <> 0
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
	/*
	select
	@InvestResult as 'Результат инвестиций', @ResutSum as 'Средневзвешенная сумма вложенных средств',
	@InvestResult/@ResutSum * 100 as 'Доходность в %',
    @InvestResult as 'Доходность абсолютная',
	@StartDate as 'Дата начала',
	@EndDate as 'Дата завершения',
	@SumT as 'Количество дней'
	*/
Declare @DATE_OPEN date, @NUM Nvarchar(100);

select
	@DATE_OPEN = DATE_OPEN,
	@NUM = NUM
from [dbo].[Assets_Info] NOLOCK
where [InvestorId] = @InvestorId and [ContractId] = @ContractId;

if @ResutSum = 0 set @ResutSum = NULL;

select
	ActiveDateToName = 'Активы на ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ActiveDateToValue =  CAST(Round(@SItog,2) as Decimal(30,2)),
	ProfitName = 'Доход за период ' + FORMAT(@StartDate,'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ProfitValue = CAST(Round(@InvestResult,2) as Decimal(30,2)),
	ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
	OpenDate = @DATE_OPEN,
	LS_NUM = @NUM,
	EndSumAmount = 99999.99,
	FundName = @NUM,
	InvestorName = @NUM,
	ContractNumber = @NUM,
	Fee = 99.99,
	ContractOpenDate = @DATE_OPEN,
	SuccessFee = 99.99,
	DateFromName = @StartDate,
	Valuta = @Valuta;

select ActiveName = 'Активы на ' + FORMAT(@StartDate,'dd.MM.yyyy') , ActiveValue = CAST(Round(@Snach,2) as Decimal(38,2)), Sort = 1, Valuta = @Valuta
union
--select 'Пополнения', CAST(Round(@Sum_INPUT_VALUE_RUR1,2) as Decimal(30,2)), 2, Valuta = @Valuta
select 'Пополнения', CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)), 2, Valuta = @Valuta
union
--select 'Выводы', CAST(Round(@Sum_OUTPUT_VALUE_RUR1,2) as Decimal(30,2)), 3, Valuta = @Valuta
select 'Выводы', CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)), 3, Valuta = @Valuta
union
select 'Дивиденды', @Sum_INPUT_DIVIDENTS_RUR, 4, Valuta = @Valuta
union
select 'Купоны', @Sum_INPUT_COUPONS_RUR, 5, Valuta = @Valuta
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



select ActiveName = 'Активы на ' + FORMAT(@StartDate,'dd.MM.yyyy') , ActiveValue = CAST(Round(@Snach,2) as Decimal(38,2)),
--[InVal] = CAST(Round(@Sum_INPUT_VALUE_RUR1,2) as Decimal(30,2)),
[InVal] = CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)),
--[OutVal] = CAST(Round(@Sum_OUTPUT_VALUE_RUR1,2) as Decimal(30,2)),
[OutVal] = CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)),
[Dividends] = @Sum_INPUT_DIVIDENTS_RUR, 
[Coupons] = @Sum_INPUT_COUPONS_RUR,
[Valuta] = @Valuta


-- Дивиденты, купоны - график
;WITH cte AS
(
  SELECT 
    [Iter]      = CAST(1 AS INT),
    [DateFrom]  = DATEFROMPARTS(YEAR(@EndDate),MONTH(@EndDate),1),
    [DateTo]    = DATEADD(MONTH,1, DATEFROMPARTS(YEAR(@EndDate),MONTH(@EndDate),1))
  
  UNION ALL
  
  SELECT 
    [Iter] + 1,
    DATEADD(MONTH,-1,[DateFrom]) ,
    DATEADD(MONTH,-1,[DateTo]) 
  FROM cte
  WHERE [Iter] < 12
)
SELECT
	[Date] = [DateFrom],
	[Dividends] = SUM([INPUT_DIVIDENTS_RUR]),
	[Coupons] = SUM([INPUT_COUPONS_RUR]),
	[Valuta] = MAX([Valuta])
FROM cte 
LEFT JOIN 
(
    SELECT
		[INPUT_DIVIDENTS_RUR], [INPUT_COUPONS_RUR], [Date], [Valuta] = @Valuta
    FROM #ResInvAssets 
    --WHERE INPUT_DIVIDENTS_RUR <> 0 or INPUT_DIVIDENTS_USD <> 0
)r ON r.[Date] BETWEEN [DateFrom] AND DATEADD(DAY,-1,[DateTo])
GROUP BY [DateFrom]
ORDER BY [DateFrom];


-- Детализация купонов и дивидендов
select
	[Date] =  a.[PaymentDateTime],
	[ToolName] = a.[ShareName],
	[PriceType] = case when a.[Type] = 1 then 'Купоны' else 'Дивиденды' end,
	[ContractName] = a.[ShareName],
	[Price] =
		--CAST(Round(a.[AmountPayments_RUR],2) as Decimal(30,2)),
		case
			when @Valuta = 'RUB' then CAST(Round(a.[AmountPayments_RUR],2) as Decimal(30,2))
			when @Valuta = 'USD' then CAST(Round(a.[AmountPayments_USD],2) as Decimal(30,2))
			when @Valuta = 'EUR' then CAST(Round(a.[AmountPayments_EURO],2) as Decimal(30,2))
			else CAST(Round(a.[AmountPayments_RUR],2) as Decimal(30,2))
		end,
	a.[PaymentDateTime],
	[RowPrice] = a.AmountPayments,
	[RowValuta] = @Valuta,
	[Valuta] = c.ShortName
from [dbo].[DIVIDENDS_AND_COUPONS_History] as a
join dbo.Currencies as c on a.CurrencyId = c.Id
where a.InvestorId = @InvestorId and a.ContractId = @ContractId
and (@StartDate is null or (@StartDate is not null and a.PaymentDateTime >= @StartDate))
and (@EndDate is null or (@EndDate is not null and a.PaymentDateTime < @EndDate))
and case
			when @Valuta = 'RUB' then a.[AmountPayments_RUR]
			when @Valuta = 'USD' then a.[AmountPayments_USD]
			when @Valuta = 'EUR' then a.[AmountPayments_EURO]
			else a.[AmountPayments_RUR]
		end > 0
union all
select
	[Date] =  a.[PaymentDateTime],
	[ToolName] = a.[ShareName],
	[PriceType] = case when a.[Type] = 1 then 'Купоны' else 'Дивиденды' end,
	[ContractName] = a.[ShareName],
	[Price] =
		--CAST(Round(a.[AmountPayments_RUR],2) as Decimal(30,2)),
		case
			when @Valuta = 'RUB' then CAST(Round(a.[AmountPayments_RUR],2) as Decimal(30,2))
			when @Valuta = 'USD' then CAST(Round(a.[AmountPayments_USD],2) as Decimal(30,2))
			when @Valuta = 'EUR' then CAST(Round(a.[AmountPayments_EURO],2) as Decimal(30,2))
			else CAST(Round(a.[AmountPayments_RUR],2) as Decimal(30,2))
		end,
	a.[PaymentDateTime],
	[RowPrice] = a.AmountPayments,
	[RowValuta] = @Valuta,
	[Valuta] = c.ShortName
from [dbo].[DIVIDENDS_AND_COUPONS_History_Last] as a
join dbo.Currencies as c on a.CurrencyId = c.Id
where a.InvestorId = @InvestorId and a.ContractId = @ContractId
and (@StartDate is null or (@StartDate is not null and a.PaymentDateTime >= @StartDate))
and (@EndDate is null or (@EndDate is not null and a.PaymentDateTime < @EndDate))
and case
			when @Valuta = 'RUB' then a.[AmountPayments_RUR]
			when @Valuta = 'USD' then a.[AmountPayments_USD]
			when @Valuta = 'EUR' then a.[AmountPayments_EURO]
			else a.[AmountPayments_RUR]
		end > 0
order by [PaymentDateTime];


select
	[Date] = a.[Date],
	[OperName] = a.T_Name,
	a.[ISIN],
	[ToolName] = a.Investment,
	[Price] = CAST(Round(a.[Price],2) as Decimal(30,2)),
	[PaperAmount] = CAST(Round(a.[Amount],2) as Decimal(30,2)),
	[RowValuta] = c.ShortName,
	[RowCost] = CAST(Round(a.[Value_Nom],2) as Decimal(30,2)),
	[Fee] = CAST(Round(a.[Fee],2) as Decimal(30,2)),
	[Status] = N''
from [dbo].[Operations_History_Contracts] as a
join dbo.Currencies as c on a.Currency = c.Id
where a.InvestorId = @InvestorId and a.ContractId = @ContractId
and (@StartDate is null or (@StartDate is not null and a.[Date] >= @StartDate))
and (@EndDate is null or (@EndDate is not null and a.[Date] <@EndDate))
union
select
	[Date] = a.[Date],
	[OperName] = a.T_Name,
	a.[ISIN],
	[ToolName] = a.Investment,
	[Price] = CAST(Round(a.[Price],2) as Decimal(30,2)),
	[PaperAmount] = CAST(Round(a.[Amount],2) as Decimal(30,2)),
	[RowValuta] = c.ShortName,
	[RowCost] = CAST(Round(a.[Value_Nom],2) as Decimal(30,2)),
	[Fee] = CAST(Round(a.[Fee],2) as Decimal(30,2)),
	[Status] = N''
from [dbo].[Operations_History_Contracts_Last] as a
join dbo.Currencies as c on a.Currency = c.Id
where a.InvestorId = @InvestorId and a.ContractId = @ContractId
and (@StartDate is null or (@StartDate is not null and a.[Date] >= @StartDate))
and (@EndDate is null or (@EndDate is not null and a.[Date] < @EndDate))
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
	from [dbo].[PortFolio_Daily] with(nolock)
	where InvestorId = @InvestorId and ContractId = @ContractId
	and PortfolioDate =  @EndDate
	union all
	select * 
	from [dbo].[PortFolio_Daily_Last] with(nolock)
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
inner join [dbo].[ClassCategories] as cc on a.CLASS = cc.ClassId
inner join [dbo].[Categories] as c on cc.CategoryId = c.Id
group by c.id, c.CategoryName, a.CUR_ID



--------------------------------
--- расчёт уровня 3
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



-- начальная дата
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


-- конечная дата
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


-- позиции на начало
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


-- позиции на конец
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

-- список бумаг на конец периода
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

-- посчитали SumInput
update a set 
	InvestResult = (SumEnd + SumOutput) - (SumStart + SumInput)
from #SumStart as a;


-- посчитали InvestResult

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
        
				-- начальную дату пропускаем
				if @DateCCur = @StartDate
				begin
					set @LastDDate = @DateCCur
				end
				else
				begin
					-- со второй записи определ¤ем период
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

			-- фиксация до последнего дня
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

	-- результат
	--select * from #SumStart
--- расчёт уровня 3
--------------------------------


-- tree3
SELECT
  c.CategoryName,
	ChildId = cast(a.InvestmentId as BigInt),
	TypeId = cast(c.id as BigInt),
	ChildName = i.Investment,
	ValutaId = cast(a.CUR_ID as BigInt),
	Valuta = cr.ShortName,
	Price =  CAST(Round(a.[VALUE_NOM],2) as Decimal(30,2)),
	Ammount = case when c.Id <> 4 then CAST(Round(a.[AMOUNT],2) as Decimal(30,2))  else NULL end,
	Detail = CAST(Round(rst.InvestResult,2) as Decimal(30,2)),
	ResultProcent = CAST(Round(rst.InvestResultProcent,2) as Decimal(30,2))
from #TrustTree as a
inner join [dbo].[ClassCategories] as cc on a.CLASS = cc.ClassId
inner join [dbo].[Categories] as c on cc.CategoryId = c.Id
inner join [dbo].[InvestmentIds] as i on a.InvestmentId = i.Id
left join  [dbo].[Currencies] as cr on a.CUR_ID = cr.id
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
	from [dbo].[POSITION_KEEPING] as a with(nolock)
	where a.InvestorId = @InvestorId and a.ContractId = @ContractId
	and Fifo_Date =  @EndDate
	union all
	select * 
	from [dbo].[POSITION_KEEPING_Last] as a with(nolock)
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
	from [dbo].[POSITION_KEEPING] as a with(nolock)
	where a.InvestorId = @InvestorId and a.ContractId = @ContractId
	and Fifo_Date = @StartDate
	union all
	select * 
	from [dbo].[POSITION_KEEPING_Last] as a with(nolock)
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

-- tree4
select
	Child2Id = a.Id,
	ChildId = b.InvestmentId,
	Child2Name = i.Investment,
	Price = CAST(Round(a.VALUE_NOM + a.NKD,2) as Decimal(30,2)),
	Valuta = c.ShortName,
	Ammount = a.Amount,
	a.FinRes,
	a.FinResProcent
from #POSITION_KEEPING_EndDate as a with(nolock)
inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
inner join [dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
left join [dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id

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
			Price = CAST(Round(a.VALUE_NOM,2) as Decimal(30,2)),
			a.Amount,
			Valuta = c.ShortName,
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
		inner join [dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
		inner join [dbo].[ClassCategories] as cc with(nolock) on a.Class = cc.ClassId and cc.CategoryId = @CategoryId
		inner join [dbo].[Categories] as cg on cc.CategoryId = cg.Id
		left join [dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id
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
			Price = CAST(Round(a.VALUE_NOM,2) as Decimal(30,2)),
			a.Amount,
			Valuta = c.ShortName,
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
		inner join [dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
		inner join [dbo].[ClassCategories] as cc with(nolock) on a.Class = cc.ClassId and cc.CategoryId = @CategoryId
		inner join [dbo].[Categories] as cg on cc.CategoryId = cg.Id
		left join [dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id
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


;WITH c AS 
(
    select
			cc.CategoryId,
			cg.CategoryName,
      c.Symbol,
      i.Investment,
      a.VALUE_NOM,
      a.Amount,
      a.FinRes,
      a.FinResProcent
		from #POSITION_KEEPING_EndDate as a with(nolock)
		inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
		inner join [CacheDB].[dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
		inner join [dbo].[ClassCategories] as cc with(nolock) on a.Class = cc.ClassId
		inner join [dbo].[Categories] as cg on cc.CategoryId = cg.Id
		left join [CacheDB].[dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id
		where isnull(a.IsActive,0) = 1
)
SELECT CategoryName,Investment,Symbol,
    Amount_Sum = SUM(Amount),
    VALUE_NOM_Sum = ROUND(SUM(Value_NOM),2),
    FinRes_Sum = ROUND(SUM(FinRes),2),
    FinResProcent_Sum = SUM(FinResProcent)
FROM c
GROUP BY CategoryName,Investment,Symbol

  select
			cc.CategoryId,
			cg.CategoryName,
      c.Symbol,
      i.Investment,
      a.VALUE_NOM,
      a.Amount,
      a.FinRes,
      a.FinResProcent
		from #POSITION_KEEPING_EndDate as a with(nolock)
		inner join #TrustTree as b with(nolock) on a.ShareId = b.VALUE_ID
		inner join [CacheDB].[dbo].[InvestmentIds] as i with(nolock) on b.InvestmentId = i.Id
		inner join [dbo].[ClassCategories] as cc with(nolock) on a.Class = cc.ClassId
		inner join [dbo].[Categories] as cg on cc.CategoryId = cg.Id
		left join [CacheDB].[dbo].[Currencies] as c with(nolock) on a.CUR_ID = c.Id
		where isnull(a.IsActive,0) = 1

SELECT 
  [MinDate]       = @MinDate,
  [MaxDate]       = @MaxDate,
  [ContractName]  = (
	SELECT TOP 1
		a.NUM + isnull(' ' + b.strategy,'')
	FROM [dbo].[Assets_Info] as a
	left join [dbo].[Assets_Strategy] as b on a.strategyguid = b.strategyguid
	WHERE a.ContractId = @ContractId AND a.InvestorId = @InvestorId
	)


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