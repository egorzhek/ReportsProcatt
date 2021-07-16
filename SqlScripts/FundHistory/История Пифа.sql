--declare @Investor Int = 16541, @FundId Int = 17578;
declare @Investor Int = 44762, @FundId Int = 17578;
	

SELECT
	[Investor]  = R.[REG_1],                                             -- ИД инвестора
	[FundId]    = R.[REG_2],                                             -- ИД ПИФа
	[W_Date]    = T.[WIRDATE],                                           -- Дата операции (проводки)
	[W_ID]      = T.[WIRING],                                            -- W_ID
	[Order_NUM] = KK.[Order_NUM],                                        -- Номер заявки		                                         
	[OperName]  = W.[NAME],                                              -- Название операции
	[WALK]      = B2.[WALK],                                             -- Код операции
	[TYPE]      = T.[TYPE_],                                             -- Тип операции (ввод/вывод)
	[RATE_RUR]  = VL.[RATE],                                             -- Стоимость 1 пая
	[Amount]    = T.[AMOUNT_] * T.[TYPE_],                               -- Количество ПИФов
	[VALUE_RUR] = [dbo].f_Round(T.[AMOUNT_] * T.[TYPE_] * VL.[RATE], 2), -- Сумма сделки
	[Fee] = ISNULL(KK.Fee,0)                                             -- Сумма комиссии
FROM OD_RESTS AS R WITH(NOLOCK)
INNER JOIN OD_TURNS AS T WITH(NOLOCK) ON T.REST=R.ID and T.IS_PLAN = 'F'
INNER JOIN OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
INNER JOIN OD_TURNS AS T2 WITH(NOLOCK) ON T2.WIRING = T.WIRING and T2.TYPE_ = -T.TYPE_
INNER JOIN OD_RESTS AS E2 WITH(NOLOCK) ON E2.ID = T2.REST
INNER JOIN OD_BALANCES AS B2 WITH(NOLOCK) ON B2.ID = E2.BAL_ACC

INNER JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON R.REG_2 = s.ID
INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON S.ISSUER = C.INVESTOR AND C.I_TYPE = 5
OUTER APPLY
(
	SELECT TOP 1
		RT.[RATE]
	FROM [BAL_DATA_STD].[dbo].[OD_VALUES_RATES] AS RT
	WHERE RT.[VALUE_ID] = R.REG_2
	AND RT.[E_DATE] >= T.WIRDATE and RT.[OFICDATE] < T.WIRDATE
	ORDER BY
		case when DATEPART(YEAR,RT.[E_DATE]) = 9999 then 1 else 0 end ASC,
		RT.[E_DATE] DESC,
		RT.[OFICDATE] DESC
) AS VL
OUTER APPLY
(
		SELECT TOP 1
			ISNULL(SISU.ADD_SUMMA, 0) as Fee, --Сумма комиссии(надбавка) за операцию
			ISNULL(D_ISU.NUM_DATE, ISNUlL(D_DISU.NUM_DATE,0)) as Order_NUM -- Номер заявки
		FROM OD_STEPS AS SSS
		INNER JOIN OD_DOCS AS DDD ON DDD.ID = SSS.DOC
		INNER JOIN U_OP_P_ISSUE AS SISU ON SISU.DOC = DDD.ID

		left join U_OP_P_DEISSUE DISU on DISU.DOC =DDD.ID
		left join OD_DOCS D_ISU on D_ISU.ID = SISU.CLAIM
		left join OD_DOCS D_DISU on D_DISU.ID = DISU.CLAIM
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
AND T.WIRING is not null
AND B2.WALK > 0 -- проводка реализована.
AND B2.WALK <> 9
ORDER BY T.WIRDATE;