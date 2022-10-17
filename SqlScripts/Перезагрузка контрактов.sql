	set dateformat dmy;


	DECLARE @ContractId Int, @InvestorId Int, @ProcName NVarChar(Max) = OBJECT_NAME(@@PROCID), @Error NVarChar(Max), @Id Int;
	declare @Rows table (id int);

	declare obj_cur cursor local fast_forward for
		-- 
		SELECT
			R.REG_1, C.INVESTOR
		FROM [BAL_DATA_STD].[dbo].OD_RESTS AS R WITH(NOLOCK)
		INNER JOIN [BAL_DATA_STD].[dbo].OD_TURNS AS T WITH(NOLOCK) ON T.REST = R.ID and T.WIRDATE < '01.01.9999'
		INNER JOIN [BAL_DATA_STD].[dbo].OD_WIRING AS W WITH(NOLOCK) ON W.ID = T.WIRING
		INNER JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON C.DOC = R.REG_1
		WHERE T.IS_PLAN = 'F' and R.BAL_ACC = 838
		and C.INVESTOR not in (16541, 17319, 17284, 17337,536368, 652397)
		
		and C.INVESTOR = 4818360 -- для теста один берём, потом это условие комментим

		-- ранее обработанные не пересчитываем
		and R.REG_1 not in
		(
			select ContractId
			from [dbo].[ReloadContractInfo]
			where EndDate is not null
		)
		and R.REG_1 in
		(
			select ContractId
			From [dbo].[Operations_History_Contracts]
			where T_Name = 'Вывод ЦБ'
			union
			select ContractId
			From [dbo].[Operations_History_Contracts_Last]
			where T_Name = 'Вывод ЦБ'
		)
		GROUP BY C.INVESTOR, R.REG_1
		ORDER BY C.INVESTOR, R.REG_1
	open obj_cur
	fetch next from obj_cur into
		@ContractId, @InvestorId
	while(@@fetch_status = 0)
	begin
		BEGIN TRY
			
			DELETE
			FROM [dbo].[ReloadContractInfo]
			WHERE InvestorId = @InvestorId and ContractId = @ContractId;

			delete from @Rows;
			
			insert into dbo.ReloadContractInfo
			(
				InvestorId,
				ContractId,
				StartDate,
				EndDate
			)
			output inserted.Id into @Rows(id)
			values
			(
				@InvestorId,
				@ContractId,
				getdate(),
				NULL
			);

			select @Id = Id from @Rows;

				DELETE
				FROM [dbo].[DIVIDENDS_AND_COUPONS_History]
				WHERE InvestorId = @InvestorId and ContractId = @ContractId;

				DELETE
				FROM [dbo].[DIVIDENDS_AND_COUPONS_History_Last]
				WHERE InvestorId = @InvestorId and ContractId = @ContractId;

				--
				DELETE
				FROM [CacheDB].[dbo].[Assets_Contracts]
                WHERE InvestorId = @InvestorId and ContractId = @ContractId;

				DELETE
				FROM [CacheDB].[dbo].[Assets_ContractsLast]
                WHERE InvestorId = @InvestorId and ContractId = @ContractId;

				--
				DELETE
				FROM [dbo].[Operations_History_Contracts]
                WHERE InvestorId = @InvestorId and ContractId = @ContractId;

				DELETE
				FROM [dbo].[Operations_History_Contracts_Last]
                WHERE InvestorId = @InvestorId and ContractId = @ContractId;

				--
				DELETE
				from [dbo].[PortFolio_Daily_Before]
				where InvestorId = @InvestorId and ContractId = @ContractId;

				DELETE FROM [dbo].[PortFolio_Daily]
				WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId;

				DELETE FROM [dbo].[PortFolio_Daily_Last]
				WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId;

				--
				DELETE FROM [dbo].[POSITION_KEEPING]
				WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId;

				DELETE FROM [dbo].[POSITION_KEEPING_Last]
				WHERE [InvestorId] = @InvestorId AND [ContractId] = @ContractId;

				EXEC [dbo].[app_Fill_Assets_Contract_Inner]
						@ContractId = @ContractId;
				
				-- ставим в логе завершение
				update dbo.ReloadContractInfo
					set EndDate = getdate()
				where Id = @Id;
		END TRY
		BEGIN CATCH
			SET @Error = ERROR_MESSAGE();

			-- ошибку в лог
			INSERT INTO [dbo].[ProcessorErrors] ([Error], [ContractId])
			SELECT @ProcName + ': ' + @Error, @ContractId;
		END CATCH


		fetch next from obj_cur into
			@ContractId, @InvestorId
	end

	close obj_cur
	deallocate obj_cur