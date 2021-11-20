Declare
    @Date Date = @DateToSharp, 
    @Contract_Id Int = @FundIdSharp,
    @Valuta Nvarchar(10) = @ValutaSharp;

	if @Valuta is null set @Valuta = 'RUB';

    --set @Date = DATEADD(DAY, 1, @Date);
--
--Declare
--    @Date Date = CONVERT(Date, '31.01.2009', 103),
--    @Contract_Id Int = 17593;

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

Declare @Contract_Id2 Int;

select
	@Contract_Id2 = a.FundId
from FundNames as a
where a.Id = @Contract_Id;

if @Contract_Id2 is not null set @Contract_Id = @Contract_Id2;


select
    CategoryName, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum, @Valuta as CurrencyName
from
(
    select
        c.CategoryName,
        res.VALUE_RUR,
        AllSum = sum(res.VALUE_RUR) over()
    from
    (
        select
            Contract_Id,
			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_RUR  * (1.00000/@USDRATE)
				when @Valuta = 'EUR' then VALUE_RUR  * (1.00000/@EURORATE)
				else VALUE_RUR
			end,
			Investment_id,
			CLASS
        from [dbo].[FundStructure] nolock
        where Investor_Id = @Contract_Id and PortfolioDate = @Date
        union all
        select
            Contract_Id,
			VALUE_RUR =
			case
				when @Valuta = 'RUB' then VALUE_RUR
				when @Valuta = 'USD' then VALUE_RUR  * (1.00000/@USDRATE)
				when @Valuta = 'EUR' then VALUE_RUR  * (1.00000/@EURORATE)
				else VALUE_RUR
			end,
			Investment_id,
			CLASS
        from [dbo].[FundStructure_Last] nolock
        where Investor_Id = @Contract_Id and PortfolioDate = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CategoryName, AllSum;