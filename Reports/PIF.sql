Declare
    @Date Date = @DateToSharp, 
    @Contract_Id Int = @FundIdSharp;
--
--Declare
--    @Date Date = CONVERT(Date, '31.01.2009', 103),
--    @Contract_Id Int = 17593;

Declare @Contract_Id2 Int;

select
	@Contract_Id2 = a.FundId
from FundNames as a
where a.Id = @Contract_Id;

if @Contract_Id2 is not null set @Contract_Id = @Contract_Id2;


select
    CategoryName, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum, 'RUB' as CurrencyName
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
        where Investor_Id = @Contract_Id and PortfolioDate = @Date
        union all
        select
            Contract_Id, VALUE_RUR, Investment_id, CLASS
        from [dbo].[FundStructure_Last] nolock
        where Investor_Id = @Contract_Id and PortfolioDate = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CategoryName, AllSum;