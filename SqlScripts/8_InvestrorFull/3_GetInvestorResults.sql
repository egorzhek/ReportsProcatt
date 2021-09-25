CREATE OR ALTER PROCEDURE [dbo].[GetInvestorFundResults]
(
    @InvestorId int = 19865873,
    @StartDate Date = NULL,
    @EndDate Date = NULL,
    @Valuta Nvarchar(10) = NULL
)
AS BEGIN
    if @Valuta is null set @Valuta = 'RUB';

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
        SELECT a.[Date]
        FROM [dbo].[InvestorFundDate] as a with(nolock)
        join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id
        WHERE a.Investor = @InvestorId and b.DATE_CLOSE >= @EndDate
        UNION
        SELECT a.[Date]
        FROM [dbo].[InvestorFundDateLast] as a with(nolock)
        join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id
        WHERE a.Investor = @InvestorId and b.DATE_CLOSE >= @EndDate
        /*
        UNION
        SELECT [Date]
        FROM [dbo].[Assets_Contracts] NOLOCK
        WHERE InvestorId = @InvestorId
        UNION
        SELECT [Date]
        FROM [dbo].[Assets_ContractsLast] NOLOCK
        WHERE InvestorId = @InvestorId
        */
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
        INPUT_COUPONS_EURO = sum(INPUT_COUPONS_EURO)
        from
        (
            select
                InvestorId = a.Investor,
                ContractId = a.Investor,
                a.[Date], a.USDRATE, EURORATE = a.EVRORATE,
                VALUE_RUR =
                case
                    when @Valuta = 'RUB' then a.VALUE_RUR
                    when @Valuta = 'USD' then a.VALUE_USD
                    when @Valuta = 'EUR' then a.VALUE_EVRO
                    else a.VALUE_RUR
                end,
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

                OUTPUT_VALUE_RUR = case
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
                INPUT_COUPONS_EURO = 0.0000000000
            from InvestorFundDate as a with(nolock)
            join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id and b.DATE_CLOSE >= @EndDate
            where a.Investor = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
            union all
            select
                InvestorId = a.Investor,
                ContractId = a.Investor,
                a.[Date], a.USDRATE, EURORATE = a.EVRORATE,
                VALUE_RUR =
                case
                    when @Valuta = 'RUB' then a.VALUE_RUR
                    when @Valuta = 'USD' then a.VALUE_USD
                    when @Valuta = 'EUR' then a.VALUE_EVRO
                    else a.VALUE_RUR
                end,
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

                OUTPUT_VALUE_RUR = case
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
                INPUT_COUPONS_EURO = 0.0000000000
            from InvestorFundDateLast as a with(nolock)
            join [dbo].[FundNames] as b with(nolock) on a.FundId = b.Id and b.DATE_CLOSE >= @EndDate
            where a.Investor = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
            /*
            union all
            select
                InvestorId,
                ContractId = InvestorId,
                [Date], USDRATE, EURORATE, VALUE_RUR,
                VALUE_USD, VALUE_EURO,
                INPUT_VALUE_RUR,
                INPUT_VALUE_USD,
                INPUT_VALUE_EURO,
                OUTPUT_VALUE_RUR,
                OUTPUT_VALUE_USD,
                OUTPUT_VALUE_EURO,
                INPUT_DIVIDENTS_RUR,
                INPUT_DIVIDENTS_USD,
                INPUT_DIVIDENTS_EURO,
                INPUT_COUPONS_RUR,
                INPUT_COUPONS_USD,
                INPUT_COUPONS_EURO
            from Assets_Contracts nolock
            where InvestorId = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
            union all
            select
                InvestorId,
                ContractId = InvestorId,
                [Date], USDRATE, EURORATE, VALUE_RUR,
                VALUE_USD, VALUE_EURO,
                INPUT_VALUE_RUR,
                INPUT_VALUE_USD,
                INPUT_VALUE_EURO,
                OUTPUT_VALUE_RUR,
                OUTPUT_VALUE_USD,
                OUTPUT_VALUE_EURO,
                INPUT_DIVIDENTS_RUR,
                INPUT_DIVIDENTS_USD,
                INPUT_DIVIDENTS_EURO,
                INPUT_COUPONS_RUR,
                INPUT_COUPONS_USD,
                INPUT_COUPONS_EURO
            from Assets_ContractsLast nolock
            where InvestorId = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
            */
        )
        as res
        group by InvestorId, ContractId, [Date]
    ) AS R




    -----------------------------------------------
    -- преобразование на начальную и последнюю дату

    -- забыть вводы выводы на первую дату
    update #ResInvAssets set
        --DailyIncrement_RUR = 0, DailyIncrement_USD = 0,   DailyIncrement_EURO = 0,
        --DailyDecrement_RUR = 0,   DailyDecrement_USD = 0, DailyDecrement_EURO = 0,
        INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
        INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
        INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
    where [Date] = @StartDate
    and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

    -- посчитать последний день обратно
    update a set 
    VALUE_RUR = VALUE_RUR - OUTPUT_VALUE_RUR,
    VALUE_USD = VALUE_USD, -- - DailyIncrement_USD - DailyDecrement_USD,
    VALUE_EURO = VALUE_EURO, -- - DailyIncrement_EURO - DailyDecrement_EURO,

    -- DailyIncrement_RUR = 0, DailyIncrement_USD = 0,  DailyIncrement_EURO = 0,
    -- DailyDecrement_RUR = 0,  DailyDecrement_USD = 0, DailyDecrement_EURO = 0,
    INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
    INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
    INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
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

    declare @IsNoStart Int = 0;

    if @Snach is null
    begin
        set @IsNoStart = 1;
        set @Snach = 0;
    end

    -- сумма всех выводов средств
    SELECT
        @AmountDayMinus_RUR = sum(OUTPUT_VALUE_RUR), -- отрицательное значение
        @AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR),
        @Sum_INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
        @Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
        @Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
        @Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
    FROM #ResInvAssets


    --SELECT
        --OUTPUT_VALUE_RUR, ContractId, [Date]
    --FROM #ResInvAssets
    --where abs(OUTPUT_VALUE_RUR) > 0


    set @InvestResult =
    (@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
    - (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'


        declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
            @SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0,
            @MinutT Int = 0

        declare @tmpt table
        (
            [Date] date,
            [AmountDayPlus_RUR] decimal(28,8),
            [AmountDayMinus_RUR] decimal(28,8)
        );

        if @IsNoStart = 1
        begin
            insert into @tmpt
            (
                [Date],
                [AmountDayPlus_RUR],
                [AmountDayMinus_RUR]
            )
            select @StartDate, 0, 0;
        end

        insert into @tmpt
        (
            [Date],
            [AmountDayPlus_RUR],
            [AmountDayMinus_RUR]
        )
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
        );
        

        declare obj_cur cursor local fast_forward for
            -- 
            SELECT
                [Date],
                [AmountDayPlus_RUR],
                [AmountDayMinus_RUR]
            FROM @tmpt
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

                if @Snach = 0.000 and @Counter = 2
                begin
                    set @MinutT = @T;
                end

                

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
            set @ResutSum = @ResutSum/(@SumT - @MinutT)
        end

        if @ResutSum = 0 set @ResutSum = NULL

    declare @Symbol Nvarchar(10)

    select
        @Symbol = Symbol
    from Currencies nolock
    where ShortName = @Valuta


    select
        NameObject = N'ПИФЫ',

        StartDate = FORMAT(@StartDate,'dd.MM.yyyy'),
        StartDateValue = @Snach,

        EndDate = FORMAT(@EndDate,'dd.MM.yyyy'),
        EndDateValue =  CAST(Round(@SItog,2) as Decimal(30,2)),

        INPUT_VALUE = @Sum_INPUT_VALUE_RUR,
        OUTPUT_VALUE = -@Sum_OUTPUT_VALUE_RUR,
        INPUT_COUPONS = @Sum_INPUT_COUPONS_RUR,
        INPUT_DIVIDENTS = @Sum_INPUT_DIVIDENTS_RUR,

        ProfitValue = CAST(Round(@InvestResult,2) as Decimal(30,2)),
        ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
        Valuta = @Symbol
END
GO
CREATE OR ALTER PROCEDURE [dbo].[GetInvestorContractResults]
(
    @InvestorId int = 19865873,
    @StartDate Date = NULL,
    @EndDate Date = NULL,
    @Valuta Nvarchar(10) = NULL
)
AS BEGIN
    if @Valuta is null set @Valuta = 'RUB';

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
        /*
        SELECT [Date]
        FROM [dbo].[InvestorFundDate] NOLOCK
        WHERE Investor = @InvestorId
        UNION
        SELECT [Date]
        FROM [dbo].[InvestorFundDateLast] NOLOCK
        WHERE Investor = @InvestorId
        
        UNION
        */
        SELECT a.[Date]
        FROM [dbo].[Assets_Contracts] as a with(nolock)
        join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId
        WHERE a.InvestorId = @InvestorId and b.DATE_CLOSE >= @EndDate
        UNION
        SELECT a.[Date]
        FROM [dbo].[Assets_ContractsLast] as a with(nolock)
        join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId
        WHERE a.InvestorId = @InvestorId and b.DATE_CLOSE >= @EndDate
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
        INPUT_COUPONS_EURO = sum(INPUT_COUPONS_EURO)
        from
        (
            /*
            select
                InvestorId = Investor,
                ContractId = Investor,
                [Date], USDRATE, EURORATE = EVRORATE, VALUE_RUR,
                VALUE_USD, VALUE_EURO = VALUE_EVRO,
                INPUT_VALUE_RUR = AmountDayPlus_RUR,
                INPUT_VALUE_USD = AmountDayPlus_USD,
                INPUT_VALUE_EURO = AmountDayPlus_EVRO,
                OUTPUT_VALUE_RUR = AmountDayMinus_RUR,
                OUTPUT_VALUE_USD = AmountDayMinus_USD,
                OUTPUT_VALUE_EURO = AmountDayMinus_EVRO,
                INPUT_DIVIDENTS_RUR = 0.0000000000,
                INPUT_DIVIDENTS_USD = 0.0000000000,
                INPUT_DIVIDENTS_EURO = 0.0000000000,
                INPUT_COUPONS_RUR = 0.0000000000,
                INPUT_COUPONS_USD = 0.0000000000,
                INPUT_COUPONS_EURO = 0.0000000000
            from InvestorFundDate nolock
            where Investor = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
            union all
            select
                InvestorId = Investor,
                ContractId = Investor,
                [Date], USDRATE, EURORATE = EVRORATE, VALUE_RUR,
                VALUE_USD, VALUE_EURO = VALUE_EVRO,
                INPUT_VALUE_RUR = AmountDayPlus_RUR,
                INPUT_VALUE_USD = AmountDayPlus_USD,
                INPUT_VALUE_EURO = AmountDayPlus_EVRO,
                OUTPUT_VALUE_RUR = AmountDayMinus_RUR,
                OUTPUT_VALUE_USD = AmountDayMinus_USD,
                OUTPUT_VALUE_EURO = AmountDayMinus_EVRO,
                INPUT_DIVIDENTS_RUR = 0.0000000000,
                INPUT_DIVIDENTS_USD = 0.0000000000,
                INPUT_DIVIDENTS_EURO = 0.0000000000,
                INPUT_COUPONS_RUR = 0.0000000000,
                INPUT_COUPONS_USD = 0.0000000000,
                INPUT_COUPONS_EURO = 0.0000000000
            from InvestorFundDateLast nolock
            where Investor = @InvestorId and [Date] >= @StartDate and [Date] <= @EndDate
            
            union all
            */
            select
                a.InvestorId,
                ContractId = a.InvestorId,
                a.[Date], a.USDRATE, a.EURORATE,

                VALUE_RUR =
                case
                    when @Valuta = 'RUB' then a.VALUE_RUR
                    when @Valuta = 'USD' then a.VALUE_USD
                    when @Valuta = 'EUR' then a.VALUE_EURO
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
                a.INPUT_COUPONS_EURO
            from dbo.Assets_Contracts as a with(nolock)
            join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId and b.DATE_CLOSE >= @EndDate
            where a.InvestorId = @InvestorId and a.[Date] >= @StartDate and a.[Date] <= @EndDate
            union all
            select
                a.InvestorId,
                ContractId = a.InvestorId,
                a.[Date], a.USDRATE, a.EURORATE,

                VALUE_RUR =
                case
                    when @Valuta = 'RUB' then a.VALUE_RUR
                    when @Valuta = 'USD' then a.VALUE_USD
                    when @Valuta = 'EUR' then a.VALUE_EURO
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
                a.INPUT_COUPONS_EURO
            from dbo.Assets_ContractsLast as a with(nolock)
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
        --DailyIncrement_RUR = 0, DailyIncrement_USD = 0,   DailyIncrement_EURO = 0,
        --DailyDecrement_RUR = 0,   DailyDecrement_USD = 0, DailyDecrement_EURO = 0,
        INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
        INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
        INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
    where [Date] = @StartDate
    and (OUTPUT_VALUE_RUR <> 0 or INPUT_VALUE_RUR <> 0 or INPUT_COUPONS_RUR <> 0 or INPUT_DIVIDENTS_RUR <> 0) -- вводы и выводы были в этот день

    -- посчитать последний день обратно
    update a set 
    VALUE_RUR = VALUE_RUR - OUTPUT_VALUE_RUR,
    VALUE_USD = VALUE_USD, -- - DailyIncrement_USD - DailyDecrement_USD,
    VALUE_EURO = VALUE_EURO, -- - DailyIncrement_EURO - DailyDecrement_EURO,

    -- DailyIncrement_RUR = 0, DailyIncrement_USD = 0,  DailyIncrement_EURO = 0,
    -- DailyDecrement_RUR = 0,  DailyDecrement_USD = 0, DailyDecrement_EURO = 0,
    INPUT_DIVIDENTS_RUR = 0,INPUT_DIVIDENTS_USD = 0,INPUT_DIVIDENTS_EURO = 0,
    INPUT_COUPONS_RUR = 0,  INPUT_COUPONS_USD = 0,  INPUT_COUPONS_EURO = 0,
    INPUT_VALUE_RUR = 0, OUTPUT_VALUE_RUR = 0
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

    declare @IsNoStart Int = 0;

    if @Snach is null
    begin
        set @IsNoStart = 1;
        set @Snach = 0;
    end

    -- сумма всех выводов средств
    SELECT
        @AmountDayMinus_RUR = sum(OUTPUT_VALUE_RUR), -- отрицательное значение
        @AmountDayPlus_RUR = sum(INPUT_VALUE_RUR + INPUT_DIVIDENTS_RUR + INPUT_COUPONS_RUR),
        @Sum_INPUT_VALUE_RUR = sum(INPUT_VALUE_RUR),
        @Sum_OUTPUT_VALUE_RUR = sum(OUTPUT_VALUE_RUR),
        @Sum_INPUT_COUPONS_RUR = sum(INPUT_COUPONS_RUR),
        @Sum_INPUT_DIVIDENTS_RUR = sum(INPUT_DIVIDENTS_RUR)
    FROM #ResInvAssets

    set @InvestResult =
    (@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
    - (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'



        declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
            @SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0,
            @MinutT Int = 0

        declare @tmpt table
        (
            [Date] date,
            [AmountDayPlus_RUR] decimal(28,8),
            [AmountDayMinus_RUR] decimal(28,8)
        );

        if @IsNoStart = 1
        begin
            insert into @tmpt
            (
                [Date],
                [AmountDayPlus_RUR],
                [AmountDayMinus_RUR]
            )
            select @StartDate, 0, 0;
        end

        insert into @tmpt
        (
            [Date],
            [AmountDayPlus_RUR],
            [AmountDayMinus_RUR]
        )
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
        );
        

        declare obj_cur cursor local fast_forward for
            -- 
            SELECT
                [Date],
                [AmountDayPlus_RUR],
                [AmountDayMinus_RUR]
            FROM @tmpt
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

                if @Snach = 0.000 and @Counter = 2
                begin
                    set @MinutT = @T;
                end

                

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
            set @ResutSum = @ResutSum/(@SumT - @MinutT)
        end

        if @ResutSum = 0 set @ResutSum = NULL

    declare @Symbol Nvarchar(10)

    select
        @Symbol = Symbol
    from Currencies nolock
    where ShortName = @Valuta


    select
        NameObject = N'ДУ',

        StartDate = FORMAT(@StartDate,'dd.MM.yyyy'),
        StartDateValue = @Snach,

        EndDate = FORMAT(@EndDate,'dd.MM.yyyy'),
        EndDateValue =  CAST(Round(@SItog,2) as Decimal(30,2)),

        INPUT_VALUE = @Sum_INPUT_VALUE_RUR,
        OUTPUT_VALUE = -@Sum_OUTPUT_VALUE_RUR,
        INPUT_COUPONS = @Sum_INPUT_COUPONS_RUR,
        INPUT_DIVIDENTS = @Sum_INPUT_DIVIDENTS_RUR,

        ProfitValue = CAST(Round(@InvestResult,2) as Decimal(30,2)),
        ProfitProcentValue = CAST(Round(@InvestResult/@ResutSum * 100,2) as Decimal(38,2)),
        Valuta = @Symbol
END
GO