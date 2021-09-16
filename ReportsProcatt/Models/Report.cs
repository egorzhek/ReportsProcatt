using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class Report
    {
        #region Свойства
        public string rootStr { get; set; }
        public int InvestorId { get; private set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public DateTime Dfrom => (DateTime)_invFullDS.GetValue(InvestFullTables.MainResultDT, "StartDate");
        public DateTime Dto => (DateTime)_invFullDS.GetValue(InvestFullTables.MainResultDT, "EndDate");
        public CurrencyClass ReportCurrency { get; set; }
        public string CurrChar => "₽";
        public Headers MainHeader { get; private set; }
        public Dictionary<string, string> MainDiagram { get; private set; }
        public TableView PIFsTotals { get; set; }
        public TableView DUsTotals { get; set; }
        public TableView AllAssets { get; set; }
        public TableView DivsNCoupons { get; set; }
        public TableView DivsNCouponsDetails { get; set; }
        public CircleDiagram Assets { get; set; }
        public CircleDiagram Instruments { get; set; }
        public CircleDiagram Currencies { get; set; }
        public List<PIF> PIFs { get; set; }
        public List<DU> DUs { get; set; }
        #endregion
        #region Поля
        private SQLData _data;
        private DataSet _invFullDS => _data.DataSet_InvestorFull;
        private DataSet _circleAssetsDS => _data.DataSet_CircleAssets;
        private DataSet _circleCurrenciesDS => _data.DataSet_CircleCurrencies;
        private DataSet _circleInstrumentsDS => _data.DataSet_CircleInstruments;
        private string connectionString => @"Data Source=DESKTOP-2G9NLM6\MSSQLSERVER15;Encrypt=False;Initial Catalog=CacheDB;Integrated Security=True;User ID=DESKTOP-2G9NLM6\D";
        private string ReportPath = @"c:\Users\D\source\Ingos\ReportsProcatt\Reports\";
        #endregion
        public Report(int aInvestorId, DateTime? aDateFrom, DateTime? aDateTo)
        {
            ReportCurrency = new CurrencyClass
            {
                Code = "RUB",
                Char = "₽",
                Name = "Рубли"
            };

            InvestorId = aInvestorId;
            _data = new SQLData(ReportCurrency.Code ,aInvestorId, aDateFrom, aDateTo, connectionString, ReportPath);

            MainHeader = new Headers
            {
                TotalSum = $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ActiveDateToValue", "#,##0")} {CurrChar}",
                ProfitSum = $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ProfitValue", "#,##0")} {CurrChar}",
                Return = $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ProfitProcentValue","#0.00", aWithSign: true)}%"
            };
            InitMainDiagram();
            InitPIFsTotalTable();
            InitDUsTotalTable();
            InitAllAssetsTable();
            InitAssets();
            InitInstruments();
            InitCurrencies();
            InitPIFs();
            InitDUs();
        }
        #region Методы
        public void InitMainDiagram()
        {
            MainDiagram = new Dictionary<string, string>();
            MainDiagram.Add(MainDiagramParams.Begin, _invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "Snach", "#,##0"));
            MainDiagram.Add(MainDiagramParams.InVal, _invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "InVal", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.OutVal, _invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "OutVal", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.Dividents, _invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "Dividents", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.Coupons, _invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "Coupons", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.ReVal, "");
            MainDiagram.Add(MainDiagramParams.Taxes, "");
            MainDiagram.Add(MainDiagramParams.Fee, "");
            MainDiagram.Add(MainDiagramParams.End, _invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ActiveDateToValue", "#,##0"));
        }
        public void InitPIFsTotalTable()
        {
            PIFsTotals = new TableView();
            PIFsTotals.Table = new DataTable();
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.PIFs);
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.AssetsToEnd);
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.Result);

            PIFsTotals.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = PIFsTotalColumns.PIFs, DisplayName = "ПИФЫ", SortOrder = 1},
                new ViewElementAttr{ColumnName = PIFsTotalColumns.AssetsToEnd, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = PIFsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ ЗА {Period}", SortOrder = 3 }
            };
            PIFsTotals.Ths.Where(t => t.ColumnName == PIFsTotalColumns.PIFs).First().AttrRow.Add("width", "520px");

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.FundsDt].Rows)
            {
                StringBuilder vRes = new StringBuilder();
                vRes.Append(dr["ProfitValue"].DecimalToStr("#,##0"));
                vRes.Append($"({dr["ProfitProcentValue"].DecimalToStr()})");
                vRes.Append(dr["Valuta"]);

                DataRow row = PIFsTotals.Table.NewRow();
                row[PIFsTotalColumns.PIFs] = dr["FundName"];
                row[PIFsTotalColumns.AssetsToEnd] = dr["EndValue"].DecimalToStr("#,##0");
                row[PIFsTotalColumns.Result] = vRes.ToString();
                PIFsTotals.Table.Rows.Add(row);
            }
        }
        public void InitDUsTotalTable()
        {
            DUsTotals = new TableView();
            DUsTotals.Table = new DataTable();
            DUsTotals.Table.Columns.Add(DUsTotalColumns.DUs);
            DUsTotals.Table.Columns.Add(DUsTotalColumns.AssetsToEnd);
            DUsTotals.Table.Columns.Add(DUsTotalColumns.Result);

            DUsTotals.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = DUsTotalColumns.DUs, DisplayName = "ДОВЕРИТЕЛЬНОЕ УПРАВЛЕНИЕ", SortOrder = 1},
                new ViewElementAttr{ColumnName = DUsTotalColumns.AssetsToEnd, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = DUsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ ЗА {Period}", SortOrder = 3 }
            };
            DUsTotals.Ths.Where(t => t.ColumnName == DUsTotalColumns.DUs).First().AttrRow.Add("width", "520px");

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.DUsDt].Rows)
            {
                StringBuilder vRes = new StringBuilder();
                vRes.Append(dr["ProfitValue"].DecimalToStr("#,##0"));
                vRes.Append($"({dr["ProfitProcentValue"].DecimalToStr()}%)");
                vRes.Append(dr["Valuta"]);

                DataRow row = DUsTotals.Table.NewRow();
                row[DUsTotalColumns.DUs] = dr["ContractName"];
                row[DUsTotalColumns.AssetsToEnd] = dr["EndValue"].DecimalToStr("#,##0");
                row[DUsTotalColumns.Result] = vRes.ToString();
                DUsTotals.Table.Rows.Add(row);
            }
        }
        public void InitAllAssetsTable()
        {
            AllAssets = new TableView();
            AllAssets.Table = new DataTable();
            AllAssets.Table.Columns.Add(AllAssetsColumns.Product);
            AllAssets.Table.Columns.Add(AllAssetsColumns.BeginAssets);
            AllAssets.Table.Columns.Add(AllAssetsColumns.InVal);
            AllAssets.Table.Columns.Add(AllAssetsColumns.OutVal);
            AllAssets.Table.Columns.Add(AllAssetsColumns.Dividents);
            AllAssets.Table.Columns.Add(AllAssetsColumns.Coupons);
            AllAssets.Table.Columns.Add(AllAssetsColumns.EndAssets);
            AllAssets.Table.Columns.Add(AllAssetsColumns.CurrencyProfit);
            AllAssets.Table.Columns.Add(AllAssetsColumns.ProfitPercent);

            AllAssets.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = AllAssetsColumns.Product, DisplayName = "ПРОДУКТ", SortOrder = 1},
                new ViewElementAttr{ColumnName = AllAssetsColumns.BeginAssets, DisplayName = "АКТИВЫ НА НАЧАЛО ПЕРИОДА", SortOrder = 2},
                new ViewElementAttr{ColumnName = AllAssetsColumns.InVal, DisplayName = "ПОПОЛНЕНИЕ", SortOrder = 3},
                new ViewElementAttr{ColumnName = AllAssetsColumns.OutVal, DisplayName = "ВЫВОД", SortOrder = 4},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Dividents, DisplayName = "СРЕДСТВ", SortOrder = 5},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Coupons, DisplayName = "ДИВИДЕНДЫ", SortOrder = 6},
                new ViewElementAttr{ColumnName = AllAssetsColumns.EndAssets, DisplayName = "КУПОНЫ", SortOrder = 7},
                new ViewElementAttr{ColumnName = AllAssetsColumns.CurrencyProfit, DisplayName = "ДОХОД В ВАЛЮТЕ", SortOrder = 8},
                new ViewElementAttr{ColumnName = AllAssetsColumns.ProfitPercent, DisplayName = "ДОХОД В %", SortOrder = 9},
            };
            AllAssets.Ths.Where(t => t.ColumnName == AllAssetsColumns.Product).First().AttrRow.Add("width", "520px");

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.FundsResultDt].Rows)
            {
                DataRow row = AllAssets.Table.NewRow();
                row[AllAssetsColumns.Product] = dr["NameObject"];
                row[AllAssetsColumns.BeginAssets] = dr["StartDateValue"].DecimalToStr("#,##0");
                row[AllAssetsColumns.InVal] = dr["INPUT_VALUE"].DecimalToStr("#,##0");
                row[AllAssetsColumns.OutVal] = dr["OUTPUT_VALUE"].DecimalToStr("#,##0");
                row[AllAssetsColumns.Dividents] = dr["INPUT_DIVIDENTS"].DecimalToStr("#,##0");
                row[AllAssetsColumns.Coupons] = dr["INPUT_COUPONS"].DecimalToStr("#,##0");
                row[AllAssetsColumns.EndAssets] = dr["StartDateValue"].DecimalToStr("#,##0");
                row[AllAssetsColumns.CurrencyProfit] = dr["ProfitValue"].DecimalToStr("#,##0");
                row[AllAssetsColumns.ProfitPercent] = $"{dr["ProfitProcentValue"].DecimalToStr("#,##0")}%";
                AllAssets.Table.Rows.Add(row);
            }

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.DUsResultDt].Rows)
            {
                DataRow row = AllAssets.Table.NewRow();
                row[AllAssetsColumns.Product] = dr["NameObject"];
                row[AllAssetsColumns.BeginAssets] = dr["StartDateValue"].DecimalToStr("#,##0");
                row[AllAssetsColumns.InVal] = dr["INPUT_VALUE"].DecimalToStr("#,##0");
                row[AllAssetsColumns.OutVal] = dr["OUTPUT_VALUE"].DecimalToStr("#,##0");
                row[AllAssetsColumns.Dividents] = dr["INPUT_DIVIDENTS"].DecimalToStr("#,##0");
                row[AllAssetsColumns.Coupons] = dr["INPUT_COUPONS"].DecimalToStr("#,##0");
                row[AllAssetsColumns.EndAssets] = dr["StartDateValue"].DecimalToStr("#,##0");
                row[AllAssetsColumns.CurrencyProfit] = dr["ProfitValue"].DecimalToStr("#,##0");
                row[AllAssetsColumns.ProfitPercent] = $"{dr["ProfitProcentValue"].DecimalToStr("#,##0")}%";
                AllAssets.Table.Rows.Add(row);
            }
        }
        public void InitAssets()
        {
            int i = 1;
            Assets = new CircleDiagram("MainAssetsCircle")
            {
                LegendName = "Актиывы",
                MainText = $"{_circleAssetsDS.DecimalToStr(1, "AllSum", "#,##0")} {ReportCurrency.Char}",
                Footer = $"{_circleAssetsDS.DecimalToStr(1, "CountRows", "#,##0")} АКТИВА(ов)",
                Data = _circleAssetsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                    .OrderByDescending(r => (decimal)r["Result"])
                    .Take(7)
                    .Select(r => 
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r["CategoryName"]}",
                            data = (decimal)r["VALUE_RUR"],
                            backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainAssetsCircle[i],
                            result = $"{((decimal)r["Result"] * 100).DecimalToStr("#,##0.00")}%"
                        };
                        i++;
                        return el;
                    }).ToList(),
                Type= "doughnut"
                
            };

            if (_circleAssetsDS.Tables[0].Rows.Count > 7)
            {
                decimal otherPerent = 100 -
                    _circleAssetsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (double)r["Result"])
                        .Skip(6)
                        .Sum(r => (decimal)r["Result"]) * 100;

                Assets.Data.RemoveAt(Assets.Data.Count - 1);

                Assets.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = _circleAssetsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Skip(6)
                        .Sum(r => (decimal)r["VALUE_RUR"]),
                    backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                    result = $"{otherPerent.DecimalToStr("#,##0")}%"
                });
            }
        }
        public void InitInstruments()
        {
            int i = 1;
            Instruments = new CircleDiagram("MainInstrumentsCircle")
            {
                LegendName = "Инструменты",
                MainText = $"{_circleInstrumentsDS.DecimalToStr(1, "AllSum", "#,##0")} {ReportCurrency.Char}",
                Footer = $"{_circleInstrumentsDS.DecimalToStr(1, "CountRows", "#,##0")} инструментов",
                Data = _circleInstrumentsDS.Tables[0].Rows.Cast<DataRow>().ToList()
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

            if (_circleInstrumentsDS.Tables[0].Rows.Count > 7)
            {
                decimal otherPerent = 100 -
                    _circleInstrumentsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Skip(6)
                        .Sum(r => (decimal)r["Result"]) * 100;

                Instruments.Data.RemoveAt(Instruments.Data.Count - 1);

                Instruments.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = _circleInstrumentsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Skip(6)
                        .Sum(r => (decimal)r["VALUE_RUR"]),
                    backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                    result = $"{otherPerent.DecimalToStr("#,##0")}%"
                });
            }
        }

        public void InitCurrencies()
        {
            int i = 1;
            Currencies = new CircleDiagram("MainCurrenciesCircle")
            {
                LegendName = "Вылюта",
                MainText = $"{_circleCurrenciesDS.DecimalToStr(1, "AllSum", "#,##0")} {ReportCurrency.Char}",
                Data = _circleCurrenciesDS.Tables[0].Rows.Cast<DataRow>().ToList()
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

            if (_circleCurrenciesDS.Tables[0].Rows.Count > 7)
            {
                decimal otherPerent = 100 -
                    _circleCurrenciesDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (double)r["Result"])
                        .Skip(6)
                        .Sum(r => (decimal)r["Result"]) * 100;

                Currencies.Data.RemoveAt(Currencies.Data.Count - 1);

                Currencies.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = _circleCurrenciesDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => (decimal)r["Result"])
                        .Skip(6)
                        .Sum(r => (decimal)r["VALUE_RUR"]),
                    backgroundColor = CircleDiagramsColorCodes.MainCurrenciesCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainCurrenciesCircle[7],
                    result = $"{otherPerent.DecimalToStr("#,##0")}%"
                });
            }
        }

        public void InitPIFs()
        {
            PIFs = new List<PIF>();
            Task.WaitAll
            (
                _invFullDS.Tables[InvestFullTables.FundsDt].Rows.Cast<DataRow>().ToList()
                .Select(r => Task.Run(() =>
                {
                    PIFs.Add(new PIF(r["FundName"].ToString(), Dfrom, Dto, ReportCurrency, (int)r["FundId"], InvestorId, connectionString, ReportPath));
                })).ToArray()
            );
        }
        public void InitDUs()
        {
            DUs = new List<DU>();
            Task.WaitAll
            (
                _invFullDS.Tables[InvestFullTables.DUsDt].Rows.Cast<DataRow>().ToList()
                .Select(r => Task.Run(() =>
                {
                    DUs.Add(new DU(r["ContractName"].ToString(), Dfrom, Dto, ReportCurrency, (int)r["ContractId"], InvestorId, connectionString, ReportPath));
                })).ToArray()
            );
        }
        #endregion
    }
    public class InvestFullTables
    {
        public const int MainResultDT = 0;
        public const int MainDiagramDT = 1;
        public const int FundsDt = 4;
        public const int DUsDt = 5;
        public const int FundsResultDt = 6;
        public const int DUsResultDt = 7;
    }
}
