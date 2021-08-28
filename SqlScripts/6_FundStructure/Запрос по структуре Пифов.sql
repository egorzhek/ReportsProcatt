Declare
    @Date Date = CONVERT(Date, '31.01.2009', 103),
    @Contract_Id Int = 17593;


select
    CategoryName, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum
from
(
    select
        --res.Contract_Id, res.PortfolioDate, res.Investor_Id,
        --Inv.Investment,
        --res.VALUE_ID,
        --res.CLASS,
        --cs.CategoryId,
        c.CategoryName,
        res.VALUE_RUR,
        AllSum = sum(res.VALUE_RUR) over()
    from
    (
        select
            Contract_Id, PortfolioDate, Investor_Id, Investment_id,
            VALUE_ID, BAL_ACC, CLASS, AMOUNT,
            BAL_SUMMA_RUR, Bal_Delta, NOMINAL, RUR_PRICE,
            Nom_Price, VALUE_RUR, VALUE_NOM, CUR_ID,
            RATE, RATE_DATE, RecordDate
        from [dbo].[FundStructure] nolock
        where Contract_Id = @Contract_Id and PortfolioDate = @Date
        union all
        select
            Contract_Id, PortfolioDate, Investor_Id, Investment_id,
            VALUE_ID, BAL_ACC, CLASS, AMOUNT,
            BAL_SUMMA_RUR, Bal_Delta, NOMINAL, RUR_PRICE,
            Nom_Price, VALUE_RUR, VALUE_NOM, CUR_ID,
            RATE, RATE_DATE, RecordDate
        from [dbo].[FundStructure_Last] nolock
        where Contract_Id = @Contract_Id and PortfolioDate = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
    left join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    left join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CategoryName, AllSum