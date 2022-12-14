Declare
    @EndDate Date = @DateToSharp, 
    @Investor_Id Int = @InvestorIdSharp,
	@Valuta Nvarchar(10) = @ValutaSharp;

	if @Valuta is null set @Valuta = 'RUB';
--    set @Investor_Id = 2149652; set @EndDate = CONVERT(Date, '01.04.2018', 103);

    --set @EndDate = DATEADD(DAY, 1, @EndDate);

    declare @Funds table (FundId int);
    declare @Contracts table ( ContractId int);

    declare @Result table
    (
        CategoryName Nvarchar(300), VALUE_RUR decimal(28,10), AllSum decimal(28,10), Result decimal(28,10), CategoryId int
    )

    declare @FundAllSum decimal(28,10), @AllSum decimal(28,10);
    
    -- пифы на дату окончания
    insert into @Funds (FundId)
    select
        sd.FundId
    from
    (
        select
            FundId
        From [dbo].[InvestorFundDate]
        where Investor = @Investor_Id and [Date] = @EndDate
        union all
        select
            FundId
        From [dbo].[InvestorFundDateLast]
        where Investor = @Investor_Id and [Date] = @EndDate
    ) as sd
    --left join FundNames as fn on sd.FundId = fn.Id
    group by sd.FundId;

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
                fs.FundId, VALUE_RUR = [dbo].f_Round((SumAmount-AmountDay) * RATE, 2) , CLASS = 10
            from @Funds as f
            join [dbo].[InvestorFundDate] as fs with(nolock) on f.FundId = fs.FundId
            where fs.Investor = @Investor_Id and fs.[Date] = @EndDate
            union all
            select
                fs.FundId, VALUE_RUR = [dbo].f_Round((SumAmount-AmountDay) * RATE, 2) , CLASS = 10
            from @Funds as f
            join [dbo].[InvestorFundDateLast] as fs with(nolock) on f.FundId = fs.FundId
            where fs.Investor = @Investor_Id and fs.[Date] = @EndDate
        ) as res
        --join [dbo].[InvestmentIds] as Inv on res.Investment_id = Inv.Id
		left join FundNames as fn on res.FundId = fn.Id
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
        where InvestorId = @Investor_Id and [PortfolioDate] =  @EndDate
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
            where fs.InvestorId = @Investor_Id and [PortfolioDate] =  @EndDate
            union all
            select
                fs.VALUE_RUR, fs.InvestmentId, fs.CLASS
            from @Contracts as f
            join [dbo].[PortFolio_Daily_Last] as fs with(nolock) on f.ContractId = fs.ContractId
            where fs.InvestorId = @Investor_Id and [PortfolioDate] =  @EndDate
        ) as res
        join [dbo].[InvestmentIds] as Inv on res.InvestmentId = Inv.Id
        join [dbo].[ClassCategories] as cs on res.CLASS = cs.ClassId
        join [dbo].[Categories] as c on cs.CategoryId = c.Id
    ) as res2
    where VALUE_RUR > 0
    group by CategoryName, AllSum, CategoryId;

    if @FundAllSum > 0
    begin
        select top 1
            @AllSum = AllSum
        from @Result

		if @AllSum is null set @AllSum = @FundAllSum;

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
            select N'Фонды', @FundAllSum, @AllSum, 5;

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
		where ac.[Date] = @EndDate
		union
		select top 1
			ac.USDRATE, ac.EURORATE
		from [dbo].[Assets_ContractsLast] as ac
		where ac.[Date] = @EndDate
	) as r

	-- результаты
    select
		CategoryName,
		VALUE_RUR =
		case
			when @Valuta = 'RUB' then VALUE_RUR
			when @Valuta = 'USD' then VALUE_RUR * (1.00000/@USDRATE)
			when @Valuta = 'EUR' then VALUE_RUR * (1.00000/@EURORATE)
			else VALUE_RUR
		end,
		AllSum =
		case
			when @Valuta = 'RUB' then AllSum
			when @Valuta = 'USD' then AllSum * (1.00000/@USDRATE)
			when @Valuta = 'EUR' then AllSum * (1.00000/@EURORATE)
			else AllSum
		end,
		Result,
		CategoryId
	from @Result;

	--if @Valuta = 'RUB'
	if @Valuta = 'USD' set @AllSum = @AllSum  * (1.00000/@USDRATE)
	if @Valuta = 'EUR' set @AllSum = @AllSum  * (1.00000/@EURORATE)

    select CountRows = Count(1), AllSum = @AllSum from @Result;