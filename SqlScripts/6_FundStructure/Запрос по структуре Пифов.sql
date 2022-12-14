Declare
    @Date Date = CONVERT(Date, '31.01.2009', 103),
    @Contract_Id Int = 17593;


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
            Contract_Id, VALUE_RUR, Investment_id, CLASS
        from [dbo].[FundStructure] nolock
        where Contract_Id = @Contract_Id and PortfolioDate = @Date
        union all
        select
            Contract_Id, VALUE_RUR, Investment_id, CLASS
        from [dbo].[FundStructure_Last] nolock
        where Contract_Id = @Contract_Id and PortfolioDate = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CategoryName, AllSum;