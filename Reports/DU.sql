Declare
    @Date Date = @DateToSharp, 
    @Contract_Id Int = @ContractIdSharp;

--Declare
--    @Date Date = CONVERT(Date, '01.04.2018', 103),
--    @Contract_Id Int = 15130129;

select
    CategoryName, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum
from
(
    select
        c.CategoryName,
        res.VALUE_RUR,
        AllSum = sum(res.VALUE_RUR) over()
    from
    (
        select
            VALUE_RUR, InvestmentId, CLASS
        from [dbo].[PortFolio_Daily] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
        union all
        select
            VALUE_RUR, InvestmentId, CLASS
        from [dbo].[PortFolio_Daily_Last] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.InvestmentId = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CategoryName, AllSum;