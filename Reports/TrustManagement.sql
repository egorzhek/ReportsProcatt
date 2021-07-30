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
	@AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR) 
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


	set @ResutSum = @ResutSum/@SumT

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
	ActiveDateToValue =  CAST(Round(@SItog,2) as Decimal(38,2)),
	ProfitName = 'Доход за период ' + FORMAT(@StartDate,'dd.MM.yyyy') + ' - ' + FORMAT(@EndDate,'dd.MM.yyyy'),
	ProfitValue = CAST(Round(@InvestResult,2) as Decimal(38,2)),
	ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
	OpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	LS_NUM = '2940000083',
	EndSumAmount = 99999.99,
	FundName = @NUM,
	InvestorName = @NUM,
	ContractNumber = @NUM,
	Fee = 99.99,
	ContractOpenDate = FORMAT(@DATE_OPEN,'dd.MM.yyyy'),
	SuccessFee = 99.99

select ActiveName = 'Активы на 20.04.2007', ActiveValue = 29448888.50, Sort = 1
union
select 'Пополнения', 854000000.00, 2
union
select 'Выводы', 804819679.28, 3
union
select 'Дивиденды', 23456.15, 4
union
select 'Купоны', 13567.25, 5
order by 3

select
Date = cast('2007-04-20' as Date), RATE = 1332.68
union
select cast('2007-04-21' as Date), 1333.00
union
select cast('2007-04-22' as Date), 1334.00
union
select cast('2007-04-23' as Date), 1332.00
union
select cast('2007-04-24' as Date), 1335.00



select ActiveName = 'Всего', ActiveValue = 37023.40, Sort = 1, Color = '#FFFFFF'
union
select 'Дивиденды', 23456.15, 4, '#7FE5F0'
union
select 'Купоны', 13567.25, 5, '#4CA3DD'
order by 3


-- Дивиденты, купоны
select
Date = cast('2007-04-20' as Date), Dividends = 1332.68, Coupons = 50.68
union
select cast('2007-04-21' as Date), 1333.00, 34.00
union
select cast('2007-04-22' as Date), 0.00, 0.00
union
select cast('2007-04-23' as Date), 1332.00, 1220.00
union
select cast('2007-04-24' as Date), 0.00, 500.00
union
select cast('2007-04-25' as Date), 660.00, 0.00
union
select cast('2007-04-26' as Date), 0.00, 0.00
union
select cast('2007-04-27' as Date), 1335.00, 1513.00

-- Детализация купонов и дивидендов

select
[Date] = '20.04.2007', -- Дата выплаты
[ToolName] = 'Сбербанк', -- Инструмент
[PriceType] = 'Дивиденды', -- Тип выплаты
[ContractName] = 'Стратегия ДУ "Агрессивная"', -- Название договора
[Price] = 123.12 -- Cумма в валюте выплаты
union
select
'21.04.2007',
'ВТБ',
'Купоны',
'Стратегия ДУ "Консервативная"',
24.14


select
[Date] = '20.04.2007', -- Дата
[OperName] = 'Покупка', -- Тип операции
[ISIN] = 'RU011',
[ToolName] = 'Сбербанк', -- Инструмент
[Price] = 100.15, -- Цена бумаги
[PaperAmount] = 12.00, -- Количество бумаг
[Valuta] = N'₽', -- Валюта
[Cost] = 123.12, -- Сумма сделки
[Fee] = 12.13, -- Комиссия
[Status] = 'Исполнена' -- Статус
union
select
[Date] = '21.04.2007', 
[OperName] = 'Продажа',
[ISIN] = 'RU012',
[ToolName] = 'ВТБ',
[Price] = 123.12,
[PaperAmount] = 123.00,
[Valuta] = N'₽',
[Cost] = 225.12,
[Fee] = 2.13,
[Status] = 'Исполнена'


-- Дерево - четыре уровня вложенности
-- tree1
select ValutaId = 145, ValutaName = 'Рубли'
--union
--select ValutaId = 148, ValutaName = 'Доллары'

-- tree2
select TypeId = 1, ValutaId = 145, TypeName = 'Денежные средства'
union
select TypeId = 2, ValutaId = 145, TypeName = 'Акции'
union
select TypeId = 3, ValutaId = 145, TypeName = 'Облигации'
--
union
select TypeId = 4, ValutaId = 148, TypeName = 'Денежные средства'
union
select TypeId = 5, ValutaId = 148, TypeName = 'Акции'
union
select TypeId = 6, ValutaId = 148, TypeName = 'Облигации'


-- tree3
select ChildId = 1, TypeId = 1, ChildName = 'Брокерский счёт АО ГПБ', PriceName = N'500 ₽', Ammount = '', Detail = N''
union
select ChildId = 2, TypeId = 1, ChildName = 'Брокерский счёт АО Открытие брокер', PriceName = N'500 ₽', Ammount = '', Detail = N''
union
select ChildId = 3, TypeId = 2, ChildName = 'Сбербанк, ао', PriceName = N'105,45 ₽', Ammount = '1 шт.', Detail = N'+5,43 ₽ (+4,7%)'
union
select ChildId = 4, TypeId = 3, ChildName = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '11 шт.', Detail = N'-15,48 ₽ (-11,2%)'

-- tree4
select Child2Id = 1, ChildId = 4, Child2Name = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '5 шт.', Detail = N'-15,48 ₽ (-11,2%)'
union
select Child2Id = 2, ChildId = 4, Child2Name = 'ОФЗ, 26257', PriceName = N'125,22 ₽', Ammount = '1 шт.', Detail = N'-15,48 ₽ (-11,2%)'


BEGIN TRY
	DROP TABLE #ResInvAssets
END TRY
BEGIN CATCH
END CATCH;