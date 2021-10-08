Declare
    @Date Date = @DateToSharp, 
    @Investor_Id Int = @InvestorIdSharp;

    --set @Date = DATEADD(DAY, 1, @Date);

--Declare
--   set @Date = CONVERT(Date, '01.04.2019', 103); set @Investor_Id = 2149652;
    
declare @Funds table ( FundId int);
declare @Contracts table ( ContractId int);

declare @Result table
(
    CurrencyName Nvarchar(500), VALUE_RUR decimal(28,10), AllSum decimal(28,10), Result decimal(28,10)
);

declare @Result2 table
(
    CurrencyName Nvarchar(500), VALUE_RUR decimal(28,10)
);

declare @AllSum decimal(28,10);


	-- пифы на дату окончания
    insert into @Funds (FundId)
    select
        sd.FundId
    from
    (
        select
            FundId
        From [dbo].[InvestorFundDate]
        where Investor = @Investor_Id and [Date] = @Date
        union all
        select
            FundId
        From [dbo].[InvestorFundDateLast]
        where Investor = @Investor_Id and [Date] = @Date
    ) as sd
    --left join FundNames as fn on sd.FundId = fn.Id
    group by sd.FundId;


insert into @Result2
(
    CurrencyName, VALUE_RUR
)
select
    CurrencyName, VALUE_RUR = sum(VALUE_RUR)
from
(
    select
        Inv.CurrencyName,
        res.VALUE_RUR
    from
    (
		select
            CUR_ID = 1, VALUE_RUR = [dbo].f_Round(SumAmount * RATE, 2) , CLASS = 10
        from @Funds as f
        join [dbo].[InvestorFundDate] as fs with(nolock) on f.FundId = fs.FundId
        where fs.Investor = @Investor_Id and fs.[Date] = @Date
        union all
        select
            CUR_ID = 1, VALUE_RUR = [dbo].f_Round(SumAmount * RATE, 2) , CLASS = 10
        from @Funds as f
        join [dbo].[InvestorFundDateLast] as fs with(nolock) on f.FundId = fs.FundId
        where fs.Investor = @Investor_Id and fs.[Date] = @Date
    ) as res
    join [dbo].[Currencies] as Inv on res.CUR_ID = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CurrencyName;

-- Добавили Пифы
--select * from @Result;

insert into @Contracts(ContractId)
select ContractId
from
(
    select
        ContractId
    from [dbo].[PortFolio_Daily] nolock
    where InvestorId = @Investor_Id and [PortfolioDate] = @Date
    union all
    select
        ContractId
    from [dbo].[PortFolio_Daily_Last] nolock
    where InvestorId = @Investor_Id and [PortfolioDate] = @Date
) as res
group by ContractId;


insert into @Result2
(
    CurrencyName, VALUE_RUR
)
select
    CurrencyName, VALUE_RUR = sum(VALUE_RUR)
from
(
     select
        Inv.CurrencyName,
        res.VALUE_RUR
    from
    (
        select
            fs.CUR_ID, fs.VALUE_RUR, fs.CLASS
        from @Contracts as f
        join [dbo].[PortFolio_Daily] as fs with(nolock) on f.ContractId = fs.ContractId
        where fs.PortfolioDate = @Date
        union all
        select
            fs.CUR_ID, fs.VALUE_RUR, fs.CLASS
        from @Contracts as f
        join [dbo].[PortFolio_Daily_Last] as fs with(nolock) on f.ContractId = fs.ContractId
        where fs.PortfolioDate = @Date
    ) as res
    join [dbo].[Currencies] as Inv on res.CUR_ID = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by CurrencyName;

-- Общее по ПИФам и ДУ
insert into @Result
(
    CurrencyName, VALUE_RUR
)
select
    CurrencyName, VALUE_RUR = sum(VALUE_RUR)
from @Result2
group by CurrencyName;

select
    @AllSum = sum(VALUE_RUR)
from @Result;

update @Result set AllSum = @AllSum;

update @Result set Result = VALUE_RUR/AllSum;

-- Результаты
select * from @Result;

select CountRows = Count(1), AllSum = @AllSum from @Result;