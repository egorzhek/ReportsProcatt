Declare
    @EndDate Date = @DateToSharp, 
    @Investor_Id Int = @InvestorIdSharp;
--    set @Investor_Id = 2149652; set @EndDate = CONVERT(Date, '01.04.2018', 103);

    set @EndDate = DATEADD(DAY, 1, @EndDate);

    declare @Funds table ( FundId int);
    declare @Contracts table ( ContractId int);

    declare @Result table
    (
        CategoryName Nvarchar(300), VALUE_RUR decimal(28,10), AllSum decimal(28,10), Result decimal(28,10), CategoryId int
    )

    declare @FundAllSum decimal(28,10), @AllSum decimal(28,10);
    
    -- пифы на дату окончания
    insert into @Funds (FundId)
    select
        Contract_Id
    from
    (
        select
            Contract_Id
        From [dbo].[FundStructure]
        where Investor_Id = @Investor_Id and [PortfolioDate] = @EndDate
        union all
        select
            Contract_Id
        From [dbo].[FundStructure_Last]
        where Investor_Id = @Investor_Id and [PortfolioDate] = @EndDate
    ) as sd
    left join FundNames as fn on sd.Contract_Id = fn.Id
    group by Contract_Id;

    select
        top 1 @FundAllSum = AllSum
    from
    (
        select
            c.CategoryName,
            res.VALUE_RUR,
            AllSum = sum(res.VALUE_RUR) over()
        from
        (
            select
                fs.Contract_Id, fs.VALUE_RUR, fs.Investment_id, fs.CLASS
            from @Funds as f
            join [dbo].[FundStructure] as fs with(nolock) on f.FundId = fs.Contract_Id
            where fs.PortfolioDate = @EndDate
            union all
            select
                fs.Contract_Id, fs.VALUE_RUR, fs.Investment_id, fs.CLASS
            from @Funds as f
            join [dbo].[FundStructure_Last] as fs with(nolock) on f.FundId = fs.Contract_Id
            where fs.PortfolioDate = @EndDate
        ) as res
        join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
        join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
        join [dbo].[Categories] as c on cs.CategoryId = c.Id
    ) as res2;

    if @FundAllSum is null set @FundAllSum = 0;

    -- вся эта сумма пойдёт в фонды
    --select @FundAllSum;

    insert into @Contracts(ContractId)
    select ContractId
    from
    (
        select
            ContractId
        from [dbo].[PortFolio_Daily] nolock
        where InvestorId = @Investor_Id and [PortfolioDate] = @EndDate
        union all
        select
            ContractId
        from [dbo].[PortFolio_Daily_Last] nolock
        where InvestorId = @Investor_Id and [PortfolioDate] = @EndDate
    ) as res
    group by ContractId;

    --select * From @Contracts
    insert into @Result
    (
        CategoryName, VALUE_RUR, AllSum, Result, CategoryId
    )
    select
        CategoryName, VALUE_RUR = sum(VALUE_RUR), AllSum, Result = sum(VALUE_RUR)/AllSum, CategoryId
    from
    (
        select
            c.CategoryName,
            res.VALUE_RUR,
            AllSum = sum(res.VALUE_RUR) over() + @FundAllSum,
            CategoryId = c.Id
        from
        (
            select
                fs.VALUE_RUR, fs.InvestmentId, fs.CLASS
            from @Contracts as f
            join [dbo].[PortFolio_Daily] as fs with(nolock) on f.ContractId = fs.ContractId
            where [PortfolioDate] = @EndDate
            union all
            select
                fs.VALUE_RUR, fs.InvestmentId, fs.CLASS
            from @Contracts as f
            join [dbo].[PortFolio_Daily_Last] as fs with(nolock) on f.ContractId = fs.ContractId
            where [PortfolioDate] = @EndDate
        ) as res
        join [dbo].[InvestmentIds] as Inv on res.InvestmentId = Inv.Id
        join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
        join [dbo].[Categories] as c on cs.CategoryId = c.Id
    ) as res2
    where VALUE_RUR > 0
    group by CategoryName, AllSum, CategoryId;

    if @FundAllSum > 0
    and exists
    (
        select top 1 1 from @Result
    )
    begin
        select top 1
            @AllSum = AllSum
        from @Result

        if exists
        (
            select top 1 1
            from @Result
            where CategoryId = 5
        )
        begin
            update @Result
                set VALUE_RUR = VALUE_RUR + @FundAllSum
            where CategoryId = 5;

            update @Result
                set Result = VALUE_RUR/AllSum
            where CategoryId = 5;
        end
        else
        begin
            insert into @Result (CategoryName, VALUE_RUR, AllSum, CategoryId)
            select N'‘онды', @FundAllSum, @AllSum, 5;

            update @Result
                set Result = VALUE_RUR/AllSum
            where CategoryId = 5;
        end
    end

    if exists
    (
        select top 1 1 from @Result
    )
    begin
        select top 1
            @AllSum = AllSum
        from @Result
    end

    -- результаты
    select * from @Result;

    select CountRows = Count(1), AllSum = @AllSum from @Result;