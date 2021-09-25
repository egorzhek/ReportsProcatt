USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_CulcFundProfit]
(
    @Investor Int,
    @FundId Int,
    @StartDate Date,
    @EndDate Date,
    @ProfitValue decimal(28,10) = NULL output,
    @ProfitProcentValue decimal(28,10) = NULL output,
    @BeginValue decimal(28,10) = NULL output,
    @EndValue decimal(28,10) = NULL output,
	@Valuta Nvarchar(10) = NULL
)
AS BEGIN
	if @Valuta is null set @Valuta = 'RUB';

    SET @ProfitValue = NULL;
    SET @ProfitProcentValue = NULL;

    SET NOCOUNT ON;


    Declare @SItog numeric(30,10), @AmountDayMinus_RUR numeric(30,10), @Snach numeric(30,10), @AmountDayPlus_RUR numeric(30,10),
    @InvestResult numeric(30,10), @AllPlus_RUR numeric(30,10), @AllMinus_RUR numeric(30,10), @EndSumAmount numeric(30,2);

    declare @MinDate date, @MaxDate date, @LS_NUM nvarchar(120);

    SELECT
        @MinDate = min([Date]),
        @MaxDate = max([Date]),
        @LS_NUM  = min([LS_NUM])
    FROM
    (
        SELECT [Date], [LS_NUM]
        FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
        WHERE Investor = @Investor and FundId = @FundId
        UNION
        SELECT [Date], [LS_NUM]
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
        SELECT
			Investor, FundId, [Date], AmountDay, SumAmount, RATE, USDRATE, EVRORATE,
			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_USD
				when @Valuta = 'EUR' then VALUE_EVRO
				else VALUE_RUR
			end,
				VALUE_USD, VALUE_EVRO,
			AmountDayPlus,

			AmountDayPlus_RUR =
			case
				when @Valuta = 'RUB' then AmountDayPlus_RUR
				when @Valuta = 'USD' then AmountDayPlus_USD
				when @Valuta = 'EUR' then AmountDayPlus_EVRO
				else AmountDayPlus_RUR
			end,
				AmountDayPlus_USD, AmountDayPlus_EVRO,
			AmountDayMinus,

			AmountDayMinus_RUR =
			case
				when @Valuta = 'RUB' then AmountDayMinus_RUR
				when @Valuta = 'USD' then AmountDayMinus_USD
				when @Valuta = 'EUR' then AmountDayMinus_EVRO
				else AmountDayMinus_RUR
			end,
				AmountDayMinus_USD, AmountDayMinus_EVRO,
			LS_NUM
        FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
        WHERE Investor = @Investor and FundId = @FundId
        UNION
        SELECT
			Investor, FundId, [Date], AmountDay, SumAmount, RATE, USDRATE, EVRORATE,
			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_USD
				when @Valuta = 'EUR' then VALUE_EVRO
				else VALUE_RUR
			end,
				VALUE_USD, VALUE_EVRO,
			AmountDayPlus,

			AmountDayPlus_RUR =
			case
				when @Valuta = 'RUB' then AmountDayPlus_RUR
				when @Valuta = 'USD' then AmountDayPlus_USD
				when @Valuta = 'EUR' then AmountDayPlus_EVRO
				else AmountDayPlus_RUR
			end,
				AmountDayPlus_USD, AmountDayPlus_EVRO,
			AmountDayMinus,

			AmountDayMinus_RUR =
			case
				when @Valuta = 'RUB' then AmountDayMinus_RUR
				when @Valuta = 'USD' then AmountDayMinus_USD
				when @Valuta = 'EUR' then AmountDayMinus_EVRO
				else AmountDayMinus_RUR
			end,
				AmountDayMinus_USD, AmountDayMinus_EVRO,
			LS_NUM
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


    set @AllPlus_RUR = @AmountDayPlus_RUR;
    set @AllMinus_RUR = @AmountDayMinus_RUR;
    
    
    
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
        @EndSumAmount = SumAmount
    from #ResInv
    where [Date] = @EndDate
    
    SET @ProfitValue = @InvestResult;
    SET @ProfitProcentValue = case when @ResutSum = 0.00 then 0 else [dbo].f_Round(@InvestResult/@ResutSum * 100.000, 2) end;
    SET @BeginValue = @Snach;
	SET @EndValue = @EndSumAmount;

    BEGIN TRY
        DROP TABLE #ResInv
    END TRY
    BEGIN CATCH
    END CATCH;
END
GO
CREATE OR ALTER PROCEDURE [dbo].[GetInvestorFunds]
(
    @Investor int,
    @StartDate Date,
    @EndDate Date,
    @Valuta Nvarchar(10) = NULL
)
AS BEGIN
    if @Valuta is null set @Valuta = 'RUB';

    declare @ReSult table
    (
        FundId Int NULL,
        FundName NVarchar(300) NULL,
        VAL decimal(28,10) NULL,
        ProfitValue decimal(28,10) NULL,
        ProfitProcentValue decimal(28,10) NULL,
        BeginValue decimal(28,10) NULL,
        EndValue decimal(28,10) NULL
    );

    insert into @ReSult
    (
        FundId,
        FundName,
        VAL,
        ProfitValue,
        ProfitProcentValue,
        BeginValue
    )
    select
        FundId,
        FundName = fn.[Name],
        VAL,
        ProfitValue = NULL,
        ProfitProcentValue = NULL,
        BeginValue = NULL
    from
    (
        select
            a.FundId,
            VAL =
            case
                when @Valuta = 'RUB' then (a.SumAmount - a.AmountDay) * a.RATE
                when @Valuta = 'USD' then (a.SumAmount - a.AmountDay) * a.RATE * 1.000/a.USDRATE
                when @Valuta = 'EUR' then (a.SumAmount - a.AmountDay) * a.RATE * 1.000/a.EVRORATE
                else (a.SumAmount - a.AmountDay) * RATE
            end
        From [dbo].[InvestorFundDate] as a
        join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id and b.DATE_CLOSE >= @EndDate
        where a.Investor = @Investor and a.[Date] = @EndDate
        union all
        select
            a.FundId,
            VAL =
            case
                when @Valuta = 'RUB' then (a.SumAmount - a.AmountDay) * a.RATE
                when @Valuta = 'USD' then (a.SumAmount - a.AmountDay) * a.RATE * 1.000/a.USDRATE
                when @Valuta = 'EUR' then (a.SumAmount - a.AmountDay) * a.RATE * 1.000/a.EVRORATE
                else (a.SumAmount - a.AmountDay) * RATE
            end
        From [dbo].[InvestorFundDateLast] as a
        join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id and b.DATE_CLOSE >= @EndDate
        where a.Investor = @Investor and a.[Date] = @EndDate
    ) as sd
    left join FundNames as fn on sd.FundId = fn.Id;


    declare @FundId Int, @ProfitValue decimal(28,10), @ProfitProcentValue decimal(28,10), @BeginValue decimal(28,10), @EndValue decimal(28,10);


    declare obj_cur cursor local fast_forward for
        -- 
        select FundId from @ReSult
    open obj_cur
    fetch next from obj_cur into
        @FundId
    while(@@fetch_status = 0)
    begin
        EXEC [dbo].[app_CulcFundProfit]
            @Investor = @Investor,
            @FundId = @FundId,
            @StartDate = @StartDate,
            @EndDate = @EndDate,
            @ProfitValue = @ProfitValue output,
            @ProfitProcentValue = @ProfitProcentValue output,
            @BeginValue = @BeginValue output,
            @EndValue = @EndValue output,
            @Valuta = @Valuta;

        update @ReSult
            set ProfitValue = @ProfitValue, ProfitProcentValue = @ProfitProcentValue, BeginValue = @BeginValue, EndValue = @EndValue
        where FundId = @FundId
        
        fetch next from obj_cur into
            @FundId
    end
    close obj_cur
    deallocate obj_cur

    declare @Symbol Nvarchar(10)

    select
        @Symbol = Symbol
    from Currencies nolock
    where ShortName = @Valuta

    select
        FundId,
        FundName,
        --VAL = CAST([dbo].f_Round(VAL, 2) AS DECIMAL(30,2)),
        ProfitValue = CAST([dbo].f_Round(ProfitValue, 2) AS DECIMAL(30,2)),
        ProfitProcentValue = CAST([dbo].f_Round(ProfitProcentValue, 2) AS DECIMAL(30,2)),
        BeginValue = CAST([dbo].f_Round(BeginValue, 2) AS DECIMAL(30,2)),
        EndValue = CAST([dbo].f_Round(VAL, 2) AS DECIMAL(30,2)),
        Valuta = @Symbol
    from @ReSult
    order by FundName;
END
GO