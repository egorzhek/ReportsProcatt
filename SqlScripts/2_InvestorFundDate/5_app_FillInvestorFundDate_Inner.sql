-- расчёт и сохранение по инвестору и пифу
USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_LoadCalendar]
as begin
	insert into [dbo].[OD_CALENDAR] (H_DATE, MARKET)
	select
		a.H_DATE, a.MARKET
	from [BAL_DATA_STD].[dbo].[OD_CALENDAR] as a
	LEFT JOIN [dbo].[OD_CALENDAR] as b on a.H_DATE = b.H_DATE and a.MARKET = b.MARKET
	where b.H_DATE is null;
end
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_OBLIG_INFO]
AS BEGIN
	MERGE
		[dbo].[OBLIG_INFO] as t
	USING
	(
		select 
			S.SELF_ID,				-- ИД облигации
			V.SYSNAME,				-- код бумаги
			V.NAME,					-- Наименование облигации (эмитент, транш)
			S.ISSUER,				-- Эмитент
			FF.NAME as IssuerName,  -- Наименование эмитента
			S.NUM_REG,				-- Регистрационный номер
			V.ISIN,					-- Код ISIN
			V.CFI,					-- Код CFI
			S.DATE_REG,				-- Дата регистрации (допуска)
			S.COUNT_,				-- Объем выпуска, шт.
			S.ISSUENUM,				-- Номер транша
			S.MNEM,					-- Транш
			S.BIRTHDATE,			-- Начало начисл. купонов
			S.DEATHDATE,			-- Дата погашения
			S.MODE,					-- Форма выпуска (1 - бездокументарная , 2 - документарная на предъявителя , 3 - в форме сертификатов, 4 - документарная именная)
			S.NOMINAL,				-- Номинал
			S.NOM_TYPE,				-- Тип номинала (1 - Амортизируемый, 0 - Постоянный )
			S.NOM_VAL,				-- Код валюты номинала
			S.TYPE_,				-- Тип купонного дохода ( 2 -  с переменной %-ой ставкой, 3 - с фиксированной ставкий)
			S.IS_MARGIN,			-- Маржинальная?
			S.IS_MCS,				-- О.Ц.Х.?
			S.STATUS,				-- Статус ЦБ (1 - Выпуск активен, 0 - выпуск блокирован)
			OS.IS_EUR_BOND,			-- Еврооблигация?
			OS.IS_SAVE,				-- Метод расчета (1 -ре
			OS.IS_CONV,				-- Тип структуры		
			OS.PERIOD,				-- Дней в периоде
			OS.PERCENT_,			-- Ставка дохода
			Os.DAYS,				-- Число дней в году
			OS.PRICE,				-- Цена размещения
			OS.PERIOD_M,			-- Месяцев в периоде
			OS.STAVKA,				-- Ставка дисконтирования
			OS.IS_GG,				-- Имеет госгарантию?
			s.REP_DATE,				-- Дата отчета
			OS.NKD_MFU,				-- Тип купонного дохода
			OS.P_MODEL,				-- Модель процентных периодов
			V.IS_IN,				-- Принята к учету?
			os.GUARANTOR,			-- Поручитель
			s.B_DATE,				-- Дата начал актуальности
			s.E_DATE,				-- Дата окончания актуальности
			op.VAL as OP_NOLIQUID,  -- Ограничение по ликвидности (Код)
			op.VALUE_				-- Ограничение по ликвидности (причина)
		from [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK)
		inner join [BAL_DATA_STD].[dbo].OD_VALUES AS v WITH(NOLOCK) ON s.id = v.id
		left join [BAL_DATA_STD].[dbo].OD_O_SHARES AS os WITH(NOLOCK) ON os.SHARE = s.ID
		left join [BAL_DATA_STD].[dbo].OD_OPTIONS AS op WITH(NOLOCK) ON op.DESCR = 11950585 and op.OBJECT = s.ISSUER and op.B_DATE <= GETDATE() and op.E_DATE > GETDATE()
		left join [BAL_DATA_STD].[dbo].OD_FACES AS ff WITH(NOLOCK) ON ff.SELF_ID = s.ISSUER and ff.LAST_FLAG = 1
		where s.CLASS = 2 and os.IS_SERT = 0
	) AS s
	on t.SELF_ID = s.SELF_ID
	when not matched
		then insert (
			[SELF_ID],
			[SYSNAME],
			[NAME],
			[ISSUER],
			[IssuerName],
			[NUM_REG],
			[ISIN],
			[CFI],
			[DATE_REG],
			[COUNT_],
			[ISSUENUM],
			[MNEM],
			[BIRTHDATE],
			[DEATHDATE],
			[MODE],
			[NOMINAL],
			[NOM_TYPE],
			[NOM_VAL],
			[TYPE_],
			[IS_MARGIN],
			[IS_MCS],
			[STATUS],
			[IS_EUR_BOND],
			[IS_SAVE],
			[IS_CONV],
			[PERIOD],
			[PERCENT_],
			[DAYS],
			[PRICE],
			[PERIOD_M],
			[STAVKA],
			[IS_GG],
			[REP_DATE],
			[NKD_MFU],
			[P_MODEL],
			[IS_IN],
			[GUARANTOR],
			[B_DATE],
			[E_DATE],
			[OP_NOLIQUID],
			[VALUE_]
		)
		values (
			s.[SELF_ID],
			s.[SYSNAME],
			s.[NAME],
			s.[ISSUER],
			s.[IssuerName],
			s.[NUM_REG],
			s.[ISIN],
			s.[CFI],
			s.[DATE_REG],
			s.[COUNT_],
			s.[ISSUENUM],
			s.[MNEM],
			s.[BIRTHDATE],
			s.[DEATHDATE],
			s.[MODE],
			s.[NOMINAL],
			s.[NOM_TYPE],
			s.[NOM_VAL],
			s.[TYPE_],
			s.[IS_MARGIN],
			s.[IS_MCS],
			s.[STATUS],
			s.[IS_EUR_BOND],
			s.[IS_SAVE],
			s.[IS_CONV],
			s.[PERIOD],
			s.[PERCENT_],
			s.[DAYS],
			s.[PRICE],
			s.[PERIOD_M],
			s.[STAVKA],
			s.[IS_GG],
			s.[REP_DATE],
			s.[NKD_MFU],
			s.[P_MODEL],
			s.[IS_IN],
			s.[GUARANTOR],
			s.[B_DATE],
			s.[E_DATE],
			s.[OP_NOLIQUID],
			s.[VALUE_]
		)
	when matched
	then update set
		[SYSNAME] = s.[SYSNAME],
		[NAME] = s.[NAME],
		[ISSUER] = s.[ISSUER],
		[IssuerName] = s.[IssuerName],
		[NUM_REG] = s.[NUM_REG],
		[ISIN] = s.[ISIN],
		[CFI] = s.[CFI],
		[DATE_REG] = s.[DATE_REG],
		[COUNT_] = s.[COUNT_],
		[ISSUENUM] = s.[ISSUENUM],
		[MNEM] = s.[MNEM],
		[BIRTHDATE] = s.[BIRTHDATE],
		[DEATHDATE] = s.[DEATHDATE],
		[MODE] = s.[MODE],
		[NOMINAL] = s.[NOMINAL],
		[NOM_TYPE] = s.[NOM_TYPE],
		[NOM_VAL] = s.[NOM_VAL],
		[TYPE_] = s.[TYPE_],
		[IS_MARGIN] = s.[IS_MARGIN],
		[IS_MCS] = s.[IS_MCS],
		[STATUS] = s.[STATUS],
		[IS_EUR_BOND] = s.[IS_EUR_BOND],
		[IS_SAVE] = s.[IS_SAVE],
		[IS_CONV] = s.[IS_CONV],
		[PERIOD] = s.[PERIOD],
		[PERCENT_] = s.[PERCENT_],
		[DAYS] = s.[DAYS],
		[PRICE] = s.[PRICE],
		[PERIOD_M] = s.[PERIOD_M],
		[STAVKA] = s.[STAVKA],
		[IS_GG] = s.[IS_GG],
		[REP_DATE] = s.[REP_DATE],
		[NKD_MFU] = s.[NKD_MFU],
		[P_MODEL] = s.[P_MODEL],
		[IS_IN] = s.[IS_IN],
		[GUARANTOR] = s.[GUARANTOR],
		[B_DATE] = s.[B_DATE],
		[E_DATE] = s.[E_DATE],
		[OP_NOLIQUID] = s.[OP_NOLIQUID],
		[VALUE_] = s.[VALUE_];
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_OBLIG_COUPONS]
AS BEGIN
	MERGE
		[dbo].[OBLIG_COUPONS] as t
	USING
	(
		select
			C.SHARE,				-- ИД Облигации	(связь с OD_SHARES по SELF_ID)
			C.B_DATE,				-- Дата начала периода
			C.E_DATE,				-- Дата конца периода
			C.PERCENT_,				-- Ставка в % годовых
			C.IS_PAY,				-- Тип купона ( 1- Выплатной, 0 - Расчетный)
			C.SUMMA,				-- Сумма к выплате
			C.DELTA,				-- Сумма амортизации
			C.DELTA + C.SUMMA as ANN, -- Аннуитет (выплата)
			C.IS_PERCENT,			-- Выплата в процентах ? ( 1 - выплата задана процентом, 0 - выплата задана суммой )
			C.O_PRICE,				-- Цена оферты
			C.B_PAY,				-- Дата начала выплаты
			C.E_PAY,				-- Дата окончания выплаты
			C.P_DATE,				-- Дата выплаты
			C.NOMINAL,				-- Номинал
			C.DEFOLT_DATE,			-- Дата объявления дефолта
			C.ACTUAL_DATE,			-- Дата объявления ставки/суммы выплаты
			C.CALC_SUMMA			-- Сумма к начислению
		from [BAL_DATA_STD].[dbo].OD_COUPONS AS C WITH(nolock)
	) AS s
	on t.[SHARE] = s.[SHARE] and t.[B_DATE] = s.[B_DATE] and t.[E_DATE] = s.[E_DATE]
	when not matched
		then insert
		(
			[SHARE],
			[B_DATE],
			[E_DATE],
			[PERCENT_],
			[IS_PAY],
			[SUMMA],
			[DELTA],
			[ANN],
			[IS_PERCENT],
			[O_PRICE],
			[B_PAY],
			[E_PAY],
			[P_DATE],
			[NOMINAL],
			[DEFOLT_DATE],
			[ACTUAL_DATE],
			[CALC_SUMMA]
		)
		values
		(
			s.[SHARE],
			s.[B_DATE],
			s.[E_DATE],
			s.[PERCENT_],
			s.[IS_PAY],
			s.[SUMMA],
			s.[DELTA],
			s.[ANN],
			s.[IS_PERCENT],
			s.[O_PRICE],
			s.[B_PAY],
			s.[E_PAY],
			s.[P_DATE],
			s.[NOMINAL],
			s.[DEFOLT_DATE],
			s.[ACTUAL_DATE],
			s.[CALC_SUMMA]
		)
	when matched
	then update set
		[PERCENT_] = s.[PERCENT_],
		[IS_PAY] = s.[IS_PAY],
		[SUMMA] = s.[SUMMA],
		[DELTA] = s.[DELTA],
		[ANN] = s.[ANN],
		[IS_PERCENT] = s.[IS_PERCENT],
		[O_PRICE] = s.[O_PRICE],
		[B_PAY] = s.[B_PAY],
		[E_PAY] = s.[E_PAY],
		[P_DATE] = s.[P_DATE],
		[NOMINAL] = s.[NOMINAL],
		[DEFOLT_DATE] = s.[DEFOLT_DATE],
		[ACTUAL_DATE] = s.[ACTUAL_DATE],
		[CALC_SUMMA] = s.[CALC_SUMMA];
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_OBLIG_OFERTS]
AS BEGIN
	MERGE
		[dbo].[OBLIG_OFERTS] as t
	USING
	(
		select
			C.SHARE,		-- ИД Облигации (связь с OD_SHARES по SELF_ID)
			C.B_DATE,		-- Дата начала периода
			C.E_DATE,		-- Дата окончания периода
			C.P_DATE,		-- Дата выплаты
			C.O_PRICE,		-- Цена оферты
			C.O_TYPE,		-- Тип оферты (1 - Право эмитента (колл), 2 - право инвесторов (пут))
			C.ACTUAL_DATE	-- Дата объявления оферты
		FROM [BAL_DATA_STD].[dbo].OD_OFFERS AS C WITH(NOLOCK)
	) AS s
	on t.[SHARE] = s.[SHARE] and t.[B_DATE] = s.[B_DATE] and t.[E_DATE] = s.[E_DATE]
	when not matched
		then insert
		(
			[SHARE],
			[B_DATE],
			[E_DATE],
			[P_DATE],
			[O_PRICE],
			[O_TYPE],
			[ACTUAL_DATE]
		)
		values
		(
			s.[SHARE],
			s.[B_DATE],
			s.[E_DATE],
			s.[P_DATE],
			s.[O_PRICE],
			s.[O_TYPE],
			s.[ACTUAL_DATE]
		)
	when matched
	then update set
		[P_DATE] = s.[P_DATE],
		[O_PRICE] = s.[O_PRICE],
		[O_TYPE] = s.[O_TYPE],
		[ACTUAL_DATE] = s.[ACTUAL_DATE];
END
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