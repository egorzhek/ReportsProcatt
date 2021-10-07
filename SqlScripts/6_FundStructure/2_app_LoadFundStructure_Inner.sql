CREATE OR ALTER PROCEDURE [dbo].[app_LoadFundStructure_Inner]
(
    @Contract_id Int,
    @ParamDate Date
)
AS BEGIN
    SET DATEFORMAT DMY;

    DECLARE @CurrentDate Date = GetDate();
    DECLARE @LastEndDate Date = DateAdd(DAY, -180, @CurrentDate);


    -----для проверки, данный блок надо расскоментировать
    DECLARE @INVESTOR INT = null            ;       -- Инвестор (множество инветоров) (ID субъектов) перечисленных через запятую (может быть пустым);
    DECLARE @CONTRACT INT =  @Contract_id  ;            ;       -- Множество портфелей (договоров, пулов, множеств) перечисленных через запятую (может быть пустым); если множество портфелей пустое, то выбираются данные всех портфелей указанных в первом параметре инвесторов; не могут быть одновременно пустыми и первый, и второй параметр;
    DECLARE @P_DATE DATETIME = @ParamDate; -- дата со временем, на которую надо получить содержимое портфеля; данные получаются на указанную в этом параметре секунду (т.е. на начало этой секунды); таким образом если время указывается нулевое (параметр содержит только дату), то все котировки, номиналы и другие показатели берутся за предыдущий день; т.е. начало суток есть синоним конца предыдущих суток;


    DECLARE @R_RATER INT = null;                -- Котировщик, используем данные из договора (портфеля);
    DECLARE @R_MODE INT = null;             -- Способ взятия котировки (null - используется способ указанный в договоре (портфеле));
    DECLARE @P_FLAGS INT = (2+8);

    -- чистка обоих кэшей
    DELETE FROM [dbo].[FundStructure_Last]
    WHERE [Contract_Id] = @Contract_id and [PortfolioDate] = @ParamDate;

    DELETE FROM [dbo].[FundStructure]
    WHERE [Contract_Id] = @Contract_id and [PortfolioDate] = @ParamDate;

    begin try
        drop table #INVESTMENT;
    end try
    begin catch
    end catch

    CREATE TABLE #INVESTMENT
    (
        [Contract_Id] [int] NULL,
        [PortfolioDate] [date] NULL,
        [Investor_Id] [int] NULL,
        [INVESTMENT] [NVarchar](400) NULL,
        [VALUE_ID] [int] NULL,
        [BAL_ACC] [int] NULL,
        [CLASS] [int] NULL,
        [AMOUNT] [numeric](28, 10) NULL,
        [BAL_SUMMA_RUR] [numeric](28, 10) NULL,
        [Bal_Delta] [numeric](28, 10) NULL,
        [NOMINAL] [numeric](28, 10) NULL,
        [RUR_PRICE] [numeric](28, 10) NULL,
        [Nom_Price] [numeric](28, 10) NULL,
        [VALUE_RUR] [numeric](28, 10) NULL,
        [VALUE_NOM] [numeric](28, 10) NULL,
        [CUR_ID] [int] NULL,
        [CUR_NAME] [Nvarchar](100) NULL,
        [RATE] [numeric](28, 10) NULL,
        [RATE_DATE] [datetime] NULL
    );



    INSERT INTO #INVESTMENT
    (
        [Contract_Id],
        [PortfolioDate],
        [Investor_Id],
        [INVESTMENT],
        [VALUE_ID],
        [BAL_ACC],
        [CLASS],
        [AMOUNT],
        [BAL_SUMMA_RUR],
        [Bal_Delta],
        [NOMINAL],
        [RUR_PRICE],
        [Nom_Price],
        [VALUE_RUR],
        [VALUE_NOM],
        [CUR_ID],
        [CUR_NAME],
        [RATE],
        [RATE_DATE]
    )
    SELECT
        P.CONTR as Contract_Id, -- ИД портфеля (Если 0 - это фонд)
        cast(@P_DATE as Date) as PortfolioDate,
        C.INVESTOR as Investor_Id, -- Идентификатор инвестора
        INVESTMENT, -- краткое описание позиции портфеля;
        VALUE_ID, -- ID  позиции портфеля;
        BAL_ACC,  -- ID балансового счёта;
        case
            when BAL_ACC=2820 then 100
            when BAL_ACC in (2774, 2925) then 101
            else s.class
        end as CLASS,  -- Тип позиции (2 - облигация, 1 - акция, 7 - расписка, 3 - вексель,  100 - Денежные средства у брокера, 101 - Прочие вложения)
        AMOUNT, -- количество ценных бумаг, валюты, контрактов или другого имущества;
        BAL_SUMMA as BAL_SUMMA_RUR, -- балансовая стоимость по позиции с переоценкой;
        Bal_Delta,
        S.NOMINAL, -- Номинал (В валюте номинала)
        RUR_PRICE , --стоимость одной позиции в рублях
        ROUND(RUR_PRICE/Cur.RATE/Cur.CNT,6)  Nom_Price, --стоимость одной позиции в валюте номинвала
        RUR_RATE as VALUE_RUR, -- оценка имущества в национальной валюте;
        ROUND(RUR_RATE/Cur.RATE/Cur.CNT, 6) as VALUE_NOM, -- оценка имущества в валюте инструмента;
        ISNULL(S.NOM_VAL,P.VALUE_ID) CUR_ID, -- Валюта номина
        VC.[SYSNAME] as CUR_NAME, -- Код валюты номинала
        Cur.RATE/Cur.CNT RATE, -- Курс валюты номинала к рублю
        Cur.OFICDATE RATE_DATE -- Дата котировки курса
    FROM [BAL_DATA_STD].[dbo].PR_B_PORTFOLIO(@INVESTOR, @CONTRACT, @P_DATE, @P_FLAGS, @R_MODE, @R_RATER) P
    LEFT JOIN [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS C WITH(NOLOCK) ON P.CONTR = C.DOC
    LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS V WITH(NOLOCK) ON V.ID = P.VALUE_ID
    LEFT JOIN [BAL_DATA_STD].[dbo].OD_SHARES AS S WITH(NOLOCK) ON S.SELF_ID = p.VALUE_ID AND S.E_DATE > @P_DATE AND S.B_DATE < @P_DATE
    CROSS APPLY [BAL_DATA_STD].[dbo].PR_GET_RATE( ISNULL(S.NOM_VAL,P.VALUE_ID),DATEADD(day,-1,@P_DATE),null,null) Cur
    LEFT JOIN [BAL_DATA_STD].[dbo].OD_VALUES AS VC WITH(NOLOCK) ON VC.ID = ISNULL(S.NOM_VAL,P.VALUE_ID)
    WHERE CONTR > 0 --Отбросим паевые фонды.
    --and BAL_ACC in (2774,2925,2820)
    and BAL_ACC not in (2814) --убираем НДФЛ из списка портфеля


    -- проливаем INVESTMENT
    INSERT INTO [dbo].[InvestmentIds] ([Investment])
    select
        R.[INVESTMENT]
    from
    (
        -- источник содержит уникальные ненуловые значения
        select INVESTMENT
        From #INVESTMENT
        WHERE INVESTMENT IS NOT NULL
        GROUP BY INVESTMENT
    ) AS R
    LEFT JOIN [dbo].[InvestmentIds] AS T ON R.INVESTMENT = T.[Investment] -- таблица тоже содержит уникальные значения
    WHERE T.[Id] IS NULL;

    -- заполняем один из кэшей
    if @ParamDate < @LastEndDate
    BEGIN
        INSERT INTO [dbo].[FundStructure]
        (
            [Contract_Id],
            [PortfolioDate],
            [Investor_Id],
            [Investment_id],
            [VALUE_ID],
            [BAL_ACC],
            [CLASS],
            [AMOUNT],
            [BAL_SUMMA_RUR],
            [Bal_Delta],
            [NOMINAL],
            [RUR_PRICE],
            [Nom_Price],
            [VALUE_RUR],
            [VALUE_NOM],
            [CUR_ID],
            [RATE],
            [RATE_DATE]
        )
        select
            a.Contract_Id,
            a.PortfolioDate,
            a.Investor_Id,
            Investment_id = b.id,
            a.VALUE_ID,
            a.BAL_ACC,
            a.CLASS,
            a.AMOUNT,
            a.BAL_SUMMA_RUR,
            a.Bal_Delta,
            a.NOMINAL,
            a.RUR_PRICE,
            a.Nom_Price,
            a.VALUE_RUR,
            a.VALUE_NOM,
            a.CUR_ID,
            a.RATE,
            a.RATE_DATE
        from #INVESTMENT as a
        join [dbo].[InvestmentIds] as b on a.INVESTMENT = b.Investment;
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[FundStructure_Last]
        (
            [Contract_Id],
            [PortfolioDate],
            [Investor_Id],
            [Investment_id],
            [VALUE_ID],
            [BAL_ACC],
            [CLASS],
            [AMOUNT],
            [BAL_SUMMA_RUR],
            [Bal_Delta],
            [NOMINAL],
            [RUR_PRICE],
            [Nom_Price],
            [VALUE_RUR],
            [VALUE_NOM],
            [CUR_ID],
            [RATE],
            [RATE_DATE]
        )
        select
            a.Contract_Id,
            a.PortfolioDate,
            a.Investor_Id,
            Investment_id = b.id,
            a.VALUE_ID,
            a.BAL_ACC,
            a.CLASS,
            a.AMOUNT,
            a.BAL_SUMMA_RUR,
            a.Bal_Delta,
            a.NOMINAL,
            a.RUR_PRICE,
            a.Nom_Price,
            a.VALUE_RUR,
            a.VALUE_NOM,
            a.CUR_ID,
            a.RATE,
            a.RATE_DATE
        from #INVESTMENT as a
        join [dbo].[InvestmentIds] as b on a.INVESTMENT = b.Investment;
    END


    begin try
        drop table #INVESTMENT;
    end try
    begin catch
    end catch
END
GO