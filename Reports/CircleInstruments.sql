Declare
    @Date Date = @DateToSharp, 
    @Investor_Id Int = @InvestorIdSharp;

--Declare
--   @Date date = CONVERT(Date, '01.04.2019', 103), @Investor_Id INT = 2149652;
    
declare @Funds table ( FundId int);
declare @Contracts table ( ContractId int);

Declare @Tmp table
(
    Investment [NVarchar](500),
    VALUE_ID Int,
    VALUE_RUR Decimal(28,10)
);

declare @Result table
(
    Investment Nvarchar(500), VALUE_ID Int, VALUE_RUR decimal(28,10), AllSum decimal(28,10), Result decimal(28,10)
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

insert into @Tmp
(
    Investment, VALUE_ID, VALUE_RUR
)
select
    Investment, VALUE_ID, VALUE_RUR = sum(VALUE_RUR) --, AllSum, Result = sum(VALUE_RUR)/AllSum
from
(
    select
        Investment = case when c.Id = 4 then c.CategoryName else Inv.Investment end,
        VALUE_ID = case when c.Id = 4 then c.Id else res.VALUE_ID end,
        res.VALUE_RUR
        --AllSum = sum(res.VALUE_RUR) over()
    from
    (
        select
            fs.Investment_id, fs.VALUE_RUR, fs.CLASS, fs.VALUE_ID
        from @Funds as f
        join [dbo].[FundStructure] as fs with(nolock) on f.FundId = fs.Contract_Id
        where fs.PortfolioDate = @Date
        union all
        select
            fs.Investment_id, fs.VALUE_RUR, fs.CLASS, fs.VALUE_ID
        from @Funds as f
        join [dbo].[FundStructure] as fs with(nolock) on f.FundId = fs.Contract_Id
        where fs.PortfolioDate = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by Investment, VALUE_ID;


insert into @Result
(
    Investment, VALUE_ID, VALUE_RUR
)
select
    Investment = 
    case when right(rtrim(s.Investment), 5) = '; НКД'
        then left( ltrim(rtrim(s.Investment)), len (ltrim(rtrim(s.Investment))) - 5)
        else s.Investment
    end,
    s.VALUE_ID, VALUE_RUR = sum(s.VALUE_RUR)
from @Tmp as s
group by s.VALUE_ID,
    case when right(rtrim(s.Investment), 5) = '; НКД'
        then left( ltrim(rtrim(s.Investment)), len (ltrim(rtrim(s.Investment))) - 5)
        else s.Investment
    end

-- Добавили Пифы
--select * from @Result;

delete from @Tmp;




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

insert into @Tmp
(
    Investment, VALUE_ID, VALUE_RUR
)
select
    Investment, VALUE_ID, VALUE_RUR = sum(VALUE_RUR)
from
(
        select
        Investment = case when c.Id = 4 then c.CategoryName else Inv.Investment end,
        VALUE_ID = case when c.Id = 4 then c.Id else res.VALUE_ID end,
        res.VALUE_RUR
    from
    (
        select
            fs.InvestmentId, fs.VALUE_ID, fs.VALUE_RUR, fs.CLASS
        from @Contracts as f
        join [dbo].[PortFolio_Daily] as fs with(nolock) on f.ContractId = fs.ContractId
        where fs.PortfolioDate = @Date
        union all
        select
            fs.InvestmentId, fs.VALUE_ID, fs.VALUE_RUR, fs.CLASS
        from @Contracts as f
        join [dbo].[PortFolio_Daily_Last] as fs with(nolock) on f.ContractId = fs.ContractId
        where fs.PortfolioDate = @Date
    ) as res
    join [dbo].[InvestmentIds] as Inv on res.InvestmentId = Inv.Id
    join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
    join [dbo].[Categories] as c on cs.CategoryId = c.Id
) as res2
where VALUE_RUR > 0
group by Investment, VALUE_ID;

--select * from @Tmp
--order by Investment;

insert into @Result
(
    Investment, VALUE_ID, VALUE_RUR
)
select
    Investment = 
    case when right(rtrim(s.Investment), 5) = '; НКД'
        then left( ltrim(rtrim(s.Investment)), len (ltrim(rtrim(s.Investment))) - 5)
        else s.Investment
    end,
    s.VALUE_ID, VALUE_RUR = sum(s.VALUE_RUR)
from @Tmp as s
group by s.VALUE_ID,
    case when right(rtrim(s.Investment), 5) = '; НКД'
        then left( ltrim(rtrim(s.Investment)), len (ltrim(rtrim(s.Investment))) - 5)
        else s.Investment
    end
--order by 1;

select
    @AllSum = sum(VALUE_RUR)
from @Result;

update @Result set AllSum = @AllSum;

update @Result set Result = VALUE_RUR/AllSum;

-- Результаты
select * from @Result;

select CountRows = Count(1), AllSum = @AllSum from @Result;