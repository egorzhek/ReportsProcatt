Declare
    @Date Date = CONVERT(Date, '01.04.2018', 103),
    @Contract_Id Int = 15130129;

select
    Investment, VALUE_ID, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum
from
(
    select
        Inv.Investment,
        res.VALUE_ID,
        res.VALUE_RUR,
        AllSum = sum(res.VALUE_RUR) over()
    from
    (
        select
            *
        from [dbo].[PortFolio_Daily] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
        union all
        select
            *
        from [dbo].[PortFolio_Daily_Last] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.InvestmentId = Inv.Id
) as res2
where VALUE_RUR > 0
group by Investment, VALUE_ID, AllSum