-- см на 2021-04-16
SELECT 
     [Date],
     [DailyIncrement_RUR] = [Value],
     coalesce(sum(s.VALUE) over (order by  s.DATE 
                rows between unbounded preceding and current row), 
                0) as Value_RUR
FROM
    (
        SELECT
            [Date] = CAST(DATEADD(SECOND, 1, W.WIRDATE) as date),
            [Value] = cast(T.VALUE_ * T.TYPE_ as decimal(38,10))
        FROM [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
        INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID AND T.WIRDATE < '01.01.9999'
        INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
        WHERE T.IS_PLAN = 'F' AND R.BAL_ACC = 838 AND R.REG_1 = 29297588 -- договор
    ) AS  S
ORDER BY S.[Date]


-- запрос из кэша
SELECT [VALUE_RUR] 
FROM
(
    SELECT [VALUE_RUR]
    FROM [CacheDB].[dbo].[Assets_Contracts] nolock
    WHERE [InvestorId] = 13325616 AND [ContractId] = 29297588 AND [Date] = '2021-04-16'
    UNION
    SELECT [VALUE_RUR]
    FROM [CacheDB].[dbo].[Assets_ContractsLast] nolock
    WHERE [InvestorId] = 13325616 AND [ContractId] = 29297588 AND [Date] = '2021-04-16'
) AS A








-- запрос к данным по договору
SELECT *
FROM [CacheDB].[dbo].[Assets_Contracts] nolock
WHERE InvestorId = 13338758 and	ContractId = 13338775
UNION
SELECT *
FROM [CacheDB].[dbo].[Assets_ContractsLast] nolock
WHERE InvestorId = 13338758 and	ContractId = 13338775
order by [Date]


-- запрос к данным по истории ДУ
select * from [dbo].[Operations_History_Contracts]
where InvestorId = 8498291 and ContractId = 32846586
UNION ALL
select * from [dbo].[Operations_History_Contracts_Last]
where InvestorId = 8498291 and ContractId = 32846586
order by [Date]