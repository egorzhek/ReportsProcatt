USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_Fill_Assets_Contract]
(
	@ParamINVESTOR Int -- инвестор, если NULL, то пересчёт будет по всем инвесторам
)
AS BEGIN
	-- EXEC [dbo].[app_Fill_Assets_Contract] @ParamINVESTOR = NULL - по всем инвесторам
	
	-- EXEC [dbo].[app_Fill_Assets_Contract] @ParamINVESTOR = 1 - по определённому договору
	-- EXEC [dbo].[app_Fill_Assets_Contract] @ParamINVESTOR = 2 - по определённому инвестору
	-- ...


	DECLARE @ContractId Int

	declare obj_cur cursor local fast_forward for
		-- 
		SELECT
			R.REG_1
		FROM [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID and T.WIRDATE < '01.01.9999'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
		INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON C.DOC = R.REG_1
		WHERE T.IS_PLAN = 'F' and R.BAL_ACC = 838
		and (C.INVESTOR = @ParamINVESTOR OR @ParamINVESTOR IS NULL)
		GROUP BY R.REG_1
		ORDER BY R.REG_1
	open obj_cur
	fetch next from obj_cur into
		@ContractId
	while(@@fetch_status = 0)
	begin
		EXEC [dbo].[app_Fill_Assets_Contract_Inner]
				@ContractId = @ContractId


		fetch next from obj_cur into
			@ContractId
	end

	close obj_cur
	deallocate obj_cur
END
GO