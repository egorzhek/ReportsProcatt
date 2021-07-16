SELECT
	A.*, FundName = B.[Name]
FROM
(
	SELECT *
	FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
	WHERE Investor = 16541 and FundId = 17578
	UNION
	SELECT *
	FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
	WHERE Investor = 16541 and FundId = 17578
) AS A
LEFT JOIN [CacheDB].[dbo].[FundNames] as B WITH(NOLOCK) ON A.FundId = B.Id
ORDER BY A.[Date]