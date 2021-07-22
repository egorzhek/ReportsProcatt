USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_Assets_Contract_Inner]
(
    @ContractId int
)
AS BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentDate Date = GetDate();
    DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate);

    DECLARE @MinDate Date, @MaxDate Date;
    DECLARE @InvestorId Int;

    SELECT
        @InvestorId = C.INVESTOR
    FROM [BAL_DATA_STD].[dbo].[D_B_CONTRACTS] AS C
    WHERE C.DOC = @ContractId;

    if @InvestorId is null return;

    BEGIN TRY
        DROP TABLE #TempContract1;
    END TRY
    BEGIN CATCH
    END CATCH;

    DECLARE @Dates table([Date] date);

    SELECT
        [Date] = CAST(DATEADD(SECOND, 1, W.WIRDATE) as date),
        [Value] = T.VALUE_ * T.TYPE_
    INTO #TempContract1
    FROM [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
    INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE < '01.01.9999'
    INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
    WHERE T.IS_PLAN = 'F' AND R.BAL_ACC = 838 AND R.REG_1 = @ContractId -- договор
    ORDER BY [Date];


    DELETE FROM @Dates;
    SET @MinDate = NULL;
    SET @MaxDate = NULL;

    SELECT
        @MinDate = min([Date])
    FROM #TempContract1;

    SELECT
        @MaxDate = max([Date])
    FROM #TempContract1;

    if @MinDate is null return;
    if @MaxDate is null return;


    -- заполняем таблицу дат от минимальной до максимальной
    WHILE @MinDate <= @MaxDate
    BEGIN
        INSERT INTO @Dates ([Date]) VALUES (@MinDate);

        SET @MinDate = DATEADD(DAY,1,@MinDate);
    END;

    -- вставляем пропущенные дни - вдруг их нет в данных
    INSERT INTO #TempContract1 ([Date], [Value])
    SELECT
        [Date] = A.Date,
        [Value] = 0
    FROM @Dates AS A
    LEFT JOIN #TempContract1 AS B ON A.Date = B.Date
    WHERE B.Date IS NULL;

    declare @Date Date, @Value decimal(38,10), @IsDateAssets Bit;
    declare @OldDate Date, @SumValue decimal(38,10);


    -- признак наличия записей в постоянном кэше
    SET @IsDateAssets = 0;

    IF EXISTS
    (
        SELECT top 1 1
        FROM [CacheDB].[dbo].[Assets_Contracts]
        WHERE InvestorId = @InvestorId and ContractId = @ContractId
    )
    BEGIN
        SET @IsDateAssets = 1;
    END

    -- чистка временного кэша
    DELETE
    FROM [CacheDB].[dbo].[Assets_ContractsLast]
    WHERE InvestorId = @InvestorId and ContractId = @ContractId;


    set @OldDate = NULL;
    set @SumValue = NULL;

    declare obj_cur cursor local fast_forward for
        -- 
        SELECT
            [Date], [Value]
        FROM #TempContract1
        ORDER BY [Date];
    open obj_cur
    fetch next from obj_cur into
        @Date,
        @Value
    while(@@fetch_status = 0)
    begin
        if @OldDate IS NULL
        begin
            -- первая строка
            set @OldDate = @Date
            set @SumValue = @Value
        end
        else
        begin
            -- вторая и последующая строки
            if @OldDate <> @Date
            begin
                IF @OldDate < @LastEndDate
                BEGIN
                    -- если записей в постоянном кэше не было ранее или попали в последние 10 дней постоянного кэша
                    -- если записи были в постоянном кэше, то записи не будет (за исключением последних 10 дней постоянного кэша)
                    IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
                    BEGIN
                        WITH CTE
                        AS
                        (
                            SELECT *
                            FROM [CacheDB].[dbo].[Assets_Contracts]
                            WHERE InvestorId = @InvestorId and ContractId = @ContractId
                        ) 
                        MERGE
                            CTE as t
                        USING
                        (
                            select
                                [InvestorId] = @InvestorId,
                                [ContractId] = @ContractId,
                                [Date] = @OldDate,
                                [VALUE_RUR] = @SumValue
                        ) AS s
                        on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
                        when not matched
                            then insert (
                                [InvestorId],
                                [ContractId],
                                [Date],
                                [VALUE_RUR]
                            )
                            values (
                                s.[InvestorId],
                                s.[ContractId],
                                s.[Date],
                                s.[VALUE_RUR]
                            )
                        when matched
                        then update set
                            [VALUE_RUR] = s.[VALUE_RUR];
                    END
                END
                ELSE
                BEGIN
                    WITH CTE
                    AS
                    (
                        SELECT *
                        FROM [CacheDB].[dbo].[Assets_ContractsLast]
                        WHERE InvestorId = @InvestorId and ContractId = @ContractId
                    ) 
                    MERGE
                        CTE as t
                    USING
                    (
                        select
                            [InvestorId] = @InvestorId,
                            [ContractId] = @ContractId,
                            [Date] = @OldDate,
                            [VALUE_RUR] = @SumValue
                    ) AS s
                    on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
                    when not matched
                        then insert (
                            [InvestorId],
                            [ContractId],
                            [Date],
                            [VALUE_RUR]
                        )
                        values (
                            s.[InvestorId],
                            s.[ContractId],
                            s.[Date],
                            s.[VALUE_RUR]
                        )
                    when matched
                    then update set
                        [VALUE_RUR] = s.[VALUE_RUR];
                END

                set @OldDate = @Date;
            end

            set @SumValue += @Value
        end
        fetch next from obj_cur into
            @Date,
            @Value
    end

    IF @OldDate IS NOT NULL
    BEGIN
        IF @OldDate < @LastEndDate
        BEGIN
            -- если записей в постоянном кэше не было ранее или попали в последние 10 дней постоянного кэша
            -- если записи были в постоянном кэше, то записи не будет (за исключением последних 10 дней постоянного кэша)
            IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
            BEGIN
                WITH CTE
                AS
                (
                    SELECT *
                    FROM [CacheDB].[dbo].[Assets_Contracts]
                    WHERE InvestorId = @InvestorId and ContractId = @ContractId
                ) 
                MERGE
                    CTE as t
                USING
                (
                    select
                        [InvestorId] = @InvestorId,
                        [ContractId] = @ContractId,
                        [Date] = @OldDate,
                        [VALUE_RUR] = @SumValue
                ) AS s
                on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
                when not matched
                    then insert (
                        [InvestorId],
                        [ContractId],
                        [Date],
                        [VALUE_RUR]
                    )
                    values (
                        s.[InvestorId],
                        s.[ContractId],
                        s.[Date],
                        s.[VALUE_RUR]
                    )
                when matched
                then update set
                    [VALUE_RUR] = s.[VALUE_RUR];
            END
        END
        ELSE
        BEGIN
            WITH CTE
            AS
            (
                SELECT *
                FROM [CacheDB].[dbo].[Assets_ContractsLast]
                WHERE InvestorId = @InvestorId and ContractId = @ContractId
            ) 
            MERGE
                CTE as t
            USING
            (
                select
                    [InvestorId] = @InvestorId,
                    [ContractId] = @ContractId,
                    [Date] = @OldDate,
                    [VALUE_RUR] = @SumValue
            ) AS s
            on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
            when not matched
                then insert (
                    [InvestorId],
                    [ContractId],
                    [Date],
                    [VALUE_RUR]
                )
                values (
                    s.[InvestorId],
                    s.[ContractId],
                    s.[Date],
                    s.[VALUE_RUR]
                )
            when matched
            then update set
                [VALUE_RUR] = s.[VALUE_RUR];
        END
    END
    
    BEGIN TRY
        DROP TABLE #TempContract1;
    END TRY
    BEGIN CATCH
    END CATCH;
END
GO