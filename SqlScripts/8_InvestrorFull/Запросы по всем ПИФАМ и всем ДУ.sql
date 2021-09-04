-- Запрос по всем ПИФАМ

EXEC [dbo].[GetInvestorFundResults]
    @InvestorId = 19865873,
    @StartDate = NULL,
    @EndDate = NULL


-- Запрос по всем ДУ

EXEC [dbo].[GetInvestorContractResults]
    @InvestorId = 2149652,
    @StartDate = NULL,
    @EndDate = NULL