Declare
    @Date Date = CONVERT(Date, '01.04.2018', 103),
    @Contract_Id Int = 15130129;

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