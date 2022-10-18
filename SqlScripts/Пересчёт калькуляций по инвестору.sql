USE [CacheDB]
GO
SET ANSI_NULLS, QUOTED_IDENTIFIER ON
GO
declare
	@InvestorId Int,
	@ContractId Int,
	@PaperId Int;

declare mycur2 cursor local fast_forward for
	select InvestorId, ContractId, ShareId
	from [dbo].[POSITION_KEEPING] as a with(nolock)
	--where InvestorId = 16593 -- для фильтра по инвестору
	union
	select InvestorId, ContractId, ShareId
	from [dbo].[POSITION_KEEPING_Last] as a with(nolock)
	--where InvestorId = 16593 -- для фильтра по инвестору
	order by InvestorId, ContractId, ShareId
open mycur2
fetch next from mycur2 into @InvestorId, @ContractId, @PaperId
while @@FETCH_STATUS = 0
begin
	exec dbo.Calc_Amortization
		@InvestorId  = @InvestorId,
		@ContractId  = @ContractId,
		@PaperId  = @PaperId,
		@StartDate = NULL;
	
	exec dbo.Calc_Cupons
		@InvestorId = @InvestorId,
		@ContractId = @ContractId,
		@PaperId = @PaperId,
		@StartDate = NULL;

	exec dbo.Calc_Dividents
		@InvestorId = @InvestorId,
		@ContractId = @ContractId,
		@PaperId = @PaperId,
		@StartDate = NULL;

	fetch next from mycur2 into @InvestorId, @ContractId, @PaperId
end
close mycur2
deallocate mycur2;
GO