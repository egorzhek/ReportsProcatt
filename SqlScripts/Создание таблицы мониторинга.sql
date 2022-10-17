CREATE TABLE ReloadContractInfo
(
	Id Int identity(1,1) primary key,
	InvestorId Int,
	ContractId Int,
	StartDate datetime,
	EndDate datetime
)
GO