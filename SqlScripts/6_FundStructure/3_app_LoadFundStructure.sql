CREATE OR ALTER PROCEDURE [dbo].[app_LoadFundStructure]
(
    @Contract_id Int
)
AS BEGIN
    SET DATEFORMAT DMY;
    SET NOCOUNT ON;

    declare @MinWirDate Date, @MaxWirDate Date, @CurrDate Date, @ErrorMessage Nvarchar(max);

    set @CurrDate = cast (GETDATE() as Date);


    select
        @MinWirDate = min(WIRDATE), @MaxWirDate = max(WIRDATE)
    from
    (
        select
            WIRDATE = cast (T.WIRDATE as Date)
        from
        [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C
        join [BAL_DATA_STD].[dbo].OD_RESTS AS R on R.REG_3 = C.DOC
        join [BAL_DATA_STD].[dbo].OD_TURNS T on T.REST = R.ID
        where C.DOC = @Contract_id
        and DATEPART(Year, T.WIRDATE) < 9999
    ) as d;


    if @MinWirDate is null return;
    if @MaxWirDate is null return;
    if DATEDIFF(DAY, @MaxWirDate, @CurrDate) > 90 return; -- 90 дней не было движений - ничего не грузим

    if @CurrDate > @MaxWirDate set @MaxWirDate = @CurrDate; -- доподнятие максимальной даты до текущего дня





    -- если в постоянном кеше нет записей, то делаем полную заливку

    -- если в постоянном кеше есть записи, то перегружаем за последние 190 дней
    -- Получится 10 дней постоянного кэша и 180 дней временного кэша
    -- нужно будет скорректировать @MinWirDate

    DECLARE @CurrentDate Date = GetDate();
    DECLARE @LastEndDate Date = DateAdd(DAY, -190, @CurrentDate);

    if exists
    (
        select top 1 1 from [dbo].[FundStructure]
        where Contract_Id = @Contract_id
    )
    begin
        set @MinWirDate = @LastEndDate;
    end




    begin try
        drop table #SDates;
    end try
    begin catch
    end catch;


    CREATE TABLE #SDates
    (
        [WIRDATE] Date NULL
    );


    while @MinWirDate <= @MaxWirDate
    begin
        insert into #SDates ([WIRDATE]) values (@MinWirDate);

        set @MinWirDate = DATEADD(DAY, 1, @MinWirDate);
    end

    -- курсор
    declare mycur cursor fast_forward for
        select WIRDATE
        from #SDates
        order by WIRDATE
    open mycur
    fetch next from mycur into @MinWirDate
    while @@FETCH_STATUS = 0
    begin
        BEGIN TRY
            EXEC [dbo].[app_LoadFundStructure_Inner]
                @Contract_id = @Contract_id,
                @ParamDate = @MinWirDate
        END TRY
        BEGIN CATCH
            SET @ErrorMessage = N'app_LoadFundStructure_Inner: ' + ERROR_MESSAGE()

            INSERT INTO [dbo].[ProcessorErrors]
            (Error, ContractId, Investor_id, PDate)
            VALUES (@ErrorMessage, @Contract_id, NULL, @MinWirDate);
        END CATCH

        fetch next from mycur into @MinWirDate
    end
    close mycur
    deallocate mycur;

    begin try
        drop table #SDates;
    end try
    begin catch
    end catch;
END
GO