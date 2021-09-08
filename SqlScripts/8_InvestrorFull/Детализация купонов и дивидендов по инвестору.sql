declare @InvestorId Int = 15130096,
@StartDate Date = NULL, -- '2018-01-10',
@EndDate Date = NULL, --'2020-09-28',
@ContractId Int = NULL; -- не указываем договор

-- Детализация купонов и дивидендов по инвестору
select
    [Date] = FORMAT([PaymentDateTime],'dd.MM.yyyy'),
    [ToolName] = [ShareName],
    [PriceType] = case when [Type] = 1 then N'Купоны' else N'Дивиденды' end,
    [ContractName] = [ShareName],
    [Price] = CAST(Round([AmountPayments_RUR],2) as Decimal(30,2)),
    [PaymentDateTime]
from [dbo].[DIVIDENDS_AND_COUPONS_History]
where InvestorId = @InvestorId
and (@ContractId is null or (@ContractId is not null and ContractId = @ContractId))
and (@StartDate is null or (@StartDate is not null and PaymentDateTime >= @StartDate))
and (@EndDate is null or (@EndDate is not null and PaymentDateTime < dateadd(day,1,@EndDate)))
union all
select
    [Date] =  FORMAT([PaymentDateTime],'dd.MM.yyyy'),
    [ToolName] = [ShareName],
    [PriceType] = case when [Type] = 1 then N'Купоны' else N'Дивиденды' end,
    [ContractName] = [ShareName],
    [Price] = CAST(Round([AmountPayments_RUR],2) as Decimal(30,2)),
    [PaymentDateTime]
from [dbo].[DIVIDENDS_AND_COUPONS_History_Last]
where InvestorId = @InvestorId
and (@ContractId is null or (@ContractId is not null and ContractId = @ContractId))
and (@StartDate is null or (@StartDate is not null and PaymentDateTime >= @StartDate))
and (@EndDate is null or (@EndDate is not null and PaymentDateTime < dateadd(day,1,@EndDate)))
order by [PaymentDateTime];