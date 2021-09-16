using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class PIF
    {
        public int Id { get; private set; }
        public string Name { get; private set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public Headers PifHeader { get; set; }
        public DateTime Dfrom { get; set; }
        public DateTime Dto { get; set; }
        public CurrencyClass Currency { get; set; }
        public Dictionary<string, string> Diagram { get; set; }
        public string AccountNumber => _FundInfoDS.GetValue(PifTables.MainResultDT, "LS_NUM").ToString();
        public string OpenDate => ((DateTime)_FundInfoDS.GetValue(PifTables.MainResultDT, "OpenDate")).ToString("dd.MM.yyyy");
        public string Amount => $"{_FundInfoDS.GetValue(PifTables.MainResultDT, "EndSumAmount")} шт.";
        public CircleDiagram AssetsStruct { get; set; }
        public CircleDiagram FundStruct { get; set; }
        public TableView OperationsHistory { get; set; }
        #region Поля
        private SQLDataPIF _data;
        private DataSet _FundInfoDS => _data.DataSet_FundInfo;
        private DataSet _PifDS => _data.DataSet_PIF;
        private DataSet _Pif2DS => _data.DataSet_PIF2;
        #endregion
        public PIF(
            string aName,
            DateTime aDFrom,
            DateTime aDTo,
            CurrencyClass aCurrency,
            int FundId,
            int InvestorId,
            string connectionString,
            string ReportPath)
        {
            Id = FundId;
            Name = aName;
            Dfrom = aDFrom;
            Dto = aDTo;
            Currency = aCurrency;
            _data = new SQLDataPIF(Currency.Code, FundId, InvestorId, aDFrom, aDTo, connectionString, ReportPath);

            PifHeader = new Headers
            {
                TotalSum = $"{_FundInfoDS.DecimalToStr(PifTables.MainResultDT, "ActiveDateToValue", "#,##0")} {Currency.Char}",
                ProfitSum = $"{_FundInfoDS.DecimalToStr(PifTables.MainResultDT, "ProfitValue", "#,##0")} {Currency.Char}",
                Return = $"{_FundInfoDS.DecimalToStr(PifTables.MainResultDT, "ProfitProcentValue", aWithSign: true)}%"
            };
            Diagram = new Dictionary<string, string>
            {
                { PifDiagramColumns.Begin, _FundInfoDS.DecimalToStr(PifTables.DiagramDT, "ActiveValue", "#,##0") },
                { PifDiagramColumns.InVal, _FundInfoDS.DecimalToStr(PifTables.DiagramDT, "Пополнения", "#,##0") },
                { PifDiagramColumns.OutVal, _FundInfoDS.DecimalToStr(PifTables.DiagramDT, "Выводы", "#,##0") },
                { PifDiagramColumns.End, _FundInfoDS.DecimalToStr(PifTables.MainResultDT, "ActiveDateToValue", "#,##0") }
            };
            //InitAccountDetails();
            InitAssetsStruct();
            InitFundStruct();
            InitOperationsHistory();
        }
        private void InitAssetsStruct()
        {
            if (_PifDS.Tables[0].Rows.Count > 0)
            {
                int i = 1;
                AssetsStruct = new CircleDiagram($"Fund_{Id}_AssetsStructCircle")
                {
                    LegendName = "Активы",
                    MainText = $"{_PifDS.DecimalToStr(0, "AllSum", "#,##0")} {Currency.Char}",
                    Footer = $"{_PifDS.Tables[0].Rows.Count} АКТИВА(ов)",
                    Data = _PifDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Take(7)
                        .Select(r =>
                        {
                            var el = new CircleDiagram.DataClass
                            {
                                lable = $"{r["CurrencyName"]}",
                                data = (decimal)r["VALUE_RUR"],
                                backgroundColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                                borderColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                                result = $"{((decimal)r["Result"] * 100).DecimalToStr("#,##0.00")}%"
                            };
                            i++;
                            return el;
                        }).ToList(),
                    Type = "doughnut"

                };

                if (_PifDS.Tables[0].Rows.Count > 7)
                {
                    decimal otherPerent = 100 -
                        _PifDS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (double)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["Result"]) * 100;

                    AssetsStruct.Data.RemoveAt(AssetsStruct.Data.Count - 1);

                    AssetsStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее",
                        data = _PifDS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (decimal)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["VALUE_RUR"]),
                        backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        result = $"{otherPerent.DecimalToStr("#,##0")}%"
                    });
                }
            }
        }
        private void InitFundStruct()
        {
            if (_Pif2DS.Tables[0].Rows.Count > 0)
            {
                int i = 1;
                FundStruct = new CircleDiagram($"Fund_{Id}_StructCircle")
                {
                    LegendName = "Инструменты",
                    MainText = $"{_Pif2DS.DecimalToStr(1, "AllSum", "#,##0")} {Currency.Char}",
                    Footer = $"{_Pif2DS.Tables[0].Rows.Count} инструментов",
                    Data = _Pif2DS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Take(7)
                        .Select(r =>
                        {
                            var el = new CircleDiagram.DataClass
                            {
                                lable = $"{r["Investment"]}",
                                data = (decimal)r["VALUE_RUR"],
                                backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                                borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                                result = $"{((decimal)r["Result"] * 100).DecimalToStr("#,##0.00")}%"
                            };
                            i++;
                            return el;
                        }).ToList(),
                    Type = "doughnut"

                };

                if (_Pif2DS.Tables[0].Rows.Count > 7)
                {
                    decimal otherPerent = 100 -
                        _Pif2DS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (decimal)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["Result"]) * 100;

                    FundStruct.Data.RemoveAt(FundStruct.Data.Count - 1);

                    FundStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее",
                        data = _Pif2DS.Tables[0].Rows.Cast<DataRow>().ToList()
                            .OrderByDescending(r => (decimal)r["Result"])
                            .Skip(6)
                            .Sum(r => (decimal)r["VALUE_RUR"]),
                        backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        result = $"{otherPerent.DecimalToStr("#,##0")}%"
                    });
                }
            }
        }
        private void InitOperationsHistory()
        {
            OperationsHistory = new TableView();
            OperationsHistory.Table = new DataTable();
            OperationsHistory.Table.Columns.Add(OperationsHistoryColumns.Wdate);
            OperationsHistory.Table.Columns.Add(OperationsHistoryColumns.Btype);
            OperationsHistory.Table.Columns.Add(OperationsHistoryColumns.Rate_rur);
            OperationsHistory.Table.Columns.Add(OperationsHistoryColumns.Amount);
            OperationsHistory.Table.Columns.Add(OperationsHistoryColumns.Value_rur);
            OperationsHistory.Table.Columns.Add(OperationsHistoryColumns.Fee_rur);

            OperationsHistory.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = OperationsHistoryColumns.Wdate, DisplayName = "Дата операции", SortOrder = 1},
                new ViewElementAttr{ColumnName = OperationsHistoryColumns.Btype, DisplayName = "Тип операции", SortOrder = 2},
                new ViewElementAttr{ColumnName = OperationsHistoryColumns.Rate_rur, DisplayName = "Стоимость бумаги", SortOrder = 3},
                new ViewElementAttr{ColumnName = OperationsHistoryColumns.Amount, DisplayName = "Количество", SortOrder = 4},
                new ViewElementAttr{ColumnName = OperationsHistoryColumns.Value_rur, DisplayName = "Сумма сделки", SortOrder = 5},
                new ViewElementAttr{ColumnName = OperationsHistoryColumns.Fee_rur, DisplayName = "Комиссия", SortOrder = 6}
            };

            foreach (DataRow dr in _FundInfoDS.Tables[PifTables.OperationsHistory].Rows)
            {
                DataRow row = OperationsHistory.Table.NewRow();
                row[OperationsHistoryColumns.Wdate] = dr["W_Date"];
                row[OperationsHistoryColumns.Btype] = dr["OperName"];
                row[OperationsHistoryColumns.Rate_rur] = dr["RATE_RUR"];
                row[OperationsHistoryColumns.Amount] = dr["Amount"];
                row[OperationsHistoryColumns.Value_rur] = dr["VALUE_RUR"];
                row[OperationsHistoryColumns.Fee_rur] = dr["FEE_RUR"];
                OperationsHistory.Table.Rows.Add(row);
            }

        }
    }
    public class PifTables
    {
        public const int MainResultDT = 0;
        public const int DiagramDT = 1;
        public const int OperationsHistory = 2;
    }
}
