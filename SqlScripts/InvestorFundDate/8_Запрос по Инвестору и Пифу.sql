SELECT *
FROM [CacheDB].[dbo].[InvestorFundDate] NOLOCK
WHERE Investor = 16541 and FundId = 17578
UNION
SELECT *
FROM [CacheDB].[dbo].[InvestorFundDateLast] NOLOCK
WHERE Investor = 16541 and FundId = 17578
ORDER BY [Date]