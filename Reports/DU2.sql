Declare
    @Date Date = @DateToSharp, 
    @Contract_Id Int = @ContractIdSharp,
	@Valuta Nvarchar(10) = @ValutaSharp;

	if @Valuta is null set @Valuta = 'RUB';

    --set @Date = DATEADD(DAY, 1, @Date);

--Declare
--    @Date Date = CONVERT(Date, '01.04.2019', 103),
--    @Contract_Id Int = 2257804;

declare @USDRATE numeric(38, 10), @EURORATE numeric(38, 10);

-- курс валют
select top 1
	@USDRATE = r.USDRATE,
	@EURORATE = r.EURORATE
from
(
	select top 1
		ac.USDRATE, ac.EURORATE
	from [dbo].[Assets_Contracts] as ac
	where ac.[Date] = @Date
	union
	select top 1
		ac.USDRATE, ac.EURORATE
	from [dbo].[Assets_ContractsLast] as ac
	where ac.[Date] = @Date
) as r

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
            InvestmentId,
			VALUE_ID,
			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_RUR  * (1.00000/@USDRATE)
				when @Valuta = 'EUR' then VALUE_RUR  * (1.00000/@EURORATE)
				else VALUE_RUR
			end,
			CLASS
        from [dbo].[PortFolio_Daily] nolock
        where ContractId = @Contract_Id and [PortfolioDate] = @Date
        union all
        select
            InvestmentId,
			VALUE_ID,
			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_RUR  * (1.00000/@USDRATE)
				when @Valuta = 'EUR' then VALUE_RUR  * (1.00000/@EURORATE)
				else VALUE_RUR
			end,
			CLASS
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