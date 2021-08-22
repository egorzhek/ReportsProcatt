Declare
    @Date Date = CONVERT(Date, '01.05.2021', 103),
    @Contract_Id Int = 2257804;



select
    res.Contract_Id, res.PortfolioDate, res.Investor_Id,
    Inv.Investment,
    res.VALUE_ID, res.BAL_ACC, res.CLASS, res.AMOUNT,
    res.BAL_SUMMA_RUR, res.Bal_Delta, res.NOMINAL, res.RUR_PRICE,
    res.Nom_Price, res.VALUE_RUR, res.VALUE_NOM, res.CUR_ID,
    res.RATE, res.RATE_DATE, res.RecordDate
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
join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id;