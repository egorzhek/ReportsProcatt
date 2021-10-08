DECLARE @ToDateStr     Nvarchar(50) = @DateToSharp;
DECLARE @FromDateStr   Nvarchar(50) = @DateFromSharp;
DECLARE @InvestorIdStr Nvarchar(50) = @InvestorIdSharp;
--DECLARE @ContractIdStr Nvarchar(50) = @ContractIdSharp;
DECLARE @Valuta        Nvarchar(10) = @ValutaSharp;

if @Valuta is null set @Valuta = 'RUB';

DECLARE
    @InvestorId int = CAST(@InvestorIdStr as Int);
DECLARE
	@ContractId int = @InvestorId,
    @StartDate Date = CONVERT(Date, @FromDateStr, 103),
    @EndDate Date = CONVERT(Date, @ToDateStr, 103);
DECLARE
	@CurrDate Date = isnull(@EndDate, GetDate());

declare @MinDate date, @MaxDate date

Declare @SItog numeric(30,10), @AmountDayMinus_RUR numeric(30,10), @Snach numeric(30,10), @AmountDayPlus_RUR numeric(30,10),
@Sum_INPUT_VALUE_RUR  numeric(30,10),
@Sum_OUTPUT_VALUE_RUR numeric(30,10), @Sum_OUTPUT_VALUE_RUR1 numeric(30,10), @Sum_OUTPUT_VALUE_RUR2 numeric(30,10),
@Sum_INPUT_COUPONS_RUR numeric(30,10),
@Sum_INPUT_DIVIDENTS_RUR numeric(30,10),
@InvestResult numeric(30,10);

SELECT
	@MinDate = min([Date]),
	@MaxDate = max([Date])
FROM
(
	SELECT a.[Date]
	FROM [dbo].[InvestorFundDate] as a with(nolock)
	join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id
	where a.Investor = @InvestorId and b.DATE_CLOSE >= @CurrDate
	UNION
	SELECT a.[Date]
	FROM [dbo].[InvestorFundDateLast] as a with(nolock)
	join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id
	where a.Investor = @InvestorId and b.DATE_CLOSE >= @CurrDate
	UNION
	SELECT a.[Date]
	FROM [dbo].[Assets_Contracts] as a with(nolock)
	join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId
	where a.InvestorId = @InvestorId and b.DATE_CLOSE >= @CurrDate
	UNION
	SELECT a.[Date]
	FROM [dbo].[Assets_ContractsLast] as a with(nolock)
	join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId
	where a.InvestorId = @InvestorId and b.DATE_CLOSE >= @CurrDate
) AS R

if @StartDate is null set @StartDate = @MinDate;
if @StartDate < @MinDate set @StartDate = @MinDate;
if @StartDate > @MaxDate set @StartDate = @MinDate;

if @EndDate is null    set @EndDate = @MaxDate;
if @EndDate > @MaxDate set @EndDate = @MaxDate;
if @EndDate < @MinDate set @EndDate = @MaxDate;


declare @FundReSult table
(
    FundId Int NULL,
    FundName NVarchar(300) NULL,
    ProfitValue decimal(28,10) NULL,
    ProfitProcentValue decimal(28,10) NULL,
    BeginValue decimal(28,10) NULL,
    EndValue decimal(28,10) NULL,
	Valuta NVarchar(10),
    InvestResult decimal(28,10) NULL,
    ResutSum decimal(28,10) NULL
);

declare @ContractReSult table
(
	ContractId Int NULL,
	ContractName NVarchar(300) NULL,
	ProfitValue decimal(28,10) NULL,
	ProfitProcentValue decimal(28,10) NULL,
	BeginValue decimal(28,10) NULL,
	EndValue decimal(28,10) NULL,
	Valuta NVarchar(300) NULL,
	InvestResult decimal(28,10) NULL,
	ResutSum decimal(28,10) NULL
);

insert into @FundReSult
EXEC [dbo].[GetInvestorFunds]
		@Investor = @InvestorId,
		@StartDate = @StartDate,
		@EndDate = @EndDate,
		@Valuta = @Valuta

insert into @ContractReSult
EXEC [dbo].[GetInvestorContracts]
		@InvestorId = @InvestorId,
		@StartDate = @StartDate,
		@EndDate = @EndDate,
		@Valuta = @Valuta


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
	InvestorId, ContractId, [Date],
	USDRATE = max(USDRATE),
	EURORATE = max(EURORATE),
	VALUE_RUR = sum(VALUE_RUR),
	VALUE_USD = sum(VALUE_USD),
	VALUE_EURO = sum(VALUE_EURO),
	INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
	INPUT_VALUE_USD = sum(INPUT_VALUE_USD),
	INPUT_VALUE_EURO = sum(INPUT_VALUE_EURO),
	OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
	OUTPUT_VALUE_USD = sum(OUTPUT_VALUE_USD),
	OUTPUT_VALUE_EURO = sum(OUTPUT_VALUE_EURO),
	INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR),
	INPUT_DIVIDENTS_USD = sum(INPUT_DIVIDENTS_USD),
	INPUT_DIVIDENTS_EURO = sum(INPUT_DIVIDENTS_EURO),
	INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
	INPUT_COUPONS_USD = sum(INPUT_COUPONS_USD),
	INPUT_COUPONS_EURO = sum(INPUT_COUPONS_EURO),
	OUTPUT_VALUE_RUR1 = sum(OUTPUT_VALUE_RUR1),
	OUTPUT_VALUE_RUR2 = sum(OUTPUT_VALUE_RUR2)
	from
	(
		select
			InvestorId = a.Investor,
			ContractId = a.Investor,
			a.[Date], a.USDRATE, EURORATE = a.EVRORATE, a.VALUE_RUR,
			a.VALUE_USD, VALUE_EURO = a.VALUE_EVRO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.AmountDayPlus_RUR
				when @Valuta = 'USD' then a.AmountDayPlus_USD
				when @Valuta = 'EUR' then a.AmountDayPlus_EVRO
				else a.AmountDayPlus_RUR
			end,
			INPUT_VALUE_USD = a.AmountDayPlus_USD,
			INPUT_VALUE_EURO = a.AmountDayPlus_EVRO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.AmountDayMinus_RUR
				when @Valuta = 'USD' then a.AmountDayMinus_USD
				when @Valuta = 'EUR' then a.AmountDayMinus_EVRO
				else a.AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_USD = a.AmountDayMinus_USD,
			OUTPUT_VALUE_EURO = a.AmountDayMinus_EVRO,


			INPUT_DIVIDENTS_RUR = 0.0000000000,
			INPUT_DIVIDENTS_USD = 0.0000000000,
			INPUT_DIVIDENTS_EURO = 0.0000000000,
			INPUT_COUPONS_RUR = 0.0000000000,
			INPUT_COUPONS_USD = 0.0000000000,
			INPUT_COUPONS_EURO = 0.0000000000,
			OUTPUT_VALUE_RUR1 =
			case
				when @Valuta = 'RUB' then a.AmountDayMinus_RUR
				when @Valuta = 'USD' then a.AmountDayMinus_USD
				when @Valuta = 'EUR' then a.AmountDayMinus_EVRO
				else a.AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_RUR2 = 0.000
		from InvestorFundDate as a with(nolock)
		join dbo.FundNames as b with(nolock) on a.FundId = b.Id and b.DATE_CLOSE >= @EndDate
		where a.Investor = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
		union all
		select
			InvestorId = a.Investor,
			ContractId = a.Investor,
			a.[Date], a.USDRATE, EURORATE = a.EVRORATE, a.VALUE_RUR,
			a.VALUE_USD, VALUE_EURO = a.VALUE_EVRO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.AmountDayPlus_RUR
				when @Valuta = 'USD' then a.AmountDayPlus_USD
				when @Valuta = 'EUR' then a.AmountDayPlus_EVRO
				else a.AmountDayPlus_RUR
			end,
			INPUT_VALUE_USD = a.AmountDayPlus_USD,
			INPUT_VALUE_EURO = a.AmountDayPlus_EVRO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.AmountDayMinus_RUR
				when @Valuta = 'USD' then a.AmountDayMinus_USD
				when @Valuta = 'EUR' then a.AmountDayMinus_EVRO
				else a.AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_USD = a.AmountDayMinus_USD,
			OUTPUT_VALUE_EURO = a.AmountDayMinus_EVRO,


			INPUT_DIVIDENTS_RUR = 0.0000000000,
			INPUT_DIVIDENTS_USD = 0.0000000000,
			INPUT_DIVIDENTS_EURO = 0.0000000000,
			INPUT_COUPONS_RUR = 0.0000000000,
			INPUT_COUPONS_USD = 0.0000000000,
			INPUT_COUPONS_EURO = 0.0000000000,
			OUTPUT_VALUE_RUR1 =
			case
				when @Valuta = 'RUB' then a.AmountDayMinus_RUR
				when @Valuta = 'USD' then a.AmountDayMinus_USD
				when @Valuta = 'EUR' then a.AmountDayMinus_EVRO
				else a.AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_RUR2 = 0.000
		from InvestorFundDateLast as a with(nolock)
		join dbo.FundNames as b with(nolock) on a.FundId = b.Id and b.DATE_CLOSE >= @EndDate
		where a.Investor = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
		union all
		select
			a.InvestorId,
			ContractId = a.InvestorId,
			a.[Date], a.USDRATE, a.EURORATE,

			VALUE_RUR =
			case
				when @Valuta = 'RUB' and a.[Date] = @StartDate then a.VALUE_RUR 
				when @Valuta = 'RUB' and a.[Date] > @StartDate then a.VALUE_RUR - a.[DailyIncrement_RUR] - a.[DailyDecrement_RUR]
				when @Valuta = 'USD' and a.[Date] = @StartDate then a.VALUE_USD 
				when @Valuta = 'USD' and a.[Date] > @StartDate then a.VALUE_USD - a.[DailyIncrement_USD] - a.[DailyDecrement_USD]
				when @Valuta = 'EUR' and a.[Date] = @StartDate then a.VALUE_EURO 
				when @Valuta = 'EUR' and a.[Date] > @StartDate then a.VALUE_EURO - a.[DailyIncrement_EURO] - a.[DailyDecrement_EURO]
				else a.VALUE_RUR
			end,
			a.VALUE_USD,
			a.VALUE_EURO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.INPUT_VALUE_RUR
				when @Valuta = 'USD' then a.INPUT_VALUE_USD
				when @Valuta = 'EUR' then a.INPUT_VALUE_EURO
				else a.INPUT_VALUE_RUR
			end,
			a.INPUT_VALUE_USD,
			a.INPUT_VALUE_EURO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then a.OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then a.OUTPUT_VALUE_EURO
				else a.OUTPUT_VALUE_RUR
			end,
			a.OUTPUT_VALUE_USD,
			a.OUTPUT_VALUE_EURO,

			INPUT_DIVIDENTS_RUR =
			case
				when @Valuta = 'RUB' then a.INPUT_DIVIDENTS_RUR
				when @Valuta = 'USD' then a.INPUT_DIVIDENTS_USD
				when @Valuta = 'EUR' then a.INPUT_DIVIDENTS_EURO
				else a.INPUT_DIVIDENTS_RUR
			end,
			a.INPUT_DIVIDENTS_USD,
			a.INPUT_DIVIDENTS_EURO,

			INPUT_COUPONS_RUR =
			case
				when @Valuta = 'RUB' then a.INPUT_COUPONS_RUR
				when @Valuta = 'USD' then a.INPUT_COUPONS_USD
				when @Valuta = 'EUR' then a.INPUT_COUPONS_EURO
				else a.INPUT_COUPONS_RUR
			end,
			a.INPUT_COUPONS_USD,
			a.INPUT_COUPONS_EURO,
			OUTPUT_VALUE_RUR1 = 0.000,
			OUTPUT_VALUE_RUR2 =
			case
				when @Valuta = 'RUB' then a.OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then a.OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then a.OUTPUT_VALUE_EURO
				else a.OUTPUT_VALUE_RUR
			end
		FROM [dbo].[Assets_Contracts] as a with(nolock)
		join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId and b.DATE_CLOSE >= @EndDate
		where a.InvestorId = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
		union all
		select
			a.InvestorId,
			ContractId = a.InvestorId,
			a.[Date], a.USDRATE, a.EURORATE,

			VALUE_RUR =
			case
				when @Valuta = 'RUB' and a.[Date] = @StartDate then a.VALUE_RUR 
				when @Valuta = 'RUB' and a.[Date] > @StartDate then a.VALUE_RUR - a.[DailyIncrement_RUR] - a.[DailyDecrement_RUR]
				when @Valuta = 'USD' and a.[Date] = @StartDate then a.VALUE_USD 
				when @Valuta = 'USD' and a.[Date] > @StartDate then a.VALUE_USD - a.[DailyIncrement_USD] - a.[DailyDecrement_USD]
				when @Valuta = 'EUR' and a.[Date] = @StartDate then a.VALUE_EURO 
				when @Valuta = 'EUR' and a.[Date] > @StartDate then a.VALUE_EURO - a.[DailyIncrement_EURO] - a.[DailyDecrement_EURO]
				else a.VALUE_RUR
			end,
			a.VALUE_USD,
			a.VALUE_EURO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.INPUT_VALUE_RUR
				when @Valuta = 'USD' then a.INPUT_VALUE_USD
				when @Valuta = 'EUR' then a.INPUT_VALUE_EURO
				else a.INPUT_VALUE_RUR
			end,
			a.INPUT_VALUE_USD,
			a.INPUT_VALUE_EURO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then a.OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then a.OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then a.OUTPUT_VALUE_EURO
				else a.OUTPUT_VALUE_RUR
			end,
			a.OUTPUT_VALUE_USD,
			a.OUTPUT_VALUE_EURO,

			INPUT_DIVIDENTS_RUR =
			case
				when @Valuta = 'RUB' then a.INPUT_DIVIDENTS_RUR
				when @Valuta = 'USD' then a.INPUT_DIVIDENTS_USD
				when @Valuta = 'EUR' then a.INPUT_DIVIDENTS_EURO
				else a.INPUT_DIVIDENTS_RUR
			end,
			a.INPUT_DIVIDENTS_USD,
			a.INPUT_DIVIDENTS_EURO,

			INPUT_COUPONS_RUR =
			case
				when @Valuta = 'RUB' then a.INPUT_COUPONS_RUR
				when @Valuta = 'USD' then a.INPUT_COUPONS_USD
				when @Valuta = 'EUR' then a.INPUT_COUPONS_EURO
				else a.INPUT_COUPONS_RUR
			end,
			a.INPUT_COUPONS_USD,
			a.INPUT_COUPONS_EURO,
			OUTPUT_VALUE_RUR1 = 0.000,
			OUTPUT_VALUE_RUR2 =
			case
				when @Valuta = 'RUB' then a.OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then a.OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then a.OUTPUT_VALUE_EURO
				else a.OUTPUT_VALUE_RUR
			end
		FROM [dbo].[Assets_ContractsLast] as a with(nolock)
		join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId and b.DATE_CLOSE >= @EndDate
		where a.InvestorId = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
	)
	as res
	group by InvestorId, ContractId, [Date]
) AS R





-----------------------------------------------
-- преобразование на начальную и последнюю дату

-- забыть вводы выводы на первую дату
update #ResInvAssets set
	--DailyIncrement_RUR = 0, DailyIncrement_USD = 0,	DailyIncrement_EURO = 0,
	--DailyDecrement_RUR = 0,	DailyDecrement_USD = 0,	DailyDecrement_EURO = 0,
	INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
	INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
	INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR1 = 0, OUTPUT_VALUE_RUR2 = 0
where [Date] = @StartDate
and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

-- посчитать последний день обратно
update a set 
VALUE_RUR = VALUE_RUR - INPUT_VALUE_RUR - OUTPUT_VALUE_RUR,
VALUE_USD = VALUE_USD - INPUT_VALUE_USD - OUTPUT_VALUE_USD,
VALUE_EURO = VALUE_EURO - INPUT_VALUE_EURO - OUTPUT_VALUE_EURO,

-- DailyIncrement_RUR = 0, DailyIncrement_USD = 0,	DailyIncrement_EURO = 0,
-- DailyDecrement_RUR = 0,	DailyDecrement_USD = 0,	DailyDecrement_EURO = 0,
INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR1 = 0, OUTPUT_VALUE_RUR2 = 0
from #ResInvAssets as a
where [Date] = @EndDate
and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

-- преобразование на начальную и последнюю дату
-----------------------------------------------

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
	@Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
	@Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
	@Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR),
	@Sum_OUTPUT_VALUE_RUR1 = sum(OUTPUT_VALUE_RUR1),
	@Sum_OUTPUT_VALUE_RUR2 = sum(OUTPUT_VALUE_RUR2)
FROM #ResInvAssets

set @InvestResult =
(@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
- (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'


	declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
		@SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0

	declare obj_cur cursor local fast_forward for
		-- 
		SELECT
			[Date],
			[AmountDayPlus_RUR] = INPUT_VALUE_RUR,
			[AmountDayMinus_RUR] = OUTPUT_VALUE_RUR
		FROM #ResInvAssets
		where (
			[Date] in (@StartDate, @EndDate) or
			(
				INPUT_VALUE_RUR <> 0 or OUTPUT_VALUE_RUR <> 0
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

	if @ResutSum = 0 set @ResutSum = NULL;

/*
Declare @DATE_OPEN date, @NUM Nvarchar(100);

select
	@DATE_OPEN = DATE_OPEN,
	@NUM = NUM
from [dbo].[Assets_Info] NOLOCK
where [InvestorId] = @InvestorId; --and [ContractId] = @ContractId;
*/

declare @FProfitValue decimal(28,10), @FInvestResult decimal(28,10), @FResutSum decimal(28,10), @FProcentValue decimal(28,10);

select
	@FProfitValue = sum(ProfitValue),
	@FInvestResult = sum(InvestResult),
	@FResutSum = sum(ResutSum)
from
(
	select
		ProfitValue, InvestResult, ResutSum
	from @FundReSult
	union all
	select
		ProfitValue, InvestResult, ResutSum
	from @ContractReSult
) as res;

if @FResutSum <> 0
begin
	set @FProcentValue = @FInvestResult/@FResutSum * 100.00;
end
else
begin
	set @FProcentValue = 0;
end

select
	ActiveDateToName = N'Сумма активов на дату окончания периода',
	ActiveDateToValue =  CAST(Round(@SItog,2) as Decimal(30,2)),
	ProfitName = N'ОТЧЁТ ПО ПОРТФЕЛЮ / ' + FORMAT(@StartDate,'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ProfitValue = CAST(Round(@FProfitValue,2) as Decimal(30,2)),
	ProfitProcentValue = CAST(Round(@FProcentValue,2) as Decimal(38,2)),
	--OpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	LS_NUM = '2940000083',
	EndSumAmount = 99999.99,
	--FundName = @NUM,
	--InvestorName = @NUM,
	--ContractNumber = @NUM,
	Fee = 99.99,
	--ContractOpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	SuccessFee = 99.99,
	DateFromName = FORMAT(@StartDate,'dd.MM.yyyy'),
	DateToName = FORMAT(@EndDate,'dd.MM.yyyy'),
	Comment1 = N'Сумма дохода',
	Comment2 = N'Относительная доходность',
	StartDate = @StartDate,
	EndDate = @EndDate,
	Valuta = @Valuta

/*
select ActiveName = 'Активы на ' + FORMAT(@StartDate,'dd.MM.yyyy') , ActiveValue = CAST(Round(@Snach,2) as Decimal(38,2)), Sort = 1
union
select 'Пополнения', CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)), 2
union
select 'Выводы', CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)), 3
union
select 'Дивиденды', @Sum_INPUT_DIVIDENTS_RUR, 4
union
select 'Купоны', @Sum_INPUT_COUPONS_RUR, 5
order by 3;
*/

select
	Snach = CAST(Round(@Snach,2) as Decimal(38,2)),
	InVal = CAST(Round(@Sum_INPUT_VALUE_RUR,2) as Decimal(30,2)),
	OutVal = CAST(Round(@Sum_OUTPUT_VALUE_RUR,2) as Decimal(30,2)),
	Dividents = CAST(Round(@Sum_INPUT_DIVIDENTS_RUR,2) as Decimal(30,2)),
	Coupons = CAST(Round(@Sum_INPUT_COUPONS_RUR,2) as Decimal(30,2)),
	OutVal1 = CAST(Round(@Sum_OUTPUT_VALUE_RUR1,2) as Decimal(30,2)),
	OutVal2 = CAST(Round(@Sum_OUTPUT_VALUE_RUR2,2) as Decimal(30,2)),
	Valuta = @Valuta


/*
select ActiveName = 'Всего', ActiveValue = CAST(Round(@Sum_INPUT_DIVIDENTS_RUR + @Sum_INPUT_COUPONS_RUR,2) as Decimal(30,2)), Sort = 1, Color = '#FFFFFF'
union
select 'Дивиденды', CAST(Round(@Sum_INPUT_DIVIDENTS_RUR,2) as Decimal(30,2)), 4, '#7FE5F0'
union
select 'Купоны', CAST(Round(@Sum_INPUT_COUPONS_RUR,2) as Decimal(30,2)), 5, '#4CA3DD'
order by 3;
*/




Declare @Categories table
(
	CategoryId Int, CategoryName NVarChar(200), CategoryVal decimal(28,10)
);

insert into @Categories
(
	CategoryId, CategoryName, CategoryVal
)
values
(1, N'Акции', 25.000),
(2, N'Облигации', 10.000),
(3, N'Вексели', 40.000),
(4, N'Валюта', 25.000);

-- Состав фонда
select * from @Categories
order by CategoryId

-- Надпись внутри пайчарта
select DonutLabel1 = N'6 405 ₽', DonutLabel2 = N'4 актива'

    -- Fifth
	-- Выдаёт Список ПИФОВ
	select
		FundId,
        FundName,
        ProfitValue = CAST([dbo].f_Round(ProfitValue, 2) AS DECIMAL(30,2)),
        ProfitProcentValue = CAST([dbo].f_Round(ProfitProcentValue, 2) AS DECIMAL(30,2)),
        BeginValue = CAST([dbo].f_Round(BeginValue, 2) AS DECIMAL(30,2)),
        EndValue = CAST([dbo].f_Round(EndValue, 2) AS DECIMAL(30,2)),
        Valuta,
        InvestResult,
		ResutSum
	from @FundReSult
	order by FundName

	-- Sixth
	-- выдаёт список ДУ
	select
        ContractId,
        ContractName,
        ProfitValue = CAST([dbo].f_Round(ProfitValue, 2) AS DECIMAL(30,2)),
        ProfitProcentValue = CAST([dbo].f_Round(ProfitProcentValue, 2) AS DECIMAL(30,2)),
        BeginValue = CAST([dbo].f_Round(BeginValue, 2) AS DECIMAL(30,2)),
        EndValue = CAST([dbo].f_Round(EndValue, 2) AS DECIMAL(30,2)),
        Valuta,
        InvestResult,
        ResutSum
    from @ContractReSult
    order by ContractName;

	



	set @FProfitValue = NULL
	set @FInvestResult = NULL
	set @FResutSum = NULL
	set @FProcentValue = NULL

	select
	@FProfitValue = sum(ProfitValue),
	@FInvestResult = sum(InvestResult),
	@FResutSum = sum(ResutSum)
	from
	(
		select
			ProfitValue, InvestResult, ResutSum
		from @FundReSult
	) as res;

	if @FResutSum <> 0
	begin
		set @FProcentValue = @FInvestResult/@FResutSum * 100.00;
	end
	else
	begin
		set @FProcentValue = 0;
	end

  -- Результаты по ПИФам
  EXEC [dbo].[GetInvestorFundResults]
		@InvestorId = @InvestorId,
  		@StartDate = @StartDate,
  		@EndDate = @EndDate,
		@Valuta = @Valuta,
		@ProfitValue = @FProfitValue,
		@ProfitProcentValue = @FProcentValue
	


	set @FProfitValue = NULL
	set @FInvestResult = NULL
	set @FResutSum = NULL
	set @FProcentValue = NULL

	select
	@FProfitValue = sum(ProfitValue),
	@FInvestResult = sum(InvestResult),
	@FResutSum = sum(ResutSum)
	from
	(
		select
			ProfitValue, InvestResult, ResutSum
		from @ContractReSult
	) as res;

	if @FResutSum <> 0
	begin
		set @FProcentValue = @FInvestResult/@FResutSum * 100.00;
	end
	else
	begin
		set @FProcentValue = 0;
	end

  -- Результаты по ДУ
  EXEC [dbo].[GetInvestorContractResults]
		@InvestorId = @InvestorId,
  		@StartDate = @StartDate,
  		@EndDate = @EndDate,
		@Valuta = @Valuta,
		@ProfitValue = @FProfitValue,
		@ProfitProcentValue = @FProcentValue


	set @ContractId = NULL;
IF OBJECT_ID('tempdb..#DivsNCouponsDetails') IS NOT NULL DROP TABLE #DivsNCouponsDetails
	-- Детализация купонов и дивидендов по инвестору - последние 12 мес
	select
		[Date] = a.[PaymentDateTime],
		[ToolName] = a.[ShareName],
		[PriceType] = case when a.[Type] = 1 then N'Купоны' else N'Дивиденды' end,
		[ContractName] = b.NUM,
		[Price] = CAST(Round(
			case
				when @Valuta = 'RUB' then a.AmountPayments_RUR
				when @Valuta = 'USD' then a.AmountPayments_USD
				when @Valuta = 'EUR' then a.AmountPayments_EURO
				else a.AmountPayments_RUR
			end
			,2) as Decimal(30,2)),
		a.[PaymentDateTime],
		Valuta = @Valuta,
		a.[Type],
		RowValuta = c.ShortName,
		RowPrice = a.AmountPayments
    INTO #DivsNCouponsDetails
	from [dbo].[DIVIDENDS_AND_COUPONS_History] as a with(nolock)
	join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId and b.DATE_CLOSE >= @EndDate
	join dbo.Currencies as c with(nolock) on a.CurrencyId = c.Id
	where a.InvestorId = @InvestorId
	and (@ContractId is null or (@ContractId is not null and a.ContractId = @ContractId))
	and (@StartDate is null or (@StartDate is not null and a.PaymentDateTime >= @StartDate))
	and (@EndDate is null or (@EndDate is not null and a.PaymentDateTime < dateadd(day,1,@EndDate)))
	union all
	select
		[Date] = a.[PaymentDateTime],
		[ToolName] = a.[ShareName],
		[PriceType] = case when a.[Type] = 1 then N'Купоны' else N'Дивиденды' end,
		[ContractName] = b.NUM,
		[Price] = CAST(Round(
			case
				when @Valuta = 'RUB' then a.AmountPayments_RUR
				when @Valuta = 'USD' then a.AmountPayments_USD
				when @Valuta = 'EUR' then a.AmountPayments_EURO
				else a.AmountPayments_RUR
			end
			,2) as Decimal(30,2)),
		a.[PaymentDateTime],
		Valuta = @Valuta,
		a.[Type],
		RowValuta = c.ShortName,
		RowPrice = a.AmountPayments
	from [dbo].[DIVIDENDS_AND_COUPONS_History_Last] as a with(nolock)
	join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId and b.DATE_CLOSE >= @EndDate
	join dbo.Currencies as c with(nolock) on a.CurrencyId = c.Id
	where a.InvestorId = @InvestorId
	and (@ContractId is null or (@ContractId is not null and a.ContractId = @ContractId))
	and (@StartDate is null or (@StartDate is not null and a.PaymentDateTime >= @StartDate))
	and (@EndDate is null or (@EndDate is not null and a.PaymentDateTime < dateadd(day,1,@EndDate)))
	order by a.[PaymentDateTime];

    SELECT * FROM #DivsNCouponsDetails

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
		[Dividends] = SUM([Dividends]),
		[Coupons] = SUM([Coupons]),
		Valuta = max(r.Valuta)
	FROM cte
	LEFT JOIN
	(
		select
			[Date] = [PaymentDateTime],
			Dividends = case when [Type] = 1 then 0.000000
			else
				[Price]
			end,
			Coupons = case when [Type] = 1 then
				[Price]
			else
				0.000000
			end,
			Valuta = @Valuta
		from #DivsNCouponsDetails

	) r ON r.[Date] BETWEEN cte.[DateFrom] AND DATEADD(DAY,-1,cte.[DateTo])
	GROUP BY cte.[DateFrom]
	ORDER BY cte.[DateFrom];

BEGIN TRY
	DROP TABLE #ResInvAssets
END TRY
BEGIN CATCH
END CATCH;