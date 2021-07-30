USE [CacheDB]
GO
CREATE OR ALTER FUNCTION [dbo].[f_Date] ( @d_date datetime )
returns datetime as
/* отбрасывание времени, оставляем только дату, через отбрасывание дробной части */
begin
   if @d_date is null return '30.12.1899' /* в FB возвращает 17.11.1858, тут пусть будет 30.12.1899 (дельфёвый ноль) */
   return cast( floor( cast( @d_date as float ) ) as datetime )
end
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Refresh_Assets_Info]
(
	@ContractId Int
)
AS BEGIN
	DECLARE @InvestorId Int, @NUM Nvarchar(100), @DATE_OPEN date, @DATE_CLOSE date;

	SELECT TOP (1)
		@InvestorId = c.INVESTOR,	-- ID инвестора
		--ContractId = c.DOC, -- идентификатор договора
		@NUM = dc.NUM, -- номер договора
		@DATE_OPEN = dc.D_DATE,	-- дата договора
		@DATE_CLOSE = c.E_DATE -- дата окончания договора
	FROM [BAL_DATA_STD].[dbo].D_B_CONTRACTS C WITH(NOLOCK)
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_DOCS DC WITH(NOLOCK) ON DC.ID = C.DOC
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACES FI WITH(NOLOCK) ON FI.SELF_ID = C.INVESTOR and FI.E_DATE > getdate() and FI.LAST_FLAG = 1 -- разыменовываем инвестора
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACE_ACCS A WITH(NOLOCK) ON A.ID = C.ACCOUNT
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACES FA WITH(NOLOCK) ON FA.SELF_ID = a.BANK and FA.E_DATE > getdate() and FA.LAST_FLAG = 1  -- разымновываем банк, в котором открыт счет для расчета с клиентом
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACE_ACCS BA ON BA.ID = C.B_ACC
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACES FB WITH(NOLOCK) ON FB.SELF_ID = ba.BANK and FB.E_DATE > getdate() and FB.LAST_FLAG = 1  -- разымновываем банк, в котором открыт счет для расчета с клиентом
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACE_ACCS DA ON DA.ID = C.D_ACC
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_FACES FD WITH(NOLOCK) ON FD.SELF_ID = da.BANK and FD.E_DATE > getdate() and FD.LAST_FLAG = 1  -- разымновываем банк, в котором открыт счет ДЕПО
	WHERE 
	c.I_TYPE = 1 -- нас интересуют только учредители ДУ
	and C.DOC = @ContractId


	IF @InvestorId IS NOT NULL
	AND @NUM IS NOT NULL
	AND @DATE_OPEN IS NOT NULL
	BEGIN
		WITH CTE
		AS
		(
		    SELECT *
		    FROM [CacheDB].[dbo].[Assets_Info]
		    WHERE InvestorId = @InvestorId and ContractId = @ContractId
		) 
		MERGE
		    CTE as t
		USING
		(
		    select
		        [InvestorId] = @InvestorId,
		        [ContractId] = @ContractId,
		        [DATE_OPEN] = @DATE_OPEN,
				[NUM] = @NUM,
				[DATE_CLOSE] = @DATE_CLOSE
		) AS s
		on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId
		when not matched
		    then insert (
		        [InvestorId],
				[ContractId],
				[DATE_OPEN],
				[NUM],
				[DATE_CLOSE]
		    )
		    values (
		        s.[InvestorId],
				s.[ContractId],
				s.[DATE_OPEN],
				s.[NUM],
				s.[DATE_CLOSE]
		    )
		when matched
		then update set
		    [DATE_OPEN] = s.[DATE_OPEN],
			[NUM] = s.[NUM],
			[DATE_CLOSE] = s.[DATE_CLOSE];
	END
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_SelectPayments]
(
	@ContractId Int = 17290
)
AS BEGIN
	-- Юр лиц отсекаем, для них будут нули
	IF EXISTS
	(
		SELECT 1
		FROM [BAL_DATA_STD].[dbo].OD_FACES AS F WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON C.INVESTOR = F.SELF_ID AND C.E_DATE > GETDATE()
		WHERE
		C.DOC = @ContractId
		AND F.S_TYPE = 1
		AND F.LAST_FLAG = 1
		AND F.E_DATE > GETDATE()
	)
	BEGIN
		-- пустой запрос
		SELECT
			[InvestorId]      = 0,
			[ContractId]      = 0,
			[WIRING]          = 0,  -- ID Проводки
			[TYPE_]           = -1,
			[PaymentDateTime] = getdate(), -- Дата движения ДС (ЦБ)
			[Amount_RUR]      = 0.00
		where 1 = 0; -- запрос без записей
		
		return;
	END

	select distinct
		[InvestorId]      = z.INVESTOR,
		[ContractId]      = z.DOC,
		[WIRING]          = W.ID,  -- ID Проводки
		[TYPE_]           = -T.TYPE_,
		[PaymentDateTime] = T.WIRDATE, -- Дата движения ДС (ЦБ)
		[Amount_RUR]      = dbo.f_Round(-T.EQ_ * T.TYPE_, 2)
	FROM [BAL_DATA_STD].[dbo].D_B_CONTRACTS      AS Z WITH(NOLOCK)
	INNER JOIN [BAL_DATA_STD].[dbo].OD_ACC_PLANS AS P WITH(NOLOCK)    on P.SYS_NAME = 'MONEY'
	INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES  AS B WITH(NOLOCK)    on B.ACC_PLAN = P.ID and B.SYS_NAME = 'ФОНД'
	INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS     AS R WITH(NOLOCK)    on R.BAL_ACC = B.ID and R.REG_1 = Z.INVESTOR and R.REG_3 = Z.DOC
	INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS     AS T WITH(NOLOCK)    on T.REST = R.ID and T.WIRDATE < GetDate()
	INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING    AS W WITH(NOLOCK)    on W.ID = T.WIRING

	LEFT JOIN [BAL_DATA_STD].[dbo].OD_TURNS      AS rt WITH(NOLOCK)   on rt.WIRING = W.ID and rt.TYPE_ = -T.TYPE_
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_RESTS      AS rr WITH(NOLOCK)   on rr.ID     = rt.REST
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_BALANCES   AS rb WITH(NOLOCK)   on rb.ID     = rr.BAL_ACC
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES     AS sv WITH(NOLOCK)   on sv.ID     = rr.REG_2
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES     AS sh WITH(NOLOCK)   on sh.ID     = sv.ID
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_SYS_TABS   AS sc WITH(NOLOCK)   on sc.CODE   = 'SHARE_CLASS' and sc.NUM = sh.CLASS
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES     AS nv WITH(NOLOCK)	  on nv.ID     = sh.NOM_VAL

	INNER JOIN [BAL_DATA_STD].[dbo].OD_STEPS     AS S WITH(NOLOCK)    on S.ID = W.O_STEP
	INNER JOIN [BAL_DATA_STD].[dbo].OD_DOCS      AS D WITH(NOLOCK)    on D.ID = S.DOC
	INNER JOIN [BAL_DATA_STD].[dbo].OD_DOLS      AS DOL WITH(NOLOCK)  on DOL.DOC = d.ID -- возьмем подвалы документов
	LEFT JOIN [BAL_DATA_STD].[dbo].D_OP_VAL      AS DV WITH(NOLOCK)   on DV.DOC = D.ID and DV.DESCR in (1743,1766) and DV.LINE = DOL.ID -- узнаем коды валюты операции 
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES     AS VO WITH(NOLOCK)   on VO.ID = DV.VAL -- Получим код валюты
	LEFT JOIN [BAL_DATA_STD].[dbo].D_OP_VAL      AS DV1 WITH(NOLOCK)  on DV1.DOC = D.Id and DV1.DESCR in (1746,1765) and DV1.LINE = DOL.ID -- получим сумму операции
	LEFT JOIN [BAL_DATA_STD].[dbo].D_OP_VAL      AS DV2 WITH(NOLOCK)  on DV2.DOC = D.Id and DV2.DESCR in (1742,1763,1759,1772) and DV2.LINE = DOL.ID and DV2.VAL = Z.DOC -- т.к. одним документом можно провести деньги по разным договорам, оставим только те операции, которые касаются конкретного портфеля.
	WHERE
	T.IS_PLAN = 'F'
	and w.ID is not null
	and T.VALUE_ <> 0
	and z.DOC = @ContractId
	and S.S_TYPE not in (1052, 7612481)
	and DV2.VAL is not null;
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Refresh_Operation_History]
(
	@InvestorId Int,
	@ContractId Int
)
AS BEGIN
	-- Юр лиц отсекаем, для них история пока не ведётся
	IF EXISTS
	(
		SELECT 1
		FROM [BAL_DATA_STD].[dbo].OD_FACES AS F WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON C.INVESTOR = F.SELF_ID AND C.E_DATE > GETDATE()
		WHERE
		C.DOC = @ContractId
		AND F.S_TYPE = 1
		AND F.LAST_FLAG = 1
		AND F.E_DATE > GETDATE()
	)
	BEGIN
		return;
	END

	declare @CurrentDateFormat Nvarchar(50), @DynSql  Nvarchar(50);

	select
		@CurrentDateFormat = date_format
	from sys.dm_exec_sessions
	where session_id = @@spid;

	set dateformat dmy;

	--declare @ContractId int = 2257804;
	--declare @InvestorId int = 2149652;
	declare @StartDate datetime		= NULL; --'01.01.1900'
	declare @EndDate datetime		= '31.12.2999';

	DECLARE @CurrentDate Date = GetDate();
	DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate);
	DECLARE @LastEndDate2 Date = DateAdd(DAY, -360, @CurrentDate);

	-- вычисляем последнее залитое значение в постоянном кэше Max to @StartDate
	-- если его нет, то @StartDate datetime = '01.01.1900'
	-- > @StartDate
	SELECT
		@StartDate = max([Date])
	FROM [dbo].[Operations_History_Contracts]
	WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId;

	IF @StartDate is null
	BEGIN
		set @StartDate = '1901-01-01';
	END

	-- чистим временный кеш
	DELETE FROM [dbo].[Operations_History_Contracts_Last]
	WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId;

	-- чистим постоянный кеш на последнюю дату - так надо - могут появиться новыестроки именно на этот момент времени
	if @StartDate > @LastEndDate2 -- но не более года
	BEGIN
		DELETE FROM [dbo].[Operations_History_Contracts]
		WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId AND [Date] = @StartDate;
	END
	ELSE
	BEGIN
		-- скорректируем на день более, чтобы не вставляло лишних строк
		set @StartDate = DATEADD(DAY, 1, @StartDate);
	END



	declare @P1 datetime = @StartDate
	declare @P2 datetime = @EndDate
	declare @P3 int = null
	declare @P4 int = @ContractId
	declare @P5 int = 1025

	BEGIN TRY
		DROP TABLE #FFF;
	END TRY
	BEGIN CATCH
	END CATCH

	CREATE TABLE #FFF
	(
		[InvestorId] [int] NOT NULL,
		[ContractId] [int] NOT NULL,
		[Date] [datetime] NULL,
		[Type] [int] NULL,
		[T_Name] NVarchar(300) Collate DATABASE_DEFAULT NULL,
		[ISIN] NVarchar(50) Collate DATABASE_DEFAULT NULL,
		[Investment] NVarchar(300) Collate DATABASE_DEFAULT NULL,
		[Price] [numeric](38, 7) NULL,
		[Amount] [numeric](38, 7) NULL,
		[Value_Nom] [numeric](38, 7) NULL,
		[Currency] [int] NULL,
		[Fee] [numeric](38, 7),
		[PaperId] [int] NULL
	);


	INSERT INTO #FFF
	(
		[InvestorId], [ContractId], [Date], [Type],
		[T_Name], [ISIN], [Investment], [Price],
		[Amount], [Value_Nom], [Currency], [Fee], [PaperId]
	)
	SELECT
		Investor, ContractID, W_Date, Type,
		T_Name, ISIN, Investment, Price,
		Amount, Value_Nom, Currency, Fee, PaperId
	FROM
	--------------------Вводы-выводы денежных средств-----------------
	(
		SELECT distinct
			z.INVESTOR as Investor,
			z.DOC as ContractID,
			T.WIRDATE as W_Date, -- Дата движения ДС (ЦБ)
			-T.TYPE_ as Type, --Тип (1 - ввод, -1 - вывод)
			w.NAME as T_Name,-- Наименование операции
			null as ISIN, --ISIN ценной бумаги
			VO.NAME as Investment, --Название инструмента
			null as Price, --Цена одной бумаги
			null as Amount, --Количество бумаг
			DV1.VAL as Value_Nom, -- Сумма сделки в валюте номинала
			--dbo.f_Round(-T.EQ_*T.TYPE_, 2) as Value_RUR, -- Сумма сделки в рублях
			VO.ID as Currency, --код валюты
			0 as Fee, --Комиссия
			sv.ID as PaperId
		FROM [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS Z WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_ACC_PLANS AS P WITH(NOLOCK) on P.SYS_NAME = 'MONEY'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK) on B.ACC_PLAN = P.ID and B.SYS_NAME = 'ФОНД'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) on R.BAL_ACC = B.ID and R.REG_1 = Z.INVESTOR and R.REG_3 = Z.DOC
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) on T.REST = R.ID and T.WIRDATE >= @StartDate and T.WIRDATE <= @EndDate
		INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) on W.ID = T.WIRING
		left join [BAL_DATA_STD].[dbo].OD_TURNS AS rt WITH(NOLOCK) on rt.WIRING = W.ID and rt.TYPE_ = -T.TYPE_
		left join [BAL_DATA_STD].[dbo].OD_RESTS AS rr WITH(NOLOCK) on rr.ID = rt.REST
		left join [BAL_DATA_STD].[dbo].OD_BALANCES AS rb WITH(NOLOCK) on rb.ID = rr.BAL_ACC
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS sv WITH(NOLOCK) on sv.ID = rr.REG_2
		left join [BAL_DATA_STD].[dbo].OD_SHARES AS sh WITH(NOLOCK) on sh.ID = sv.ID
		left join [BAL_DATA_STD].[dbo].OD_SYS_TABS AS sc WITH(NOLOCK) on sc.CODE = 'SHARE_CLASS' and sc.NUM = sh.CLASS
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS nv WITH(NOLOCK) on nv.ID = sh.NOM_VAL
		INNER JOIN [BAL_DATA_STD].[dbo].OD_STEPS AS S WITH(NOLOCK) on S.ID = W.O_STEP
		left join [BAL_DATA_STD].[dbo].OD_DOCS AS D WITH(NOLOCK) on D.ID = S.DOC

		left join [BAL_DATA_STD].[dbo].OD_DOLS AS DOL WITH(NOLOCK) on DOL.DOC = d.ID -- возьмем подвалы документов
		left join [BAL_DATA_STD].[dbo].D_OP_VAL AS DV WITH(NOLOCK) on DV.DOC = D.ID and DV.DESCR in (1743,1766) and DV.LINE = DOL.ID -- узнаем коды валюты операции 
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS VO WITH(NOLOCK) on VO.ID = DV.VAL -- Получим код валюты
		INNER JOIN [BAL_DATA_STD].[dbo].D_OP_VAL AS DV1 WITH(NOLOCK) on DV1.DOC = D.Id and DV1.DESCR in (1746,1765) and DV1.LINE = DOL.ID -- получим сумму операции
		INNER JOIN [BAL_DATA_STD].[dbo].D_OP_VAL AS DV2 WITH(NOLOCK) on DV2.DOC = D.Id and DV2.DESCR in (1742,1763,1759,1772) and DV2.LINE = DOL.ID and DV2.VAL = Z.DOC -- т.к. одним документом можно провести деньги по разным договорам, оставим только те операции, которые касаются конкретного портфеля.
		WHERE
		T.IS_PLAN = 'F'
		and W.ID is not null
		and T.VALUE_ <> 0
		and z.DOC = @ContractId
		and S.S_TYPE not in (1052 ,7612481)
		and DV2.VAL is not null
		and DV1.VAL is not null
	) as AAA
	UNION ALL
	--------------------Вводы-выводы ценных бумаг-----------------
	(
	--Declare @ContractId int = 2257804 

		select
			Investor, ContractID, W_Date, Type,
			T_Name, ISIN, Investment,
			Price = case when Amount = 0 then 0.00 else dbo.f_Round((Value_RUR * (1/isnull(VB.RATE,1)))/Amount, 2) end,
			Amount, Value_Nom = dbo.f_Round(Value_RUR * (1/isnull(VB.RATE,1)), 2), Currency, Fee, PaperId
		from
		(
			select distinct
				z.INVESTOR as Investor,
				z.DOC as ContractID,
				dbo.f_Date(T.WIRDATE) as W_Date, -- Дата движения ДС (ЦБ)
				-T.TYPE_ as Type, --Тип (1 - ввод, -1 - вывод)
				w.NAME as T_Name,-- Наименование операции
				sv.ISIN as ISIN, --ISIN ценной бумаги
				sv.NAME as Investment, --Название инструмента
				null as Price, --Цена одной бумаги  -------------------------Высчитываем сумму в валюте номинала (по курсу) а потом делим на Amount 
				w.D_AMOUNT - w.K_AMOUNT as Amount, --Количество бумаг
				null as Value_Nom, -- Сумма сделки в валюте номинала -найти курс валюты и пересчитать из рублей
		
				NOM_VAL as Currency, --код валюты
				0 as Fee, --Комиссия
				dbo.f_Round(-T.EQ_*T.TYPE_, 2) as Value_RUR, -- Сумма сделки в рублях
				sv.ID as PaperId
			FROM [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS Z WITH(NOLOCK)
			INNER JOIN [BAL_DATA_STD].[dbo].OD_ACC_PLANS AS P WITH(NOLOCK) on P.SYS_NAME = 'MONEY'
			INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK) on B.ACC_PLAN = P.ID and B.SYS_NAME = 'ФОНД'
			INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) on R.BAL_ACC = B.ID and R.REG_1 = Z.INVESTOR and R.REG_3 = Z.DOC
			INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) on T.REST = R.ID and T.WIRDATE >= @StartDate and T.WIRDATE <= @EndDate
			INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) on W.ID = T.WIRING
			left join [BAL_DATA_STD].[dbo].OD_TURNS AS rt WITH(NOLOCK) on rt.WIRING = W.ID and rt.TYPE_ = -T.TYPE_
			left join [BAL_DATA_STD].[dbo].OD_RESTS AS rr WITH(NOLOCK) on rr.ID = rt.REST
			left join [BAL_DATA_STD].[dbo].OD_BALANCES AS rb WITH(NOLOCK) on rb.ID = rr.BAL_ACC
			left join [BAL_DATA_STD].[dbo].OD_VALUES AS sv WITH(NOLOCK) on sv.ID = rr.REG_2
			left join [BAL_DATA_STD].[dbo].OD_SHARES AS sh WITH(NOLOCK) on sh.ID = sv.ID
			left join [BAL_DATA_STD].[dbo].OD_SYS_TABS AS sc WITH(NOLOCK) on sc.CODE = 'SHARE_CLASS' and sc.NUM = sh.CLASS
			left join [BAL_DATA_STD].[dbo].OD_VALUES AS nv WITH(NOLOCK) on nv.ID = sh.NOM_VAL
			INNER JOIN [BAL_DATA_STD].[dbo].OD_STEPS AS S WITH(NOLOCK) on S.ID = W.O_STEP
			INNER JOIN [BAL_DATA_STD].[dbo].OD_DOCS AS D WITH(NOLOCK) on D.ID = S.DOC

			left join [BAL_DATA_STD].[dbo].OD_DOLS AS DOL WITH(NOLOCK) on DOL.DOC = d.ID -- возьмем подвалы документов
			left join [BAL_DATA_STD].[dbo].D_OP_VAL AS DV WITH(NOLOCK) on DV.DOC=D.ID and DV.DESCR in (1743,1766) and DV.LINE=DOL.ID -- узнаем коды валюты операции 
			left join [BAL_DATA_STD].[dbo].OD_VALUES AS VO WITH(NOLOCK) on VO.ID = DV.VAL -- Получим код валюты
			left join [BAL_DATA_STD].[dbo].D_OP_VAL AS DV1 WITH(NOLOCK) on DV1.DOC = D.Id and DV1.DESCR in (1746,1765) and DV1.LINE=DOL.ID -- получим сумму операции
			INNER JOIN [BAL_DATA_STD].[dbo].D_OP_VAL AS DV2 WITH(NOLOCK) on DV2.DOC = D.Id and DV2.DESCR in (1742,1763,1759,1772) and DV2.LINE = DOL.ID and DV2.VAL = Z.DOC -- т.к. одним документом можно провести деньги по разным договорам, оставим только те операции, которые касаются конкретного портфеля.

			WHERE
			T.IS_PLAN = 'F'
			and W.ID is not null
			and T.VALUE_ <> 0
			and Z.DOC = @ContractId
			and S.S_TYPE not in (1052 ,7612481)
			and DV2.VAL is not null
			and DV1.VAL is null
		) as RR
		OUTER APPLY
		(
			SELECT TOP 1
				RT.[RATE]
			FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
			WHERE RT.[VALUE_ID] = RR.Currency -- валюта
			AND RT.[E_DATE] >= RR.W_Date and RT.[OFICDATE] < RR.W_Date
			ORDER BY
				case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
				RT.[E_DATE] DESC,
				RT.[OFICDATE] DESC
		) AS VB
	)
	UNION ALL
	--------------------Выплаты купонов-----------------
	(
		SELECT
			@InvestorId as Investor,  ----------Добавить
			R.REG_3 as ContractID, --------Добавить
			dbo.f_Date(T.WIRDATE) as W_Date, -- Дата движения ДС (ЦБ)
			1 as Type, --Тип (1 - ввод, -1 - вывод)
			(select 'Выплата купонов') as T_Name,-- Наименование операции
			V.ISIN as ISIN, --ISIN ценной бумаги
			V.NAME as Investment, --Название инструмента
			null as Price, --Цена одной бумаги  
			null as Amount, --Количество бумаг
			 SUM( T.VALUE_ ) as Value_Nom, -- Сумма сделки в валюте номинала 
			VV.Id as Currency, --код валюты
			0 as Fee, --Комиссия
			V.ID as PaperId
		FROM [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) ON R.BAL_ACC = B.ID and R.REG_3 = @ContractId
		INNER JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.ID = R.REG_2 and S.CLASS = 2
		INNER JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = R.REG_2
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE >= @StartDate AND T.WIRDATE < @EndDate AND S.ID IS NOT NULL AND T.TYPE_ = -1
		INNER JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VV WITH(NOLOCK) ON R.VALUE_ID = VV.ID
		CROSS APPLY
		(
			SELECT TOP(1)
				PERCENT_, SUMMA
			FROM  [BAL_DATA_STD].[dbo].OD_COUPONS AS C WITH(NOLOCK)
			WHERE C.SHARE = S.ID AND C.E_DATE <= dbo.f_Date(T.WIRDATE) order by E_DATE desc
		) CC
		WHERE
			B.ACC_PLAN = 95
			AND B.SYS_NAME = 'ПИФ-ДИВ'
			AND T.IS_PLAN = 'F'
		GROUP BY R.REG_3, S.ISSUER, S.ID, V.ISIN, V.NAME, dbo.f_Date(T.WIRDATE), CC.PERCENT_, VV.SYSNAME, VV.ID, V.ID
	)
	UNION ALL
	--------------------Выплаты дивидендов-----------------
	(
		SELECT
			@InvestorId as Investor,  ---------Добавить
			R.REG_3 as ContractID, --------Добавить
			dbo.f_Date(T.WIRDATE) as W_Date, -- Дата движения ДС (ЦБ)
			1 as Type, --Тип (1 - ввод, -1 - вывод)
			(select 'Выплата дивидендов') as T_Name,-- Наименование операции
			V.ISIN as ISIN, --ISIN ценной бумаги
			V.NAME as Investment, --Название инструмента
			null as Price, --Цена одной бумаги  
			null as Amount, --Количество бумаг
			 SUM( T.VALUE_ ) as Value_Nom, -- Сумма сделки в валюте номинала 
			VV.Id as Currency, --код валюты
			0 as Fee, --Комиссия
			V.ID as PaperId
		FROM [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) ON R.BAL_ACC = B.ID AND R.REG_3 = @ContractId
		INNER JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.ID = R.REG_2 AND S.CLASS in (1,7,10)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = R.REG_2
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE >= @StartDate AND T.WIRDATE < @EndDate AND S.ID IS NOT NULL AND T.TYPE_=-1
		INNER JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VV WITH(NOLOCK) ON VV.id = R.VALUE_ID
		WHERE
			B.ACC_PLAN = 95
			AND B.SYS_NAME = 'ПИФ-ДИВ'
			AND T.IS_PLAN = 'F'
		GROUP BY R.REG_3, S.ISSUER, S.ID, V.ISIN, V.NAME, dbo.f_Date(T.WIRDATE), VV.SYSNAME, VV.ID, V.ID
	)
	UNION ALL
	--------------------Сделки в рамках Договора ДУ-----------------
	(
		SELECT 
			q.INVESTOR as Investor, -- ID Инвестора
			q.PORTFOLIO as ContractID, -- ИД портфеля
			q.F_DATE_P as W_Date, -- Дата оплаты(операции)
			q.OPERATION as Type, --Тип операции 1-покупка, 2-продажа, 3-приход ЦБ, 4-расход ЦБ, 5-приход ДС, 6-расход ДС, 7-перевод ДС, 8-перевод ЦБ, 9-мена (приход), 10-мена (расход)
			(CASE 
				WHEN q.OPERATION = 1 THEN 'Покупка'
				WHEN q.OPERATION = 2 THEN 'Продажа'
				WHEN q.OPERATION = 3 THEN 'Ввод ЦБ'
				WHEN q.OPERATION = 4 THEN 'Вывод ЦБ'
				WHEN q.OPERATION = 5 THEN 'Пополнение счета'
				WHEN q.OPERATION = 6 THEN 'Вывод со счета'
				WHEN q.OPERATION = 7 THEN 'Перевод ДС'
				WHEN q.OPERATION = 8 THEN 'Перевод ЦБ'
				WHEN q.OPERATION = 9 THEN 'Обмен (приход)'
				WHEN q.OPERATION = 10 THEN 'Обмен (расход)'
			END	) as T_Name,-- Наименование операции
			s.ISIN as ISIN, --ISIN ценной бумаги
			s.NAME as Investment, --Название инструмента
			q.PRICE as Price, --Цена одной бумаги  
			q.AMOUNT as Amount, --Количество бумаг
			q.SUMMA as Value_Nom, -- Сумма сделки в валюте номинала (с учетом НКД)
			v.Id as Currency, --код валюты
			q.RUR_TAX as Fee, --Комиссия в валюте эмитента ------------------Делить на курс валюты эмитента(код валюты) на дату операции
			s.ID as PaperId
		FROM [BAL_DATA_STD].[dbo].PR_B_DEALS( @P1, @P2, @P3, @P4, @P5 ) AS q
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS s with(nolock) on s.ID = q.SHARE
		left join [BAL_DATA_STD].[dbo].OD_SHARES AS sh with(nolock) on sh.ID = s.ID
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS v with(nolock) on v.ID = q.VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS p with(nolock) on p.ID = q.D_VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS vt with(nolock) on vt.ID = q.T_VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS vr with(nolock) on vr.ID = q.R_VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS vb with(nolock) on vb.ID = q.B_VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS vm with(nolock) on vm.ID = q.M_VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS vc with(nolock) on vc.ID = q.C_VAL
		left join [BAL_DATA_STD].[dbo].OD_VALUES AS vx with(nolock) on vx.ID = q.X_VAL
		left join [BAL_DATA_STD].[dbo].OD_DOCS AS dd with(nolock) on dd.ID = q.DIR_ID
		left join [BAL_DATA_STD].[dbo].OD_CHAINS AS c with(nolock) on c.ID = q.CHAIN
		left join [BAL_DATA_STD].[dbo].OD_FACES AS cf with(nolock) on cf.SELF_ID=q.CONTRAGENT and ((cf.B_DATE<=q.D_DATE and cf.E_DATE>q.D_DATE) or (cf.B_DATE>q.D_DATE and cf.SELF_ID=cf.ID) or (cf.E_DATE<=q.D_DATE and cf.LAST_FLAG=1))
		left join [BAL_DATA_STD].[dbo].OD_FACES AS mf with(nolock) on mf.SELF_ID=q.MEDIATOR   and ((mf.B_DATE<=q.D_DATE and mf.E_DATE>q.D_DATE) or (mf.B_DATE>q.D_DATE and mf.SELF_ID=mf.ID) or (mf.E_DATE<=q.D_DATE and mf.LAST_FLAG=1))
		left join [BAL_DATA_STD].[dbo].OD_FACES AS nf with(nolock) on nf.SELF_ID=q.MARKET     and ((nf.B_DATE<=q.D_DATE and nf.E_DATE>q.D_DATE) or (nf.B_DATE>q.D_DATE and nf.SELF_ID=nf.ID) or (nf.E_DATE<=q.D_DATE and nf.LAST_FLAG=1))
		left join [BAL_DATA_STD].[dbo].OD_FACES AS i with(nolock) on i.SELF_ID=sh.ISSUER and ((i.B_DATE<=q.D_DATE and i.E_DATE>q.D_DATE) or (i.B_DATE>q.D_DATE and i.SELF_ID=i.ID) or (i.E_DATE<=q.D_DATE and i.LAST_FLAG=1))
		left join [BAL_DATA_STD].[dbo].OD_SYS_TABS AS sc with(nolock) on sc.CODE ='SHARE_CLASS' and sc.NUM = sh.CLASS
		left join [BAL_DATA_STD].[dbo].OD_SYS_TABS AS st with(nolock) on st.CODE ='A_SHARE_TYPE' and st.NUM = sh.TYPE_ and sh.CLASS = 1
		left join [BAL_DATA_STD].[dbo].OD_FACE_ACCS AS ac with(nolock) on ac.ID = q.ACC
		WHERE
			q.IS_REPO <> 1 or q.F_DATE_P is null or q.F_DATE_R is null or q.F_DATE_P >= @p1 or q.F_DATE_R >= @P1
	)
	--ORDER BY W_Date

	
	-- заливаем постоянный кэш по принципу >= @StartDate and < @LastEndDate
	INSERT INTO [dbo].[Operations_History_Contracts]
	(
		[InvestorId], [ContractId], [Date], [Type],
		[T_Name], [ISIN], [Investment], [Price],
		[Amount], [Value_Nom], [Currency], [Fee], [PaperId]
	)
	select
		[InvestorId], [ContractId], [Date], [Type],
		[T_Name], [ISIN], [Investment], [Price],
		[Amount], [Value_Nom], [Currency], [Fee], [PaperId]
	from #FFF
	WHERE [Date] >= @StartDate and [Date] < @LastEndDate;

	-- заливаем временный кэш по принципу >= @LastEndDate
	INSERT INTO [dbo].[Operations_History_Contracts_Last]
	(
		[InvestorId], [ContractId], [Date], [Type],
		[T_Name], [ISIN], [Investment], [Price],
		[Amount], [Value_Nom], [Currency], [Fee], [PaperId]
	)
	select
		[InvestorId], [ContractId], [Date], [Type],
		[T_Name], [ISIN], [Investment], [Price],
		[Amount], [Value_Nom], [Currency], [Fee], [PaperId]
	from #FFF
	WHERE [Date] >= @LastEndDate;


	BEGIN TRY
		DROP TABLE #FFF;
	END TRY
	BEGIN CATCH
	END CATCH

	if @CurrentDateFormat = N'mdy'
	BEGIN
		set dateformat mdy;
	END
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_FillPortFolio_Daily]
(
	@InvestorId INT = 17357,
	@ContractId INT = 2257804,
	@P_DATE DATETIME = NULL
)
AS BEGIN
	IF @P_DATE IS NULL return;
	declare @CurrentDateFormat Nvarchar(50);

	select
		@CurrentDateFormat = date_format
	from sys.dm_exec_sessions
	where session_id = @@spid;

	--select @CurrentDateFormat;

	SET DATEFORMAT DMY;

	DECLARE @CurrentDate Date = getdate()
	DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate)


	-----для проверки, данный блок надо расскоментировать
	--DECLARE @InvestorId INT = 17357			;		-- Инвестор (множество инветоров) (ID субъектов) перечисленных через запятую (может быть пустым);
	--DECLARE @ContractId INT = 2257804			;		-- Множество портфелей (договоров, пулов, множеств) перечисленных через запятую (может быть пустым); если множество портфелей пустое, то выбираются данные всех портфелей указанных в первом параметре инвесторов; не могут быть одновременно пустыми и первый, и второй параметр;
	--DECLARE @P_DATE DATETIME = '30.05.2018';	-- дата со временем, на которую надо получить содержимое портфеля; данные получаются на указанную в этом параметре секунду (т.е. на начало этой секунды); таким образом если время указывается нулевое (параметр содержит только дату), то все котировки, номиналы и другие показатели берутся за предыдущий день; т.е. начало суток есть синоним конца предыдущих суток;


	DECLARE @R_RATER INT = null;				-- Котировщик, используем данные из договора (портфеля);
	DECLARE @R_MODE INT = null;				-- Способ взятия котировки (null - используется способ указанный в договоре (портфеле));
	DECLARE @P_FLAGS INT = (2+8+16+32);


	-- вычищаем постоянный кэш на указанную дату
	DELETE FROM [dbo].[PortFolio_Daily]
	WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId AND [PortfolioDate]  = cast(@P_DATE as Date);

	-- вычищаем временный кэш на указанную дату
	DELETE FROM [dbo].[PortFolio_Daily_Last]
	WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId AND [PortfolioDate]  = cast(@P_DATE as Date);

	-- заполняем временную таблицу
	BEGIN TRY
		DROP TABLE #PortFolio_Daily;
	END TRY
	BEGIN CATCH
	END CATCH

	CREATE TABLE #PortFolio_Daily
	(
		[InvestorId] [int] NOT NULL,
		[ContractId] [int] NOT NULL,
		[PortfolioDate] [date] NOT NULL,
		[INVESTMENT] [Nvarchar](500) Collate DATABASE_DEFAULT NULL,
		[VALUE_ID] [int] NULL,
		[BAL_ACC] [int] NULL,
		[CLASS] [int] NULL,
		[AMOUNT] [numeric](38, 10) NULL,
		[S_BAL_SUMMA_RUR] [numeric](38, 10)NULL,
		[NOMINAL] [numeric](38, 10) NULL,
		[RUR_PRICE] [numeric](38, 10) NULL,
		[Nom_Price] [numeric](38, 10) NULL,
		[VALUE_RUR] [numeric](38, 10) NULL,
		[VALUE_NOM] [numeric](38, 10) NULL,
		[CUR_ID] [int] NULL,
		[CUR_NAME] [Nvarchar](200) Collate DATABASE_DEFAULT NULL,
		[RATE] [numeric](38, 10) NULL,
		[RATE_DATE] [datetime] NULL
	);

	INSERT INTO #PortFolio_Daily
	(
		[InvestorId],
		[ContractId],
		[PortfolioDate],
		[INVESTMENT],
		[VALUE_ID],
		[BAL_ACC],
		[CLASS],
		[AMOUNT],
		[S_BAL_SUMMA_RUR],
		[NOMINAL],
		[RUR_PRICE],
		[Nom_Price],
		[VALUE_RUR],
		[VALUE_NOM],
		[CUR_ID],
		[CUR_NAME],
		[RATE],
		[RATE_DATE]
	)
	SELECT
		C.INVESTOR as InvestorId, -- Идентификатор инвестора
		CONTR as ContractId, -- ИД портфеля (Если 0 - это фонд)
		cast(@P_DATE as Date) as PortfolioDate,
		INVESTMENT, -- краткое описание позиции портфеля;
		VALUE_ID, -- ID  позиции портфеля;
		BAL_ACC,  -- ID балансового счёта;
		case 
			when BAL_ACC=2820 then 100
			when BAL_ACC in (2774, 2925) then 101
			else s.class 
		end as CLASS,  -- Тип позиции (2 - облигация, 1 - акция, 7 - расписка, 3 - вексель,  100 - Денежные средства у брокера, 101 - Прочие вложения)
		AMOUNT, -- количество ценных бумаг, валюты, контрактов или другого имущества;
		S_BAL_SUMMA_RUR = BAL_SUMMA, -- балансовая стоимость по позиции с переоценкой;
		S.NOMINAL, -- Номинал (В валюте номинала)
		RUR_PRICE , --стоимость одной позиции в рублях
		ROUND(RUR_PRICE/Cur.RATE/Cur.CNT,2) as Nom_Price, --стоимость одной позиции в валюте номинвала 
		RUR_RATE as VALUE_RUR, -- оценка имущества в национальной валюте;
		ROUND(RUR_RATE/Cur.RATE/Cur.CNT, 3) as VALUE_NOM, -- оценка имущества в валюте инструмента;
		ISNULL(S.NOM_VAL,P.VALUE_ID) as CUR_ID, -- Валюта номина
		VC.[SYSNAME] as CUR_NAME, -- Код валюты номинала
		Cur.RATE/Cur.CNT as RATE, -- Курс валюты номинала к рублю
		Cur.OFICDATE as RATE_DATE -- Дата котировки курса
	--INTO TTT
	FROM [BAL_DATA_STD].[dbo].PR_B_PORTFOLIO(@InvestorId, @ContractId, @P_DATE, @P_FLAGS, @R_MODE, @R_RATER) P
	LEFT JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON P.CONTR = C.DOC
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = VALUE_ID 
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.SELF_ID = p.VALUE_ID AND S.E_DATE > GetDate()
	CROSS APPLY [BAL_DATA_STD].[dbo].PR_GET_RATE( ISNULL(S.NOM_VAL,P.VALUE_ID),DATEADD(day,-1,@P_DATE),null,null) Cur
	LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VC WITH(NOLOCK) ON VC.ID = ISNULL(S.NOM_VAL,P.VALUE_ID)
	WHERE CONTR > 0 -- Отбросим паевые фонды.
	--and BAL_ACC in (2774,2925,2820)
	--and BAL_ACC not in (2814, 2782); --убираем НДФЛ из списка портфеля


	-- проливаем INVESTMENT
	INSERT INTO [dbo].[InvestmentIds] ([Investment])
	select
		R.[INVESTMENT]
	from
	(
		-- источник содержит уникальные ненуловые значения
		select INVESTMENT
		From #PortFolio_Daily
		WHERE INVESTMENT IS NOT NULL
		GROUP BY INVESTMENT
	) AS R
	LEFT JOIN [dbo].[InvestmentIds] AS T ON R.INVESTMENT = T.[Investment] -- таблица тоже содержит уникальные значения
	WHERE T.[Id] IS NULL;

	-- select * from [dbo].[InvestmentIds]

	-- если дата меньше 180, вставляем в постоянный кэш
	-- иначе во временный кэш

	-- заполняем Value_Nom из истории

	IF @P_DATE < @LastEndDate
	BEGIN
		INSERT INTO [dbo].[PortFolio_Daily]
		(
			[InvestorId],
			[ContractId],
			[PortfolioDate] ,
			[InvestmentId],
			[VALUE_ID],
			[BAL_ACC],
			[CLASS],
			[AMOUNT],
			[S_BAL_SUMMA_RUR],
			[NOMINAL],
			[RUR_PRICE],
			[Nom_Price],
			[VALUE_RUR],
			[VALUE_NOM],
			[CUR_ID],
			[CUR_NAME],
			[RATE],
			[RATE_DATE],
			[BAL_SUMMA]
		)
		select
			a.InvestorId,
			a.ContractId,
			a.PortfolioDate,
			InvestmentId = b.Id,
			a.VALUE_ID,
			a.BAL_ACC,
			a.CLASS,
			a.AMOUNT,
			a.S_BAL_SUMMA_RUR,
			a.NOMINAL,
			a.RUR_PRICE,
			a.Nom_Price,
			a.VALUE_RUR,
			a.VALUE_NOM,
			a.CUR_ID,
			a.CUR_NAME,
			a.RATE,
			a.RATE_DATE,
			s.BAL_SUMMA
		From #PortFolio_Daily as a
		join [dbo].[InvestmentIds] as b on a.INVESTMENT = b.Investment
		outer apply
		(
			select
				BAL_SUMMA = sum(Value_Nom)
			from
			(
				select
					Value_Nom = SUM(case when T_Name = 'Продажа' then -Value_Nom else Value_Nom end)
				from Operations_History_Contracts AS FA
				where
				InvestorId = a.InvestorId and ContractId = a.ContractId and PaperId = a.VALUE_ID
				and (T_Name like 'Ввод ЦБ%' or T_Name in ('Вывод ЦБ','Покупка','Продажа'))
				and [Date] < a.PortfolioDate
				UNION ALL
				select
					Value_Nom = SUM(case when T_Name = 'Продажа' then -Value_Nom else Value_Nom end)
				from Operations_History_Contracts_Last AS FB
				where
				InvestorId = a.InvestorId and ContractId = a.ContractId and PaperId = a.VALUE_ID
				and (T_Name like 'Ввод ЦБ%' or T_Name in ('Вывод ЦБ','Покупка','Продажа'))
				and [Date] < a.PortfolioDate
			) as G
		) as s;
	END
	ELSE
	BEGIN
		INSERT INTO [dbo].[PortFolio_Daily_Last]
		(
			[InvestorId],
			[ContractId],
			[PortfolioDate] ,
			[InvestmentId],
			[VALUE_ID],
			[BAL_ACC],
			[CLASS],
			[AMOUNT],
			[S_BAL_SUMMA_RUR],
			[NOMINAL],
			[RUR_PRICE],
			[Nom_Price],
			[VALUE_RUR],
			[VALUE_NOM],
			[CUR_ID],
			[CUR_NAME],
			[RATE],
			[RATE_DATE],
			[BAL_SUMMA]
		)
		select
			a.InvestorId,
			a.ContractId,
			a.PortfolioDate,
			InvestmentId = b.Id,
			a.VALUE_ID,
			a.BAL_ACC,
			a.CLASS,
			a.AMOUNT,
			a.S_BAL_SUMMA_RUR,
			a.NOMINAL,
			a.RUR_PRICE,
			a.Nom_Price,
			a.VALUE_RUR,
			a.VALUE_NOM,
			a.CUR_ID,
			a.CUR_NAME,
			a.RATE,
			a.RATE_DATE,
			s.BAL_SUMMA
		From #PortFolio_Daily as a
		join [dbo].[InvestmentIds] as b on a.INVESTMENT = b.Investment
		outer apply
		(
			select
				BAL_SUMMA = sum(Value_Nom)
			from
			(
				select
					Value_Nom = SUM(case when T_Name = 'Продажа' then -Value_Nom else Value_Nom end)
				from Operations_History_Contracts AS FA
				where
				InvestorId = a.InvestorId and ContractId = a.ContractId and PaperId = a.VALUE_ID
				and (T_Name like 'Ввод ЦБ%' or T_Name in ('Вывод ЦБ','Покупка','Продажа'))
				and [Date] < a.PortfolioDate
				UNION ALL
				select
					Value_Nom = SUM(case when T_Name = 'Продажа' then -Value_Nom else Value_Nom end)
				from Operations_History_Contracts_Last AS FB
				where
				InvestorId = a.InvestorId and ContractId = a.ContractId and PaperId = a.VALUE_ID
				and (T_Name like 'Ввод ЦБ%' or T_Name in ('Вывод ЦБ','Покупка','Продажа'))
				and [Date] < a.PortfolioDate
			) as G
		) as s;
	END





	-- возвращаем DateFormat
	if @CurrentDateFormat = N'mdy'
	BEGIN
		set dateformat mdy;
	END

	BEGIN TRY
		DROP TABLE #PortFolio_Daily;
	END TRY
	BEGIN CATCH
	END CATCH;


	/*
	d.	
	После загрузки портфелей необходимо рассчитать балансовую стоимость позиции в валюте номинала (поле BAL_SUMMA). 
	Для этого за весь период до PortfolioDate нужно посчитать сумму OPERATIONS_HISTORY_CONTRACTS. 
	Value_Nom по логике (Покупка бумаг + Ввод ЦБ – Вывод ЦБ - Продажа) для каждого PORTFOLIO_DAILY.VALUE_ID= OPERATIONS_HISTORY_CONTRACTS.ID.
	*/
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_FillPortFolio_Daily_Before]
(
	@InvestorId INT,
	@ContractId INT
)
AS BEGIN
	-- Юр лиц не считать
	IF EXISTS
	(
		SELECT 1
		FROM [BAL_DATA_STD].[dbo].OD_FACES AS F WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON C.INVESTOR = F.SELF_ID AND C.E_DATE > GETDATE()
		WHERE
		C.DOC = @ContractId
		AND F.S_TYPE = 1
		AND F.LAST_FLAG = 1
		AND F.E_DATE > GETDATE()
	)
	BEGIN
		-- пифы для юр.лиц. считаем
		if not exists
		(
			select 1
			from [BAL_DATA_STD].[dbo].od_faces F 
			inner join [BAL_DATA_STD].[dbo].D_B_CONTRACTS C ON F.self_ID=C.INVESTOR
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_DOCS D ON C.DOC=D.ID
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES S ON  S.ISSUER = F.SELF_ID
			where F.LAST_FLAG=1 AND C.I_TYPE=5 AND C.E_DATE>GETDATE() AND F.E_DATE>GETDATE() AND S.E_DATE>GetDate() AND D.ID <> 541875
			and D.ID = @ContractId
		)
		BEGIN
			return;
		END
	END
	
	declare @InvestorIdC Int, @ContractIdC Int, @WIRDATEC DateTime,
		@ErrorMessage Nvarchar(max), @ErrorSeverity Int, @ErrorState Int;

	BEGIN TRY
		DROP TABLE #ForUpd;
	END TRY
	BEGIN CATCH
	END CATCH;


	CREATE TABLE #ForUpd
	(
		[InvestorId] [int] NOT NULL,
		[ContractId] [int] NOT NULL,
		[WIRING_ID] [int] NOT NULL,
		[WIRDATE] [date] NOT NULL,
		[S_DATE] [datetime] NOT NULL,
		[NUM] [NVarchar](200) NULL,
		[Value] [numeric](38, 10) NULL
	);


	-- получаем новые или изменённые записи
	INSERT INTO #ForUpd
	(
		[InvestorId],
		[ContractId],
		[WIRING_ID],
		[WIRDATE],
		[S_DATE],
		[NUM],
		[Value]
	)
	select
		A.InvestorId,
		A.ContractId,
		A.WIRING_ID,
		A.WIRDATE,
		A.S_DATE,
		A.NUM,
		A.[Value]
	from
	(
		SELECT
			InvestorId = @InvestorId,
			ContractId = RE.REG_1,
			WIRING_ID = W.ID,
			WIRDATE = cast(W.WIRDATE as Date),
			S_DATE = CAST(FORMAT(S_DATE,'yyyy-MM-dd HH:mm:ss') AS datetime),
			D.NUM,
			TU.VALUE_ * TU.TYPE_ as [Value]
		--INTO GGG
		FROM [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_STEPS AS ST WITH(NOLOCK) ON ST.ID = W.O_STEP 
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS TU WITH(NOLOCK) ON W.ID = TU.WIRING
		INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS RE WITH(NOLOCK) ON TU.REST = RE.ID
		INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES AS BA WITH(NOLOCK) ON RE.BAL_ACC = BA.ID AND BA.SYS_NAME = 'ЧАПИФ'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_ACC_PLANS AS AP WITH(NOLOCK) ON BA.ACC_PLAN = Ap.ID AND AP.SYS_NAME = 'PROFIT'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_DOCS AS D WITH(NOLOCK) ON RE.REG_1 = D.ID
		WHERE RE.REG_1 = @ContractId
	) as A
	LEFT JOIN 
	(
		select
			InvestorId, ContractId, WIRING_ID, WIRDATE, S_DATE, NUM, [Value]
		from [dbo].[PortFolio_Daily_Before] AS WW WITH(NOLOCK)
		where InvestorId = @InvestorId and ContractId = @ContractId
	) as B
	ON A.InvestorId = B.InvestorId
		and A.ContractId = B.ContractId
		and A.WIRING_ID = B.WIRING_ID
		AND A.WIRDATE = B.WIRDATE
	WHERE B.InvestorId IS NULL OR A.S_DATE <> B.S_DATE
	--ORDER BY W.WIRDATE;

	
	-- сдесь перезаполняем портфели, если что-то поменялось

	declare mycur cursor fast_forward for
		select
			InvestorId, ContractId, WIRDATE
		from #ForUpd
		group by
			InvestorId, ContractId, WIRDATE
	open mycur
	fetch next from mycur into @InvestorIdC, @ContractIdC, @WIRDATEC
	while @@FETCH_STATUS = 0
	begin
		BEGIN TRY

			EXEC [dbo].[app_FillPortFolio_Daily]
					@InvestorId = @InvestorIdC,
					@ContractId = @ContractIdC,
					@P_DATE = @WIRDATEC
		END TRY
		BEGIN CATCH
			SELECT
				@ErrorMessage = N'app_FillPortFolio_Daily: ' + ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();

			-- запись в лог
			INSERT INTO [dbo].[ProcessorErrors]
			(Error, ContractId, Investor_id, PDate)
			VALUES (@ErrorMessage, @ContractIdC, @InvestorIdC, @WIRDATEC);

			-- закрытие курсора
			close mycur
			deallocate mycur;

			-- возврат ошибки
			RAISERROR (@ErrorMessage, -- Message text.
					   @ErrorSeverity, -- Severity.
					   @ErrorState -- State.
					   );
			RETURN; -- ВЫХОД
		END CATCH;
		
		  fetch next from mycur into @InvestorIdC, @ContractIdC, @WIRDATEC
	end
	close mycur
	deallocate mycur;

	-- заполняем постоянный кэш - временного нет
	
	WITH CTE
    AS
    (
        SELECT *
        FROM [dbo].[PortFolio_Daily_Before]
        WHERE InvestorId = @InvestorId and ContractId = @ContractId
    ) 
    MERGE
        CTE as t
    USING
    (
        select
			InvestorId,
			ContractId,
			WIRING_ID,
			WIRDATE,
			S_DATE,
			NUM,
			[Value]
		from #ForUpd
    ) AS s
    ON s.InvestorId = t.InvestorId
		and s.ContractId = t.ContractId
		and s.WIRING_ID = t.WIRING_ID
		AND s.WIRDATE = t.WIRDATE
    when not matched
        then insert (
            InvestorId,
			ContractId,
			WIRING_ID,
			WIRDATE,
			S_DATE,
			NUM,
			[Value]
        )
        values (
            s.InvestorId,
			s.ContractId,
			s.WIRING_ID,
			s.WIRDATE,
			s.S_DATE,
			s.NUM,
			s.[Value]
        )
    when matched
    then update set
		[S_DATE] = s.[S_DATE],
        [NUM] = s.[NUM],
		[Value] = s.[Value];

	BEGIN TRY
		DROP TABLE #ForUpd;
	END TRY
	BEGIN CATCH
	END CATCH;
END
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_Assets_Contract_Inner]
(
    @ContractId int = 2257804
)
AS BEGIN
    SET NOCOUNT ON;
	DECLARE @Date Date, @Value decimal(38,10), @IsDateAssets Bit, @USDRATE decimal(38,10), @EURORATE decimal(38,10);
    DECLARE @OldDate Date, @SumValue decimal(38,10), @SumDayValue decimal(38,10);

	DECLARE @CurrentDate Date = getdate();
	DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate);
	DECLARE @LastBeginDate DateTime;

	DECLARE
		@DailyIncrement_USD decimal(38,10),
		@DailyIncrement_EURO decimal(38,10),
		@DailyDecrement_USD decimal(38,10),
		@DailyDecrement_EURO decimal(38,10),
		@INPUT_DIVIDENTS_RUR decimal(38,10),
		@INPUT_DIVIDENTS_USD decimal(38,10),
		@INPUT_DIVIDENTS_EURO decimal(38,10),
		@INPUT_COUPONS_RUR decimal(38,10),
		@INPUT_COUPONS_USD decimal(38,10),
		@INPUT_COUPONS_EURO decimal(38,10);


	DECLARE
		@AmountPayments_RUR decimal(38,10),
		@AmountPayments_USD decimal(38,10),
		@AmountPayments_EURO decimal(38,10),			
		@INPUT_VALUE_RUR decimal(38,10),
		@INPUT_VALUE_USD decimal(38,10),
		@INPUT_VALUE_EURO decimal(38,10),
		@OUTPUT_VALUE_RUR decimal(38,10),
		@OUTPUT_VALUE_USD decimal(38,10),
		@OUTPUT_VALUE_EURO decimal(38,10);


	DECLARE @USDRATE_Last decimal(38,10), @EURORATE_Last decimal(38,10);

    DECLARE @MinDate Date, @MaxDate Date;
    DECLARE @InvestorId Int;

    SELECT
        @InvestorId = C.INVESTOR
    FROM [BAL_DATA_STD].[dbo].[D_B_CONTRACTS] AS C
    WHERE C.DOC = @ContractId;

	-- обновление информации по договору
	EXEC [dbo].[app_Refresh_Assets_Info] @ContractId = @ContractId;

	-- обновление истории операций
	EXEC [dbo].[app_Refresh_Operation_History]
			@InvestorId = @InvestorId,
			@ContractId = @ContractId;
	
	-- перезаливка портфелей, если нужно -- обязательно после истории
	EXEC [dbo].[app_FillPortFolio_Daily_Before]
			@InvestorId = @InvestorId,
			@ContractId = @ContractId;

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
        DROP TABLE #TempContract22;
    END TRY
    BEGIN CATCH
    END CATCH;

	BEGIN TRY
        DROP TABLE #TempContract32;
    END TRY
    BEGIN CATCH
    END CATCH;

	CREATE TABLE #TempContract22
	(
		WIRING int,
		TYPE_ smallint,
		Type int,
		CurrencyId int,
		AmountPayments decimal(38,10),
		ShareName NVarchar(300),
		PaymentDate date,
		PaymentDateTime datetime,
		[USDRATE] decimal(38,10),
		[EURORATE] decimal(38,10),
		[AmountPayments_RUR] decimal(38,10),
		[AmountPayments_USD] decimal(38,10),
		[AmountPayments_EURO] decimal(38,10)
	)

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
        [Date] = CAST(W.WIRDATE as date),
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
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT WITH(NOLOCK)
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
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT WITH(NOLOCK)
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

	insert into #TempContract22
	(
		PaymentDate,
		Type,
		CurrencyId,
		AmountPayments,
		ShareName,
		PaymentDateTime,
		WIRING,
		TYPE_
	)
	SELECT
		PaymentDate,
		Type,
		CurrencyId,
		AmountPayments,
		[ShareName],
		[PaymentDateTime],
		[WIRING],
		[TYPE_]
	FROM
	(
		SELECT
			PaymentDate = cast(PaymentDate as Date), Type, CurrencyId, AmountPayments,
			[ShareName],
			[PaymentDateTime] = PaymentDate,
			[WIRING], [TYPE_]
		FROM
		(
			SELECT
				[PaymentDate] = T.WIRDATE,
				[Type] = 1, -- Купоны
				[CurrencyId] = VV.Id,
				[AmountPayments] = T.VALUE_,
				[ShareName] = V.[NAME],
				[WIRING] = T.[WIRING],
				[TYPE_] = T.[TYPE_]
			FROM [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK)
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) ON R.BAL_ACC = B.ID and R.REG_3 = @ContractId
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.ID = R.REG_2 and S.CLASS = 2
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = R.REG_2
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE >= @StartDate AND T.WIRDATE < @EndDate AND S.ID IS NOT NULL AND T.TYPE_ = -1
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VV on R.VALUE_ID = VV.ID
			CROSS APPLY (SELECT TOP(1) PERCENT_, SUMMA FROM [BAL_DATA_STD].[dbo].OD_COUPONS AS C WHERE C.SHARE = S.ID AND C.E_DATE <= T.WIRDATE order by E_DATE desc ) CC
			WHERE B.ACC_PLAN = 95 AND B.SYS_NAME = 'ПИФ-ДИВ' AND T.IS_PLAN = 'F'
			GROUP BY
				T.[WIRDATE], VV.[Id], T.[VALUE_], V.[NAME], T.[WIRING], T.[TYPE_]
		) AS D
		UNION ALL
		select
			PaymentDate = cast(PaymentDate as Date), Type, CurrencyId, AmountPayments,
			[ShareName],
			[PaymentDateTime] = PaymentDate,
			[WIRING], [TYPE_]
		FROM
		(
			SELECT 
				[PaymentDate] = T.[WIRDATE],
				[Type] = 2,  -- Дивиденды
				[CurrencyId] = VV.[ID],
				[AmountPayments] = T.VALUE_,
				[ShareName] = V.[NAME],
				[WIRING] = T.[WIRING],
				[TYPE_] = T.[TYPE_]
			FROM [BAL_DATA_STD].[dbo].OD_BALANCES AS B WITH(NOLOCK)
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK) ON R.BAL_ACC = B.ID AND R.REG_3 = @ContractId
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.ID = R.REG_2 AND S.CLASS in (1,7,10)
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = R.REG_2
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE >= @StartDate AND T.WIRDATE < @EndDate AND S.ID IS NOT NULL AND T.TYPE_=-1
			LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VV WITH(NOLOCK) ON VV.id = R.VALUE_ID
			WHERE B.ACC_PLAN = 95 AND B.SYS_NAME = 'ПИФ-ДИВ' AND T.IS_PLAN = 'F' 
			GROUP BY T.[WIRDATE], VV.[ID], T.[VALUE_], V.[NAME], T.[WIRING], T.[TYPE_]
		) AS F
	) AS GG;
	--GROUP BY PaymentDate, Type, CurrencyId;


	-- вытягиваем курсы валют
	UPDATE B SET
		[USDRATE]  = VB.RATE,
		[EURORATE] = VE.RATE
	FROM #TempContract22 AS B
	--  в долларах
	OUTER APPLY
	(
		SELECT TOP 1
			RT.[RATE]
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
		WHERE RT.[VALUE_ID] = 2 -- доллары
		AND RT.[E_DATE] >= B.[PaymentDateTime] and RT.[OFICDATE] < B.[PaymentDateTime]
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
		AND RT.[E_DATE] >= B.[PaymentDateTime] and RT.[OFICDATE] < B.[PaymentDateTime]
		ORDER BY
			case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
			RT.[E_DATE] DESC,
			RT.[OFICDATE] DESC
	) AS VE;

	UPDATE A Set
		AmountPayments_RUR = case
				when CurrencyId = 1 then AmountPayments
				when CurrencyId = 2 then AmountPayments * USDRATE
				when CurrencyId = 5 then AmountPayments * EURORATE
				else 0
			end,
		AmountPayments_USD = case
				when CurrencyId = 1 and USDRATE <> 0 then AmountPayments * (1/USDRATE)
				when CurrencyId = 2 then AmountPayments
				when CurrencyId = 5 and USDRATE <> 0 then AmountPayments * (1/USDRATE) * EURORATE
				else 0
			end,
		AmountPayments_EURO = case
				when CurrencyId = 1 and EURORATE <> 0 then AmountPayments * (1/EURORATE)
				when CurrencyId = 2 and EURORATE <> 0 then AmountPayments * (1/EURORATE) * USDRATE
				when CurrencyId = 5 then AmountPayments
				else 0
			end
	FROM #TempContract22 AS A;
	
	update a set
		AmountPayments_RUR = [dbo].f_Round(AmountPayments_RUR, 2),
		AmountPayments_USD = [dbo].f_Round(AmountPayments_USD, 2),
		AmountPayments_EURO = [dbo].f_Round(AmountPayments_EURO, 2)
	from #TempContract22 as a;

	SET @LastBeginDate = NULL-- взять максимальную дату из постоянного кэша и вычесть ещё пару дней на всякий случай (merge простит)

	SELECT
		@LastBeginDate = max([PaymentDateTime])
	FROM [dbo].[DIVIDENDS_AND_COUPONS_History] nolock
	WHERE InvestorId = @InvestorId and ContractId = @ContractId

	IF @LastBeginDate is null
	BEGIN
		set @LastBeginDate = '1901-01-03'
	END
	
	SET @LastBeginDate = DATEADD(DAY, -10, @LastBeginDate);

	-- чистка за полгода
	DELETE
    FROM [dbo].[DIVIDENDS_AND_COUPONS_History_Last]
    WHERE InvestorId = @InvestorId and ContractId = @ContractId;


	WITH CTE
    AS
    (
        SELECT *
        FROM [dbo].[DIVIDENDS_AND_COUPONS_History]
        WHERE InvestorId = @InvestorId and ContractId = @ContractId
    ) 
    MERGE
        CTE as t
    USING
    (
        select
			InvestorId = @InvestorId,
			ContractId = @ContractId,
			[WIRING],
			[TYPE_],
			PaymentDateTime,
			Type,
			CurrencyId,
			AmountPayments,
			ShareName,
			[USDRATE],
			[EURORATE],
			[AmountPayments_RUR],
			[AmountPayments_USD],
			[AmountPayments_EURO]
		from #TempContract22
		WHERE [PaymentDateTime] >= @LastBeginDate and [PaymentDateTime] <= @LastEndDate -- заливка постоянного кэша в диапазоне дат
    ) AS s
    on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId
	AND t.[WIRING] = s.[WIRING] and t.[TYPE_] = s.[TYPE_]
    when not matched
        then insert (
            [InvestorId],
			[ContractId],
			[WIRING],
			[TYPE_],
			[PaymentDateTime],
			[Type],
			[CurrencyId],
			[AmountPayments],
			[ShareName],
			[USDRATE],
			[EURORATE],
			[AmountPayments_RUR],
			[AmountPayments_USD],
			[AmountPayments_EURO]
        )
        values (
            s.[InvestorId],
			s.[ContractId],
			s.[WIRING],
			s.[TYPE_],
			s.[PaymentDateTime],
			s.[Type],
			s.[CurrencyId],
			s.[AmountPayments],
			s.[ShareName],
			s.[USDRATE],
			s.[EURORATE],
			s.[AmountPayments_RUR],
			s.[AmountPayments_USD],
			s.[AmountPayments_EURO]
        )
    when matched
    then update set
		[PaymentDateTime] = s.[PaymentDateTime],
        [Type] = s.[Type],
		[CurrencyId] = s.[CurrencyId],
		[AmountPayments] = s.[AmountPayments],
		[ShareName] = s.[ShareName],
		[USDRATE] = s.[USDRATE],
		[EURORATE] = s.[EURORATE],
		[AmountPayments_RUR] = s.[AmountPayments_RUR],
		[AmountPayments_USD] = s.[AmountPayments_USD],
		[AmountPayments_EURO] = s.[AmountPayments_EURO];

	
	CREATE TABLE #TempContract32
	(
		InvestorId Int,
		ContractId Int,
		WIRING Int,
		TYPE_ Int,
		PaymentDateTime Datetime,
		Amount_RUR decimal (38,10),

		PaymentDate date,
		[USDRATE] decimal(38,10),
		[EURORATE] decimal(38,10),
		[AmountPayments_RUR] decimal(38,10),
		[AmountPayments_USD] decimal(38,10),
		[AmountPayments_EURO] decimal(38,10)
	);

	INSERT INTO #TempContract32
	(
		InvestorId, ContractId, WIRING, TYPE_, PaymentDateTime, Amount_RUR
	)
	EXEC [dbo].[app_SelectPayments]
		@ContractId = @ContractId;
	
	-- вытягиваем курсы валют
	UPDATE B SET
		[USDRATE]  = VB.RATE,
		[EURORATE] = VE.RATE,
		[PaymentDate] = [PaymentDateTime],
		[AmountPayments_RUR] = [Amount_RUR]
	FROM #TempContract32 AS B
	--  в долларах
	OUTER APPLY
	(
		SELECT TOP 1
			RT.[RATE]
		FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
		WHERE RT.[VALUE_ID] = 2 -- доллары
		AND RT.[E_DATE] >= B.[PaymentDateTime] and RT.[OFICDATE] < B.[PaymentDateTime]
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
		AND RT.[E_DATE] >= B.[PaymentDateTime] and RT.[OFICDATE] < B.[PaymentDateTime]
		ORDER BY
			case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
			RT.[E_DATE] DESC,
			RT.[OFICDATE] DESC
	) AS VE;


	UPDATE B SET
		AmountPayments_USD = AmountPayments_RUR * (1.00/nullif(USDRATE,0)),
		AmountPayments_EURO = AmountPayments_RUR * (1.00/nullif(EURORATE,0))
	FROM #TempContract32 AS B;

	update a set
		AmountPayments_USD = [dbo].f_Round(AmountPayments_USD, 2),
		AmountPayments_EURO = [dbo].f_Round(AmountPayments_EURO, 2)
	from #TempContract32 as a;


	WITH CTE
    AS
    (
        SELECT *
        FROM [dbo].[DIVIDENDS_AND_COUPONS_History_Last]
        WHERE InvestorId = @InvestorId and ContractId = @ContractId
    ) 
    MERGE
        CTE as t
    USING
    (
        select
			InvestorId = @InvestorId,
			ContractId = @ContractId,
			[WIRING],
			[TYPE_],
			PaymentDateTime,
			Type,
			CurrencyId,
			AmountPayments,
			ShareName,
			[USDRATE],
			[EURORATE],
			[AmountPayments_RUR],
			[AmountPayments_USD],
			[AmountPayments_EURO]
		from #TempContract22
		WHERE [PaymentDateTime] > @LastEndDate -- заливка временного кеша за последние полгода
    ) AS s
    on t.InvestorId = s.InvestorId and t.ContractId = s.ContractId
	AND t.[WIRING] = s.[WIRING] and t.[TYPE_] = s.[TYPE_]
    when not matched
        then insert (
            [InvestorId],
			[ContractId],
			[WIRING],
			[TYPE_],
			[PaymentDateTime],
			[Type],
			[CurrencyId],
			[AmountPayments],
			[ShareName],
			[USDRATE],
			[EURORATE],
			[AmountPayments_RUR],
			[AmountPayments_USD],
			[AmountPayments_EURO]
        )
        values (
            s.[InvestorId],
			s.[ContractId],
			s.[WIRING],
			s.[TYPE_],
			s.[PaymentDateTime],
			s.[Type],
			s.[CurrencyId],
			s.[AmountPayments],
			s.[ShareName],
			s.[USDRATE],
			s.[EURORATE],
			s.[AmountPayments_RUR],
			s.[AmountPayments_USD],
			s.[AmountPayments_EURO]
        )
    when matched
    then update set
        [PaymentDateTime] = s.[PaymentDateTime],
        [Type] = s.[Type],
		[CurrencyId] = s.[CurrencyId],
		[AmountPayments] = s.[AmountPayments],
		[ShareName] = s.[ShareName],
		[USDRATE] = s.[USDRATE],
		[EURORATE] = s.[EURORATE],
		[AmountPayments_RUR] = s.[AmountPayments_RUR],
		[AmountPayments_USD] = s.[AmountPayments_USD],
		[AmountPayments_EURO] = s.[AmountPayments_EURO];

	




	SELECT
		PaymentDate, Type, CurrencyId, AmountPayments = sum(AmountPayments)
	INTO #TempContract2
	FROM #TempContract22
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

						SET @DailyIncrement_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
						SET @DailyIncrement_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;
						SET @DailyDecrement_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
						SET @DailyDecrement_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;

						



						set @AmountPayments_RUR = NULL
						set @AmountPayments_USD = NULL 
						set @AmountPayments_EURO = NULL 
						
						select
							@AmountPayments_RUR = sum(AmountPayments_RUR),
							@AmountPayments_USD = sum(AmountPayments_USD),
							@AmountPayments_EURO = sum(AmountPayments_EURO)
						from #TempContract32
						where PaymentDate = @OldDate
						group by PaymentDate;

						set @AmountPayments_RUR  = isnull(@AmountPayments_RUR, 0)
						set @AmountPayments_USD  = isnull(@AmountPayments_USD, 0) 
						set @AmountPayments_EURO = isnull(@AmountPayments_EURO, 0)

						SET @INPUT_VALUE_RUR  = CASE WHEN @AmountPayments_RUR > 0 THEN @AmountPayments_RUR ELSE 0 END;
						SET @INPUT_VALUE_USD  = CASE WHEN @AmountPayments_USD > 0 THEN @AmountPayments_USD ELSE 0 END;
						SET @INPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO > 0 THEN @AmountPayments_EURO ELSE 0 END;
						SET @OUTPUT_VALUE_RUR = CASE WHEN @AmountPayments_RUR < 0 THEN @AmountPayments_RUR ELSE 0 END;
						SET @OUTPUT_VALUE_USD = CASE WHEN @AmountPayments_USD < 0 THEN @AmountPayments_USD ELSE 0 END;
						SET @OUTPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO < 0 THEN @AmountPayments_EURO ELSE 0 END;


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
								[VALUE_USD] = [dbo].f_Round(@SumValue * (1/NULLIF(@USDRATE,0)), 2),
								[VALUE_EURO] = [dbo].f_Round(@SumValue * (1/NULLIF(@EURORATE,0)), 2),
								[DailyIncrement_RUR] = CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
								[DailyDecrement_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
								[DailyIncrement_USD]  = @DailyIncrement_USD,
								[DailyIncrement_EURO] = @DailyIncrement_EURO,
								[DailyDecrement_USD] = @DailyDecrement_USD,
								[DailyDecrement_EURO]= @DailyDecrement_EURO,
								[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
								[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
								[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
								[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
								[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
								[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO,

								[INPUT_VALUE_RUR] = @INPUT_VALUE_RUR,
								[INPUT_VALUE_USD] = @INPUT_VALUE_USD,
								[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
								[OUTPUT_VALUE_RUR] = @OUTPUT_VALUE_RUR,
								[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
								[OUTPUT_VALUE_EURO] = @OUTPUT_VALUE_EURO

								
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
								[DailyIncrement_RUR],
								[DailyDecrement_RUR],
								[DailyIncrement_USD],
								[DailyIncrement_EURO],
								[DailyDecrement_USD],
								[DailyDecrement_EURO],
								[INPUT_DIVIDENTS_RUR],
								[INPUT_DIVIDENTS_USD],
								[INPUT_DIVIDENTS_EURO],
								[INPUT_COUPONS_RUR],
								[INPUT_COUPONS_USD],
								[INPUT_COUPONS_EURO],

								[INPUT_VALUE_RUR],
								[INPUT_VALUE_USD],
								[INPUT_VALUE_EURO],
								[OUTPUT_VALUE_RUR],
								[OUTPUT_VALUE_USD],
								[OUTPUT_VALUE_EURO]
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
								s.[DailyIncrement_RUR],
								s.[DailyDecrement_RUR],
								s.[DailyIncrement_USD],
								s.[DailyIncrement_EURO],
								s.[DailyDecrement_USD],
								s.[DailyDecrement_EURO],
								s.[INPUT_DIVIDENTS_RUR],
								s.[INPUT_DIVIDENTS_USD],
								s.[INPUT_DIVIDENTS_EURO],
								s.[INPUT_COUPONS_RUR],
								s.[INPUT_COUPONS_USD],
								s.[INPUT_COUPONS_EURO],
								
								s.[INPUT_VALUE_RUR],
								s.[INPUT_VALUE_USD],
								s.[INPUT_VALUE_EURO],
								s.[OUTPUT_VALUE_RUR],
								s.[OUTPUT_VALUE_USD],
								s.[OUTPUT_VALUE_EURO]
                            )
                        when matched
                        then update set
                            [VALUE_RUR] = s.[VALUE_RUR],
							[USDRATE] = s.[USDRATE],
							[EURORATE] = s.[EURORATE],
							[VALUE_USD] = s.[VALUE_USD],
							[VALUE_EURO] = s.[VALUE_EURO],
							[DailyIncrement_RUR] = s.[DailyIncrement_RUR],
							[DailyDecrement_RUR] = s.[DailyDecrement_RUR],
							[DailyIncrement_USD] = s.[DailyIncrement_USD],
							[DailyIncrement_EURO] = s.[DailyIncrement_EURO],
							[DailyDecrement_USD] = s.[DailyDecrement_USD],
							[DailyDecrement_EURO] = s.[DailyDecrement_EURO],					
							[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
							[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
							[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
							[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
							[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
							[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO],

							[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
							[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
							[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
							[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
							[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
							[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO];
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

					SET @DailyIncrement_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
					SET @DailyIncrement_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;
					SET @DailyDecrement_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
					SET @DailyDecrement_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;



					set @AmountPayments_RUR = NULL
					set @AmountPayments_USD = NULL 
					set @AmountPayments_EURO = NULL 
					
					select
						@AmountPayments_RUR = sum(AmountPayments_RUR),
						@AmountPayments_USD = sum(AmountPayments_USD),
						@AmountPayments_EURO = sum(AmountPayments_EURO)
					from #TempContract32
					where PaymentDate = @OldDate
					group by PaymentDate;

					set @AmountPayments_RUR  = isnull(@AmountPayments_RUR, 0)
					set @AmountPayments_USD  = isnull(@AmountPayments_USD, 0) 
					set @AmountPayments_EURO = isnull(@AmountPayments_EURO, 0)

					SET @INPUT_VALUE_RUR  = CASE WHEN @AmountPayments_RUR > 0 THEN @AmountPayments_RUR ELSE 0 END;
					SET @INPUT_VALUE_USD  = CASE WHEN @AmountPayments_USD > 0 THEN @AmountPayments_USD ELSE 0 END;
					SET @INPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO > 0 THEN @AmountPayments_EURO ELSE 0 END;
					SET @OUTPUT_VALUE_RUR = CASE WHEN @AmountPayments_RUR < 0 THEN @AmountPayments_RUR ELSE 0 END;
					SET @OUTPUT_VALUE_USD = CASE WHEN @AmountPayments_USD < 0 THEN @AmountPayments_USD ELSE 0 END;
					SET @OUTPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO < 0 THEN @AmountPayments_EURO ELSE 0 END;




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
							[VALUE_USD] = [dbo].f_Round(@SumValue * (1/NULLIF(@USDRATE,0)), 2),
							[VALUE_EURO] = [dbo].f_Round(@SumValue * (1/NULLIF(@EURORATE,0)), 2),
							[DailyIncrement_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
							[DailyDecrement_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
							[DailyIncrement_USD]  = @DailyIncrement_USD,
							[DailyIncrement_EURO] = @DailyIncrement_EURO,
							[DailyDecrement_USD] = @DailyDecrement_USD,
							[DailyDecrement_EURO]= @DailyDecrement_EURO,
							[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
							[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
							[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
							[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
							[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
							[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO,

							[INPUT_VALUE_RUR] = @INPUT_VALUE_RUR,
							[INPUT_VALUE_USD] = @INPUT_VALUE_USD,
							[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
							[OUTPUT_VALUE_RUR] = @OUTPUT_VALUE_RUR,
							[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
							[OUTPUT_VALUE_EURO] = @OUTPUT_VALUE_EURO
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
							[DailyIncrement_RUR],
							[DailyDecrement_RUR],
							[DailyIncrement_USD],
							[DailyIncrement_EURO],
							[DailyDecrement_USD],
							[DailyDecrement_EURO],
							[INPUT_DIVIDENTS_RUR],
							[INPUT_DIVIDENTS_USD],
							[INPUT_DIVIDENTS_EURO],
							[INPUT_COUPONS_RUR],
							[INPUT_COUPONS_USD],
							[INPUT_COUPONS_EURO],

							[INPUT_VALUE_RUR],
							[INPUT_VALUE_USD],
							[INPUT_VALUE_EURO],
							[OUTPUT_VALUE_RUR],
							[OUTPUT_VALUE_USD],
							[OUTPUT_VALUE_EURO]
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
							s.[DailyIncrement_RUR],
							s.[DailyDecrement_RUR],
							s.[DailyIncrement_USD],
							s.[DailyIncrement_EURO],
							s.[DailyDecrement_USD],
							s.[DailyDecrement_EURO],
							s.[INPUT_DIVIDENTS_RUR],
							s.[INPUT_DIVIDENTS_USD],
							s.[INPUT_DIVIDENTS_EURO],
							s.[INPUT_COUPONS_RUR],
							s.[INPUT_COUPONS_USD],
							s.[INPUT_COUPONS_EURO],

							s.[INPUT_VALUE_RUR],
							s.[INPUT_VALUE_USD],
							s.[INPUT_VALUE_EURO],
							s.[OUTPUT_VALUE_RUR],
							s.[OUTPUT_VALUE_USD],
							s.[OUTPUT_VALUE_EURO]
                        )
                    when matched
                    then update set
                        [VALUE_RUR] = s.[VALUE_RUR],
						[USDRATE] = s.[USDRATE],
						[EURORATE] = s.[EURORATE],
						[VALUE_USD] = s.[VALUE_USD],
						[VALUE_EURO] = s.[VALUE_EURO],
						[DailyIncrement_RUR] = s.[DailyIncrement_RUR],
						[DailyDecrement_RUR] = s.[DailyDecrement_RUR],
						[DailyIncrement_USD] = s.[DailyIncrement_USD],
						[DailyIncrement_EURO] = s.[DailyIncrement_EURO],
						[DailyDecrement_USD] = s.[DailyDecrement_USD],
						[DailyDecrement_EURO] = s.[DailyDecrement_EURO],
						[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
						[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
						[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
						[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
						[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
						[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO],

						[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
						[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
						[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
						[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
						[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
						[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO];
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

				SET @DailyIncrement_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
				SET @DailyIncrement_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;
				SET @DailyDecrement_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
				SET @DailyDecrement_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;




				set @AmountPayments_RUR = NULL
				set @AmountPayments_USD = NULL 
				set @AmountPayments_EURO = NULL 
				
				select
					@AmountPayments_RUR = sum(AmountPayments_RUR),
					@AmountPayments_USD = sum(AmountPayments_USD),
					@AmountPayments_EURO = sum(AmountPayments_EURO)
				from #TempContract32
				where PaymentDate = @OldDate
				group by PaymentDate;

				set @AmountPayments_RUR  = isnull(@AmountPayments_RUR, 0)
				set @AmountPayments_USD  = isnull(@AmountPayments_USD, 0) 
				set @AmountPayments_EURO = isnull(@AmountPayments_EURO, 0)

				SET @INPUT_VALUE_RUR  = CASE WHEN @AmountPayments_RUR > 0 THEN @AmountPayments_RUR ELSE 0 END;
				SET @INPUT_VALUE_USD  = CASE WHEN @AmountPayments_USD > 0 THEN @AmountPayments_USD ELSE 0 END;
				SET @INPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO > 0 THEN @AmountPayments_EURO ELSE 0 END;
				SET @OUTPUT_VALUE_RUR  = CASE WHEN @AmountPayments_RUR < 0 THEN @AmountPayments_RUR ELSE 0 END;
				SET @OUTPUT_VALUE_USD  = CASE WHEN @AmountPayments_USD < 0 THEN @AmountPayments_USD ELSE 0 END;
				SET @OUTPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO < 0 THEN @AmountPayments_EURO ELSE 0 END;



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
						[VALUE_USD] = [dbo].f_Round(@SumValue * (1/NULLIF(@USDRATE,0)), 2),
						[VALUE_EURO] = [dbo].f_Round(@SumValue * (1/NULLIF(@EURORATE,0)), 2),
						[DailyIncrement_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
						[DailyDecrement_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
						[DailyIncrement_USD]  = @DailyIncrement_USD,
						[DailyIncrement_EURO] = @DailyIncrement_EURO,
						[DailyDecrement_USD] = @DailyDecrement_USD,
						[DailyDecrement_EURO]= @DailyDecrement_EURO,
						[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
						[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
						[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
						[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
						[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
						[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO,

						[INPUT_VALUE_RUR] = @INPUT_VALUE_RUR,
						[INPUT_VALUE_USD] = @INPUT_VALUE_USD,
						[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
						[OUTPUT_VALUE_RUR] = @OUTPUT_VALUE_RUR,
						[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
						[OUTPUT_VALUE_EURO] = @OUTPUT_VALUE_EURO
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
						[DailyIncrement_RUR],
						[DailyDecrement_RUR],
						[DailyIncrement_USD],
						[DailyIncrement_EURO],
						[DailyDecrement_USD],
						[DailyDecrement_EURO],
						[INPUT_DIVIDENTS_RUR],
						[INPUT_DIVIDENTS_USD],
						[INPUT_DIVIDENTS_EURO],
						[INPUT_COUPONS_RUR],
						[INPUT_COUPONS_USD],
						[INPUT_COUPONS_EURO],

						[INPUT_VALUE_RUR],
						[INPUT_VALUE_USD],
						[INPUT_VALUE_EURO],
						[OUTPUT_VALUE_RUR],
						[OUTPUT_VALUE_USD],
						[OUTPUT_VALUE_EURO]
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
						s.[DailyIncrement_RUR],
						s.[DailyDecrement_RUR],
						s.[DailyIncrement_USD],
						s.[DailyIncrement_EURO],
						s.[DailyDecrement_USD],
						s.[DailyDecrement_EURO],
						s.[INPUT_DIVIDENTS_RUR],
						s.[INPUT_DIVIDENTS_USD],
						s.[INPUT_DIVIDENTS_EURO],
						s.[INPUT_COUPONS_RUR],
						s.[INPUT_COUPONS_USD],
						s.[INPUT_COUPONS_EURO],
						s.[INPUT_VALUE_RUR],
						s.[INPUT_VALUE_USD],
						s.[INPUT_VALUE_EURO],
						s.[OUTPUT_VALUE_RUR],
						s.[OUTPUT_VALUE_USD],
						s.[OUTPUT_VALUE_EURO]
                    )
                when matched
                then update set
                    [VALUE_RUR] = s.[VALUE_RUR],
					[USDRATE] = s.[USDRATE],
					[EURORATE] = s.[EURORATE],
					[VALUE_USD] = s.[VALUE_USD],
					[VALUE_EURO] = s.[VALUE_EURO],
					[DailyIncrement_RUR] = s.[DailyIncrement_RUR],
					[DailyDecrement_RUR] = s.[DailyDecrement_RUR],
					[DailyIncrement_USD] = s.[DailyIncrement_USD],
					[DailyIncrement_EURO] = s.[DailyIncrement_EURO],
					[DailyDecrement_USD] = s.[DailyDecrement_USD],
					[DailyDecrement_EURO] = s.[DailyDecrement_EURO],
					[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
					[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
					[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
					[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
					[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
					[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO],

					[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
					[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
					[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
					[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
					[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
					[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO];
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

			SET @DailyIncrement_USD = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
			SET @DailyIncrement_EURO = CASE WHEN @SumDayValue > 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;
			SET @DailyDecrement_USD = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@USDRATE,0)), 2) ELSE 0 END;
			SET @DailyDecrement_EURO = CASE WHEN @SumDayValue < 0 THEN [dbo].f_Round(@SumDayValue * (1/NULLIF(@EURORATE,0)), 2) ELSE 0 END;

			
			set @AmountPayments_RUR = NULL
			set @AmountPayments_USD = NULL 
			set @AmountPayments_EURO = NULL 
			
			select
				@AmountPayments_RUR = sum(AmountPayments_RUR),
				@AmountPayments_USD = sum(AmountPayments_USD),
				@AmountPayments_EURO = sum(AmountPayments_EURO)
			from #TempContract32
			where PaymentDate = @OldDate
			group by PaymentDate;

			set @AmountPayments_RUR  = isnull(@AmountPayments_RUR, 0)
			set @AmountPayments_USD  = isnull(@AmountPayments_USD, 0) 
			set @AmountPayments_EURO = isnull(@AmountPayments_EURO, 0)

			SET @INPUT_VALUE_RUR  = CASE WHEN @AmountPayments_RUR > 0 THEN @AmountPayments_RUR ELSE 0 END;
			SET @INPUT_VALUE_USD  = CASE WHEN @AmountPayments_USD > 0 THEN @AmountPayments_USD ELSE 0 END;
			SET @INPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO > 0 THEN @AmountPayments_EURO ELSE 0 END;
			SET @OUTPUT_VALUE_RUR = CASE WHEN @AmountPayments_RUR < 0 THEN @AmountPayments_RUR ELSE 0 END;
			SET @OUTPUT_VALUE_USD = CASE WHEN @AmountPayments_USD < 0 THEN @AmountPayments_USD ELSE 0 END;
			SET @OUTPUT_VALUE_EURO = CASE WHEN @AmountPayments_EURO < 0 THEN @AmountPayments_EURO ELSE 0 END;


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
					[VALUE_USD] = [dbo].f_Round(@SumValue * (1/NULLIF(@USDRATE,0)), 2),
					[VALUE_EURO] = [dbo].f_Round(@SumValue * (1/NULLIF(@EURORATE,0)), 2),
					[DailyIncrement_RUR] =  CASE WHEN @SumDayValue > 0 THEN @SumDayValue ELSE 0 END,
					[DailyDecrement_RUR] = CASE WHEN @SumDayValue < 0 THEN @SumDayValue ELSE 0 END,
					[DailyIncrement_USD]  = @DailyIncrement_USD,
					[DailyIncrement_EURO] = @DailyIncrement_EURO,
					[DailyDecrement_USD] = @DailyDecrement_USD,
					[DailyDecrement_EURO]= @DailyDecrement_EURO,
					[INPUT_DIVIDENTS_RUR] = @INPUT_DIVIDENTS_RUR,
					[INPUT_DIVIDENTS_USD] = @INPUT_DIVIDENTS_USD,
					[INPUT_DIVIDENTS_EURO] = @INPUT_DIVIDENTS_EURO,
					[INPUT_COUPONS_RUR] = @INPUT_COUPONS_RUR,
					[INPUT_COUPONS_USD] = @INPUT_COUPONS_USD,
					[INPUT_COUPONS_EURO] = @INPUT_COUPONS_EURO,

					[INPUT_VALUE_RUR] = @INPUT_VALUE_RUR,
					[INPUT_VALUE_USD] = @INPUT_VALUE_USD,
					[INPUT_VALUE_EURO] = @INPUT_VALUE_EURO,
					[OUTPUT_VALUE_RUR] = @OUTPUT_VALUE_RUR,
					[OUTPUT_VALUE_USD] = @OUTPUT_VALUE_USD,
					[OUTPUT_VALUE_EURO] = @OUTPUT_VALUE_EURO
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
					[DailyIncrement_RUR],
					[DailyDecrement_RUR],
					[DailyIncrement_USD],
					[DailyIncrement_EURO],
					[DailyDecrement_USD],
					[DailyDecrement_EURO],
					[INPUT_DIVIDENTS_RUR],
					[INPUT_DIVIDENTS_USD],
					[INPUT_DIVIDENTS_EURO],
					[INPUT_COUPONS_RUR],
					[INPUT_COUPONS_USD],
					[INPUT_COUPONS_EURO],

					[INPUT_VALUE_RUR],
					[INPUT_VALUE_USD],
					[INPUT_VALUE_EURO],
					[OUTPUT_VALUE_RUR],
					[OUTPUT_VALUE_USD],
					[OUTPUT_VALUE_EURO]
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
					s.[DailyIncrement_RUR],
					s.[DailyDecrement_RUR],
					s.[DailyIncrement_USD],
					s.[DailyIncrement_EURO],
					s.[DailyDecrement_USD],
					s.[DailyDecrement_EURO],
					s.[INPUT_DIVIDENTS_RUR],
					s.[INPUT_DIVIDENTS_USD],
					s.[INPUT_DIVIDENTS_EURO],
					s.[INPUT_COUPONS_RUR],
					s.[INPUT_COUPONS_USD],
					s.[INPUT_COUPONS_EURO],

					s.[INPUT_VALUE_RUR],
					s.[INPUT_VALUE_USD],
					s.[INPUT_VALUE_EURO],
					s.[OUTPUT_VALUE_RUR],
					s.[OUTPUT_VALUE_USD],
					s.[OUTPUT_VALUE_EURO]
                )
            when matched
            then update set
                [VALUE_RUR] = s.[VALUE_RUR],
				[USDRATE] = s.[USDRATE],
				[EURORATE] = s.[EURORATE],
				[VALUE_USD] = s.[VALUE_USD],
				[VALUE_EURO] = s.[VALUE_EURO],
				[DailyIncrement_RUR] = s.[DailyIncrement_RUR],
				[DailyDecrement_RUR] = s.[DailyDecrement_RUR],
				[DailyIncrement_USD] = s.[DailyIncrement_USD],
				[DailyIncrement_EURO] = s.[DailyIncrement_EURO],
				[DailyDecrement_USD] = s.[DailyDecrement_USD],
				[DailyDecrement_EURO] = s.[DailyDecrement_EURO],
				[INPUT_DIVIDENTS_RUR] = s.[INPUT_DIVIDENTS_RUR],
				[INPUT_DIVIDENTS_USD] = s.[INPUT_DIVIDENTS_USD],
				[INPUT_DIVIDENTS_EURO] = s.[INPUT_DIVIDENTS_EURO],
				[INPUT_COUPONS_RUR] = s.[INPUT_COUPONS_RUR],
				[INPUT_COUPONS_USD] = s.[INPUT_COUPONS_USD],
				[INPUT_COUPONS_EURO] = s.[INPUT_COUPONS_EURO],

				[INPUT_VALUE_RUR] = s.[INPUT_VALUE_RUR],
				[INPUT_VALUE_USD] = s.[INPUT_VALUE_USD],
				[INPUT_VALUE_EURO] = s.[INPUT_VALUE_EURO],
				[OUTPUT_VALUE_RUR] = s.[OUTPUT_VALUE_RUR],
				[OUTPUT_VALUE_USD] = s.[OUTPUT_VALUE_USD],
				[OUTPUT_VALUE_EURO] = s.[OUTPUT_VALUE_EURO];
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
        DROP TABLE #TempContract22;
    END TRY
    BEGIN CATCH
    END CATCH;

	BEGIN TRY
        DROP TABLE #TempContract3
    END TRY
    BEGIN CATCH
    END CATCH;

	BEGIN TRY
        DROP TABLE #TempContract32;
    END TRY
    BEGIN CATCH
    END CATCH;
END
GO