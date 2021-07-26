USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_FillInvestorFundHistory]
(
	@ParamINVESTOR Int -- инвестор, если NULL, то пересчёт будет по всем инвесторам
)
AS BEGIN
	-- EXEC [dbo].[app_FillInvestorFundHistory] @ParamINVESTOR = NULL - по всем инвесторам
	
	-- EXEC [dbo].[app_FillInvestorFundHistory] @ParamINVESTOR = 1 - по определённому инвестору
	-- EXEC [dbo].[app_FillInvestorFundHistory] @ParamINVESTOR = 2 - по определённому инвестору
	-- ...
	SET NOCOUNT ON;
	
	DECLARE @Investor int, @FundId Int, @ProcName NVarChar(Max) = OBJECT_NAME(@@PROCID), @Error NVarChar(Max)
	
	declare obj_cur cursor local fast_forward for
		-- 
		SELECT --TOP 10 --test
			R.REG_1 AS Investor,
			R.REG_2 AS FundId
		FROM [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID and T.IS_PLAN = 'F'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T2 WITH(NOLOCK) ON T2.WIRING = T.WIRING and T2.TYPE_ = -T.TYPE_
		INNER JOIN [BAL_DATA_STD].[dbo].OD_RESTS AS E2 WITH(NOLOCK) ON E2.ID = T2.REST
		INNER JOIN [BAL_DATA_STD].[dbo].OD_BALANCES AS B2 WITH(NOLOCK) ON B2.ID = E2.BAL_ACC
		
		INNER JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON R.REG_2 = s.ID
		INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON S.ISSUER = C.INVESTOR AND C.I_TYPE = 5
		WHERE 
		R.BAL_ACC = 2793
		and T.WIRING is not null
		and B2.WALK > 0 -- проводка реализована.
		and (R.REG_1 = @ParamINVESTOR OR @ParamINVESTOR IS NULL)
		GROUP BY R.REG_1, R.REG_2
		ORDER BY R.REG_1, R.REG_2
	open obj_cur
	fetch next from obj_cur into
		@Investor,
		@FundId
	while(@@fetch_status = 0)
	begin
		BEGIN TRY
			EXEC [dbo].[app_FillInvestorFundHistory_Inner]
					@Investor = @Investor, @FundId = @FundId
		END TRY
		BEGIN CATCH
			SET @Error = ERROR_MESSAGE();

			-- ошибку в лог
			INSERT INTO [dbo].[ProcessorErrors] ([Error])
			SELECT @ProcName + ': ' + @Error;
		END CATCH
		
		
		fetch next from obj_cur into
			@Investor,
			@FundId
	end
	
	close obj_cur
	deallocate obj_cur
END
GO