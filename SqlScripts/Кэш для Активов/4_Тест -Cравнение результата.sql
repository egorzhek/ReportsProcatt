
-- сквозной просмотр
SELECT *
FROM
(
	SELECT 
		 Date,
		 Value as Revolution,
		 coalesce(sum(s.VALUE) over (order by  s.DATE 
					rows between unbounded preceding and current row), 
					0) as AssetsValue,
		ROW_NUMBER() over (order by  s.DATE) as RowNumber
	FROM
		(select
			DATEADD(SECOND,1, W.WIRDATE) as date , 
			T.VALUE_*T.TYPE_ as VALUE
		FROM [BAL_DATA_STD].[dbo].OD_RESTS R 
		left join [BAL_DATA_STD].[dbo].OD_TURNS T with(readcommitted)  on T.REST=R.ID and T.WIRDATE<'01.01.9999'
		left join [BAL_DATA_STD].[dbo].OD_WIRING W on W.ID = T.WIRING
		WHERE T.IS_PLAN='F'  and R.BAL_ACC=838 and R.REG_1 in (
			select DOC FROM [BAL_DATA_STD].[dbo].[D_B_CONTRACTS]
				where INVESTOR = 16541 and ACCOUNT is null) --@ContractId 

		) s
) as Res
order by RowNumber



-- сравнение запросов по инвестору целиком
SELECT TOP (1) AssetsValue
FROM
(
	SELECT 
		 Date,
		 Value as Revolution,
		 coalesce(sum(s.VALUE) over (order by  s.DATE 
					rows between unbounded preceding and current row), 
					0) as AssetsValue,
		ROW_NUMBER() over (order by  s.DATE) as RowNumber
	FROM
		(
			select
				DATEADD(SECOND,1, W.WIRDATE) as date , 
				T.VALUE_*T.TYPE_ as VALUE
			FROM [BAL_DATA_STD].[dbo].OD_RESTS R 
			left join [BAL_DATA_STD].[dbo].OD_TURNS T with(readcommitted)  on T.REST=R.ID and T.WIRDATE<'01.01.9999'
			left join [BAL_DATA_STD].[dbo].OD_WIRING W on W.ID = T.WIRING
			WHERE T.IS_PLAN='F'  and R.BAL_ACC=838 and R.REG_1 in (
				select DOC FROM [BAL_DATA_STD].[dbo].[D_B_CONTRACTS]
					where INVESTOR = 16541 and ACCOUNT is null) --@ContractId 

		) s
) as Res
where [Date] <= '2020-06-20'
order by RowNumber desc

select top 1 AssetsValue
from [CacheDB].[dbo].[InvestorDateAssets] nolock
where Investor_Id = 16541
and [Date] <= '2020-06-20'
order by [Date] desc







-- сравнение запросов по инвестору и договору
SELECT TOP (1) AssetsValue
FROM
(
	SELECT 
		 Date,
		 Value as Revolution,
		 coalesce(sum(s.VALUE) over (order by  s.DATE 
					rows between unbounded preceding and current row), 
					0) as AssetsValue,
		ROW_NUMBER() over (order by  s.DATE) as RowNumber
	FROM
		(
			select
				DATEADD(SECOND,1, W.WIRDATE) as date , 
				T.VALUE_*T.TYPE_ as VALUE
			FROM [BAL_DATA_STD].[dbo].OD_RESTS R 
			left join [BAL_DATA_STD].[dbo].OD_TURNS T with(readcommitted)  on T.REST=R.ID and T.WIRDATE<'01.01.9999'
			left join [BAL_DATA_STD].[dbo].OD_WIRING W on W.ID = T.WIRING
			WHERE T.IS_PLAN='F'  and R.BAL_ACC=838 and R.REG_1 in (
				32266170) --@ContractId 

		) s
) as Res
where [Date] <= '2021-06-22'
order by RowNumber desc

select top 1 AssetsValue
from [CacheDB].[dbo].[InvestorContractDateAssets] nolock
WHERE Investor_Id = 16541 and Contract_Id = 32266170
and [Date] <= '2021-06-22'
order by [Date] desc

-- Что-то