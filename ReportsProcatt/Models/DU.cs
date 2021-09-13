using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class DU
    {
        public int Id { get; private set; }
        public string Name { get; private set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public DateTime Dfrom { get; set; }
        public DateTime Dto { get; set; }
        public CurrencyClass Currency { get; set; }
        public Headers DuHeader { get; set; }
        public Dictionary<string, string> Diagram { get; set; }

        //Дивиденды и купоны
        public string Totals { get; set; }
        public string Dividends { get; set; }
        public string Coupons { get; set; }
        public ChartClass DividedtsCouponsChart { get; set; }

        //Детализация купонов и дивидендов
        public TableView DividedtsCoupons { get; set; }

        //Информация по договору
        public string ContractNumber => _TrustManagementDS.GetValue(DuTables.MainResultDT, "LS_NUM").ToString();
        public string OpenDate => ((DateTime)_TrustManagementDS.GetValue(DuTables.MainResultDT, "OpenDate")).ToString("dd.MM.yyyy");
        public string ManagementFee => $"{_TrustManagementDS.GetValue(DuTables.MainResultDT, "EndSumAmount")} шт.";
        public string SuccessFee => $"{_TrustManagementDS.GetValue(DuTables.MainResultDT, "Fee")}%";

        //Текущие позиции по валютам

        //Текущие позиции в периоде
        public TableView CurrentShares { get; set; }
        public TableView CurrentBonds { get; set; }
        public TableView CurrentBills { get; set; }
        public TableView CurrentCash { get; set; }
        public TableView CurrentFunds { get; set; }
        public TableView CurrentDerivatives { get; set; }

        //Закрытые позиции в периоде
        public TableView ClosedShares { get; set; }
        public TableView ClosedBonds { get; set; }
        public TableView ClosedBills { get; set; }
        public TableView ClosedCash { get; set; }
        public TableView ClosedFunds { get; set; }
        public TableView ClosedDerivatives { get; set; }

        //Состав договора
        public CircleDiagram AssetsStruct { get; set; }
        public CircleDiagram ContractStruct { get; set; }

        //История операций
        public TableView OperationsHistory { get; set; }
        #region Поля
        private SQLDataDU _data;
        private DataSet _TrustManagementDS => _data.DataSet_TrustManagement;
        private DataSet _DuDS => _data.DataSet_DU;
        private DataSet _Du2DS => _data.DataSet_DU2;
        #endregion
        public DU(
            string aName,
            DateTime aDFrom,
            DateTime aDTo,
            CurrencyClass aCurrency,
            int ContractId,
            int InvestorId,
            string connectionString,
            string ReportPath)
        {
            Id = ContractId;
            Name = aName;
            Dfrom = aDFrom;
            Dto = aDTo;
            Currency = aCurrency;
            _data = new SQLDataDU(Currency.Code, ContractId, InvestorId, aDFrom, aDTo, connectionString, ReportPath);

            DuHeader = new Headers
            {
                TotalSum = $"{_TrustManagementDS.DecimalToStr(DuTables.MainResultDT, "ActiveDateToValue", "#,##0")} {Currency.Char}",
                ProfitSum = $"{_TrustManagementDS.DecimalToStr(DuTables.MainResultDT, "ProfitValue", "#,##0")} {Currency.Char}",
                Return = $"{_TrustManagementDS.DecimalToStr(DuTables.MainResultDT, "ProfitProcentValue", "#0.00", aWithSign: true)}%"
            };
            Diagram = new Dictionary<string, string>
            {
                { DuDiagramColumns.Begin, _TrustManagementDS.DecimalToStr(DuTables.DiagramDT, "ActiveValue", "#,##0") },
                { DuDiagramColumns.InVal, _TrustManagementDS.DecimalToStr(DuTables.DiagramDT, "InVal", "#,##0") },
                { DuDiagramColumns.OutVal, _TrustManagementDS.DecimalToStr(DuTables.DiagramDT, "Outval", "#,##0") },
                { DuDiagramColumns.Coupons, _TrustManagementDS.DecimalToStr(DuTables.DiagramDT, "Coupons", "#,##0") },
                { DuDiagramColumns.Dividents, _TrustManagementDS.DecimalToStr(DuTables.DiagramDT, "Dividends", "#,##0") },
                { DuDiagramColumns.End, _TrustManagementDS.DecimalToStr(DuTables.MainResultDT, "ActiveDateToValue", "#,##0") }
            };
            InitAssetsStruct();
            InitFundStruct();

            InitClosedShares();
            InitClosedBonds();
            InitClosedFunds();
            InitClosedDerivatives();
            InitClosedBills();
            InitClosedCash();

            InitCurrentShares();
            InitCurrentBonds();
            InitCurrentBills();
            InitCurrentCash();
            InitCurrentFunds();
            InitCurrentDerivatives();


        }
        private void InitAssetsStruct()
        {
            if (_DuDS.Tables[0].Rows.Count > 0)
            {
                int i = 1;
                AssetsStruct = new CircleDiagram($"Contract_{Id}_AssetsStructCircle")
                {
                    MainText = $"{_DuDS.DecimalToStr(0, "AllSum", "#,##0")} {Currency.Char}",
                    Footer = $"{_DuDS.Tables[0].Rows.Count} АКТИВА(ов)",
                    Data = _DuDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Take(7)
                        .Select(r =>
                        {
                            var el = new CircleDiagram.DataClass
                            {
                                lable = $"{r["CategoryName"]} {((decimal)r["Result"] * 100).DecimalToStr("#,##0.00")}%",
                                data = (decimal)r["VALUE_RUR"],
                                backgroundColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                                borderColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i]
                            };
                            i++;
                            return el;
                        }).ToList(),
                    Type = "doughnut"

                };

                if (_DuDS.Tables[0].Rows.Count > 7)
                {
                    decimal otherPerent = 100 -
                        _DuDS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (double)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["Result"]) * 100;

                    AssetsStruct.Data.RemoveAt(AssetsStruct.Data.Count - 1);

                    AssetsStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее {otherPerent.DecimalToStr("#,##0")}%",
                        data = _DuDS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (decimal)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["VALUE_RUR"]),
                        backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7]
                    });
                }
            }
        }
        private void InitFundStruct()
        {
            if (_Du2DS.Tables[0].Rows.Count > 0)
            {
                int i = 1;
                ContractStruct = new CircleDiagram($"Contract_{Id}_Struct")
                {
                    MainText = $"{_Du2DS.DecimalToStr(0, "AllSum", "#,##0")} {Currency.Char}",
                    Footer = $"{_Du2DS.Tables[0].Rows.Count} инструментов",
                    Data = _Du2DS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Take(7)
                        .Select(r =>
                        {
                            var el = new CircleDiagram.DataClass
                            {
                                lable = $"{r["Investment"]} {((decimal)r["Result"] * 100).DecimalToStr("#,##0.00")}%",
                                data = (decimal)r["VALUE_RUR"],
                                backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                                borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i]
                            };
                            i++;
                            return el;
                        }).ToList(),
                    Type = "doughnut"

                };

                if (_Du2DS.Tables[0].Rows.Count > 7)
                {
                    decimal otherPerent = 100 -
                        _Du2DS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (decimal)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["Result"]) * 100;

                    ContractStruct.Data.RemoveAt(ContractStruct.Data.Count - 1);

                    ContractStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее {otherPerent.DecimalToStr("#,##0")}%",
                        data = _Du2DS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (decimal)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["VALUE_RUR"]),
                        backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7]
                    });
                }
            }
        }
        private void InitClosedShares()
        {
            ClosedShares = new TableView();
            ClosedShares.Table = new DataTable();
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.IN_DATE);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.ISIN);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Investment);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.IN_PRICE);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Amount);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.In_Summa);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Out_Price);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Dividends);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Out_Date);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Out_Summa);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.FinRes);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.FinResProcent);

            ClosedShares.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedSharesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 11},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 12},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.ClosedShares].Rows)
            { 
                DataRow row = ClosedShares.Table.NewRow(); 
                row[ClosedSharesColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[ClosedSharesColumns.ISIN] = dr["ISIN"];
                row[ClosedSharesColumns.Investment] = dr["Investment"];
                row[ClosedSharesColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[ClosedSharesColumns.Amount] = dr["Amount"].DecimalToStr();
                row[ClosedSharesColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[ClosedSharesColumns.Out_Price] = dr["OutPrice"].DecimalToStr();
                row[ClosedSharesColumns.Dividends] = dr["Dividends"].DecimalToStr();
                row[ClosedSharesColumns.Out_Date] = (dr["Out_Date"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedSharesColumns.Out_Summa] = dr["Out_Summa"].DecimalToStr();
                row[ClosedSharesColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[ClosedSharesColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }

        private void InitClosedBonds() 
        {
            ClosedBonds = new TableView();
            ClosedBonds.Table = new DataTable(); 
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.IN_DATE);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.ISIN);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Investment);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Oblig_Date_end);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Oferta_Date);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.IN_PRICE);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Amount);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.In_Summa);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.UKD);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.In_Summa_UKD);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Out_Price);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.NKD);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Amortizations);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Out_Date);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Out_Summa);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.FinRes);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.FinResProcent);

            ClosedBonds.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedBondsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.In_Summa, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 11},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 14},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 15},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 16},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 17},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.ClosedBonds].Rows)
            {
                DataRow row = ClosedBonds.Table.NewRow(); 
                row[ClosedBondsColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[ClosedBondsColumns.ISIN] = dr["ISIN"];
                row[ClosedBondsColumns.Investment] = dr["Investment"];
                row[ClosedBondsColumns.Oblig_Date_end] = (dr["Oblig_Date_end"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedBondsColumns.Oferta_Date] = $"{(dr["Oferta_Date"] as DateTime?)?.ToString("dd.MM.yyyy")} ({dr["Oferta_Type"]})";
                row[ClosedBondsColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[ClosedBondsColumns.Amount] = dr["Amount"].DecimalToStr();
                row[ClosedBondsColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[ClosedBondsColumns.UKD] = dr["UKD"].DecimalToStr();
                row[ClosedBondsColumns.In_Summa_UKD] = ((decimal)dr["In_Summa"] + (decimal)dr["UKD"]).DecimalToStr();
                row[ClosedBondsColumns.Out_Price] = dr["OutPrice"].DecimalToStr();
                row[ClosedBondsColumns.NKD] = dr["NKD"].DecimalToStr();
                row[ClosedBondsColumns.Amortizations] = $"{dr["Amortizations"].DecimalToStr()} ({dr["Coupons"].DecimalToStr()})";
                row[ClosedBondsColumns.Out_Date] = (dr["Out_Date"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedBondsColumns.Out_Summa] = dr["Out_Summa"].DecimalToStr();
                row[ClosedBondsColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[ClosedBondsColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitClosedFunds() 
        {
            ClosedFunds = new TableView();
            ClosedFunds.Table = new DataTable(); 
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.IN_DATE);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.Investment);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.IN_PRICE);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.Amount);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.In_Summa);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.Out_Price);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.Out_Date);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.Out_Summa);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.FinRes);
            ClosedFunds.Table.Columns.Add(ClosedFundsColumns.FinResProcent);

            ClosedFunds.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedFundsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.Investment, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedFundsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 10},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.ClosedFunds].Rows)
            {
                DataRow row = ClosedFunds.Table.NewRow(); 
                row[ClosedFundsColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[ClosedFundsColumns.Investment] = dr["Investment"];
                row[ClosedFundsColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[ClosedFundsColumns.Amount] = dr["Amount"].DecimalToStr();
                row[ClosedFundsColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[ClosedFundsColumns.Out_Price] = dr["OutPrice"].DecimalToStr();
                row[ClosedFundsColumns.Out_Date] = (dr["Out_Date"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedFundsColumns.Out_Summa] = dr["Out_Summa"].DecimalToStr();
                row[ClosedFundsColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[ClosedFundsColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitClosedDerivatives() 
        {
            ClosedDerivatives = new TableView();
            ClosedDerivatives.Table = new DataTable(); 
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.IN_DATE);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.ISIN);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Investment);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.IN_PRICE);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Amount);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.In_Summa);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Out_Price);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Dividends);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Out_Date);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Out_Summa);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.FinRes);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.FinResProcent);

            ClosedDerivatives.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 11},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 12},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.ClosedDerivatives].Rows)
            {
                DataRow row = ClosedDerivatives.Table.NewRow(); 
                row[ClosedDerivativesColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[ClosedDerivativesColumns.ISIN] = dr["ISIN"];
                row[ClosedDerivativesColumns.Investment] = dr["Investment"];
                row[ClosedDerivativesColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[ClosedDerivativesColumns.Amount] = dr["Amount"].DecimalToStr();
                row[ClosedDerivativesColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[ClosedDerivativesColumns.Out_Price] = dr["OutPrice"].DecimalToStr();
                row[ClosedDerivativesColumns.Dividends] = dr["Dividends"];
                row[ClosedDerivativesColumns.Out_Date] = (dr["Out_Date"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedDerivativesColumns.Out_Summa] = dr["Out_Summa"].DecimalToStr();
                row[ClosedDerivativesColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[ClosedDerivativesColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitClosedBills() 
        {
            ClosedBills = new TableView();
            ClosedBills.Table = new DataTable(); 
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.IN_DATE);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.ISIN);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Investment);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Oblig_Date_end);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Oferta_Date);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.IN_PRICE);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Amount);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.In_Summa);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.UKD);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.In_Summa_UKD);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Out_Price);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.NKD);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Amortizations);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Out_Date);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.Out_Summa);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.FinRes);
            ClosedBills.Table.Columns.Add(ClosedBillsColumns.FinResProcent);

            ClosedBills.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedBillsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.In_Summa, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 11},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 14},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 15},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 16},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 17},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.ClosedBills].Rows)
            {
                DataRow row = ClosedBills.Table.NewRow(); 
                row[ClosedBillsColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[ClosedBillsColumns.ISIN] = dr["ISIN"];
                row[ClosedBillsColumns.Investment] = dr["Investment"];
                row[ClosedBillsColumns.Oblig_Date_end] = (dr["Oblig_Date_end"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedBillsColumns.Oferta_Date] = $"{(dr["Oferta_Date"] as DateTime?)?.ToString("dd.MM.yyyy")} ({dr["Oferta_Type"]})";
                row[ClosedBillsColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[ClosedBillsColumns.Amount] = dr["Amount"].DecimalToStr();
                row[ClosedBillsColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[ClosedBillsColumns.UKD] = dr["UKD"].DecimalToStr();
                row[ClosedBillsColumns.In_Summa_UKD] = ((decimal)dr["In_Summa"] + (decimal)dr["UKD"]).DecimalToStr();
                row[ClosedBillsColumns.Out_Price] = dr["OutPrice"].DecimalToStr();
                row[ClosedBillsColumns.NKD] = dr["NKD"].DecimalToStr();
                row[ClosedBillsColumns.Amortizations] = $"{dr["Amortizations"].DecimalToStr()} ({dr["Coupons"].DecimalToStr()})";
                row[ClosedBillsColumns.Out_Date] = (dr["Out_Date"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedBillsColumns.Out_Summa] = dr["Out_Summa"].DecimalToStr();
                row[ClosedBillsColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[ClosedBillsColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitClosedCash() 
        {
            ClosedCash = new TableView();
            ClosedCash.Table = new DataTable(); 
            ClosedCash.Table.Columns.Add(ClosedCashColumns.IN_DATE);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.Investment);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.IN_PRICE);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.Amount);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.In_Summa);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.Out_Price);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.Out_Date);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.Out_Summa);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.FinRes);
            ClosedCash.Table.Columns.Add(ClosedCashColumns.FinResProcent);

            ClosedCash.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedCashColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedCashColumns.Investment, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = ClosedCashColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedCashColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedCashColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedCashColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedCashColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedCashColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedCashColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedCashColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 10},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.ClosedCash].Rows)
            {
                DataRow row = ClosedCash.Table.NewRow(); 
                row[ClosedCashColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[ClosedCashColumns.Investment] = dr["Investment"];
                row[ClosedCashColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[ClosedCashColumns.Amount] = dr["Amount"].DecimalToStr();
                row[ClosedCashColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[ClosedCashColumns.Out_Price] = dr["OutPrice"].DecimalToStr();
                row[ClosedCashColumns.Out_Date] = (dr["Out_Date"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[ClosedCashColumns.Out_Summa] = dr["Out_Summa"].DecimalToStr();
                row[ClosedCashColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[ClosedCashColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }

        }
        private void InitCurrentShares() {
            CurrentShares = new TableView();
            CurrentShares.Table = new DataTable(); 
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.IN_DATE);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.ISIN);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Investment);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.IN_PRICE);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Amount);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.In_Summa);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Today_Price);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Dividends);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Value_NOM);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.FinRes);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.FinResProcent);

            CurrentShares.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentSharesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Value_NOM, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 10},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 11},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.CurrentShares].Rows)
            {
                DataRow row = CurrentShares.Table.NewRow(); 
                row[CurrentSharesColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[CurrentSharesColumns.ISIN] = dr["ISIN"];
                row[CurrentSharesColumns.Investment] = dr["Investment"];
                row[CurrentSharesColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[CurrentSharesColumns.Amount] = dr["Amount"].DecimalToStr();
                row[CurrentSharesColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[CurrentSharesColumns.Today_Price] = dr["Today_Price"];
                row[CurrentSharesColumns.Dividends] = dr["Dividends"];
                row[CurrentSharesColumns.Value_NOM] = dr["Value_NOM"];
                row[CurrentSharesColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[CurrentSharesColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitCurrentBonds() {
            CurrentBonds = new TableView();
            CurrentBonds.Table = new DataTable(); 
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.ISIN);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Investment);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Oblig_Date_end);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Oferta_Date);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.IN_PRICE);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Amount);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.In_Summa_UKD);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.UKD);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.In_Summa);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Today_Price);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.NKD);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Amortizations);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Value_Nom);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.FinRes);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.FinResProcent);

            CurrentBonds.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = CurrentBondsColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.In_Summa_UKD, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.In_Summa, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 11},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Value_Nom, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 14},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 15},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 16},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.CurrentBonds].Rows)
            {
                DataRow row = CurrentBonds.Table.NewRow(); 
                row[CurrentBondsColumns.ISIN] = dr["ISIN"];
                row[CurrentBondsColumns.Investment] = dr["Investment"];
                row[CurrentBondsColumns.Oblig_Date_end] = (dr["Oblig_Date_end"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[CurrentBondsColumns.Oferta_Date] = $"{(dr["Oferta_Date"] as DateTime?)?.ToString("dd.MM.yyyy")} ({dr["Oferta_Type"]})";
                row[CurrentBondsColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[CurrentBondsColumns.Amount] = dr["Amount"].DecimalToStr();
                row[CurrentBondsColumns.In_Summa_UKD] = ((decimal)dr["In_Summa"] + (decimal)dr["UKD"]).DecimalToStr();
                row[CurrentBondsColumns.UKD] = dr["UKD"].DecimalToStr();
                row[CurrentBondsColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[CurrentBondsColumns.Today_Price] = dr["Today_Price"];
                row[CurrentBondsColumns.NKD] = dr["NKD"].DecimalToStr();
                row[CurrentBondsColumns.Amortizations] = $"{dr["Amortizations"].DecimalToStr()} ({dr["Coupons"].DecimalToStr()})";
                row[CurrentBondsColumns.Value_Nom] = dr["Value_Nom"];
                row[CurrentBondsColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[CurrentBondsColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }


        }
        private void InitCurrentBills() {
            CurrentBills = new TableView();
            CurrentBills.Table = new DataTable(); 
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.IN_DATE);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.ISIN);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Investment);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Oblig_Date_end);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Oferta_Date);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.IN_PRICE);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Amount);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.In_Summa);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.UKD);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.In_Summa_UKD);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Today_Price);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.NKD);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Amortizations);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Value_Nom);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.FinRes);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.FinResProcent);

            CurrentBills.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentBillsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.In_Summa, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 11},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Value_Nom, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 14},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 15},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 16},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.CurrentBills].Rows)
{
                DataRow row = CurrentBills.Table.NewRow(); 
                row[CurrentBillsColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[CurrentBillsColumns.ISIN] = dr["ISIN"];
                row[CurrentBillsColumns.Investment] = dr["Investment"];
                row[CurrentBillsColumns.Oblig_Date_end] = (dr["Oblig_Date_end"] as DateTime?)?.ToString("dd.MM.yyyy");
                row[CurrentBillsColumns.Oferta_Date] = $"{(dr["Oferta_Date"] as DateTime?)?.ToString("dd.MM.yyyy")} ({dr["Oferta_Type"]})";
                row[CurrentBillsColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[CurrentBillsColumns.Amount] = dr["Amount"].DecimalToStr();
                row[CurrentBillsColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[CurrentBillsColumns.UKD] = dr["UKD"].DecimalToStr();
                row[CurrentBillsColumns.In_Summa_UKD] = ((decimal)dr["In_Summa"] + (decimal)dr["UKD"]).DecimalToStr();
                row[CurrentBillsColumns.Today_Price] = dr["Today_Price"];
                row[CurrentBillsColumns.NKD] = dr["NKD"].DecimalToStr();
                row[CurrentBillsColumns.Amortizations] = $"{dr["Amortizations"].DecimalToStr()} ({dr["Coupons"].DecimalToStr()})";
                row[CurrentBillsColumns.Value_Nom] = dr["Value_Nom"];
                row[CurrentBillsColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[CurrentBillsColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitCurrentCash() {
            CurrentCash = new TableView();
            CurrentCash.Table = new DataTable(); 
            CurrentCash.Table.Columns.Add(CurrentCashColumns.IN_DATE);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.Investment);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.IN_PRICE);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.Amount);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.In_Summa);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.Today_Price);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.Value_NOM);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.FinRes);
            CurrentCash.Table.Columns.Add(CurrentCashColumns.FinResProcent);

            CurrentCash.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentCashColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Investment, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentCashColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки + валюта", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentCashColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Value_NOM, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentCashColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentCashColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 9},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.CurrentCash].Rows)
            { 
                DataRow row = CurrentCash.Table.NewRow(); 
                row[CurrentCashColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[CurrentCashColumns.Investment] = dr["Investment"];
                row[CurrentCashColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[CurrentCashColumns.Amount] = dr["Amount"].DecimalToStr();
                row[CurrentCashColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[CurrentCashColumns.Today_Price] = dr["Today_Price"];
                row[CurrentCashColumns.Value_NOM] = dr["Value_NOM"];
                row[CurrentCashColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[CurrentCashColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }


        }
        private void InitCurrentFunds() {
            CurrentFunds = new TableView();
            CurrentFunds.Table = new DataTable(); 
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.IN_DATE);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.Investment);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.IN_PRICE);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.Amount);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.In_Summa);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.Today_Price);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.Value_NOM);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.FinRes);
            CurrentFunds.Table.Columns.Add(CurrentFundsColumns.FinResProcent);

            CurrentFunds.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentFundsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Investment, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки + валюта", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Value_NOM, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 9},
            };

           foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.CurrentFunds].Rows)
            {
                DataRow row = CurrentFunds.Table.NewRow(); 
                row[CurrentFundsColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[CurrentFundsColumns.Investment] = dr["Investment"];
                row[CurrentFundsColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[CurrentFundsColumns.Amount] = dr["Amount"].DecimalToStr();
                row[CurrentFundsColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[CurrentFundsColumns.Today_Price] = dr["Today_Price"];
                row[CurrentFundsColumns.Value_NOM] = dr["Value_NOM"];
                row[CurrentFundsColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[CurrentFundsColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }
        }
        private void InitCurrentDerivatives() {
            CurrentDerivatives = new TableView();
            CurrentDerivatives.Table = new DataTable(); 
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.IN_DATE);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.ISIN);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Investment);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.IN_PRICE);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Amount);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.In_Summa);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Today_Price);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Dividends);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Value_NOM);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.FinRes);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.FinResProcent);

            CurrentDerivatives.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.ISIN, DisplayName = "ISIN", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Value_NOM, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 10},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 11},
            };

            foreach (DataRow dr in _TrustManagementDS.Tables[DuTables.CurrentDerivatives].Rows)
            {
                DataRow row = CurrentDerivatives.Table.NewRow(); 
                row[CurrentDerivativesColumns.IN_DATE] = ((DateTime)dr["IN_DATE"]).ToString("dd.MM.yyyy");
                row[CurrentDerivativesColumns.ISIN] = dr["ISIN"];
                row[CurrentDerivativesColumns.Investment] = dr["Investment"];
                row[CurrentDerivativesColumns.IN_PRICE] = $"{dr["IN_PRICE"].DecimalToStr()} {dr["Valuta"]}";
                row[CurrentDerivativesColumns.Amount] = dr["Amount"].DecimalToStr();
                row[CurrentDerivativesColumns.In_Summa] = dr["In_Summa"].DecimalToStr();
                row[CurrentDerivativesColumns.Today_Price] = dr["Today_Price"];
                row[CurrentDerivativesColumns.Dividends] = dr["Dividends"];
                row[CurrentDerivativesColumns.Value_NOM] = dr["Value_NOM"];
                row[CurrentDerivativesColumns.FinRes] = dr["FinRes"].DecimalToStr();
                row[CurrentDerivativesColumns.FinResProcent] = $"{dr["FinResProcent"].DecimalToStr("#0.00")}%";
            }

        }

    }
    public class DuTables
    {
        public const int MainResultDT = 0;
        public const int DiagramDT = 3;
        public const int CurrentShares = 11;
        public const int ClosedShares = 12;
        public const int CurrentBonds = 13;
        public const int ClosedBonds = 14;
        public const int CurrentBills = 15;
        public const int ClosedBills = 16;
        public const int CurrentCash = 17;
        public const int ClosedCash = 18;
        public const int CurrentFunds = 19;
        public const int ClosedFunds = 20;
        public const int CurrentDerivatives = 21;
        public const int ClosedDerivatives = 22;

    }
}
