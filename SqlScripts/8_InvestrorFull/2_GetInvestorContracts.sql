USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_CulcContractProfit]
(
    @InvestorId Int,
    @ContractId Int,
    @StartDate Date,
    @EndDate Date,
    @ProfitValue decimal(28,10) = NULL output,
    @ProfitProcentValue decimal(28,10) = NULL output,
    @BeginValue decimal(28,10) = NULL output,
    @EndValue decimal(28,10) = NULL output
)
AS BEGIN
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
        DROP TABLE #ResInvAssets5
    END TRY
    BEGIN CATCH
    END CATCH;

    SELECT *
    INTO #ResInvAssets5
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

    -----------------------------------------------
    -- преобразование на начальную и последнюю дату

    -- забыть вводы выводы на первую дату
    update #ResInvAssets5 set
        DailyIncrement_RUR = 0, DailyIncrement_USD = 0, DailyIncrement_EURO = 0,
        DailyDecrement_RUR = 0, DailyDecrement_USD = 0, DailyDecrement_EURO = 0,
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

    DailyIncrement_RUR = 0, DailyIncrement_USD = 0, DailyIncrement_EURO = 0,
    DailyDecrement_RUR = 0, DailyDecrement_USD = 0, DailyDecrement_EURO = 0,
    INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
    INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
    INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
    from #ResInvAssets5 as a
    where [Date] = @EndDate
    and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

    -- преобразование на начальную и последнюю дату
    -----------------------------------------------

    -- В рублях
    -- Итоговая оценка инвестиций

    SELECT
        @SItog = VALUE_RUR
    FROM #ResInvAssets5
    where [Date] = @EndDate

    SELECT
        @Snach = VALUE_RUR
    FROM #ResInvAssets5
    where [Date] = @StartDate



    -- сумма всех выводов средств
    SELECT
        @AmountDayMinus_RUR = sum(OUTPUT_VALUE_RUR), -- отрицательное значение
        @AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR),
        @Sum_INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
        @Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
        @Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
        @Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
    FROM #ResInvAssets5


    set @InvestResult =
    (@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
    - (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'


    declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
        @SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0

    declare obj_cur cursor local fast_forward for
        -- 
        SELECT --*
            [Date],
            [AmountDayPlus_RUR] = INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR,
            [AmountDayMinus_RUR] = OUTPUT_VALUE_RUR
        FROM #ResInvAssets5
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
    
    SET @ProfitValue = @InvestResult;
    SET @ProfitProcentValue = @InvestResult/@ResutSum;
    SET @BeginValue = @Snach;
	SET @EndValue = @SItog;

    BEGIN TRY
        DROP TABLE #ResInvAssets5
    END TRY
    BEGIN CATCH
    END CATCH;
END
GO
CREATE OR ALTER PROCEDURE [dbo].[GetInvestorContracts]
(
    @InvestorId int,
    @StartDate Date,
    @EndDate Date
)
AS BEGIN
    declare @ReSult table
    (
        ContractId Int NULL,
		VAL decimal(28,10) NULL,
        ContractName NVarchar(300) NULL,
        ProfitValue decimal(28,10) NULL,
        ProfitProcentValue decimal(28,10) NULL,
        BeginValue decimal(28,10) NULL,
		EndValue decimal(28,10) NULL
    );

    insert into @ReSult
    (
        ContractId,
		VAL,
        ContractName,
        ProfitValue,
        ProfitProcentValue,
        BeginValue
    )
    select
        sd.ContractId,
		sd.VAL,
        ContractName = fn.NUM,
        ProfitValue = NULL,
        ProfitProcentValue = NULL,
        BeginValue = NULL
    from
    (
        SELECT
			ContractId,
            VAL = VALUE_RUR - DailyIncrement_RUR - DailyDecrement_RUR
        FROM [CacheDB].[dbo].[Assets_Contracts] nolock
        where InvestorId = @InvestorId and [Date] = @EndDate
        union all
        SELECT
			ContractId,
            VAL = VALUE_RUR - DailyIncrement_RUR - DailyDecrement_RUR
        FROM [CacheDB].[dbo].[Assets_ContractsLast] nolock
        where InvestorId = @InvestorId and [Date] = @EndDate
    ) as sd
    left join [dbo].[Assets_Info] as fn on sd.ContractId = fn.ContractId;

    
    
    declare @ContractId Int, @ProfitValue decimal(28,10), @ProfitProcentValue decimal(28,10), @BeginValue decimal(28,10), @EndValue decimal(28,10);


    declare obj_cur cursor local fast_forward for
        -- 
        select ContractId from @ReSult
    open obj_cur
    fetch next from obj_cur into
        @ContractId
    while(@@fetch_status = 0)
    begin
        EXEC [dbo].[app_CulcContractProfit]
            @InvestorId = @InvestorId,
            @ContractId = @ContractId,
            @StartDate = @StartDate,
            @EndDate = @EndDate,
            @ProfitValue = @ProfitValue output,
            @ProfitProcentValue = @ProfitProcentValue output,
            @BeginValue = @BeginValue output,
			@EndValue = @EndValue output

        update @ReSult
            set ProfitValue = @ProfitValue, ProfitProcentValue = @ProfitProcentValue, BeginValue = @BeginValue, EndValue = @EndValue
        where ContractId = @ContractId
        
        fetch next from obj_cur into
            @ContractId
    end
    close obj_cur
    deallocate obj_cur

    select
        ContractName,
        ProfitValue = CAST([dbo].f_Round(ProfitValue, 2) AS DECIMAL(30,2)),
        ProfitProcentValue = CAST([dbo].f_Round(ProfitProcentValue, 2) AS DECIMAL(30,2)),
        BeginValue = CAST([dbo].f_Round(BeginValue, 2) AS DECIMAL(30,2)),
		EndValue = CAST([dbo].f_Round(VAL, 2) AS DECIMAL(30,2)),
        Valuta = N'₽'
    from @ReSult
    order by ContractName;
END
GO