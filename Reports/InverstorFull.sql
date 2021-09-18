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
	SELECT [Date]
	FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
	WHERE Investor = @InvestorId
	UNION
	SELECT [Date]
	FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
	WHERE Investor = @InvestorId
	UNION
	SELECT [Date]
	FROM [CacheDB].[dbo].[Assets_Contracts] NOLOCK
	WHERE InvestorId = @InvestorId
	UNION
	SELECT [Date]
	FROM [CacheDB].[dbo].[Assets_ContractsLast] NOLOCK
	WHERE InvestorId = @InvestorId
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
			InvestorId = Investor,
			ContractId = Investor,
			[Date], USDRATE, EURORATE = EVRORATE, VALUE_RUR,
			VALUE_USD, VALUE_EURO = VALUE_EVRO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then AmountDayPlus_RUR
				when @Valuta = 'USD' then AmountDayPlus_USD
				when @Valuta = 'EUR' then AmountDayPlus_EVRO
				else AmountDayPlus_RUR
			end,
			INPUT_VALUE_USD = AmountDayPlus_USD,
			INPUT_VALUE_EURO = AmountDayPlus_EVRO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then AmountDayMinus_RUR
				when @Valuta = 'USD' then AmountDayMinus_USD
				when @Valuta = 'EUR' then AmountDayMinus_EVRO
				else AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_USD = AmountDayMinus_USD,
			OUTPUT_VALUE_EURO = AmountDayMinus_EVRO,


			INPUT_DIVIDENTS_RUR = 0.0000000000,
			INPUT_DIVIDENTS_USD = 0.0000000000,
			INPUT_DIVIDENTS_EURO = 0.0000000000,
			INPUT_COUPONS_RUR = 0.0000000000,
			INPUT_COUPONS_USD = 0.0000000000,
			INPUT_COUPONS_EURO = 0.0000000000,
			OUTPUT_VALUE_RUR1 =
			case
				when @Valuta = 'RUB' then AmountDayMinus_RUR
				when @Valuta = 'USD' then AmountDayMinus_USD
				when @Valuta = 'EUR' then AmountDayMinus_EVRO
				else AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_RUR2 = 0.000
		from InvestorFundDate nolock
		where Investor = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
		union all
		select
			InvestorId = Investor,
			ContractId = Investor,
			[Date], USDRATE, EURORATE = EVRORATE, VALUE_RUR,
			VALUE_USD, VALUE_EURO = VALUE_EVRO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then AmountDayPlus_RUR
				when @Valuta = 'USD' then AmountDayPlus_USD
				when @Valuta = 'EUR' then AmountDayPlus_EVRO
				else AmountDayPlus_RUR
			end,
			INPUT_VALUE_USD = AmountDayPlus_USD,
			INPUT_VALUE_EURO = AmountDayPlus_EVRO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then AmountDayMinus_RUR
				when @Valuta = 'USD' then AmountDayMinus_USD
				when @Valuta = 'EUR' then AmountDayMinus_EVRO
				else AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_USD = AmountDayMinus_USD,
			OUTPUT_VALUE_EURO = AmountDayMinus_EVRO,


			INPUT_DIVIDENTS_RUR = 0.0000000000,
			INPUT_DIVIDENTS_USD = 0.0000000000,
			INPUT_DIVIDENTS_EURO = 0.0000000000,
			INPUT_COUPONS_RUR = 0.0000000000,
			INPUT_COUPONS_USD = 0.0000000000,
			INPUT_COUPONS_EURO = 0.0000000000,
			OUTPUT_VALUE_RUR1 =
			case
				when @Valuta = 'RUB' then AmountDayMinus_RUR
				when @Valuta = 'USD' then AmountDayMinus_USD
				when @Valuta = 'EUR' then AmountDayMinus_EVRO
				else AmountDayMinus_RUR
			end,
			OUTPUT_VALUE_RUR2 = 0.000
		from InvestorFundDateLast nolock
		where Investor = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
		union all
		select
			InvestorId,
			ContractId = InvestorId,
			[Date], USDRATE, EURORATE,

			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_USD
				when @Valuta = 'EUR' then VALUE_EURO
				else VALUE_RUR
			end,
			VALUE_USD,
			VALUE_EURO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then INPUT_VALUE_RUR
				when @Valuta = 'USD' then INPUT_VALUE_USD
				when @Valuta = 'EUR' then INPUT_VALUE_EURO
				else INPUT_VALUE_RUR
			end,
			INPUT_VALUE_USD,
			INPUT_VALUE_EURO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then OUTPUT_VALUE_EURO
				else OUTPUT_VALUE_RUR
			end,
			OUTPUT_VALUE_USD,
			OUTPUT_VALUE_EURO,

			INPUT_DIVIDENTS_RUR =
			case
				when @Valuta = 'RUB' then INPUT_DIVIDENTS_RUR
				when @Valuta = 'USD' then INPUT_DIVIDENTS_USD
				when @Valuta = 'EUR' then INPUT_DIVIDENTS_EURO
				else INPUT_DIVIDENTS_RUR
			end,
			INPUT_DIVIDENTS_USD,
			INPUT_DIVIDENTS_EURO,

			INPUT_COUPONS_RUR =
			case
				when @Valuta = 'RUB' then INPUT_COUPONS_RUR
				when @Valuta = 'USD' then INPUT_COUPONS_USD
				when @Valuta = 'EUR' then INPUT_COUPONS_EURO
				else INPUT_COUPONS_RUR
			end,
			INPUT_COUPONS_USD,
			INPUT_COUPONS_EURO,
			OUTPUT_VALUE_RUR1 = 0.000,
			OUTPUT_VALUE_RUR2 =
			case
				when @Valuta = 'RUB' then OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then OUTPUT_VALUE_EURO
				else OUTPUT_VALUE_RUR
			end
		from Assets_Contracts nolock
		where InvestorId = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
		union all
		select
			InvestorId,
			ContractId = InvestorId,
			[Date], USDRATE, EURORATE,

			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_USD
				when @Valuta = 'EUR' then VALUE_EURO
				else VALUE_RUR
			end,
			VALUE_USD,
			VALUE_EURO,

			INPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then INPUT_VALUE_RUR
				when @Valuta = 'USD' then INPUT_VALUE_USD
				when @Valuta = 'EUR' then INPUT_VALUE_EURO
				else INPUT_VALUE_RUR
			end,
			INPUT_VALUE_USD,
			INPUT_VALUE_EURO,

			OUTPUT_VALUE_RUR =
			case
				when @Valuta = 'RUB' then OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then OUTPUT_VALUE_EURO
				else OUTPUT_VALUE_RUR
			end,
			OUTPUT_VALUE_USD,
			OUTPUT_VALUE_EURO,

			INPUT_DIVIDENTS_RUR =
			case
				when @Valuta = 'RUB' then INPUT_DIVIDENTS_RUR
				when @Valuta = 'USD' then INPUT_DIVIDENTS_USD
				when @Valuta = 'EUR' then INPUT_DIVIDENTS_EURO
				else INPUT_DIVIDENTS_RUR
			end,
			INPUT_DIVIDENTS_USD,
			INPUT_DIVIDENTS_EURO,

			INPUT_COUPONS_RUR =
			case
				when @Valuta = 'RUB' then INPUT_COUPONS_RUR
				when @Valuta = 'USD' then INPUT_COUPONS_USD
				when @Valuta = 'EUR' then INPUT_COUPONS_EURO
				else INPUT_COUPONS_RUR
			end,
			INPUT_COUPONS_USD,
			INPUT_COUPONS_EURO,
			OUTPUT_VALUE_RUR1 = 0.000,
			OUTPUT_VALUE_RUR2 =
			case
				when @Valuta = 'RUB' then OUTPUT_VALUE_RUR
				when @Valuta = 'USD' then OUTPUT_VALUE_USD
				when @Valuta = 'EUR' then OUTPUT_VALUE_EURO
				else OUTPUT_VALUE_RUR
			end
		from Assets_ContractsLast nolock
		where InvestorId = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
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
VALUE_RUR = VALUE_RUR, -- - DailyIncrement_RUR - DailyDecrement_RUR,
VALUE_USD = VALUE_USD, -- - DailyIncrement_USD - DailyDecrement_USD,
VALUE_EURO = VALUE_EURO, -- - DailyIncrement_EURO - DailyDecrement_EURO,

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
	@AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR),
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

	if @ResutSum = 0 set @ResutSum = NULL;

/*
Declare @DATE_OPEN date, @NUM Nvarchar(100);

select
	@DATE_OPEN = DATE_OPEN,
	@NUM = NUM
from [CacheDB].[dbo].[Assets_Info] NOLOCK
where [InvestorId] = @InvestorId; --and [ContractId] = @ContractId;
*/
select
	ActiveDateToName = N'Сумма активов на дату окончания периода',
	ActiveDateToValue =  CAST(Round(@SItog,2) as Decimal(30,2)),
	ProfitName = N'ОТЧЁТ ПО ПОРТФЕЛЮ / ' + FORMAT(@StartDate,'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ProfitValue = CAST(Round(@InvestResult,2) as Decimal(30,2)),
	ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
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
	OutVal2 = CAST(Round(@Sum_OUTPUT_VALUE_RUR2,2) as Decimal(30,2))


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
	EXEC [dbo].[GetInvestorFunds]
		@Investor = @InvestorId,
		@StartDate = @StartDate,
		@EndDate = @EndDate,
		@Valuta = @Valuta

	-- Sixth
	-- выдаёт список ДУ
	EXEC [dbo].[GetInvestorContracts]
		@InvestorId = @InvestorId,
		@StartDate = @StartDate,
		@EndDate = @EndDate,
		@Valuta = @Valuta

  -- Результаты по ПИФам
  EXEC [dbo].[GetInvestorFundResults]
		@InvestorId = @InvestorId,
  		@StartDate = @StartDate,
  		@EndDate = @EndDate,
		@Valuta = @Valuta

  -- Результаты по ДУ
  EXEC [dbo].[GetInvestorContractResults]
		@InvestorId = @InvestorId,
  		@StartDate = @StartDate,
  		@EndDate = @EndDate,
		@Valuta = @Valuta

BEGIN TRY
	DROP TABLE #ResInvAssets
END TRY
BEGIN CATCH
END CATCH;