DECLARE @ToDateStr     Nvarchar(50) = @DateToSharp;
DECLARE @FromDateStr   Nvarchar(50) = @DateFromSharp;
DECLARE @InvestorIdStr Nvarchar(50) = @InvestorIdSharp;
DECLARE @FundIdStr     Nvarchar(50) = @FundIdSharp;
DECLARE @Valuta        Nvarchar(10) = @ValutaSharp;

if @Valuta is null set @Valuta = 'RUB';

DECLARE
    @Investor int = CAST(@InvestorIdStr as Int),
    @FundId int = CAST(@FundIdStr as Int),
    @StartDate Date = CONVERT(Date, @FromDateStr, 103),
    @EndDate Date = CONVERT(Date, @ToDateStr, 103);

SET NOCOUNT ON;


Declare @SItog numeric(30,10), @AmountDayMinus_RUR numeric(30,10), @Snach numeric(30,10), @AmountDayPlus_RUR numeric(30,10),
@InvestResult numeric(30,10), @AllPlus_RUR numeric(30,10), @AllMinus_RUR numeric(30,10), @EndSumAmount numeric(30,7),
@FundName NVarchar(300), @InvestorName NVarchar(300);

declare @MinDate date, @MaxDate date, @LS_NUM nvarchar(120), @MaxDate1 date;
  
DECLARE	@CurrDate Date = isnull(CONVERT(Date, @ToDateStr, 103), GetDate());


SELECT
    @MinDate = min([Date]),
    @MaxDate = max([Date]),
    @LS_NUM  = min([LS_NUM])
FROM
(
    SELECT [Date], [LS_NUM]
    FROM [dbo].[InvestorFundDate] NOLOCK
    WHERE Investor = @Investor and FundId = @FundId
    UNION
    SELECT [Date], [LS_NUM]
    FROM [dbo].[InvestorFundDateLast] NOLOCK
    WHERE Investor = @Investor and FundId = @FundId
) AS R

-------Берем даты из ДУ для минимальной и максимальной дат
SELECT
	@MaxDate1 = max([Date])
FROM
(
	SELECT a.[Date]
	FROM [dbo].[Assets_Contracts] as a with(nolock)
	join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId
	where a.InvestorId = @Investor and b.DATE_CLOSE >= @CurrDate
	UNION
	SELECT a.[Date]
	FROM [dbo].[Assets_ContractsLast] as a with(nolock)
	join [dbo].[Assets_Info] as b with(nolock) on a.InvestorId = b.InvestorId and a.ContractId = b.ContractId
	where a.InvestorId = @Investor and b.DATE_CLOSE >= @CurrDate
) AS R

----------------Новое условие ограничения даты----------

if @MaxDate1 is not null and @MaxDate1 < @MaxDate set @MaxDate=@MaxDate1
--------------------------------------------------------


if @StartDate is null set @StartDate = @MinDate;
if @StartDate < @MinDate set @StartDate = @MinDate;
if @StartDate > @MaxDate set @StartDate = @MinDate;

if @EndDate is null    set @EndDate = @MaxDate;
if @EndDate > @MaxDate set @EndDate = @MaxDate;
if @EndDate < @MinDate set @EndDate = @MaxDate;


declare @PortfolioDateMax Date

select
	@PortfolioDateMax = max(PortfolioDate)
from
(
	select PortfolioDate = max(PortfolioDate)
	from [dbo].[PortFolio_Daily] pd with(nolock)
	inner join Assets_Info ai on pd.ContractId=ai.ContractId and ai.DATE_CLOSE>=@EndDate
	where pd.InvestorId = @Investor 
	union all
	select PortfolioDate = max(PortfolioDate)
	from [dbo].[PortFolio_Daily_Last] pdl with(nolock)
	inner join Assets_Info ai on pdl.ContractId=ai.ContractId and ai.DATE_CLOSE>=@EndDate
	where pdl.InvestorId = @Investor
) as res

if @PortfolioDateMax is not null
begin
	if @EndDate > @PortfolioDateMax
	begin
		set @EndDate = @PortfolioDateMax;
	end
end



if @StartDate = @EndDate
begin
    select [Error] = 'Даты равны'
    return;
end

BEGIN TRY
    DROP TABLE #ResInv
END TRY
BEGIN CATCH
END CATCH;


SELECT *
INTO #ResInv
FROM
(
    SELECT
		Investor, FundId, Date, AmountDay, SumAmount,
		RATE, USDRATE, EVRORATE,
		VALUE_RUR =
		case
			when @Valuta = 'RUB' then VALUE_RUR
			when @Valuta = 'USD' then VALUE_USD
			when @Valuta = 'EUR' then VALUE_EVRO
			else VALUE_RUR
		end,
		VALUE_USD, VALUE_EVRO,
		AmountDayPlus,
		AmountDayPlus_RUR = 
		case
			when @Valuta = 'RUB' then AmountDayPlus_RUR
			when @Valuta = 'USD' then AmountDayPlus_USD
			when @Valuta = 'EUR' then AmountDayPlus_EVRO
			else AmountDayPlus_RUR
		end
		,
			AmountDayPlus_USD, AmountDayPlus_EVRO,
		AmountDayMinus,
		AmountDayMinus_RUR =
		case
			when @Valuta = 'RUB' then AmountDayMinus_RUR
			when @Valuta = 'USD' then AmountDayMinus_USD
			when @Valuta = 'EUR' then AmountDayMinus_EVRO
			else AmountDayMinus_RUR
		end
		,
			AmountDayMinus_USD, AmountDayMinus_EVRO,
		LS_NUM
    FROM [dbo].[InvestorFundDate] NOLOCK
    WHERE Investor = @Investor and FundId = @FundId
    UNION
    SELECT
		Investor, FundId, Date, AmountDay, SumAmount,
		RATE, USDRATE, EVRORATE,
		VALUE_RUR =
		case
			when @Valuta = 'RUB' then VALUE_RUR
			when @Valuta = 'USD' then VALUE_USD
			when @Valuta = 'EUR' then VALUE_EVRO
			else AmountDayPlus_RUR
		end,
		VALUE_USD, VALUE_EVRO,
		AmountDayPlus,
		AmountDayPlus_RUR = 
		case
			when @Valuta = 'RUB' then AmountDayPlus_RUR
			when @Valuta = 'USD' then AmountDayPlus_USD
			when @Valuta = 'EUR' then AmountDayPlus_EVRO
			else AmountDayPlus_RUR
		end
		,
			AmountDayPlus_USD, AmountDayPlus_EVRO,
		AmountDayMinus,
		AmountDayMinus_RUR =
		case
			when @Valuta = 'RUB' then AmountDayMinus_RUR
			when @Valuta = 'USD' then AmountDayMinus_USD
			when @Valuta = 'EUR' then AmountDayMinus_EVRO
			else AmountDayMinus_RUR
		end
		,
			AmountDayMinus_USD, AmountDayMinus_EVRO,
		LS_NUM
    FROM [dbo].[InvestorFundDateLast] NOLOCK
    WHERE Investor = @Investor and FundId = @FundId
) AS R
WHERE [Date] >= @StartDate and [Date] <= @EndDate
--ORDER BY [Date]

-----------------------------------------------
-- преобразование на начальную и последнюю дату

-- забыть вводы выводы на первую дату
update #ResInv set
    AmountDayPlus  = 0, AmountDayPlus_RUR  = 0, AmountDayPlus_USD  = 0, AmountDayPlus_EVRO  = 0,
    AmountDayMinus = 0, AmountDayMinus_RUR = 0, AmountDayMinus_USD = 0, AmountDayMinus_EVRO = 0,
    AmountDay = 0
where [Date] = @StartDate
and AmountDay <> 0 -- вводы и выводы были в этот день


-- посчитать последний день обратно
update #ResInv set
    SumAmount = SumAmount - AmountDay
where [Date] = @EndDate
and AmountDay <> 0 -- вводы и выводы были в этот день

update #ResInv set
    VALUE_RUR = [dbo].f_Round(SumAmount * RATE, 2),
    VALUE_USD = [dbo].f_Round(SumAmount * RATE * 1.00000/USDRATE, 2),
    VALUE_EVRO = [dbo].f_Round(SumAmount * RATE * 1.00000/EVRORATE, 2),
    AmountDayPlus  = 0, AmountDayPlus_RUR  = 0, AmountDayPlus_USD  = 0, AmountDayPlus_EVRO  = 0,
    AmountDayMinus = 0, AmountDayMinus_RUR = 0, AmountDayMinus_USD = 0, AmountDayMinus_EVRO = 0,
    AmountDay = 0
where [Date] = @EndDate
and AmountDay <> 0 -- вводы и выводы были в этот день

-- преобразование на начальную и последнюю дату
-----------------------------------------------

-- В рублях

-- Итоговая оценка инвестиций

SELECT
    @SItog = VALUE_RUR
FROM #ResInv
where [Date] = @EndDate

SELECT
    @Snach = VALUE_RUR
FROM #ResInv
where [Date] = @StartDate



-- сумма всех выводов средств
SELECT
    @AmountDayMinus_RUR = sum(AmountDayMinus_RUR), -- отрицательное значение
    @AmountDayPlus_RUR = sum(AmountDayPlus_RUR) 
FROM #ResInv

set @InvestResult =
(@SItog - @AmountDayMinus_RUR) -- минус, потому что отрицательное значение
- (@Snach + @AmountDayPlus_RUR) --as 'Результат инвестиций'


set @AllPlus_RUR = @AmountDayPlus_RUR;
set @AllMinus_RUR = @AmountDayMinus_RUR;
    
    
    
    declare @DateCur date, @AmountDayPlus_RURCur numeric(30,10), @AmountDayMinus_RURCur numeric(30,10), @LastDate date,
        @SumAmountDay_RUR numeric(30,10) = 0, @Counter Int = 0, @T Int, @SumT numeric(30,10) = 0, @ResutSum numeric(30,10) = 0
    
    declare obj_cur cursor local fast_forward for
        -- 
        SELECT
            [Date], [AmountDayPlus_RUR], [AmountDayMinus_RUR]
        FROM #ResInv
        where ([Date] in (@StartDate, @EndDate) or [AmountDay] <> 0)
        order by [Date]
    open obj_cur
    fetch next from obj_cur into
        @DateCur, @AmountDayPlus_RUR, @AmountDayMinus_RUR
    while(@@fetch_status = 0)
    begin
        set @Counter += 1;
        
        -- начальную дату пропускаем
        if @DateCur = @StartDate
        begin
            set @LastDate = @DateCur
        end
        else
        begin
            -- со второй записи определяем период
            set @T = DATEDIFF(DAY, @LastDate, @DateCur);
            if @DateCur = @EndDate set @T = @T + 1;
            
            set @ResutSum += @T * (@Snach + @SumAmountDay_RUR)
            
            set @LastDate = @DateCur
            set @SumAmountDay_RUR = @SumAmountDay_RUR + @AmountDayPlus_RUR + @AmountDayMinus_RUR
            
            set @SumT += @T;
        end
        
        fetch next from obj_cur into
            @DateCur, @AmountDayPlus_RUR, @AmountDayMinus_RUR
    end
    close obj_cur
    deallocate obj_cur
    
    set @ResutSum = @ResutSum/@SumT
    
    select
        @EndSumAmount = SumAmount
    from #ResInv
    where [Date] = @EndDate
    
    SELECT
        @FundName = [Name]
    FROM [dbo].[FundNames]
    WHERE [Id] = @FundId;
    
	/*
    SELECT TOP 1
        @InvestorName = FF.[NAME]
    FROM [BAL_DATA_STD].[dbo].D_B_CONTRACTS AS CC
    INNER JOIN [BAL_DATA_STD].[dbo].OD_FACES AS FF ON FF.SELF_ID = CC.INVESTOR  AND FF.LAST_FLAG = 1
    WHERE CC.INVESTOR = @Investor;
	*/
    
    SELECT
    [ActiveDateToName] = 'Активы на ' + Replace(CONVERT(NVarchar(50), @EndDate, 103),'/','.'),
    [ActiveDateToValue] = CAST([dbo].f_Round(@SItog, 2) AS DECIMAL(30,2)),
    [ProfitName] = 'Доход за период ' + Replace(CONVERT(NVarchar(50), @StartDate, 103),'/','.') + ' - ' + Replace(CONVERT(NVarchar(50), @EndDate, 103),'/','.'),
    [ProfitValue] = CAST([dbo].f_Round(@InvestResult, 2) AS DECIMAL(30,2)),
    [ProfitProcentValue] = case when @ResutSum = 0.00 then 0.00 else CAST(Round(@InvestResult/@ResutSum * 100.000, 2) AS DECIMAL(30,2)) end,
    [OpenDate] = @MinDate,
    [LS_NUM] = @LS_NUM,
    [EndSumAmount] = @EndSumAmount,
    [FundName] = @FundName,
    [InvestorName] = @InvestorName,
	  [Valuta] = @Valuta,
    [MinDate] = @StartDate,
    [MaxDate] = @EndDate;
    
    select
        [ActiveName]  = 'Активы на ' + Replace(CONVERT(NVarchar(50), @StartDate, 103),'/','.'),
        [ActiveValue] = CAST([dbo].f_Round(@Snach, 2) AS DECIMAL(30,2)),
        [Пополнения]  = CAST([dbo].f_Round(@AllPlus_RUR, 2) AS DECIMAL(30,2)),
        [Выводы]      = CAST([dbo].f_Round(-@AllMinus_RUR, 2) AS DECIMAL(30,2)),
		[Valuta] = @Valuta;
    
    SELECT 
        B.[W_ID],
        [W_Date] = Replace(CONVERT(NVarchar(50), CAST(B.[W_Date] AS Date), 103),'/','.'),
        B.[Order_NUM],
        B.[WALK],
        B.[TYPE],
        [RATE_RUR] = Cast(B.[RATE_RUR] as decimal(30,2)),
        [Amount] = Cast(B.[Amount] as decimal(30,7)),
        [VALUE_RUR] = Cast(B.[VALUE_RUR] as decimal(30,2)),
        [Fee_RUR] = Cast(B.[Fee_RUR] as decimal(30,2)),
        C.[OperName],
		[Valuta] = 'RUB'
    FROM
    (
        SELECT * 
        FROM [dbo].[FundHistory] AS A WITH(NOLOCK)
        WHERE A.Investor = @Investor AND A.FundId = @FundId
        AND [W_Date] >= @StartDate AND [W_Date] < @EndDate
        UNION
        SELECT * 
        FROM [dbo].[FundHistoryLast] AS A WITH(NOLOCK)
        WHERE A.Investor = @Investor AND A.FundId = @FundId
        AND [W_Date] >= @StartDate AND [W_Date] < @EndDate
    ) AS B
    LEFT JOIN [dbo].[WalkTypes] AS C WITH(NOLOCK) ON B.WALK = C.WALK AND B.[TYPE] = C.[TYPE]
    ORDER BY B.[W_Date];

    select
        [Date], [RATE], [Valuta] = 'RUB'
		/*case
			when @Valuta = 'RUB' then RATE
			when @Valuta = 'USD' then USDRATE
			when @Valuta = 'EUR' then EVRORATE
			else AmountDayMinus_RUR
		end*/
    from #ResInv
    order by [Date];
    
BEGIN TRY
    DROP TABLE #ResInv
END TRY
BEGIN CATCH
END CATCH;