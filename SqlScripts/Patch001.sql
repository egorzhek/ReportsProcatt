USE CacheDB
  GO

CREATE OR ALTER VIEW vAssets_Contracts AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM Assets_Contracts
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM Assets_ContractsLast
GO

CREATE OR ALTER VIEW vInvestorFundDate AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM InvestorFundDate
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM InvestorFundDateLast
GO

CREATE OR ALTER VIEW vDIVIDENDS_AND_COUPONS_History AS
SELECT *, CAST(1 AS BIT) IsArchive FROM DIVIDENDS_AND_COUPONS_History
UNION ALL
SELECT *, CAST(0 AS BIT) IsArchive FROM DIVIDENDS_AND_COUPONS_History_Last 
GO

CREATE OR ALTER VIEW vPOSITION_KEEPING AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM POSITION_KEEPING
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM POSITION_KEEPING_Last
GO

CREATE OR ALTER VIEW vOperations_History_Contracts  AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM Operations_History_Contracts
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM Operations_History_Contracts_Last
GO

CREATE OR ALTER VIEW vPortFolio_Daily AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM PortFolio_Daily
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM PortFolio_Daily_Last
GO

CREATE OR ALTER VIEW vFundHistory AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM FundHistory
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM FundHistoryLast
GO

CREATE OR ALTER VIEW vFundStructure AS
SELECT *, CAST(1 AS BIT) AS IsArchive FROM FundStructure
UNION ALL
SELECT *, CAST(0 AS BIT) AS IsArchive FROM FundStructure_Last
GO


CREATE OR ALTER FUNCTION ContractsData
( 
    @Investor_Id  INT,
    @Currency     VARCHAR(3)  = NULL,    
    @DateFrom     DATE        = NULL,
    @DateTo       DATE        = NULL
)
RETURNS TABLE AS RETURN
SELECT 
    InvestorId,
    ContractId,
    Date,
    
    VALUE = CASE
  		WHEN @Currency = 'USD' then VALUE_USD
  		WHEN @Currency = 'EUR' then VALUE_EURO
  		ELSE VALUE_RUR
    END,
    
    INPUT_VALUE = CASE
  		WHEN @Currency = 'USD' then INPUT_VALUE_USD
  		WHEN @Currency = 'EUR' then INPUT_VALUE_EURO
  		ELSE INPUT_VALUE_RUR
  	END,
    
    OUTPUT_VALUE = CASE
  		WHEN @Currency = 'USD' then OUTPUT_VALUE_USD
  		WHEN @Currency = 'EUR' then OUTPUT_VALUE_EURO
  		ELSE OUTPUT_VALUE_RUR
  	END,
    
    INPUT_DIVIDENTS = CASE
  		WHEN @Currency = 'USD' then INPUT_DIVIDENTS_USD
  		WHEN @Currency = 'EUR' then INPUT_DIVIDENTS_EURO
  		ELSE INPUT_DIVIDENTS_RUR
  	END,
    
    INPUT_COUPONS = CASE
  		WHEN @Currency = 'USD' then INPUT_COUPONS_USD
  		WHEN @Currency = 'EUR' then INPUT_COUPONS_EURO
		ELSE INPUT_COUPONS_RUR
    END,
    
    ISPIF = CAST(0 AS BIT),

    LS_NUM = CAST(NULL AS NVARCHAR(120)),
    SumAmount = CAST(NULL AS NUMERIC(38, 10))
FROM vAssets_Contracts  A
WHERE InvestorId = @Investor_Id
  AND (Date >= @DateFrom OR @DateFrom IS NULL) 
  AND (Date <= @DateTo OR @DateTo IS NULL)

UNION ALL

SELECT 
    Investor,
    FundId,
    Date,
    
    VALUE = CASE
  		WHEN @Currency = 'USD' then VALUE_USD
  		WHEN @Currency = 'EUR' then VALUE_EVRO
  		ELSE VALUE_RUR
    END,
    
    INPUT_VALUE = CASE
  		WHEN @Currency = 'USD' then AmountDayPlus_USD
  		WHEN @Currency = 'EUR' then AmountDayPlus_EVRO
  		ELSE AmountDayPlus_RUR
  	END,
    
    OUTPUT_VALUE = CASE
  		WHEN @Currency = 'USD' then AmountDayMinus_USD
  		WHEN @Currency = 'EUR' then AmountDayMinus_EVRO
  		ELSE AmountDayMinus_RUR
  	END,

    INPUT_DIVIDENTS = 0,
    INPUT_COUPONS   = 0,
    
    ISPIF = CAST(1 AS BIT),

    LS_NUM,
    F.SumAmount
FROM vInvestorFundDate  F
WHERE Investor = @Investor_Id
  AND (Date >= @DateFrom OR @DateFrom IS NULL) 
  AND (Date <= @DateTo OR @DateTo IS NULL)
GO

CREATE OR ALTER FUNCTION ContractsDataSum
( 
    @Investor_Id  INT,
    @Currency     VARCHAR(3)  = NULL,    
    @DateFrom     DATE        = NULL,
    @DateTo       DATE        = NULL
)
RETURNS TABLE AS RETURN
WITH R AS 
(
    SELECT * FROM dbo.ContractsData(@Investor_Id, @Currency, @DateFrom, @DateTo)
),
C AS 
(
    SELECT *,
        T = DATEDIFF(DAY,Date,LEAD(Date)OVER (PARTITION BY ContractId ORDER BY Date)),
        S = SUM(IIF(D.RowNum = 1, D.VALUE_Sum ,(D.INPUT_VALUE_Sum + D.OUTPUT_VALUE_Sum))) 
              OVER (PARTITION BY ContractId ORDER BY D.Date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    FROM (
        SELECT 
          RowNum = ROW_NUMBER() OVER (PARTITION BY ContractId ORDER BY V.Date),
          RowNumRev = ROW_NUMBER() OVER (PARTITION BY ContractId ORDER BY V.Date DESC),
          V.Date,
          V.ContractId,
          V.ISPIF,
          V.LS_NUM,
          V.VALUE_Sum,
          V.INPUT_VALUE_Sum,
          V.OUTPUT_VALUE_Sum,
          V.OUTPUT_VALUE_Sum_PIF,
          V.OUTPUT_VALUE_Sum_DU,
          V.INPUT_COUPONS_Sum,
          V.INPUT_DIVIDENTS_Sum,
          V.SumAmount
        FROM 
        (
            SELECT 
                Date,
                ContractId,
                ISPIF,
                LS_NUM,
                VALUE_Sum             = SUM(VALUE),
                INPUT_VALUE_Sum       = SUM(INPUT_VALUE),
                OUTPUT_VALUE_Sum      = SUM(OUTPUT_VALUE),
                OUTPUT_VALUE_Sum_PIF  = SUM(IIF(ISPIF = 1, OUTPUT_VALUE, 0)),
                OUTPUT_VALUE_Sum_DU   = SUM(IIF(ISPIF = 0, OUTPUT_VALUE, 0)),
                INPUT_COUPONS_Sum     = SUM(INPUT_COUPONS),
                INPUT_DIVIDENTS_Sum   = SUM(INPUT_DIVIDENTS),
                SumAmount             = SUM(SumAmount)
            FROM R            
            GROUP BY Date, ContractId, ISPIF, LS_NUM
        ) V
    ) D
    WHERE (D.RowNum = 1 OR D.RowNumRev = 1) OR D.INPUT_VALUE_Sum <> 0 OR D.OUTPUT_VALUE_Sum <> 0
       OR D.INPUT_DIVIDENTS_Sum <> 0 OR D.INPUT_COUPONS_Sum <> 0
),
G AS 
(
    SELECT *,
        T = DATEDIFF(DAY,Date,LEAD(Date)OVER (PARTITION BY ISPIF ORDER BY Date)),
        S = SUM(IIF(D.RowNum = 1, D.VALUE_Sum ,(D.INPUT_VALUE_Sum + D.OUTPUT_VALUE_Sum))) 
              OVER (PARTITION BY ISPIF ORDER BY D.Date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    FROM (
        SELECT 
          RowNum = ROW_NUMBER() OVER (PARTITION BY ISPIF ORDER BY V.Date),
          RowNumRev = ROW_NUMBER() OVER (PARTITION BY ISPIF ORDER BY V.Date DESC),
          V.Date,
          V.ISPIF,
          V.VALUE_Sum,
          V.INPUT_VALUE_Sum,
          V.OUTPUT_VALUE_Sum,
          V.OUTPUT_VALUE_Sum_PIF,
          V.OUTPUT_VALUE_Sum_DU,
          V.INPUT_COUPONS_Sum,
          V.INPUT_DIVIDENTS_Sum
        FROM 
        (
            SELECT 
                Date,
                ISPIF,
                VALUE_Sum             = SUM(VALUE),
                INPUT_VALUE_Sum       = SUM(INPUT_VALUE),
                OUTPUT_VALUE_Sum      = SUM(OUTPUT_VALUE),
                OUTPUT_VALUE_Sum_PIF  = SUM(IIF(ISPIF = 1, OUTPUT_VALUE, 0)),
                OUTPUT_VALUE_Sum_DU   = SUM(IIF(ISPIF = 0, OUTPUT_VALUE, 0)),
                INPUT_COUPONS_Sum     = SUM(INPUT_COUPONS),
                INPUT_DIVIDENTS_Sum   = SUM(INPUT_DIVIDENTS)
            FROM R            
            GROUP BY Date, ISPIF
        ) V
    ) D
    WHERE (D.RowNum = 1 OR D.RowNumRev = 1) OR D.INPUT_VALUE_Sum <> 0 OR D.OUTPUT_VALUE_Sum <> 0
       OR D.INPUT_DIVIDENTS_Sum <> 0 OR D.INPUT_COUPONS_Sum <> 0
),
P AS 
(
    SELECT *,
        T = DATEDIFF(DAY,Date,LEAD(Date)OVER (ORDER BY Date)),
        S = SUM(IIF(D.RowNum = 1, D.VALUE_Sum ,(D.INPUT_VALUE_Sum + D.OUTPUT_VALUE_Sum))) 
              OVER (ORDER BY D.Date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    FROM (
        SELECT 
          RowNum = ROW_NUMBER() OVER (ORDER BY V.Date),
          RowNumRev = ROW_NUMBER() OVER (ORDER BY V.Date DESC),
          V.Date,
          V.VALUE_Sum,
          V.INPUT_VALUE_Sum,
          V.OUTPUT_VALUE_Sum,
          V.OUTPUT_VALUE_Sum_PIF,
          V.OUTPUT_VALUE_Sum_DU,
          V.INPUT_COUPONS_Sum,
          V.INPUT_DIVIDENTS_Sum
        FROM 
        (
            SELECT 
                Date,
                VALUE_Sum         = SUM(VALUE),
                INPUT_VALUE_Sum   = SUM(INPUT_VALUE),
                OUTPUT_VALUE_Sum  = SUM(OUTPUT_VALUE),
                OUTPUT_VALUE_Sum_PIF  = SUM(IIF(ISPIF = 1, OUTPUT_VALUE, 0)),
                OUTPUT_VALUE_Sum_DU   = SUM(IIF(ISPIF = 0, OUTPUT_VALUE, 0)),
                INPUT_COUPONS_Sum     = SUM(INPUT_COUPONS),
                INPUT_DIVIDENTS_Sum   = SUM(INPUT_DIVIDENTS)
            FROM R            
            GROUP BY Date
        ) V
    ) D
    WHERE (D.RowNum = 1 OR D.RowNumRev = 1) OR D.INPUT_VALUE_Sum <> 0 OR D.OUTPUT_VALUE_Sum <> 0
       OR D.INPUT_DIVIDENTS_Sum <> 0 OR D.INPUT_COUPONS_Sum <> 0
),
PS AS 
(
    SELECT 
        ContractId,
        ISPIF,
        LS_NUM,
        SNach       = SUM(IIF(RowNum = 1, VALUE_Sum, 0)),
        SItog       = SUM(IIF(RowNumRev = 1, VALUE_Sum, 0)),
        InVal       = SUM(IIF(RowNum > 1, INPUT_VALUE_Sum, 0)),
        OutVal      = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum, 0)),
        OutVal_PIF  = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum_PIF, 0)),
        OutVal_DU   = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum_DU, 0)),
        Dividends   = SUM(IIF(RowNum > 1, INPUT_DIVIDENTS_Sum, 0)),
        Coupons     = SUM(IIF(RowNum > 1, INPUT_COUPONS_Sum, 0)),
        WAmounr     = SUM(IIF(S > 0, S * T, 0))/SUM(T),
        MaxDate     = MAX(Date),
        MinDate     = MIN(Date),
        SumAmount   = SUM(IIF(RowNumRev = 1,SumAmount,0))
    FROM C 
    GROUP BY ContractId, ISPIF, LS_NUM

    UNION ALL

    SELECT 
        ContractId  = -1,
        ISPIF,
        NULL,
        SNach       = SUM(IIF(RowNum = 1, VALUE_Sum, 0)),
        SItog       = SUM(IIF(RowNumRev = 1, VALUE_Sum, 0)),
        InVal       = SUM(IIF(RowNum > 1, INPUT_VALUE_Sum, 0)),
        OutVal      = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum, 0)),
        OutVal_PIF  = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum_PIF, 0)),
        OutVal_DU   = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum_DU, 0)),
        Dividends   = SUM(IIF(RowNum > 1, INPUT_DIVIDENTS_Sum, 0)),
        Coupons     = SUM(IIF(RowNum > 1, INPUT_COUPONS_Sum, 0)),
        WAmounr     = SUM(IIF(S > 0, S * T, 0))/SUM(T),
        MaxDate     = MAX(Date),
        MinDate     = MIN(Date),
        SumAmount   = NULL    
    FROM G 
    GROUP BY ISPIF

    UNION ALL 
    
    SELECT 
        ContractId  = -1,
        ISPIF       = -1,
        NULL,
        SNach       = SUM(IIF(RowNum = 1, VALUE_Sum, 0)),
        SItog       = SUM(IIF(RowNumRev = 1, VALUE_Sum, 0)),
        InVal       = SUM(IIF(RowNum > 1, INPUT_VALUE_Sum, 0)),
        OutVal      = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum, 0)),
        OutVal_PIF  = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum_PIF, 0)),
        OutVal_DU   = SUM(IIF(RowNum > 1, OUTPUT_VALUE_Sum_DU, 0)),
        Dividends   = SUM(IIF(RowNum > 1, INPUT_DIVIDENTS_Sum, 0)),
        Coupons     = SUM(IIF(RowNum > 1, INPUT_COUPONS_Sum, 0)),
        WAmounr     = SUM(IIF(S > 0, S * T, 0))/SUM(T),
        MaxDate     = MAX(Date),
        MinDate     = MIN(Date),
        SumAmount   = NULL
    FROM P 
)
SELECT 
    ISPIF,	--Флаг того что это ПИФ
    PS.ContractId,	--Id-шник контракта
    Name      = ISNULL(AI.NUM, FN.Name),	--Название контракта (ПИФа, ДУ)
    LS_NUM,	--Номер лицевого счета
    SumAmount,	--Колличество Паев
    DATE_OPEN = ISNULL(AI.DATE_OPEN, IIF(PS.ContractId = -1, NULL, MinDate)),	--Дата открытия конртракта
    DATE_CLOSE = ISNULL(AI.DATE_CLOSE,fn.DATE_CLOSE),	--Дата закрытия контракта
    MinDate,	--Минимальное значение даты в периоде
    MaxDate,	--Максимальное значение даты в периоде
    SNach,	--Соимость контракта на начало перида
    SItog,	--Стоимость контракта на конец периода
    InVal,	--Пополнения
    OutVal,	--Изятия
    OutVal_PIF,	--Изятия ПИФ
    OutVal_DU,	--Изятия ДУ
    Dividends,	--Дивиденды
    Coupons,	--Купоны
    Income = (SItog - OutVal - InVal - SNach),	--Доход за период
    WAmounr,	--Среднее значение используемых средств
    Res = (SItog - OutVal - InVal - SNach) / WAmounr * 100	--Доход за период %
FROM PS
LEFT JOIN Assets_Info AI  ON PS.ContractId = AI.ContractId AND AI.InvestorId = @Investor_Id AND ISPIF = 0
LEFT JOIN FundNames   FN  ON PS.ContractId = FN.Id AND ISPIF = 1
WHERE WAmounr > 0 
GO

CREATE OR ALTER FUNCTION CircleDiagrams
(
    @Investor_Id  INT,
    @Currency     VARCHAR(3)  = NULL,    
    @Date         DATE        = NULL
)
RETURNS TABLE AS RETURN
WITH RD AS 
(
    SELECT 
        C.CategoryName,
        PF.ISPIF,
        PF.ContractId,
        PF.ClassId,
        AssetName       = CASE WHEN c.Id = 4 AND PF.ISPIF = 1 THEN C.CategoryName else PF.AssetName END,
        PF.VALUE_RUR,
        CUR.CurrencyName        
    FROM 
    (
        SELECT 
            ISPIF       = CAST(1 AS BIT), 
            ContractId  = IFD.FundId,
            ClassId     = 10,
            AssetName   = FN.Name,
            VALUE_RUR   = (IFD.SumAmount - IFD.AmountDay)  * IFD.RATE,
            CUR_ID      = 1
        FROM [vInvestorFundDate]  IFD
        LEFT JOIN [FundNames]     FN  ON IFD.FundId = FN.Id
        WHERE IFD.Date      = ISNULL(@Date, GETDATE())
          AND IFD.Investor  = @Investor_Id 
        
        
        UNION ALL
        
        SELECT
            ISPIF       = CAST(0 AS BIT),  
            ContractId  = PFD.ContractId,
            ClassId     = PFD.CLASS,
            AssetName   = TRIM(REPLACE(I.Investment,'; НКД','')),
            VALUE_RUR   = PFD.VALUE_RUR,
            CUR_ID      = PFD.CUR_ID
        FROM [vPortFolio_Daily]   PFD
        LEFT JOIN [InvestmentIds] I   ON PFD.InvestmentId = I.Id
        WHERE PFD.PortfolioDate = ISNULL(@Date, GETDATE())
          AND PFD.InvestorId    = @Investor_Id
      ) PF 
      LEFT JOIN [Currencies]        CUR ON PF.CUR_ID      = CUR.Id
      LEFT JOIN [ClassCategories]   CS  ON PF.ClassId     = CS.ClassId
      LEFT JOIN [Categories]        C   ON CS.CategoryId  = C.Id
      WHERE PF.VALUE_RUR <> 0
),
GR AS 
(
    SELECT 
        GroupType = 'CategoryName',
        CategoryName,
        ISPIF,
        ContractId,
        VALUE_RUR_Sum = SUM(VALUE_RUR)
    FROM [RD]
    GROUP BY CategoryName,ISPIF,ContractId
    
    UNION ALL
    
    SELECT 
        GroupType = 'CurrencyName',
        CurrencyName,
        ISPIF,
        ContractId,
        VALUE_RUR_Sum = SUM(VALUE_RUR)
    FROM [RD]
    GROUP BY CurrencyName,ISPIF,ContractId
    
    UNION ALL
    
    SELECT 
        GroupType = 'AssetName',
        AssetName,
        ISPIF,
        ContractId,
        VALUE_RUR_Sum = SUM(VALUE_RUR)
    FROM [RD]
    GROUP BY AssetName,ISPIF,ContractId
),
Res AS 
(
    SELECT 
        GR_RUR.ISPIF,
        GR_RUR.ContractId,
        ContractName = ISNULL(AI.NUM, FN.Name),
        GR_RUR.GroupType,
        GR_RUR.CategoryName,
        VALUE_CUR = CASE 
            WHEN @Currency = 'USD' THEN GR_RUR.VALUE_RUR_Sum / AC.USDRATE
            WHEN @Currency = 'EUR' THEN GR_RUR.VALUE_RUR_Sum / AC.EURORATE
            ELSE GR_RUR.VALUE_RUR_Sum
        END
    FROM 
    (
        SELECT
            ISPIF = -1,
            ContractId = -1,
            GroupType,
            CategoryName,    
            VALUE_RUR_Sum = SUM(VALUE_RUR_Sum)
        FROM [GR]
        GROUP BY GroupType,CategoryName
        
        UNION ALL 
        
        SELECT
            ISPIF,
            ContractId,
            GroupType,
            CategoryName,    
            VALUE_RUR_Sum
        FROM [GR]
    ) GR_RUR
    LEFT JOIN [Assets_Info]   AI  ON GR_RUR.ContractId = AI.ContractId AND AI.InvestorId = @Investor_Id AND ISPIF = 0
    LEFT JOIN [FundNames]     FN  ON GR_RUR.ContractId = FN.Id AND ISPIF = 1
    OUTER APPLY
    (
          SELECT TOP 1 USDRATE, EURORATE FROM [vAssets_Contracts]
          WHERE Date = ISNULL(@Date, GETDATE())
    ) AC
)
SELECT R.ISPIF
      ,R.ContractId
      ,R.ContractName
      ,R.GroupType
      ,R.CategoryName
      ,R.VALUE_CUR
      ,Res = IIF(S.VALUE_CUR_Sum <>0, R.VALUE_CUR/S.VALUE_CUR_Sum * 100, 0)
FROM Res R
JOIN
(
    SELECT ISPIF, ContractId, VALUE_CUR_Sum = SUM(VALUE_CUR) FROM Res GROUP BY ISPIF, ContractId
)        S  ON S.ContractId = R.ContractId AND S.ISPIF = R.ISPIF
GO

CREATE OR ALTER FUNCTION DuPositions
(
    @Investor_Id  INT,
    @Contract_Id  INT,
    @DateFrom     DATE,
    @DateTo       DATE,
    @Currency     VARCHAR(3) = 'RUR'
)
RETURNS TABLE AS RETURN
SELECT 
    A.InvestorId
   ,A.ContractId
   ,A.ShareId
   ,A.Fifo_Date
   ,A.Id
   ,A.ISIN
   ,A.Class
   ,A.CUR_ID
   ,A.Oblig_Date_end
   ,A.Oferta_Date
   ,A.Oferta_Type
   ,A.IsActive
   ,A.In_Wir
   ,A.In_Date
   ,A.Ic_NameId
   ,A.Il_Num
   ,A.In_Dol
   ,A.Ir_Trans
   ,A.Amount
   ,A.In_Summa
   ,A.In_Eq
   ,A.In_Comm
   ,A.In_Price
   ,A.In_Price_eq
   ,A.IN_PRICE_UKD
   ,A.Today_PRICE
   ,A.Value_NOM
   ,A.Dividends
   ,A.UKD
   ,A.NKD
   ,A.Amortizations
   ,A.Coupons
   ,A.Out_Wir
   ,A.Out_Date
   ,A.Od_Id
   ,A.Oc_NameId
   ,A.Ol_Num
   ,A.Out_Dol
   ,A.OutPrice
   ,A.Out_Summa
   ,A.Out_Eq
   ,A.RecordDate
   ,IsArchive = ISNULL(A.IsArchive,0),

    Currency = C.ShortName,
    B.InstrumentId,
    I.Investment,
    CC.CategoryId,
    
    FinRes = 
      IIF(A.IsActive = 0,
          case
        		when a.Class in (1,7,10)
        			then isnull(a.Out_Summa,0) + isnull(a.Dividends,0) - isnull(a.In_Summa,0)
        		when a.Class in (2)
        			then isnull(a.Out_Summa,0) + isnull(a.Amortizations,0)  + isnull(a.Coupons,0) + isnull(a.NKD,0) - isnull(a.In_Summa,0) - isnull(a.UKD,0)
        		else 0
        	END,
          
          case
        		when b.id is not null and a.Class in (1,7,10) then
        			isnull(a.Value_NOM,0)
        			+ isnull(a.Dividends,0)
        				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
        				- isnull(isnull(b.Dividends,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
        
        		when b.id is null     and a.Class in (1,7,10) then
        			isnull(a.Value_NOM,0) + isnull(a.Dividends,0) - isnull(a.In_Summa,0)
        
        
        		when b.id is not null and a.Class in (2) then
        			isnull(a.Value_NOM,0)
        			+ isnull(a.Amortizations,0)
        			+ isnull(a.Coupons,0)
        			+ isnull(a.NKD,0)
        				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
        				- isnull(isnull(b.Amortizations,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
        				- isnull(isnull(b.Coupons,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
        				- isnull(isnull(b.NKD,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
        		
        		when b.id is null     and a.Class in (2) then
        			isnull(a.Value_NOM,0)
        			+ isnull(a.Amortizations,0)
        			+ isnull(a.Coupons,0)
        			+ isnull(a.NKD,0)
        				- isnull(a.In_Summa,0)
        				- isnull(a.UKD,0)
        
        		else 0
        	END),

      FinResProcent = 
        IIF(A.IsActive = 0,
            case
          		when a.Class in (1,7,10)
          			then isnull(a.Out_Summa,0) + isnull(a.Dividends,0) - isnull(a.In_Summa,0)
          		when a.Class in (2)
          			then isnull(a.Out_Summa,0) + isnull(a.Amortizations,0)  + isnull(a.Coupons,0) + isnull(a.NKD,0) - isnull(a.In_Summa,0) - isnull(a.UKD,0)
          		else 0
          	end
          	/
          	nullif(
          	case
          		when a.Class in (1,7,10)
          			then isnull(a.In_Summa,0)
          		when a.Class in (2)
          			then isnull(a.Out_Summa,0) + isnull(a.UKD,0)
          		else NULL
          	end, 0),

            case
          		when b.id is not null and a.Class in (1,7,10) then
          			isnull(a.Value_NOM,0)
          			+ isnull(a.Dividends,0)
          				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          				- isnull(isnull(b.Dividends,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          
          		when b.id is null     and a.Class in (1,7,10) then
          			isnull(a.Value_NOM,0) + isnull(a.Dividends,0) - isnull(a.In_Summa,0)
          
          
          		when b.id is not null and a.Class in (2) then
          			isnull(a.Value_NOM,0)
          			+ isnull(a.Amortizations,0)
          			+ isnull(a.Coupons,0)
          			+ isnull(a.NKD,0)
          				- isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          				- isnull(isnull(b.Amortizations,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          				- isnull(isnull(b.Coupons,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          				- isnull(isnull(b.NKD,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          		
          		when b.id is null     and a.Class in (2) then
          			isnull(a.Value_NOM,0)
          			+ isnull(a.Amortizations,0)
          			+ isnull(a.Coupons,0)
          			+ isnull(a.NKD,0)
          				- isnull(a.In_Summa,0)
          				- isnull(a.UKD,0)
          
          		else 0
          	end
          	/
          	nullif(
          	case
          		when b.id is not null and a.Class in (1,7,10) then
          			isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          			+ isnull(isnull(b.Dividends,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          
          		when b.id is null     and a.Class in (1,7,10) then
          			isnull(a.In_Summa,0)
          
          
          		when b.id is not null and a.Class in (2) then
          			isnull(isnull(b.Value_NOM,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          			+ isnull(isnull(b.Amortizations,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          			+ isnull(isnull(b.Coupons,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          			+ isnull(isnull(b.NKD,0) / nullif(b.Amount,0),0) * isnull(a.Amount,0)
          
          		when b.id is null     and a.Class in (2) then
          			isnull(a.In_Summa,0) + isnull(a.UKD,0)
          
          		else NULL
          	end, 0))
              
FROM [vPOSITION_KEEPING] A
OUTER APPLY
(
    SELECT * FROM [vPOSITION_KEEPING]
    WHERE InvestorId = @Investor_Id AND Fifo_Date = @DateFrom
      AND ContractId = @Contract_Id AND In_Wir = A.In_Wir
)                       B
JOIN [vPortFolio_Daily] P   ON A.ShareId = P.VALUE_ID AND P.PortfolioDate = @DateTo AND 
                               A.InvestorId = P.InvestorId AND A.ContractId = P.ContractId
JOIN [InvestmentIds]    I   ON P.InvestmentId = I.Id
JOIN [ClassCategories]  CC  ON A.Class = CC.ClassId
JOIN [Categories]       CG  ON CC.CategoryId = CG.Id
LEFT JOIN [Currencies]  C   ON A.CUR_ID = C.Id
WHERE A.InvestorId = @Investor_Id AND A.Fifo_Date = @DateTo
  AND A.ContractId = @Contract_Id 
GO

CREATE OR ALTER FUNCTION DuPositionGrouByElement
(
    @Investor_Id  INT,
    @Contract_Id  INT,
    @Currency     VARCHAR(3) = 'RUR',
    @DateTo       DATE
)
RETURNS TABLE AS RETURN
WITH R AS 
(
    SELECT InvestorId, ContractId, ShareId, [Date] = CAST(In_Date AS DATE), In_Summa = sum(In_Summa), Out_Summa = 0
    FROM vPOSITION_KEEPING 
    WHERE Fifo_Date = @DateTo
      AND InvestorId = @Investor_Id AND ContractId = @Contract_Id
    group by InvestorId, ContractId, ShareId, In_Date

    UNION ALL

    SELECT InvestorId, ContractId, ShareId, [Date] = CAST(Out_Date AS DATE), In_Summa = 0, Out_Summa = sum(Out_Summa) 
    FROM vPOSITION_KEEPING 
    WHERE Fifo_Date = @DateTo
      AND InvestorId = @Investor_Id AND ContractId = @Contract_Id
    group by InvestorId, ContractId, ShareId, Out_Date
),
FR AS 
(
    SELECT
        ShareId,
        Income  = SUM(Out_Summa - In_Summa),
        FinRes  = IIF(SUM(T) > 0, SUM(Out_Summa - In_Summa)/(SUM(IIF(S > 0, S * T, 0))/SUM(T)),0)
    FROM 
    (
        SELECT *,
            T = DATEDIFF(DAY,Date,LEAD(Date)OVER (PARTITION BY ShareId ORDER BY Date)),
            S = SUM(In_Summa - Out_Summa) 
                  OVER (PARTITION BY ShareId ORDER BY Date RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
        FROM 
        (
            SELECT * FROM R
            
            UNION ALL

            SELECT DISTINCT 
                InvestorId, 
                ContractId, 
                ShareId   = VALUE_ID, 
                [Date]    = @DateTo, 
                In_Summa = 0,
                Out_Summa = VALUE_NOM
            FROM [vPortFolio_Daily]
            WHERE InvestorId = @Investor_Id AND ContractId = @Contract_Id
              AND PortfolioDate = @DateTo
        ) R
        WHERE In_Summa <> 0 OR Out_Summa <> 0 OR Date = @DateTo
    ) A
    GROUP BY ContractId,ShareId
)
SELECT 
    R.VALUE_ID,
    c.CategoryName,
  	ChildId     = cast(R.InvestmentId as BigInt),
  	TypeId      = cast(c.id as BigInt),
  	ChildName   = i.Investment,
  	ValutaId    = cast(R.CUR_ID as BigInt),
  	Valuta      = cr.ShortName,
  	Price       = CAST(Round(R.[VALUE_NOM],2) as Decimal(30,2)),
  	Ammount     = case when c.Id <> 4 then CAST(Round(R.[AMOUNT],2) as Decimal(30,2))  else NULL END,
    FinRes      = FR.Income,
    FinResPrcnt = FR.FinRes
FROM [vPortFolio_Daily] R
LEFT JOIN               FR  ON FR.ShareId = R.VALUE_ID
JOIN [ClassCategories]  CC  ON R.CLASS = CC.ClassId
JOIN [Categories]       C   ON CC.CategoryId = C.Id
JOIN [InvestmentIds]    I   ON R.InvestmentId = I.Id
LEFT JOIN  [dbo].[Currencies] as cr on R.CUR_ID = cr.id
WHERE PortfolioDate = @DateTo
      AND InvestorId = @Investor_Id AND ContractId = @Contract_Id
      AND BAL_ACC <> 2782 
GO

CREATE OR ALTER FUNCTION dbo.DuOperationHistory
(
    @InvestorId   INT,
    @ContractId   INT,
    @Currency     VARCHAR(3) = 'RUR',
    @DateFrom     DATE,
    @DateTo       DATE
)
RETURNS TABLE AS RETURN
SELECT
  a.Id,a.IsArchive,--PK
  [Date] = a.[Date],
  [OperName] = a.T_Name,
  a.[ISIN],
  [ToolName] = a.Investment,
  [Price] = CAST(Round(a.[Price],2) as Decimal(30,2)),
  [PaperAmount] = CAST(Round(a.[Amount],2) as Decimal(30,2)),
  [RowValuta] = c.ShortName,
  [RowCost] = CAST(Round(a.[Value_Nom],2) as Decimal(30,2)),
  [Fee] = CAST(Round(a.[Fee],2) as Decimal(30,2)),
  [Status] = N''
from [vOperations_History_Contracts] as a
join dbo.Currencies as c on a.Currency = c.Id
where a.InvestorId = @InvestorId and a.ContractId = @ContractId
and (@DateFrom is null or (@DateFrom is not null and a.[Date] >= @DateFrom))
and (@DateTo is null or (@DateTo is not null and a.[Date] <@DateTo))
GO

CREATE OR ALTER FUNCTION FundOperationHistory
(
    @InvestorId   INT,
    @FundId       INT,
    @Currency     VARCHAR(3) = 'RUR',
    @DateFrom     DATE,
    @DateTo       DATE
)
RETURNS TABLE AS RETURN
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
    [Valuta] = 'RUB',
    [IsArchive]
FROM
(
    SELECT * 
    FROM [vFundHistory] AS A WITH(NOLOCK)
    WHERE A.Investor = @InvestorId AND A.FundId = @FundId
      AND ([W_Date] >= @DateFrom OR @DateFrom IS NULL) 
      AND ([W_Date] < @DateTo OR @DateTo IS NULL)
) AS B
LEFT JOIN [dbo].[WalkTypes] AS C WITH(NOLOCK) ON B.WALK = C.WALK AND B.[TYPE] = C.[TYPE]
GO

CREATE OR ALTER FUNCTION DivNCouponsGraph
(
    @InvestorId   INT,
    @Currency     VARCHAR(3) = 'RUR',
    @DateFrom     DATE,
    @DateTo       DATE
)
RETURNS TABLE AS RETURN
WITH cte AS
(
  SELECT 
    [Iter]      = CAST(1 AS INT),
    [DateFrom]  = DATEFROMPARTS(YEAR(@DateTo),MONTH(@DateTo),1),
    [DateTo]    = DATEADD(MONTH,1, DATEFROMPARTS(YEAR(@DateTo),MONTH(@DateTo),1))
  
  UNION ALL
  
  SELECT 
    [Iter] + 1,
    DATEADD(MONTH,-1,[DateFrom]) ,
    DATEADD(MONTH,-1,[DateTo]) 
  FROM cte
  WHERE [Iter] < 12
),
C AS 
(
    SELECT DISTINCT ContractId FROM vDIVIDENDS_AND_COUPONS_History
    WHERE PaymentDateTime BETWEEN (SELECT MIN(DateFrom) FROM cte) AND (SELECT MAX(DateTo) FROM cte)
      AND InvestorId = @InvestorId
)
SELECT
    C.ContractId,
  	[Date] = [DateFrom],
  	[Dividends] = SUM(IIF(r.Type = 1, r.INPUT_VALUE,0)),
  	[Coupons] = SUM(IIF(r.Type <> 1, r.INPUT_VALUE,0)),
    [Valuta] = @Currency
FROM cte 
CROSS APPLY 
(
    SELECT ContractId FROM C
) C
LEFT JOIN 
(
    SELECT
        GCD.ContractId,
        GCD.Type, 
        [Date] = GCD.PaymentDateTime, 
        INPUT_VALUE = CASE
          WHEN @Currency = 'USD' then GCD.AmountPayments_USD
          WHEN @Currency = 'EUR' then GCD.AmountPayments_EURO
          ELSE GCD.AmountPayments_RUR
        END    
    FROM vDIVIDENDS_AND_COUPONS_History GCD 
    WHERE GCD.InvestorId = @InvestorId
)r ON r.[Date] BETWEEN [DateFrom] AND DATEADD(DAY,-1,[DateTo]) AND C.ContractId = r.ContractId
GROUP BY [DateFrom], C.ContractId
GO

CREATE OR ALTER FUNCTION DivNCouponsDetails
(
    @InvestorId   INT,
    @Currency     VARCHAR(3) = 'RUR',
    @DateFrom     DATE,
    @DateTo       DATE
)
RETURNS TABLE AS RETURN
SELECT
    GCD.ContractId,
    ContractName = AI.NUM,
    PaymentType = case GCD.Type WHEN 1 THEN 'Купоны' ELSE 'Дивиденды' END, 
    GCD.ShareName,
    [Date] = GCD.PaymentDateTime, 
    INPUT_VALUE = CASE
      WHEN @Currency = 'USD' then GCD.AmountPayments_USD
      WHEN @Currency = 'EUR' then GCD.AmountPayments_EURO
      ELSE GCD.AmountPayments_RUR
    END,
    [Valuta] = @Currency
FROM vDIVIDENDS_AND_COUPONS_History GCD 
LEFT JOIN Assets_Info               AI  ON GCD.InvestorId = AI.InvestorId AND GCD.ContractId = AI.ContractId
WHERE GCD.InvestorId = @InvestorId
  AND (@DateFrom IS NULL OR GCD.PaymentDateTime >= @DateFrom)
  AND (@DateTo IS NULL  OR GCD.PaymentDateTime <= @DateTo)


GO