-- результат инвестиций
--Declare @Investor int = 16541, @FundId int = 17578,
--@StartDate Date = '2007-04-20',
--@EndDate Date = '2017-12-28'

Declare @Investor int = 16541, @FundId int = 17578,
@StartDate Date = '2003-09-19',
@EndDate Date = '2018-12-20'

Declare @SItog numeric(30,10), @AmountDayMinus_RUR numeric(30,10), @Snach numeric(30,10), @AmountDayPlus_RUR numeric(30,10),
@InvestResult numeric(30,10);

declare @MinDate date, @MaxDate date

SELECT
	@MinDate = min([Date]),
	@MaxDate = max([Date])
FROM
(
	SELECT [Date]
	FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
	WHERE Investor = @Investor and FundId = @FundId
	UNION
	SELECT [Date]
	FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
	WHERE Investor = @Investor and FundId = @FundId
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
	DROP TABLE #ResInv
END TRY
BEGIN CATCH
END CATCH;


SELECT *
INTO #ResInv
FROM
(
	SELECT *
	FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
	WHERE Investor = @Investor and FundId = @FundId
	UNION
	SELECT *
	FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
	WHERE Investor = @Investor and FundId = @FundId
) AS R
WHERE [Date] >= @StartDate and [Date] <= @EndDate
--ORDER BY [Date]

-----------------------------------------------
-- преобразование на начальную и последнюю дату

-- забыть вводы выводы на первую дату
update #ResInv set
	AmountDayPlus  = 0, AmountDayPlus_RUR  = 0, AmountDayPlus_USD  = 0, AmountDayPlus_EVRO  = 0,
	AmountDayMinus = 0, AmountDayMinus_RUR = 0, AmountDayMinus_USD = 0, AmountDayMinus_EVRO = 0,
	AmountDay = 0
where [Date] = @StartDate
and AmountDay <> 0 -- вводы и выводы были в этот день


-- посчитать последний день обратно
update #ResInv set
	SumAmount = SumAmount - AmountDay
where [Date] = @EndDate
and AmountDay <> 0 -- вводы и выводы были в этот день

update #ResInv set
	VALUE_RUR = [dbo].f_Round(SumAmount * RATE, 2),
	VALUE_USD = [dbo].f_Round(SumAmount * RATE * 1.00000/USDRATE, 2),
	VALUE_EVRO = [dbo].f_Round(SumAmount * RATE * 1.00000/EVRORATE, 2),
	AmountDayPlus  = 0, AmountDayPlus_RUR  = 0, AmountDayPlus_USD  = 0, AmountDayPlus_EVRO  = 0,
	AmountDayMinus = 0, AmountDayMinus_RUR = 0, AmountDayMinus_USD = 0, AmountDayMinus_EVRO = 0,
	AmountDay = 0
where [Date] = @EndDate
and AmountDay <> 0 -- вводы и выводы были в этот день

-- преобразование на начальную и последнюю дату
-----------------------------------------------

-- В рублях

-- Итоговая оценка инвестиций

SELECT
	@SItog = VALUE_RUR
FROM #ResInv
where [Date] = @EndDate

SELECT
	@Snach = VALUE_RUR
FROM #ResInv
where [Date] = @StartDate



-- сумма всех выводов средств
SELECT
	@AmountDayMinus_RUR = sum(AmountDayMinus_RUR), -- отрицательное значение
	@AmountDayPlus_RUR = sum(AmountDayPlus_RUR) 
FROM #ResInv

set @InvestResult =
(@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
- (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'

--select @InvestResult -- 56794533.7800000000


--select @Snach

	declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
		@SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0

	declare obj_cur cursor local fast_forward for
		-- 
		SELECT
			[Date], [AmountDayPlus_RUR], [AmountDayMinus_RUR]
		FROM #ResInv
		where ([Date] in (@StartDate, @EndDate) or [AmountDay] <> 0)
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
			--select @LastDate, @DateCur, @T, @Snach, @SumAmountDay_RUR, @Counter as '@Counter', @T * (@Snach + @SumAmountDay_RUR)

			set @ResutSum += @T * (@Snach + @SumAmountDay_RUR)
			--set @Snach = @Snach + @SumAmountDay_RUR
			set @LastDate = @DateCur
			set @SumAmountDay_RUR = @SumAmountDay_RUR + @AmountDayPlus_RUR + @AmountDayMinus_RUR
			--set @SumAmountDay_RUR = @AmountDayPlus_RUR + @AmountDayMinus_RUR
			--set @SumAmountDay_RUR = @SumAmountDay_RUR
			set @SumT += @T;
			
			--select @Snach, @ResutSum, @LastDate, @SumAmountDay_RUR
			-- 56081083,08
		end

		fetch next from obj_cur into
			@DateCur, @AmountDayPlus_RUR, @AmountDayMinus_RUR
	end
	close obj_cur
	deallocate obj_cur

	--select @ResutSum, @SumT

	set @ResutSum = @ResutSum/@SumT

	--select @ResutSum

	select
	@InvestResult as 'Результат инвестиций',
	@ResutSum as 'Средневзвешенная сумма вложенных средств',
	@InvestResult/@ResutSum * 100 as 'Доходность в %',
	@InvestResult as 'Доходность абсолютная',
	@StartDate as 'Дата начала',
	@EndDate as 'Дата завершения',
	@SumT as 'Количество дней'

	SELECT
		*
	FROM #ResInv
	where ([Date] in (@StartDate, @EndDate) or [AmountDay] <> 0)
	order by [Date]



BEGIN TRY
	DROP TABLE #ResInv
END TRY
BEGIN CATCH
END CATCH;