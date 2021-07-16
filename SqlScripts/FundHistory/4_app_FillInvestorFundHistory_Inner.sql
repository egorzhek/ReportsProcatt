-- расчёт и сохранение истории пифа
USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_FillInvestorFundHistory_Inner]
(
	@Investor int = 44762, @FundId Int = 17578
)
AS BEGIN
	DECLARE @CurrentDate DateTime = GetDate()
	DECLARE @LastEndDate DateTime = DateAdd(DAY, -180, @CurrentDate)
	DECLARE @LastBeginDate DateTime

	SET @LastBeginDate = NULL-- взять максимальную дату из постоянного кэша и вычесть ещё пару дней на всякий случай (merge простит)

	SELECT @LastBeginDate = max([W_Date])
	FROM [CacheDB].[dbo].[FundHistory]
	WHERE Investor = @Investor and FundId = @FundId

	IF @LastBeginDate is null
	BEGIN
		set @LastBeginDate = '1901-01-03'
	END
	
	SET @LastBeginDate = DATEADD(DAY, -2, @LastBeginDate);



	----------------------------------------------
	-- предусловие - взято из предыдущего скприпта
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
	If @CacheMAXDate <  DateAdd(DAY, -10, @LastEndDate) and @SumAmount = 0.000
	and exists
	(
		SELECT TOP 1 1
		FROM [CacheDB].[dbo].[FundHistory]
		WHERE Investor = @Investor and FundId = @FundId
	)
	return;
	-- предусловие
	--------------








	BEGIN TRY
		DROP TABLE #InvestorFundHistory;
	END TRY
	BEGIN CATCH
	END CATCH

	SELECT
		[Investor]  = R.[REG_1],                                             -- ИД инвестора
		[FundId]    = R.[REG_2],                                             -- ИД ПИФа
		[W_ID]      = T.[WIRING],                                            -- W_ID
		[W_Date]    = T.[WIRDATE],                                           -- Дата операции (проводки)
		[Order_NUM] = KK.[Order_NUM],                                        -- Номер заявки
		--[OperName]  = W.[NAME],                                            -- Название операции
		[WALK]      = B2.[WALK],                                             -- Код операции
		[TYPE]      = T.[TYPE_],                                             -- Тип операции (ввод/вывод)
		[RATE_RUR]  = VL.[RATE],                                             -- Стоимость 1 пая
		[Amount]    = T.[AMOUNT_] * T.[TYPE_],                               -- Количество ПИФов
		[VALUE_RUR] = [dbo].f_Round(T.[AMOUNT_] * T.[TYPE_] * VL.[RATE], 2), -- Сумма сделки
		[Fee_RUR] = ISNULL(KK.Fee,0)                                         -- Сумма комиссии
	INTO #InvestorFundHistory
	FROM [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
	INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST=R.ID and T.IS_PLAN = 'F'
	INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
	INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T2 WITH(NOLOCK) ON T2.WIRING = T.WIRING and T2.TYPE_ = -T.TYPE_
	INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS E2 WITH(NOLOCK) ON E2.ID = T2.REST
	INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES AS B2 WITH(NOLOCK) ON B2.ID = E2.BAL_ACC

	INNER JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON R.REG_2 = S.ID
	INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON S.ISSUER = C.INVESTOR AND C.I_TYPE = 5
	OUTER APPLY
	(
		SELECT TOP 1
			RT.[RATE]
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
		WHERE RT.[VALUE_ID] = R.REG_2
		AND RT.[E_DATE] >= T.WIRDATE and RT.[OFICDATE] < T.WIRDATE
		ORDER BY
			CASE WHEN DATEPART(YEAR,RT.[E_DATE]) = 9999 THEN 1 ELSE 0 END ASC,
			RT.[E_DATE] DESC,
			RT.[OFICDATE] DESC
	) AS VL
	OUTER APPLY
	(
			SELECT TOP 1
				ISNULL(SISU.ADD_SUMMA, 0) AS Fee, --Сумма комиссии(надбавка) за операцию
				ISNULL(D_ISU.NUM_DATE, ISNUlL(D_DISU.NUM_DATE,0)) as Order_NUM -- Номер заявки
			FROM [BAL_DATA_STD].[dbo].OD_STEPS AS SSS
			INNER JOIN [BAL_DATA_STD].[dbo].OD_DOCS AS DDD ON DDD.ID = SSS.DOC
			INNER JOIN [BAL_DATA_STD].[dbo].U_OP_P_ISSUE AS SISU ON SISU.DOC = DDD.ID

			left join [BAL_DATA_STD].[dbo].U_OP_P_DEISSUE AS DISU ON DISU.DOC =DDD.ID
			left join [BAL_DATA_STD].[dbo].OD_DOCS AS D_ISU ON D_ISU.ID = SISU.CLAIM
			left join [BAL_DATA_STD].[dbo].OD_DOCS AS D_DISU ON D_DISU.ID = DISU.CLAIM
			WHERE SSS.ID = W.O_STEP
			/* -- нет записей таких вообще
			UNION ALL
			SELECT
				ISNULL(SISU.ADD_SUMMA, 0) as Fee --Сумма комиссии(надбавка) за операцию
			FROM OD_DOLS AS LLL WITH(NOLOCK)
			INNER JOIN OD_DOCS AS DDD WITH(NOLOCK) ON DDD.ID = LLL.DOC
			INNER JOIN U_OP_P_ISSUE AS SISU WITH(NOLOCK) ON SISU.DOC = DDD.ID
			WHERE LLL.ID = W.DOL
			*/
	) AS KK
	WHERE 
	R.BAL_ACC = 2793
	AND R.REG_2 = @FundId
	AND R.REG_1 = @Investor
	AND T.WIRING IS NOT NULL
	AND B2.WALK > 0 -- проводка реализована.
	AND B2.WALK <> 9;

	-- заливка постоянного кэша
	--select * from #InvestorFundHistory
	--WHERE [W_Date] > @LastBeginDate and [W_Date] <= @LastEndDate; -- заливка постоянного кэша в диапазоне дат



	-- заливка постоянного кэша
	WITH CTE
	AS
	(
		SELECT *
		FROM [CacheDB].[dbo].[FundHistory]
		WHERE Investor = @Investor and FundId = @FundId
	) 
	MERGE
		CTE as t
	USING
	(
		SELECT
			Investor,
			FundId,
			W_ID,
			W_Date,
			Order_NUM,
			WALK,
			TYPE,
			RATE_RUR,
			Amount,
			VALUE_RUR,
			Fee_RUR
		FROM #InvestorFundHistory
		WHERE [W_Date] > @LastBeginDate and [W_Date] <= @LastEndDate -- заливка постоянного кэша в диапазоне дат
	
	) AS s
	on
		t.Investor = s.Investor and t.FundId = s.FundId and t.W_ID = s.W_ID
	when not matched
		then insert (
			Investor,
			FundId,
			W_ID,
			W_Date,
			Order_NUM,
			WALK,
			TYPE,
			RATE_RUR,
			Amount,
			VALUE_RUR,
			Fee_RUR
		)
		values (
			s.Investor,
			s.FundId,
			s.W_ID,
			s.W_Date,
			s.Order_NUM,
			s.WALK,
			s.TYPE,
			s.RATE_RUR,
			s.Amount,
			s.VALUE_RUR,
			s.Fee_RUR
		)
	when matched
	then update set
		[W_Date]    = s.W_Date,
		[Order_NUM] = s.Order_NUM,
		[WALK]      = s.WALK,
		[TYPE]	    = s.TYPE,
		[RATE_RUR]  = s.RATE_RUR,
		[Amount]    = s.Amount,
		[VALUE_RUR] = s.VALUE_RUR,
		[Fee_RUR]   = s.Fee_RUR;


	-- чистка временного кэша за последние полгода
	DELETE
	FROM [CacheDB].[dbo].[FundHistoryLast]
	WHERE Investor = @Investor and FundId = @FundId;
	

	-- заливка временного хэша
	WITH CTE
	AS
	(
		SELECT *
		FROM [CacheDB].[dbo].[FundHistoryLast]
		WHERE Investor = @Investor and FundId = @FundId
	) 
	MERGE
		CTE as t
	USING
	(
		SELECT
			Investor,
			FundId,
			W_ID,
			W_Date,
			Order_NUM,
			WALK,
			TYPE,
			RATE_RUR,
			Amount,
			VALUE_RUR,
			Fee_RUR
		FROM #InvestorFundHistory
		WHERE [W_Date] > @LastEndDate -- заливка временного кеша за последние полгода
	) AS s
	on
		t.Investor = s.Investor and t.FundId = s.FundId and t.W_ID = s.W_ID
	when not matched
		then insert (
			Investor,
			FundId,
			W_ID,
			W_Date,
			Order_NUM,
			WALK,
			TYPE,
			RATE_RUR,
			Amount,
			VALUE_RUR,
			Fee_RUR
		)
		values (
			s.Investor,
			s.FundId,
			s.W_ID,
			s.W_Date,
			s.Order_NUM,
			s.WALK,
			s.TYPE,
			s.RATE_RUR,
			s.Amount,
			s.VALUE_RUR,
			s.Fee_RUR
		)
	when matched
	then update set
		[W_Date]    = s.W_Date,
		[Order_NUM] = s.Order_NUM,
		[WALK]      = s.WALK,
		[TYPE]	    = s.TYPE,
		[RATE_RUR]  = s.RATE_RUR,
		[Amount]    = s.Amount,
		[VALUE_RUR] = s.VALUE_RUR,
		[Fee_RUR]   = s.Fee_RUR;


	BEGIN TRY
		DROP TABLE #InvestorFundHistory;
	END TRY
	BEGIN CATCH
	END CATCH;
END
GO