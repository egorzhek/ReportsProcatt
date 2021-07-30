-- результат инвестиций
Declare @InvestorId int = 17286, @ContractId int = 17297,
@StartDate Date = '2017-11-24', -- NULL
@EndDate Date = '2020-07-01' -- NULL

Declare @SItog numeric(30,10), @AmountDayMinus_RUR numeric(30,10), @Snach numeric(30,10), @AmountDayPlus_RUR numeric(30,10),
@InvestResult numeric(30,10);

declare @MinDate date, @MaxDate date

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

if @StartDate = @EndDate
begin
	select [Error] = 'Даты равны'
	return;
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

	select
	@InvestResult as 'Результат инвестиций',
	@ResutSum as 'Средневзвешенная сумма вложенных средств',
	@InvestResult/@ResutSum * 100 as 'Доходность в %',
	@InvestResult as 'Доходность абсолютная',
	@StartDate as 'Дата начала',
	@EndDate as 'Дата завершения',
	@SumT as 'Количество дней'

	-- Данные
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


-- test - потом убрать
BEGIN TRY
	DROP TABLE #ResInvAssets
END TRY
BEGIN CATCH
END CATCH;