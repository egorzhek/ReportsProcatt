-- расчёт и сохранение по инвестору и пифу
USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_FillInvestorFundDate_Inner]
(
	@Investor int = 16541, @FundId Int = 17578
)
AS BEGIN

	set nocount on;
	DECLARE @Min1Date Date, @Min2Date Date, @Max1Date Date, @Max2Date Date, @LastBeginDate Date;
	DECLARE @Dates table([Date] date);

	DECLARE @CurrentDate Date = getdate()
	DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate)






	-- предусловие
	DECLARE @CacheMAXDate Date, @SumAmount numeric(38, 10)

	SELECT 
		@CacheMAXDate = ([Date]) 
	FROM
	(
		SELECT [Date]
		FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
		WHERE Investor = @Investor and FundId = @FundId
		UNION
		SELECT [Date]
		FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
		WHERE Investor = @Investor and FundId = @FundId
	) AS D



	if @CacheMAXDate is not null
	BEGIN
		SELECT
			@SumAmount = SumAmount 
		FROM
		(
			SELECT SumAmount
			FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
			WHERE Investor = @Investor and FundId = @FundId AND [Date] = @CacheMAXDate
			UNION
			SELECT SumAmount
			FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
			WHERE Investor = @Investor and FundId = @FundId AND [Date] = @CacheMAXDate
		) AS D
	END

	-- не пересчитывать пиф, если закрыт более полугода назад
	If @CacheMAXDate <  DateAdd(DAY, -10, @LastEndDate) and @SumAmount = 0.000 return;



	-- Обновление имени Пифа
	WITH CTE
	AS
	(
		SELECT *
		FROM [dbo].[FundNames]
		WHERE [Id] = @FundId
	)
	MERGE
		CTE as t
	USING
	(
		SELECT TOP 1
			[ID] = S.[id], [NAME] = F.[NAME]
		FROM [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_FACES AS F WITH(NOLOCK) ON S.ISSUER = F.SELF_ID AND F.LAST_FLAG =1 AND F.E_DATE >= @CurrentDate
		WHERE S.id = @FundId
	) AS s
	on t.Id = s.Id
	when not matched
		then insert (
			[ID], [NAME]
		)
		values (
			s.[ID],
			s.[NAME]
		)
	when matched
	then update set
		[NAME] = s.[NAME];





		SET @Min1Date = NULL;
		SET @Min2Date = NULL;
		SET @Max1Date = NULL;
		SET @Max2Date = NULL;
		SET @LastBeginDate = NULL-- взять максимальную дату из постоянного кэша и вычесть ещё пару дней на всякий случай (merge простит)

		-- min_max
		SELECT
			@Min1Date = min(OFICDATE),
			@Min2Date = min(E_DATE),
			@Max1Date = max(OFICDATE),
			@Max2Date = max(E_DATE)
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES]
		WHERE VALUE_ID = @FundId;

		DELETE FROM @Dates;

		INSERT INTO @Dates ([Date]) VALUES
		(@Min1Date),(@Min2Date),(@Max1Date),(@Max2Date);

		SET @Min1Date = NULL;

		-- минимальная дата из минимальных
		SELECT
			@Min1Date = min([Date])
		FROM @Dates
		WHERE DATEPART(YEAR,[Date]) <> 9999;

		SET @Max1Date = NULL;

		-- максимальная дата из максимальных
		SELECT
			@Max1Date = max([Date])
		FROM @Dates
		WHERE DATEPART(YEAR,[Date]) <> 9999;

		DELETE FROM @Dates;

		-- заполняем таблицу дат
		WHILE @Min1Date <= @Max1Date
		BEGIN
			INSERT INTO @Dates ([Date]) VALUES (@Min1Date);

			SET @Min1Date = DATEADD(DAY,1,@Min1Date);
		END



		--SET @LastBeginDate = NULL-- взять максимальную дату из постоянного кэша и вычесть ещё пару дней на всякий случай (merge простит)

		SELECT @LastBeginDate = max([Date])
		FROM [CacheDB].[dbo].[InvestorFundDate]
		WHERE Investor = @Investor and FundId = @FundId

		IF @LastBeginDate is null
		BEGIN
			set @LastBeginDate = '1901-01-03'
		END
		
		SET @LastBeginDate = DATEADD(DAY, -2, @LastBeginDate);

		BEGIN TRY
			DROP TABLE #TempFund;
		END TRY
		BEGIN CATCH
		END CATCH

		SELECT *
		INTO #TempFund
		FROM
		(
			SELECT
				Investor, FundId, Amount, D,
				SUM(Amount) over (order by D rows between unbounded preceding and current row) as SumAmount,
				SUM(case when Amount > 0 then Amount else 0 end) over (partition by D) as AmountDayPlus,
				SUM(case when Amount < 0 then Amount else 0 end) over (partition by D) as AmountDayMinus,
				ROW_NUMBER() over (order by  D) as RowNumber
			FROM
			(
				select
				ISNULL(Investor, @Investor) as Investor,
				ISNULL(FundId, @FundId) as FundId,
				ISNULL(Amount,0) as Amount,
				ISNULL(D,DD) AS D
				from
				(
					select
						R.REG_1 AS Investor,
						R.REG_2 AS FundId,
						T.WIRDATE AS W_Date, 
						T.WIRING AS W_ID,
						B2.WALK AS WALK, 
						B2.ID AS ACC,
						T.AMOUNT_ * T.TYPE_ AS Amount,
						CAST(T.WIRDATE AS Date) AS D
					from [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
					INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST=R.ID and T.IS_PLAN='F'
					INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
					INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T2 WITH(NOLOCK) ON T2.WIRING = T.WIRING and T2.TYPE_ = -T.TYPE_
					INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS E2 WITH(NOLOCK) ON E2.ID = T2.REST
					INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES AS B2 WITH(NOLOCK) ON B2.ID = E2.BAL_ACC

					INNER JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON R.REG_2 = s.ID
					INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON S.ISSUER = C.INVESTOR AND C.I_TYPE = 5

					where 
					R.BAL_ACC = 2793
					AND R.REG_2 = @FundId
					AND R.REG_1 = @Investor
					AND T.WIRING is not null
					AND B2.WALK > 0 -- проводка реализована.
				 ) as Res
				FULL JOIN
				(
					SELECT
						[Date] AS DD
					FROM @Dates
				) AS Dt ON Res.D = Dt.DD
			) AS Res2
		) as Res3
		where Amount <> 0 or SumAmount <> 0
		ORDER BY
				Investor, FundId, D;

		
					BEGIN TRY
						DROP TABLE #TempFund4;
					END TRY
					BEGIN CATCH
					END CATCH


					SELECT
						[Investor] = B.Investor,
						[FundId] = B.FundId,
						[Date] = B.D,
						[AmountDay] = B.Amount,
						[SumAmount] = B.SumAmount,
						[RATE] = VL.[RATE],
						[USDRATE] = VB.[RATE],
						[EVRORATE] = VE.[RATE],

						[VALUE_RUR] = [BAL_DATA_STD].[dbo].f_Round(SumAmount * VL.[RATE], 2),
						--[VALUE_USD] = CASE WHEN ISNULL(VB.RATE,0) = 0 THEN 0 ELSE [BAL_DATA_STD].[dbo].f_Round(SumAmount * VL.[RATE] * (1.0000000/VB.RATE), 2) END,
						--[VALUE_EVRO] = CASE WHEN ISNULL(VE.RATE,0) = 0 THEN 0 ELSE [BAL_DATA_STD].[dbo].f_Round(SumAmount * VE.[RATE] * (1.0000000/VE.RATE), 2) END,

						[AmountDayPlus] = B.AmountDayPlus,
						[AmountDayPlus_RUR] = [BAL_DATA_STD].[dbo].f_Round(B.AmountDayPlus * VL.[RATE], 2),
						--[AmountDayPlus_USD] = CASE WHEN ISNULL(VB.RATE,0) = 0 THEN 0 ELSE [BAL_DATA_STD].[dbo].f_Round(B.AmountDayPlus * VL.[RATE] * (1.0000000/VB.RATE), 2) END,
						--[AmountDayPlus_EVRO] = CASE WHEN ISNULL(VE.RATE,0) = 0 THEN 0 ELSE [BAL_DATA_STD].[dbo].f_Round(B.AmountDayPlus * VL.[RATE] * (1.0000000/VE.RATE), 2) END,

						[AmountDayMinus] = B.AmountDayMinus,
						[AmountDayMinus_RUR] = [BAL_DATA_STD].[dbo].f_Round(B.AmountDayMinus * VL.[RATE], 2),
						--[AmountDayMinus_USD] = CASE WHEN ISNULL(VB.RATE,0) = 0 THEN 0 ELSE [BAL_DATA_STD].[dbo].f_Round(B.AmountDayMinus * VL.[RATE] * (1.0000000/VB.RATE), 2) END,
						--[AmountDayMinus_EVRO] = CASE WHEN ISNULL(VE.RATE,0) = 0 THEN 0 ELSE [BAL_DATA_STD].[dbo].f_Round(B.AmountDayMinus * VL.[RATE] * (1.0000000/VE.RATE), 2) END
						[LS_NUM] = LS.[LS_NUM]
					INTO #TempFund4
					FROM
					(
						SELECT
							D, RowNumber = max(RowNumber)
						FROM #TempFund
						GROUP BY D
					) AS A
					INNER JOIN #TempFund as B ON A.D = B.D and A.RowNumber = B.RowNumber
					OUTER APPLY
					(
						SELECT TOP 1
							RT.[RATE]
						FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
						WHERE RT.[VALUE_ID] = B.[FundId]
						AND RT.[E_DATE] >= B.D and RT.[OFICDATE] < B.D
						ORDER BY
							case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
							RT.[E_DATE] DESC,
							RT.[OFICDATE] DESC
					) AS VL
					--  в долларах
				
					OUTER APPLY
					(
						SELECT TOP 1
							RT.[RATE]
						FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
						WHERE RT.[VALUE_ID] = 2 -- доллары
						AND RT.[E_DATE] >= B.D and RT.[OFICDATE] < B.D
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
						AND RT.[E_DATE] >= B.D and RT.[OFICDATE] < B.D
						ORDER BY
							case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
							RT.[E_DATE] DESC,
							RT.[OFICDATE] DESC
					) AS VE

					OUTER APPLY
					(
						SELECT TOP(1)
							[LS_NUM] = T.[DEPO_LS]
						FROM [BAL_DATA_STD].[dbo].[D_B_TRUSTERS]   AS T 
						INNER JOIN [BAL_DATA_STD].[dbo].[OD_DOCS]  AS D ON D.[ID]     = T.[DOC]
						INNER JOIN [BAL_DATA_STD].[dbo].[OD_FUNDS] AS F ON F.[U_FACE] = T.[FOND]
						WHERE 
							T.[TRUSTER] = @Investor
							AND F.[SHARE] = @FundId
							AND T.[E_DATE] > B.D
							AND D.[STATE] IN (1,2846163)
						ORDER BY D.[D_DATE] DESC
					) AS LS
				
					--WHERE B.D > @LastBeginDate and B.D <= @LastEndDate -- заливка постоянного кэша в диапазоне дат


					BEGIN TRY
						DROP TABLE #TempFund5;
					END TRY
					BEGIN CATCH
					END CATCH

					SELECT
						[Investor],
						[FundId],
						[Date],
						[AmountDay],
						[SumAmount],
						[RATE],
						[USDRATE],
						[EVRORATE],

						[VALUE_RUR],
						[VALUE_USD]  = CASE WHEN [USDRATE] = 0 THEN 0.000 ELSE [dbo].f_Round([VALUE_RUR] * (1.0000000/[USDRATE]), 2) END,
						[VALUE_EVRO] = CASE WHEN [EVRORATE] = 0 THEN 0.000 ELSE [dbo].f_Round([VALUE_RUR] * (1.0000000/[EVRORATE]), 2) END,

						[AmountDayPlus],
						[AmountDayPlus_RUR],
						[AmountDayPlus_USD] = CASE WHEN [USDRATE] = 0 THEN 0.000 ELSE [dbo].f_Round([AmountDayPlus_RUR] * (1.0000000/[USDRATE]), 2) END,
						[AmountDayPlus_EVRO] = CASE WHEN [EVRORATE] = 0 THEN 0.000 ELSE [dbo].f_Round([AmountDayPlus_RUR] * (1.0000000/[EVRORATE]), 2) END,

						[AmountDayMinus],
						[AmountDayMinus_RUR],
						--[AmountDayMinus_USD] = [dbo].f_Round([AmountDayMinus_RUR] * (1.0000000/[USDRATE]), 2),
						--[AmountDayMinus_EVRO] = [dbo].f_Round([AmountDayMinus_RUR] * (1.0000000/[EVRORATE]), 2)
						[LS_NUM]
					INTO #TempFund5
					FROM
					(
						select * from  #TempFund4
					) AS FF;




			WITH CTE
			AS
			(
				SELECT *
				FROM [CacheDB].[dbo].[InvestorFundDate]
				WHERE Investor = @Investor and FundId = @FundId
			) 
			MERGE
				CTE as t
			USING
			(
					SELECT
						[Investor],
						[FundId],
						[Date],
						[AmountDay],
						[SumAmount],
						[RATE],
						[USDRATE],
						[EVRORATE],

						[VALUE_RUR],
						[VALUE_USD],
						[VALUE_EVRO],

						[AmountDayPlus],
						[AmountDayPlus_RUR],
						[AmountDayPlus_USD],
						[AmountDayPlus_EVRO],

						[AmountDayMinus],
						[AmountDayMinus_RUR],
						[AmountDayMinus_USD] = CASE WHEN [USDRATE] = 0 THEN 0.000 ELSE [dbo].f_Round([AmountDayMinus_RUR] * (1.0000000/[USDRATE]), 2) END,
						[AmountDayMinus_EVRO] = CASE WHEN [EVRORATE] = 0 THEN 0.000 ELSE [dbo].f_Round([AmountDayMinus_RUR] * (1.0000000/[EVRORATE]), 2) END,
						[LS_NUM]
					FROM
					(
						select * from  #TempFund5
						WHERE [Date] > @LastBeginDate and [Date] <= @LastEndDate -- заливка постоянного кэша в диапазоне дат
					) AS FF
				
			
			) AS s
			on t.Investor = s.Investor and t.FundId = s.FundId and t.[Date] = s.[Date]
			when not matched
				then insert (
					[Investor],
					[FundId],
					[Date],

					[AmountDay],
					[SumAmount],
					[RATE],
					[USDRATE],
					[EVRORATE],
					[VALUE_RUR],
					[VALUE_USD],
					[VALUE_EVRO],

					[AmountDayPlus],
					[AmountDayPlus_RUR],
					[AmountDayPlus_USD],
					[AmountDayPlus_EVRO],

					[AmountDayMinus],
					[AmountDayMinus_RUR],
					[AmountDayMinus_USD],
					[AmountDayMinus_EVRO],
					[LS_NUM]
				)
				values (
					s.[Investor],
					s.[FundId],
					s.[Date],

					s.[AmountDay],
					s.[SumAmount],
					s.[RATE],
					s.[USDRATE],
					s.[EVRORATE],
					s.[VALUE_RUR],
					s.[VALUE_USD],
					s.[VALUE_EVRO],

					s.[AmountDayPlus],
					s.[AmountDayPlus_RUR],
					s.[AmountDayPlus_USD],
					s.[AmountDayPlus_EVRO],

					s.[AmountDayMinus],
					s.[AmountDayMinus_RUR],
					s.[AmountDayMinus_USD],
					s.[AmountDayMinus_EVRO],
					s.[LS_NUM]
				)
			when matched
			then update set
				[AmountDay] = s.[AmountDay],
				[SumAmount] = s.[SumAmount],
				[RATE] = s.[RATE],
				[USDRATE] = s.[USDRATE],
				[EVRORATE] = s.[EVRORATE],
				[VALUE_RUR] = s.[VALUE_RUR],
				[VALUE_USD] = s.[VALUE_USD],
				[VALUE_EVRO] = s.[VALUE_EVRO],

				[AmountDayPlus] = s.[AmountDayPlus],
				[AmountDayPlus_RUR] = s.[AmountDayPlus_RUR],
				[AmountDayPlus_USD] = s.[AmountDayPlus_USD],
				[AmountDayPlus_EVRO] = s.[AmountDayPlus_EVRO],

				[AmountDayMinus] = s.[AmountDayMinus],
				[AmountDayMinus_RUR] = s.[AmountDayMinus_RUR],
				[AmountDayMinus_USD] = s.[AmountDayMinus_USD],
				[AmountDayMinus_EVRO] = s.[AmountDayMinus_EVRO],
				[LS_NUM] = s.[LS_NUM];
			
		


		-- чистка временного кэша за последние полгода
		DELETE
		FROM [CacheDB].[dbo].[InvestorFundDateLast]
		WHERE Investor = @Investor and FundId = @FundId;

		-- заливка временного кэша за последние полгода
		-- WHERE B.D > @LastEndDate -- заливка временного кэша за последние полгода
		-- [CacheDB].[dbo].[InvestorFundDateLast]

			WITH CTE
			AS
			(
				SELECT *
				FROM [CacheDB].[dbo].[InvestorFundDateLast]
				WHERE Investor = @Investor and FundId = @FundId
			) 
			MERGE
				CTE as t
			USING
			(
					SELECT
						[Investor],
						[FundId],
						[Date],
						[AmountDay],
						[SumAmount],
						[RATE],
						[USDRATE],
						[EVRORATE],

						[VALUE_RUR],
						[VALUE_USD],
						[VALUE_EVRO],

						[AmountDayPlus],
						[AmountDayPlus_RUR],
						[AmountDayPlus_USD],
						[AmountDayPlus_EVRO],

						[AmountDayMinus],
						[AmountDayMinus_RUR],
						[AmountDayMinus_USD] = CASE WHEN [USDRATE] = 0 THEN 0.000 ELSE [dbo].f_Round([AmountDayMinus_RUR] * (1.0000000/[USDRATE]), 2) END,
						[AmountDayMinus_EVRO] = CASE WHEN [EVRORATE] = 0 THEN 0.000 ELSE [dbo].f_Round([AmountDayMinus_RUR] * (1.0000000/[EVRORATE]), 2) END,
						[LS_NUM]
					FROM
					(
						select * from  #TempFund5
						WHERE [Date] > @LastEndDate
					) AS FF
				
			
			) AS s
			on t.Investor = s.Investor and t.FundId = s.FundId and t.[Date] = s.[Date]
			when not matched
				then insert (
					[Investor],
					[FundId],
					[Date],

					[AmountDay],
					[SumAmount],
					[RATE],
					[USDRATE],
					[EVRORATE],
					[VALUE_RUR],
					[VALUE_USD],
					[VALUE_EVRO],

					[AmountDayPlus],
					[AmountDayPlus_RUR],
					[AmountDayPlus_USD],
					[AmountDayPlus_EVRO],

					[AmountDayMinus],
					[AmountDayMinus_RUR],
					[AmountDayMinus_USD],
					[AmountDayMinus_EVRO],
					[LS_NUM]
				)
				values (
					s.[Investor],
					s.[FundId],
					s.[Date],

					s.[AmountDay],
					s.[SumAmount],
					s.[RATE],
					s.[USDRATE],
					s.[EVRORATE],
					s.[VALUE_RUR],
					s.[VALUE_USD],
					s.[VALUE_EVRO],

					s.[AmountDayPlus],
					s.[AmountDayPlus_RUR],
					s.[AmountDayPlus_USD],
					s.[AmountDayPlus_EVRO],

					s.[AmountDayMinus],
					s.[AmountDayMinus_RUR],
					s.[AmountDayMinus_USD],
					s.[AmountDayMinus_EVRO],
					s.[LS_NUM]
				)
			when matched
			then update set
				[AmountDay] = s.[AmountDay],
				[SumAmount] = s.[SumAmount],
				[RATE] = s.[RATE],
				[USDRATE] = s.[USDRATE],
				[EVRORATE] = s.[EVRORATE],
				[VALUE_RUR] = s.[VALUE_RUR],
				[VALUE_USD] = s.[VALUE_USD],
				[VALUE_EVRO] = s.[VALUE_EVRO],

				[AmountDayPlus] = s.[AmountDayPlus],
				[AmountDayPlus_RUR] = s.[AmountDayPlus_RUR],
				[AmountDayPlus_USD] = s.[AmountDayPlus_USD],
				[AmountDayPlus_EVRO] = s.[AmountDayPlus_EVRO],

				[AmountDayMinus] = s.[AmountDayMinus],
				[AmountDayMinus_RUR] = s.[AmountDayMinus_RUR],
				[AmountDayMinus_USD] = s.[AmountDayMinus_USD],
				[AmountDayMinus_EVRO] = s.[AmountDayMinus_EVRO],
				[LS_NUM] = s.[LS_NUM];

		BEGIN TRY
			DROP TABLE #TempFund;
		END TRY
		BEGIN CATCH
		END CATCH;

		BEGIN TRY
			DROP TABLE #TempFund4;
		END TRY
		BEGIN CATCH
		END CATCH;

		BEGIN TRY
			DROP TABLE #TempFund5;
		END TRY
		BEGIN CATCH
		END CATCH;
END
GO