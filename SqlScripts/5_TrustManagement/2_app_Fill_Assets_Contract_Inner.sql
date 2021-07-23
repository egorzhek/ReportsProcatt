USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_Assets_Contract_Inner]
(
    @ContractId int -- = 18699821
)
AS BEGIN
    SET NOCOUNT ON;
	DECLARE @Date Date, @Value decimal(38,10), @IsDateAssets Bit, @USDRATE decimal(38,10), @EURORATE decimal(38,10);
    DECLARE @OldDate Date, @SumValue decimal(38,10), @SumDayValue decimal(38,10);

	DECLARE
		@INPUT_VALUE_USD decimal(38,10),
		@INPUT_VALUE_EURO decimal(38,10),
		@OUTPUT_VALUE_USD decimal(38,10),
		@OUTPUT_VALUE_EURO decimal(38,10),
		@INPUT_DIVIDENTS_RUR decimal(38,10),
		@INPUT_DIVIDENTS_USD decimal(38,10),
		@INPUT_DIVIDENTS_EURO decimal(38,10),
		@INPUT_COUPONS_RUR decimal(38,10),
		@INPUT_COUPONS_USD decimal(38,10),
		@INPUT_COUPONS_EURO decimal(38,10);

	DECLARE @USDRATE_Last decimal(38,10), @EURORATE_Last decimal(38,10);

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

	BEGIN TRY
        DROP TABLE #TempContract2;
    END TRY
    BEGIN CATCH
    END CATCH;

	BEGIN TRY
        DROP TABLE #TempContract3
    END TRY
    BEGIN CATCH
    END CATCH;

	CREATE TABLE #TempContract1
	(
		[Date] date,
		[Value] decimal(38,10),
		[USDRATE] decimal(38,10),
		[EURORATE] decimal(38,10)
	);

    DECLARE @Dates table([Date] date);

	INSERT #TempContract1
	(
		[Date], [Value]
	)
    SELECT
        [Date] = CAST(DATEADD(SECOND, 1, W.WIRDATE) as date),
        [Value] = T.VALUE_ * T.TYPE_
    --INTO #TempContract1
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


	-- вытягиваем курсы валют
	UPDATE B SET
		[USDRATE]  = VB.RATE,
		[EURORATE] = VE.RATE
	FROM #TempContract1 AS B
	--  в долларах
	OUTER APPLY
	(
		SELECT TOP 1
			RT.[RATE]
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
		WHERE RT.[VALUE_ID] = 2 -- доллары
		AND RT.[E_DATE] >= B.[Date] and RT.[OFICDATE] < B.[Date]
		ORDER BY
			case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
			RT.[E_DATE] DESC,
			RT.[OFICDATE] DESC
	) AS VB
	--  в евро
	OUTER APPLY
	(
		SELECT TOP 1
			RT.[RATE]
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
		WHERE RT.[VALUE_ID] = 5 -- евро
		AND RT.[E_DATE] >= B.[Date] and RT.[OFICDATE] < B.[Date]
		ORDER BY
			case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
			RT.[E_DATE] DESC,
			RT.[OFICDATE] DESC
	) AS VE;






	-- минимальная и максимальная дата
	declare @StartDate datetime, @EndDate datetime;

	SELECT
        @StartDate = min([Date])
    FROM #TempContract1;

    SELECT
        @EndDate = max([Date])
    FROM #TempContract1;

	set @EndDate = DATEADD(DAY, 1, @EndDate); -- + 1 день

	SELECT
		PaymentDate, Type, CurrencyId, AmountPayments = sum(AmountPayments)
	INTO #TempContract2
	FROM
	(
		SELECT
			PaymentDate = cast(PaymentDate as Date), Type, CurrencyId, AmountPayments
		FROM
		(
			SELECT
				[PaymentDate] = T.WIRDATE,
				[Type] = 1, -- Купоны
				[CurrencyId] = VV.Id,
				[AmountPayments] = SUM( T.VALUE_ )
			FROM [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK)
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) ON R.BAL_ACC = B.ID and R.REG_3 = @ContractId
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.ID = R.REG_2 and S.CLASS = 2
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = R.REG_2
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE >= @StartDate AND T.WIRDATE < @EndDate AND S.ID IS NOT NULL AND T.TYPE_ = -1
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VV on R.VALUE_ID = VV.ID
			CROSS APPLY (SELECT TOP(1) PERCENT_, SUMMA FROM [BAL_DATA_STD].[dbo].OD_COUPONS AS C WHERE C.SHARE = S.ID AND C.E_DATE <= T.WIRDATE order by E_DATE desc ) CC
			WHERE B.ACC_PLAN = 95 AND B.SYS_NAME = 'ПИФ-ДИВ' AND T.IS_PLAN = 'F'
			GROUP BY S.ISSUER, S.ID, V.NAME, T.WIRDATE, CC.PERCENT_, VV.SYSNAME, VV.ID
		) AS D
		UNION ALL
		select
			PaymentDate = cast(PaymentDate as Date), Type, CurrencyId, AmountPayments
		FROM
		(
			SELECT 
				[PaymentDate] = T.WIRDATE,
				[Type] = 2,  -- Дивиденды
				[CurrencyId] = VV.ID,
				[AmountPayments] = SUM( T.VALUE_ )
			FROM [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK)
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) ON R.BAL_ACC = B.ID AND R.REG_3 = @ContractId
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.ID = R.REG_2 AND S.CLASS in (1,7,10)
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = R.REG_2
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE >= @StartDate AND T.WIRDATE < @EndDate AND S.ID IS NOT NULL AND T.TYPE_=-1
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VV WITH(NOLOCK) ON VV.id = R.VALUE_ID
			WHERE B.ACC_PLAN = 95 AND B.SYS_NAME = 'ПИФ-ДИВ' AND T.IS_PLAN = 'F' 
			GROUP BY S.ISSUER, S.ID, V.NAME, T.WIRDATE, VV.SYSNAME, VV.ID
		) AS F
	) AS GG
	GROUP BY PaymentDate, Type, CurrencyId;

	SELECT
		A.PaymentDate, A.Type,
		RUB = case
				when CurrencyId = 1 then AmountPayments
				when CurrencyId = 2 then AmountPayments * USDRATE
				when CurrencyId = 5 then AmountPayments * EURORATE
				else 0
			end,
		USD = case
				when CurrencyId = 1 and USDRATE <> 0 then AmountPayments * (1/USDRATE)
				when CurrencyId = 2 then AmountPayments
				when CurrencyId = 5 and USDRATE <> 0 then AmountPayments * (1/USDRATE) * EURORATE
				else 0
			end,
		EURO = case
				when CurrencyId = 1 and EURORATE <> 0 then AmountPayments * (1/EURORATE)
				when CurrencyId = 2 and EURORATE <> 0 then AmountPayments * (1/EURORATE) * USDRATE
				when CurrencyId = 5 then AmountPayments
				else 0
			end
	INTO #TempContract3
	FROM #TempContract2 AS A
	LEFT JOIN
	(
		SELECT
			[Date], [USDRATE], [EURORATE]
		FROM #TempContract1
		GROUP BY
			[Date], [USDRATE], [EURORATE]
	) AS B ON A.[PaymentDate] = B.[Date];

	update a set
		RUB = [dbo].f_Round(RUB, 2),
		USD = [dbo].f_Round(USD, 2),
		EURO = [dbo].f_Round(EURO, 2)
	from #TempContract3 as a;


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
	set @SumDayValue = 0;

    declare obj_cur cursor local fast_forward for
        -- 
        SELECT
            A.[Date], A.[Value], A.[USDRATE], A.[EURORATE]
        FROM #TempContract1 as A
        ORDER BY A.[Date]
    open obj_cur
    fetch next from obj_cur into
        @Date,
        @Value,
		@USDRATE,
		@EURORATE
    while(@@fetch_status = 0)
    begin
        if @OldDate IS NULL
        begin
            -- первая строка
            set @OldDate = @Date
            set @SumValue = @Value
			set @SumDayValue = @Value
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
						select
							@INPUT_DIVIDENTS_RUR = isnull(D.RUB,0),
							@INPUT_DIVIDENTS_USD = isnull(D.USD,0),
							@INPUT_DIVIDENTS_EURO = isnull(D.EURO,0),
							@INPUT_COUPONS_RUR = isnull(K.RUB,0),
							@INPUT_COUPONS_USD = isnull(K.USD,0),
							@INPUT_COUPONS_EURO = isnull(K.EURO,0)
						from
						(
							select @OldDate as [Date]
						) as A
						LEFT JOIN
						(
							select
								PaymentDate,
								RUB = Sum(RUB),
								USD = Sum(USD),
								EURO = Sum(EURO)
							from #TempContract3
							where [Type] = 1 -- Купоны
							and PaymentDate = @OldDate
							group by PaymentDate
						) as K ON A.[Date] = K.PaymentDate
						LEFT JOIN
						(
							select
								PaymentDate,
								RUB = Sum(RUB),
								USD = Sum(USD),
								EURO = Sum(EURO)
							from #TempContract3
							where [Type] = 2 -- Дивиденды
							and PaymentDate = @OldDate
							group by PaymentDate
						) as D ON A.[Date] = D.PaymentDate;

						SET @INPUT_VALUE_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
						SET @INPUT_VALUE_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;
						SET @OUTPUT_VALUE_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
						SET @OUTPUT_VALUE_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;

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
                                [VALUE_RUR] = @SumValue,
								[USDRATE] = @USDRATE,
								[EURORATE] = @EURORATE,
								[VALUE_USD] = [dbo].f_Round(@SumValue * @USDRATE, 2),
								[VALUE_EURO] = [dbo].f_Round(@SumValue * @EURORATE, 2),
								[INPUT_VALUE_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
								[OUTPUT_VALUE_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
								[INPUT_VALUE_USD]  = @INPUT_VALUE_USD,
								[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
								[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
								[OUTPUT_VALUE_EURO]= @OUTPUT_VALUE_EURO,
								[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
								[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
								[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
								[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
								[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
								[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO
								
                        ) AS s
                        on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
                        when not matched
                            then insert (
                                [InvestorId],
                                [ContractId],
                                [Date],
                                [VALUE_RUR],
								[USDRATE],
								[EURORATE],
								[VALUE_USD],
								[VALUE_EURO],
								[INPUT_VALUE_RUR],
								[OUTPUT_VALUE_RUR],
								[INPUT_VALUE_USD],
								[INPUT_VALUE_EURO],
								[OUTPUT_VALUE_USD],
								[OUTPUT_VALUE_EURO],
								[INPUT_DIVIDENTS_RUR],
								[INPUT_DIVIDENTS_USD],
								[INPUT_DIVIDENTS_EURO],
								[INPUT_COUPONS_RUR],
								[INPUT_COUPONS_USD],
								[INPUT_COUPONS_EURO]
                            )
                            values (
                                s.[InvestorId],
                                s.[ContractId],
                                s.[Date],
                                s.[VALUE_RUR],
								s.[USDRATE],
								s.[EURORATE],
								s.[VALUE_USD],
								s.[VALUE_EURO],
								s.[INPUT_VALUE_RUR],
								s.[OUTPUT_VALUE_RUR],
								s.[INPUT_VALUE_USD],
								s.[INPUT_VALUE_EURO],
								s.[OUTPUT_VALUE_USD],
								s.[OUTPUT_VALUE_EURO],
								s.[INPUT_DIVIDENTS_RUR],
								s.[INPUT_DIVIDENTS_USD],
								s.[INPUT_DIVIDENTS_EURO],
								s.[INPUT_COUPONS_RUR],
								s.[INPUT_COUPONS_USD],
								s.[INPUT_COUPONS_EURO]
                            )
                        when matched
                        then update set
                            [VALUE_RUR] = s.[VALUE_RUR],
							[USDRATE] = s.[USDRATE],
							[EURORATE] = s.[EURORATE],
							[VALUE_USD] = s.[VALUE_USD],
							[VALUE_EURO] = s.[VALUE_EURO],
							[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
							[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
							[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
							[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
							[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
							[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO],					
							[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
							[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
							[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
							[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
							[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
							[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO];
                    END
                END
                ELSE
                BEGIN
					select
						@INPUT_DIVIDENTS_RUR = isnull(D.RUB,0),
						@INPUT_DIVIDENTS_USD = isnull(D.USD,0),
						@INPUT_DIVIDENTS_EURO = isnull(D.EURO,0),
						@INPUT_COUPONS_RUR = isnull(K.RUB,0),
						@INPUT_COUPONS_USD = isnull(K.USD,0),
						@INPUT_COUPONS_EURO = isnull(K.EURO,0)
					from
					(
						select @OldDate as [Date]
					) as A
					LEFT JOIN
					(
						select
							PaymentDate,
							RUB = Sum(RUB),
							USD = Sum(USD),
							EURO = Sum(EURO)
						from #TempContract3
						where [Type] = 1 -- Купоны
						and PaymentDate = @OldDate
						group by PaymentDate
					) as K ON A.[Date] = K.PaymentDate
					LEFT JOIN
					(
						select
							PaymentDate,
							RUB = Sum(RUB),
							USD = Sum(USD),
							EURO = Sum(EURO)
						from #TempContract3
						where [Type] = 2 -- Дивиденды
						and PaymentDate = @OldDate
						group by PaymentDate
					) as D ON A.[Date] = D.PaymentDate;

					SET @INPUT_VALUE_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
					SET @INPUT_VALUE_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;
					SET @OUTPUT_VALUE_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
					SET @OUTPUT_VALUE_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;

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
                            [VALUE_RUR] = @SumValue,
							[USDRATE] = @USDRATE,
							[EURORATE] = @EURORATE,
							[VALUE_USD] = [dbo].f_Round(@SumValue * @USDRATE, 2),
							[VALUE_EURO] = [dbo].f_Round(@SumValue * @EURORATE, 2),
							[INPUT_VALUE_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
							[OUTPUT_VALUE_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
							[INPUT_VALUE_USD]  = @INPUT_VALUE_USD,
							[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
							[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
							[OUTPUT_VALUE_EURO]= @OUTPUT_VALUE_EURO,
							[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
							[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
							[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
							[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
							[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
							[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO
                    ) AS s
                    on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
                    when not matched
                        then insert (
                            [InvestorId],
                            [ContractId],
                            [Date],
                            [VALUE_RUR],
							[USDRATE],
							[EURORATE],
							[VALUE_USD],
							[VALUE_EURO],
							[INPUT_VALUE_RUR],
							[OUTPUT_VALUE_RUR],
							[INPUT_VALUE_USD],
							[INPUT_VALUE_EURO],
							[OUTPUT_VALUE_USD],
							[OUTPUT_VALUE_EURO],
							[INPUT_DIVIDENTS_RUR],
							[INPUT_DIVIDENTS_USD],
							[INPUT_DIVIDENTS_EURO],
							[INPUT_COUPONS_RUR],
							[INPUT_COUPONS_USD],
							[INPUT_COUPONS_EURO]
                        )
                        values (
                            s.[InvestorId],
                            s.[ContractId],
                            s.[Date],
                            s.[VALUE_RUR],
							s.[USDRATE],
							s.[EURORATE],
							s.[VALUE_USD],
							s.[VALUE_EURO],
							s.[INPUT_VALUE_RUR],
							s.[OUTPUT_VALUE_RUR],
							s.[INPUT_VALUE_USD],
							s.[INPUT_VALUE_EURO],
							s.[OUTPUT_VALUE_USD],
							s.[OUTPUT_VALUE_EURO],
							s.[INPUT_DIVIDENTS_RUR],
							s.[INPUT_DIVIDENTS_USD],
							s.[INPUT_DIVIDENTS_EURO],
							s.[INPUT_COUPONS_RUR],
							s.[INPUT_COUPONS_USD],
							s.[INPUT_COUPONS_EURO]
                        )
                    when matched
                    then update set
                        [VALUE_RUR] = s.[VALUE_RUR],
						[USDRATE] = s.[USDRATE],
						[EURORATE] = s.[EURORATE],
						[VALUE_USD] = s.[VALUE_USD],
						[VALUE_EURO] = s.[VALUE_EURO],
						[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
						[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
						[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
						[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
						[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
						[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO],
						[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
						[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
						[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
						[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
						[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
						[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO];
                END

                set @OldDate = @Date;
				set @SumDayValue = 0;
            end

            set @SumValue += @Value
			set @SumDayValue += @Value
        end

		set @USDRATE_Last = @USDRATE;
		set @EURORATE_Last = @EURORATE;

        fetch next from obj_cur into
            @Date,
            @Value,
			@USDRATE,
			@EURORATE
    end

	set @USDRATE = @USDRATE_Last;
	set @EURORATE = @EURORATE_Last;

    IF @OldDate IS NOT NULL
    BEGIN
        IF @OldDate < @LastEndDate
        BEGIN
            -- если записей в постоянном кэше не было ранее или попали в последние 10 дней постоянного кэша
            -- если записи были в постоянном кэше, то записи не будет (за исключением последних 10 дней постоянного кэша)
            IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
            BEGIN
				select
					@INPUT_DIVIDENTS_RUR = isnull(D.RUB,0),
					@INPUT_DIVIDENTS_USD = isnull(D.USD,0),
					@INPUT_DIVIDENTS_EURO = isnull(D.EURO,0),
					@INPUT_COUPONS_RUR = isnull(K.RUB,0),
					@INPUT_COUPONS_USD = isnull(K.USD,0),
					@INPUT_COUPONS_EURO = isnull(K.EURO,0)
				from
				(
					select @OldDate as [Date]
				) as A
				LEFT JOIN
				(
					select
						PaymentDate,
						RUB = Sum(RUB),
						USD = Sum(USD),
						EURO = Sum(EURO)
					from #TempContract3
					where [Type] = 1 -- Купоны
					and PaymentDate = @OldDate
					group by PaymentDate
				) as K ON A.[Date] = K.PaymentDate
				LEFT JOIN
				(
					select
						PaymentDate,
						RUB = Sum(RUB),
						USD = Sum(USD),
						EURO = Sum(EURO)
					from #TempContract3
					where [Type] = 2 -- Дивиденды
					and PaymentDate = @OldDate
					group by PaymentDate
				) as D ON A.[Date] = D.PaymentDate;

				SET @INPUT_VALUE_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
				SET @INPUT_VALUE_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;
				SET @OUTPUT_VALUE_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
				SET @OUTPUT_VALUE_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;

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
                        [VALUE_RUR] = @SumValue,
						[USDRATE] = @USDRATE,
						[EURORATE] = @EURORATE,
						[VALUE_USD] = [dbo].f_Round(@SumValue * @USDRATE, 2),
						[VALUE_EURO] = [dbo].f_Round(@SumValue * @EURORATE, 2),
						[INPUT_VALUE_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
						[OUTPUT_VALUE_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
						[INPUT_VALUE_USD]  = @INPUT_VALUE_USD,
						[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
						[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
						[OUTPUT_VALUE_EURO]= @OUTPUT_VALUE_EURO,
						[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
						[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
						[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
						[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
						[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
						[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO
                ) AS s
                on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
                when not matched
                    then insert (
                        [InvestorId],
                        [ContractId],
                        [Date],
                        [VALUE_RUR],
						[USDRATE],
						[EURORATE],
						[VALUE_USD],
						[VALUE_EURO],
						[INPUT_VALUE_RUR],
						[OUTPUT_VALUE_RUR],
						[INPUT_VALUE_USD],
						[INPUT_VALUE_EURO],
						[OUTPUT_VALUE_USD],
						[OUTPUT_VALUE_EURO],
						[INPUT_DIVIDENTS_RUR],
						[INPUT_DIVIDENTS_USD],
						[INPUT_DIVIDENTS_EURO],
						[INPUT_COUPONS_RUR],
						[INPUT_COUPONS_USD],
						[INPUT_COUPONS_EURO]
                    )
                    values (
                        s.[InvestorId],
                        s.[ContractId],
                        s.[Date],
                        s.[VALUE_RUR],
						s.[USDRATE],
						s.[EURORATE],
						s.[VALUE_USD],
						s.[VALUE_EURO],
						s.[INPUT_VALUE_RUR],
						s.[OUTPUT_VALUE_RUR],
						s.[INPUT_VALUE_USD],
						s.[INPUT_VALUE_EURO],
						s.[OUTPUT_VALUE_USD],
						s.[OUTPUT_VALUE_EURO],
						s.[INPUT_DIVIDENTS_RUR],
						s.[INPUT_DIVIDENTS_USD],
						s.[INPUT_DIVIDENTS_EURO],
						s.[INPUT_COUPONS_RUR],
						s.[INPUT_COUPONS_USD],
						s.[INPUT_COUPONS_EURO]
                    )
                when matched
                then update set
                    [VALUE_RUR] = s.[VALUE_RUR],
					[USDRATE] = s.[USDRATE],
					[EURORATE] = s.[EURORATE],
					[VALUE_USD] = s.[VALUE_USD],
					[VALUE_EURO] = s.[VALUE_EURO],
					[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
					[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
					[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
					[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
					[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
					[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO],
					[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
					[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
					[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
					[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
					[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
					[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO];
            END
        END
        ELSE
        BEGIN
			select
				@INPUT_DIVIDENTS_RUR = isnull(D.RUB,0),
				@INPUT_DIVIDENTS_USD = isnull(D.USD,0),
				@INPUT_DIVIDENTS_EURO = isnull(D.EURO,0),
				@INPUT_COUPONS_RUR = isnull(K.RUB,0),
				@INPUT_COUPONS_USD = isnull(K.USD,0),
				@INPUT_COUPONS_EURO = isnull(K.EURO,0)
			from
			(
				select @OldDate as [Date]
			) as A
			LEFT JOIN
			(
				select
					PaymentDate,
					RUB = Sum(RUB),
					USD = Sum(USD),
					EURO = Sum(EURO)
				from #TempContract3
				where [Type] = 1 -- Купоны
				and PaymentDate = @OldDate
				group by PaymentDate
			) as K ON A.[Date] = K.PaymentDate
			LEFT JOIN
			(
				select
					PaymentDate,
					RUB = Sum(RUB),
					USD = Sum(USD),
					EURO = Sum(EURO)
				from #TempContract3
				where [Type] = 2 -- Дивиденды
				and PaymentDate = @OldDate
				group by PaymentDate
			) as D ON A.[Date] = D.PaymentDate;

			SET @INPUT_VALUE_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
			SET @INPUT_VALUE_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;
			SET @OUTPUT_VALUE_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @USDRATE, 2) ELSE 0 END;
			SET @OUTPUT_VALUE_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * @EURORATE, 2) ELSE 0 END;

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
                    [VALUE_RUR] = @SumValue,
					[USDRATE] = @USDRATE,
					[EURORATE] = @EURORATE,
					[VALUE_USD] = [dbo].f_Round(@SumValue * @USDRATE, 2),
					[VALUE_EURO] = [dbo].f_Round(@SumValue * @EURORATE, 2),
					[INPUT_VALUE_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
					[OUTPUT_VALUE_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
					[INPUT_VALUE_USD]  = @INPUT_VALUE_USD,
					[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
					[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
					[OUTPUT_VALUE_EURO]= @OUTPUT_VALUE_EURO,
					[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
					[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
					[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
					[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
					[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
					[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO
            ) AS s
            on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId and t.[Date] = s.[Date]
            when not matched
                then insert (
                    [InvestorId],
                    [ContractId],
                    [Date],
                    [VALUE_RUR],
					[USDRATE],
					[EURORATE],
					[VALUE_USD],
					[VALUE_EURO],
					[INPUT_VALUE_RUR],
					[OUTPUT_VALUE_RUR],
					[INPUT_VALUE_USD],
					[INPUT_VALUE_EURO],
					[OUTPUT_VALUE_USD],
					[OUTPUT_VALUE_EURO],
					[INPUT_DIVIDENTS_RUR],
					[INPUT_DIVIDENTS_USD],
					[INPUT_DIVIDENTS_EURO],
					[INPUT_COUPONS_RUR],
					[INPUT_COUPONS_USD],
					[INPUT_COUPONS_EURO]
                )
                values (
                    s.[InvestorId],
                    s.[ContractId],
                    s.[Date],
                    s.[VALUE_RUR],
					s.[USDRATE],
					s.[EURORATE],
					s.[VALUE_USD],
					s.[VALUE_EURO],
					s.[INPUT_VALUE_RUR],
					s.[OUTPUT_VALUE_RUR],
					s.[INPUT_VALUE_USD],
					s.[INPUT_VALUE_EURO],
					s.[OUTPUT_VALUE_USD],
					s.[OUTPUT_VALUE_EURO],
					s.[INPUT_DIVIDENTS_RUR],
					s.[INPUT_DIVIDENTS_USD],
					s.[INPUT_DIVIDENTS_EURO],
					s.[INPUT_COUPONS_RUR],
					s.[INPUT_COUPONS_USD],
					s.[INPUT_COUPONS_EURO]
                )
            when matched
            then update set
                [VALUE_RUR] = s.[VALUE_RUR],
				[USDRATE] = s.[USDRATE],
				[EURORATE] = s.[EURORATE],
				[VALUE_USD] = s.[VALUE_USD],
				[VALUE_EURO] = s.[VALUE_EURO],
				[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
				[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
				[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
				[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
				[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
				[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO],
				[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
				[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
				[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
				[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
				[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
				[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO];
        END
    END
    
    BEGIN TRY
        DROP TABLE #TempContract1;
    END TRY
    BEGIN CATCH
    END CATCH;

	BEGIN TRY
        DROP TABLE #TempContract2;
    END TRY
    BEGIN CATCH
    END CATCH;

	BEGIN TRY
        DROP TABLE #TempContract3
    END TRY
    BEGIN CATCH
    END CATCH;
END
GO