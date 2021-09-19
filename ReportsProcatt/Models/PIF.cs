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
        public TableView PifOperationsHistory { get; set; }
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
            PifOperationsHistory = new TableView();
            PifOperationsHistory.Table = new DataTable();
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Wdate);
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Btype);
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Instrument);
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Rate_rur);
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Amount);
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Value_rur);
            PifOperationsHistory.Table.Columns.Add(PifOperationsHistoryColumns.Fee_rur);

            PifOperationsHistory.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Wdate, DisplayName = "Дата", SortOrder = 1},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Btype, DisplayName = "Тип операции", SortOrder = 2},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Instrument, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Rate_rur, DisplayName = "Цена Пая", SortOrder = 4},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Amount, DisplayName = "Количество", SortOrder = 5},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Value_rur, DisplayName = "Сумма сделки", SortOrder = 6},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Fee_rur, DisplayName = "Комиссия (надбавка/скидка)", SortOrder = 7}
            };

            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Wdate).First().AttrRow.Add("width", "170px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Btype).First().AttrRow.Add("width", "300px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Rate_rur).First().AttrRow.Add("width", "130px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Amount).First().AttrRow.Add("width", "96px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Value_rur).First().AttrRow.Add("width", "145px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Fee_rur).First().AttrRow.Add("width", "117px");


            foreach (DataRow dr in _FundInfoDS.Tables[PifTables.OperationsHistory].Rows)
            {
                DataRow row = PifOperationsHistory.Table.NewRow();
                row[PifOperationsHistoryColumns.Wdate] = dr["W_Date"];
                row[PifOperationsHistoryColumns.Btype] = dr["OperName"];
                row[PifOperationsHistoryColumns.Instrument] = dr["Order_NUM"];
                row[PifOperationsHistoryColumns.Rate_rur] = dr["RATE_RUR"].DecimalToStr();
                row[PifOperationsHistoryColumns.Amount] = dr["Amount"].DecimalToStr();
                row[PifOperationsHistoryColumns.Value_rur] = dr["VALUE_RUR"].DecimalToStr();
                row[PifOperationsHistoryColumns.Fee_rur] = dr["FEE_RUR"].DecimalToStr();
                PifOperationsHistory.Table.Rows.Add(row);
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
