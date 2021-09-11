Declare
    @Date Date = DateToSharp, 
    @Investor_Id Int = InvestorIdSharp;

--Declare
--    @Date Date = CONVERT(Date, '01.04.2019', 103),
--    @Contract_Id Int = 2257804;

Declare @Tmp table
(
    Investment [NVarchar](500),
    VALUE_ID Int,
    VALUE_RUR Decimal(28,10),
    AllSum Decimal(28,10),
    Result Decimal(28,10)
);



insert into @Tmp
(
    Investment, VALUE_ID, VALUE_RUR, AllSum, Result
)
select
    Investment, VALUE_ID, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum
from
(
    	select
		Investment = case when c.Id = 4 then c.CategoryName else Inv.Investment end,
        VALUE_ID = case when c.Id = 4 then c.Id else res.VALUE_ID end,
        res.VALUE_RUR,
        AllSum = sum(res.VALUE_RUR) over()
    from
    (
        select
            InvestmentId, VALUE_ID, VALUE_RUR, CLASS
        from [dbo].[PortFolio_Daily] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
        union all
        select
            InvestmentId, VALUE_ID, VALUE_RUR, CLASS
        from [dbo].[PortFolio_Daily_Last] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.InvestmentId = Inv.Id
	join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by Investment, VALUE_ID, AllSum;

--select * from @Tmp
--order by Investment;


select
    Investment = 
    case when right(rtrim(s.Investment), 5) = '; НКД'
        then left( ltrim(rtrim(s.Investment)), len (ltrim(rtrim(s.Investment))) - 5)
        else s.Investment
    end,
    s.VALUE_ID, VALUE_RUR = sum(s.VALUE_RUR), Result = sum(s.Result), s.AllSum
from @Tmp as s
group by s.VALUE_ID, s.AllSum,
    case when right(rtrim(s.Investment), 5) = '; НКД'
        then left( ltrim(rtrim(s.Investment)), len (ltrim(rtrim(s.Investment))) - 5)
        else s.Investment
    end
order by 1;