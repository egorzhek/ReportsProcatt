-- запрос к данным
SELECT B.*, C.OperName
FROM
(
	SELECT * 
	FROM [CacheDB].[dbo].[FundHistory] AS A WITH(NOLOCK)
	WHERE A.Investor = 25313127 AND A.FundId = 17590
	UNION
	SELECT * 
	FROM [CacheDB].[dbo].[FundHistoryLast] AS A WITH(NOLOCK)
	WHERE A.Investor = 25313127 AND A.FundId = 17590
) AS B
INNER JOIN [CacheDB].[dbo].[WalkTypes] AS C WITH(NOLOCK) ON B.WALK = C.WALK AND B.[TYPE] = C.[TYPE]
ORDER BY B.[W_Date]