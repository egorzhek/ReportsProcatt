Declare
    @Date Date = CONVERT(Date, '01.04.2019', 103), @Investor_Id Int = 2149652;
    
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
    Contract_Id
from
(
    select
        Contract_Id
    From [dbo].[FundStructure]
    where Investor_Id = @Investor_Id and [PortfolioDate] = @Date
    union all
    select
        Contract_Id
    From [dbo].[FundStructure_Last]
    where Investor_Id = @Investor_Id and [PortfolioDate] = @Date
) as sd
left join FundNames as fn on sd.Contract_Id = fn.Id
group by Contract_Id;


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
        from @Funds as f
        join [dbo].[FundStructure] as fs with(nolock) on f.FundId = fs.Contract_Id
        where fs.PortfolioDate = @Date
        union all
        select
            fs.CUR_ID, fs.VALUE_RUR, fs.CLASS
        from @Funds as f
        join [dbo].[FundStructure] as fs with(nolock) on f.FundId = fs.Contract_Id
        where fs.PortfolioDate = @Date
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