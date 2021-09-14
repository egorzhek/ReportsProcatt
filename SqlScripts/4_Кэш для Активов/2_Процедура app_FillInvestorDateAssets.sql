USE [CacheDB]
GO
CREATE OR ALTER PROCEDURE [dbo].[app_FillInvestorDateAssets]
(
	@ParamINVESTOR Int -- инвестор, если NULL, то пересчёт будет по всем инвесторам
)
AS BEGIN
	-- калькуляция активов по инвестору на дату
	-- и по договорам инвестора  на дату
	-- сохранение в кэш-таблицы

	-- предполагается вызов в SQL Агенте ночью по всем инвесторам
	-- EXEC [CacheDB].[dbo].[app_FillInvestorDateAssets] @ParamINVESTOR = NULL

	-- или только по определённым инвесторам
	-- EXEC [CacheDB].[dbo].[app_FillInvestorDateAssets] @ParamINVESTOR = 1
	-- EXEC [CacheDB].[dbo].[app_FillInvestorDateAssets] @ParamINVESTOR = 2
	-- ...

	set nocount on;

	DECLARE @CurrentDate Date = GetDate();
	DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate);
	DECLARE @IsDateAssets Bit, @ProcName NVarChar(Max) = OBJECT_NAME(@@PROCID), @Error NVarChar(Max);

	declare @DOC2 Int, @INV2 Int;

	DECLARE 
		@Date date,
		@Revolution [numeric](28, 7),
		@INVESTORR int, @INVESTORR2 int,
		@DOC int,

		@OldDate date = NULL,
		@SumRevolution [numeric](28, 7) = NULL;

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
	and C.INVESTOR not in (16541, 17319, 17284, 17337)
	and C.E_DATE > DateAdd(day, -3, getdate())
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
		BEGIN

			BEGIN TRY


			-- очистка временного кэша
			delete from [CacheDB].[dbo].[InvestorDateAssetsLast]
			where Investor_id = @INV2;

			-- признак наличия записей в постоянном кэше
			SET @IsDateAssets = 0;

			IF EXISTS
			(
				SELECT TOP 1 1
				FROM [CacheDB].[dbo].[InvestorDateAssets] NOLOCK
				WHERE Investor_Id = @INV2
			)
			BEGIN
				SET @IsDateAssets = 1;
			END



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
						left join [BAL_DATA_STD].[dbo].[OD_WIRING] AS W with(nolock) on W.ID = T.WIRING
						WHERE T.IS_PLAN = 'F' and R.BAL_ACC = 838 and R.REG_1 in
						(
							select DOC FROM #CONTRACTS
							where INVESTOR = @INV2
						)
					) s
			) as Res
			ORDER BY RowNumber


			-- калькуляция по инвестору по всем договорам
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
						-- первая строка
						set @OldDate = @Date
						set @SumRevolution = @Revolution
					end
					else
					begin
						-- вторая и последующая строки
						if @OldDate <> @Date
						begin
							-- дата изменилась
							-- если дата менее полугода, то заливаем в постоянную таблицу
							-- если дата за последние полгода, то во временную таблицу

							IF @OldDate < @LastEndDate
							BEGIN
								-- если записей в постоянном кэше не было ранее или попали в последние 10 дней постоянного кэша
								-- если записи были в постоянном кэше, то записи не будет (за исключением последних 10 дней постоянного кэша)
								IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
								BEGIN
									WITH CTE
									AS
									(
										SELECT *
										FROM [CacheDB].[dbo].[InvestorDateAssets]
										WHERE Investor_Id = @INVESTORR2 and [Date] = @OldDate
									) 
									MERGE
										CTE as t
									USING
									(
										select Investor_Id = @INVESTORR2, [Date] = @OldDate, AssetsValue = @SumRevolution
									) AS s
									on t.Investor_Id = s.Investor_Id and t.[Date] = s.[Date]
									when not matched
										then insert (
											[Investor_Id],
											[Date],
											[AssetsValue]
										)
										values (
											s.[Investor_Id],
											s.[Date],
											s.[AssetsValue]
										)
									when matched
									then update set
										[AssetsValue] = s.[AssetsValue];
								END
							END
							ELSE
							BEGIN
								WITH CTE
								AS
								(
									SELECT *
									FROM [CacheDB].[dbo].[InvestorDateAssetsLast]
									WHERE Investor_Id = @INVESTORR2 and [Date] = @OldDate
								) 
								MERGE
									CTE as t
								USING
								(
									select Investor_Id = @INVESTORR2, [Date] = @OldDate, AssetsValue = @SumRevolution
								) AS s
								on t.Investor_Id = s.Investor_Id and t.[Date] = s.[Date]
								when not matched
									then insert (
										[Investor_Id],
										[Date],
										[AssetsValue]
									)
									values (
										s.[Investor_Id],
										s.[Date],
										s.[AssetsValue]
									)
								when matched
								then update set
									[AssetsValue] = s.[AssetsValue];
							END

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
				IF @OldDate < @LastEndDate
				BEGIN
					-- если записей в постоянном кэше не было ранее или попали в последние 10 дней постоянного кэша
					-- если записи были в постоянном кэше, то записи не будет (за исключением последних 10 дней постоянного кэша)
					IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
					BEGIN
						WITH CTE
						AS
						(
							SELECT *
							FROM [CacheDB].[dbo].[InvestorDateAssets]
							WHERE Investor_Id = @INV2 and [Date] = @OldDate
						) 
						MERGE
							CTE as t
						USING
						(
							select Investor_Id = @INV2, [Date] = @OldDate, AssetsValue = @SumRevolution
						) AS s
						on t.Investor_Id = s.Investor_Id and t.[Date] = s.[Date]
						when not matched
							then insert (
								[Investor_Id],
								[Date],
								[AssetsValue]
							)
							values (
								s.[Investor_Id],
								s.[Date],
								s.[AssetsValue]
							)
						when matched
						then update set
							[AssetsValue] = s.[AssetsValue];
					END
				END
				ELSE
				BEGIN
					WITH CTE
					AS
					(
						SELECT *
						FROM [CacheDB].[dbo].[InvestorDateAssetsLast]
						WHERE Investor_Id = @INV2 and [Date] = @OldDate
					) 
					MERGE
						CTE as t
					USING
					(
						select Investor_Id = @INV2, [Date] = @OldDate, AssetsValue = @SumRevolution
					) AS s
					on t.Investor_Id = s.Investor_Id and t.[Date] = s.[Date]
					when not matched
						then insert (
							[Investor_Id],
							[Date],
							[AssetsValue]
						)
						values (
							s.[Investor_Id],
							s.[Date],
							s.[AssetsValue]
						)
					when matched
					then update set
						[AssetsValue] = s.[AssetsValue];
				END
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
				-- очистка временного кэша по инвестору и договору
				delete from [CacheDB].[dbo].[InvestorContractDateAssetsLast]
				where Investor_id = @INV2 AND Contract_Id = @DOC2;

				-- признак наличия записей в постоянном кэше по инвестору и договору
				SET @IsDateAssets = 0;

				IF EXISTS
				(
					SELECT TOP 1 1
					FROM [CacheDB].[dbo].[InvestorContractDateAssets] NOLOCK
					where Investor_id = @INV2 AND Contract_Id = @DOC2
				)
				BEGIN
					SET @IsDateAssets = 1;
				END


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
								-- первая строка
								set @OldDate = @Date
								set @SumRevolution = @Revolution
							end
							else
							begin
								-- вторая и последующая строки
								if @OldDate <> @Date
								begin
									-- дата изменилась
									-- если записей в постоянном кэше не было ранее или попали в 10 дней постоянного кэша
									-- если записи были в постоянном кэше, то записи не будет (за исключением последних 10 дней постоянного кэша)
									IF @OldDate < @LastEndDate
									BEGIN
										IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
										BEGIN
											WITH CTE
											AS
											(
												SELECT *
												FROM [CacheDB].[dbo].[InvestorContractDateAssets]
												WHERE Investor_Id = @INVESTORR2 and Contract_Id = @DOC2 and [Date] = @OldDate
											) 
											MERGE
												CTE as t
											USING
											(
												select Investor_Id = @INVESTORR2, Contract_Id = @DOC2, [Date] = @OldDate, AssetsValue = @SumRevolution
											) AS s
											on t.Investor_Id = s.Investor_Id and t.[Contract_Id] = s.[Contract_Id] and t.[Date] = s.[Date]
											when not matched
												then insert (
													[Investor_Id],
													[Contract_Id],
													[Date],
													[AssetsValue]
												)
												values (
													s.[Investor_Id],
													s.[Contract_Id],
													s.[Date],
													s.[AssetsValue]
												)
											when matched
											then update set
												[AssetsValue] = s.[AssetsValue];
										END
									END
									ELSE
									BEGIN
										WITH CTE
										AS
										(
											SELECT *
											FROM [CacheDB].[dbo].[InvestorContractDateAssetsLast]
											WHERE Investor_Id = @INVESTORR2 and Contract_Id = @DOC2 and [Date] = @OldDate
										) 
										MERGE
											CTE as t
										USING
										(
											select Investor_Id = @INVESTORR2, Contract_Id = @DOC2, [Date] = @OldDate, AssetsValue = @SumRevolution
										) AS s
										on t.Investor_Id = s.Investor_Id and t.[Contract_Id] = s.[Contract_Id] and t.[Date] = s.[Date]
										when not matched
											then insert (
												[Investor_Id],
												[Contract_Id],
												[Date],
												[AssetsValue]
											)
											values (
												s.[Investor_Id],
												s.[Contract_Id],
												s.[Date],
												s.[AssetsValue]
											)
										when matched
										then update set
											[AssetsValue] = s.[AssetsValue];
									END

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
						IF @OldDate < @LastEndDate
						BEGIN
							IF @IsDateAssets = 0 OR @OldDate >= DateAdd(DAY, -10, @LastEndDate)
							BEGIN
								WITH CTE
								AS
								(
									SELECT *
									FROM [CacheDB].[dbo].[InvestorContractDateAssets]
									WHERE Investor_Id = @INV2 and Contract_Id = @DOC2 and [Date] = @OldDate
								) 
								MERGE
									CTE as t
								USING
								(
									select Investor_Id = @INV2, Contract_Id = @DOC2, [Date] = @OldDate, AssetsValue = @SumRevolution
								) AS s
								on t.Investor_Id = s.Investor_Id and t.[Contract_Id] = s.[Contract_Id] and t.[Date] = s.[Date]
								when not matched
									then insert (
										[Investor_Id],
										[Contract_Id],
										[Date],
										[AssetsValue]
									)
									values (
										s.[Investor_Id],
										s.[Contract_Id],
										s.[Date],
										s.[AssetsValue]
									)
								when matched
								then update set
									[AssetsValue] = s.[AssetsValue];
							END
						END
						ELSE
						BEGIN
							WITH CTE
							AS
							(
								SELECT *
								FROM [CacheDB].[dbo].[InvestorContractDateAssetsLast]
								WHERE Investor_Id = @INV2 and Contract_Id = @DOC2 and [Date] = @OldDate
							) 
							MERGE
								CTE as t
							USING
							(
								select Investor_Id = @INV2, Contract_Id = @DOC2, [Date] = @OldDate, AssetsValue = @SumRevolution
							) AS s
							on t.Investor_Id = s.Investor_Id and t.[Contract_Id] = s.[Contract_Id] and t.[Date] = s.[Date]
							when not matched
								then insert (
									[Investor_Id],
									[Contract_Id],
									[Date],
									[AssetsValue]
								)
								values (
									s.[Investor_Id],
									s.[Contract_Id],
									s.[Date],
									s.[AssetsValue]
								)
							when matched
							then update set
								[AssetsValue] = s.[AssetsValue];
						END
					END

					close obj_cur
					deallocate obj_cur

				fetch next from docs_cur into
					@DOC2
			end

			close docs_cur
			deallocate docs_cur


			END TRY
			BEGIN CATCH
				SET @Error = ERROR_MESSAGE();

				-- ошибку в лог
				INSERT INTO [dbo].[ProcessorErrors] ([Error], [Investor_id])
				SELECT @ProcName + ': ' + @Error, @INV2;
			END CATCH
		
			fetch next from inv_cur into
				@INV2
		END

		close inv_cur
		deallocate inv_cur
END
GO