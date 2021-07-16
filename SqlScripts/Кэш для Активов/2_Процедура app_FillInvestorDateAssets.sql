USE [CacheDB]
GO
CREATE PROCEDURE [dbo].[app_FillInvestorDateAssets]
(
	@ParamINVESTOR Int -- инвестор, если NULL, то пересчЄт будет по всем инвесторам
)
AS BEGIN
	-- калькул€ци€ активов по инвестору на дату
	-- и по договорам инвестора  на дату
	-- сохранение в кэш-таблицы

	-- предполагаетс€ вызов в SQL јгенте ночью по всем инвесторам
	-- EXEC [CacheDB].[dbo].[app_FillInvestorDateAssets] @ParamINVESTOR = NULL

	-- или только по определЄнным инвесторам
	-- EXEC [CacheDB].[dbo].[app_FillInvestorDateAssets] @ParamINVESTOR = 1
	-- EXEC [CacheDB].[dbo].[app_FillInvestorDateAssets] @ParamINVESTOR = 2
	-- ...

	set nocount on;

	declare @DOC2 Int, @INV2 Int;

	DECLARE 
		@Date date,
		@Revolution [numeric](28, 7),
		@INVESTORR int, @INVESTORR2 int,
		@DOC int,

		@OldDate date = NULL,
		@SumRevolution [numeric](28, 7) = NULL

	IF @ParamINVESTOR IS NULL
	BEGIN
		truncate table [CacheDB].[dbo].[InvestorDateAssets];
		truncate table [CacheDB].[dbo].[InvestorContractDateAssets];
	END
	ELSE
	BEGIN
		delete from [CacheDB].[dbo].[InvestorDateAssets]
		where Investor_id = @ParamINVESTOR;

		delete from [CacheDB].[dbo].[InvestorContractDateAssets]
		where Investor_id = @ParamINVESTOR;
	END

	BEGIN TRY
		DROP TABLE #CONTRACTS;
	END TRY
	BEGIN CATCH
	END CATCH

	BEGIN TRY
		DROP TABLE #TEMPFORCALC;
	END TRY
	BEGIN CATCH
	END CATCH

	SELECT
		INVESTOR, DOC
	INTO #CONTRACTS
	FROM [BAL_DATA_STD].[dbo].[D_B_CONTRACTS] AS C with(nolock)
	WHERE ACCOUNT is null
	and (INVESTOR = @ParamINVESTOR or @ParamINVESTOR is null)
	GROUP BY INVESTOR, DOC
	ORDER BY INVESTOR, DOC

		-- курсор по инвесторам
		declare inv_cur cursor local fast_forward for
			-- 
			SELECT
				INVESTOR
			FROM #CONTRACTS
			GROUP BY INVESTOR
		open inv_cur
		fetch next from inv_cur into
			@INV2
		while(@@fetch_status = 0)
		begin
			BEGIN TRY
				DROP TABLE #TEMPFORCALC;
			END TRY
			BEGIN CATCH
			END CATCH

			SELECT *
			INTO #TEMPFORCALC
			FROM
			(
				SELECT 
					Date,
					Value as Revolution,
					ROW_NUMBER() over (order by s.DATE) as RowNumber,
					INVESTOR,
					DOC
				FROM
					(
						SELECT
							DATEADD(SECOND,1, W.WIRDATE) as date , 
							T.VALUE_*T.TYPE_ as VALUE,
							INVESTOR = @INV2,
							DOC = R.REG_1
						FROM [BAL_DATA_STD].[dbo].[OD_RESTS] AS R with(nolock)
						left join [BAL_DATA_STD].[dbo].[OD_TURNS] AS T with(nolock) on T.REST = R.ID and T.WIRDATE < '01.01.9999'
						left join [BAL_DATA_STD].[dbo].[OD_WIRING] W on W.ID = T.WIRING
						WHERE T.IS_PLAN = 'F' and R.BAL_ACC = 838 and R.REG_1 in
						(
							select DOC FROM #CONTRACTS
							where INVESTOR = @INV2
						)
					) s
			) as Res
			ORDER BY RowNumber


			-- калькул€ци€ по инвестору по всем договорам
			set @Date = NULL;
			set @Revolution = NULL;
			set @INVESTORR  = NULL;
			set @INVESTORR2 = NULL;
			set @DOC = NULL;

			set @OldDate = NULL;
			set @SumRevolution = NULL;

			declare obj_cur cursor local fast_forward for
				-- 
				SELECT
					Date, Revolution, INVESTOR, DOC
				FROM #TEMPFORCALC
				ORDER BY RowNumber
			open obj_cur
			fetch next from obj_cur into
				@Date,
				@Revolution,
				@INVESTORR,
				@DOC
			while(@@fetch_status = 0)
			begin
					set @INVESTORR2 = @INVESTORR
			
					if @OldDate IS NULL
					begin
						-- перва€ строка
						set @OldDate = @Date
						set @SumRevolution = @Revolution
					end
					else
					begin
						-- втора€ и последующа€ строки
						if @OldDate <> @Date
						begin
							-- дата изменилась
							insert into [CacheDB].[dbo].[InvestorDateAssets] (Investor_Id,	Date, AssetsValue)
							select @INVESTORR2, @OldDate, @SumRevolution

							set @OldDate = @Date
						end
				
						set @SumRevolution += @Revolution
					end
		
				fetch next from obj_cur into
					@Date,
					@Revolution,
					@INVESTORR,
					@DOC
			end

			-- запись по последней строке
			IF @OldDate IS NOT NULL
			BEGIN
				insert into [CacheDB].[dbo].[InvestorDateAssets] (Investor_Id,	Date, AssetsValue)
				select @INV2, @OldDate, @SumRevolution
			END

			close obj_cur
			deallocate obj_cur
	


			set @DOC2 = NULL;
		

			-- а теперь по каждому договору инвестора
			declare docs_cur cursor local fast_forward for
				-- 
				SELECT
					DOC
				FROM #TEMPFORCALC
				GROUP BY DOC
			open docs_cur
			fetch next from docs_cur into
				@DOC2
			while(@@fetch_status = 0)
			begin
					set @Date = NULL;
					set @Revolution = NULL;
					set @INVESTORR = NULL;
					set @INVESTORR2 = NULL;
					set @DOC = NULL;
					set @OldDate = NULL;
					set @SumRevolution = NULL;

					declare obj_cur cursor local fast_forward for
						-- 
						SELECT
							Date, Revolution, INVESTOR, DOC
						FROM #TEMPFORCALC
						WHERE DOC = @DOC2
						ORDER BY RowNumber
					open obj_cur
					fetch next from obj_cur into
						@Date,
						@Revolution,
						@INVESTORR,
						@DOC
					while(@@fetch_status = 0)
					begin
							set @INVESTORR2 = @INVESTORR
			
							if @OldDate IS NULL
							begin
								-- перва€ строка
								set @OldDate = @Date
								set @SumRevolution = @Revolution
							end
							else
							begin
								-- втора€ и последующа€ строки
								if @OldDate <> @Date
								begin
									-- дата изменилась
									insert into [CacheDB].[dbo].[InvestorContractDateAssets] (Investor_Id,	Contract_Id, Date, AssetsValue)
									select @INVESTORR2, @DOC2, @OldDate, @SumRevolution

									set @OldDate = @Date
								end
				
								set @SumRevolution += @Revolution
							end
		
						fetch next from obj_cur into
							@Date,
							@Revolution,
							@INVESTORR,
							@DOC
					end

					-- запись по последней строке
					IF @OldDate IS NOT NULL
					BEGIN
						insert into [CacheDB].[dbo].[InvestorContractDateAssets] (Investor_Id,	Contract_Id, Date, AssetsValue)
						select @INV2, @DOC2, @OldDate, @SumRevolution
					END

					close obj_cur
					deallocate obj_cur

				fetch next from docs_cur into
					@DOC2
			end

			close docs_cur
			deallocate docs_cur

		
			fetch next from inv_cur into
				@INV2
		end

		close inv_cur
		deallocate inv_cur
END
GO