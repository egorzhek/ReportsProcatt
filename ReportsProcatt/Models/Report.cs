using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

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
        public Headers MainHeader { get; private set; }
        public Dictionary<string, string> MainDiagram { get; private set; }
        public TableView PIFsTotals { get; set; }
        public TableView DUsTotals { get; set; }
        public TableView AllAssets { get; set; }
        public TableView DivsNCoupons { get; set; }
        public ChartDiaramnClass DivsNCouponsChart { get; set; }
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
        private string connectionString;
        private string ReportPath;

        #endregion
        public Report(int aInvestorId, DateTime? aDateFrom, DateTime? aDateTo,string CurrencyCode)
        {
            ReportPath = Environment.GetEnvironmentVariable("ReportPath");
            connectionString = Program.GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));
            //connectionString = @"Data Source=DESKTOP-30A75GK;Encrypt=False;Initial Catalog=CacheDB;Integrated Security=True;User ID=DESKTOP-30A75GK\Света";
            //connectionString = @"Data Source=DESKTOP-2G9NLM6\MSSQLSERVER15;Encrypt=False;Initial Catalog=CacheDB;Integrated Security=True;User ID=DESKTOP-2G9NLM6\D";
            //ReportPath = @"c:\Users\D\source\Ingos\ReportsProcatt\Reports\";

            ReportCurrency = CurrencyClass.GetCurrency(CurrencyCode);

            InvestorId = aInvestorId;
            _data = new SQLData(ReportCurrency.Code ,aInvestorId, aDateFrom, aDateTo, connectionString, ReportPath);

            MainHeader = new Headers
            {
                TotalSum = $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ActiveDateToValue", "#,##0")} {ReportCurrency.Char}",
                ProfitSum = $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ProfitValue", "#,##0")} {ReportCurrency.Char}",
                Return = $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ProfitProcentValue","#0.00", aWithSign: true)}%"
            };
            InitMainDiagram();
            InitPIFsTotalTable();
            InitDUsTotalTable();
            InitDivsNCoupons();
            InitDivsNCouponsChart();
            InitDivsNCouponsDetails();
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
            MainDiagram.Add(MainDiagramParams.Begin, $"{_invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "Snach", "#,##0")} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.InVal, $"{_invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "InVal", "#,##0", true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.OutVal, $"{_invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "OutVal2", "#,##0", true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.Dividents, $"{_invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "Dividents", "#,##0", true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.Coupons, $"{_invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "Coupons", "#,##0", true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.OutVal1, $"{_invFullDS.DecimalToStr(InvestFullTables.MainDiagramDT, "OutVal1", "#,##0", true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.End, $"{_invFullDS.DecimalToStr(InvestFullTables.MainResultDT, "ActiveDateToValue", "#,##0")} {ReportCurrency.Char}");
        }
        public void InitPIFsTotalTable()
        {
            PIFsTotals = new TableView();
            PIFsTotals.IsTextBlock = true;
            PIFsTotals.Table = new DataTable();
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.PIFs);
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.StartValue);
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.EndValue);
            PIFsTotals.Table.Columns.Add(PIFsTotalColumns.Result);

            PIFsTotals.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = PIFsTotalColumns.PIFs, DisplayName = "ПИФЫ", SortOrder = 0},
                new ViewElementAttr{ColumnName = PIFsTotalColumns.EndValue, DisplayName = $"АКТИВЫ НА {Dfrom.ToString("dd.MM.yyyy")}", SortOrder = 1 },
                new ViewElementAttr{ColumnName = PIFsTotalColumns.StartValue, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = PIFsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ* ЗА {Period}", SortOrder = 3 }
            };
            PIFsTotals.Ths.Where(t => t.ColumnName == PIFsTotalColumns.PIFs).First().AttrRow.Add("width", "520px");

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.FundsDt].Rows)
            {
                DataRow row = PIFsTotals.Table.NewRow();
                row[PIFsTotalColumns.PIFs] = dr["FundName"];
                row[PIFsTotalColumns.StartValue] = dr["BeginValue"].DecimalToStr();
                row[PIFsTotalColumns.EndValue] = dr["EndValue"].DecimalToStr();
                row[PIFsTotalColumns.Result] = $"{dr["ProfitValue"].DecimalToStr()} {dr["Valuta"]} ({dr["ProfitProcentValue"].DecimalToStr("#,##0.00")}%)";
                PIFsTotals.Table.Rows.Add(row);
            }
        }
        public void InitDUsTotalTable()
        {
            DUsTotals = new TableView();
            DUsTotals.IsTextBlock = true;
            DUsTotals.Table = new DataTable();
            DUsTotals.Table.Columns.Add(DUsTotalColumns.DUs);
            DUsTotals.Table.Columns.Add(DUsTotalColumns.StartValue);
            DUsTotals.Table.Columns.Add(DUsTotalColumns.EndValue);
            DUsTotals.Table.Columns.Add(DUsTotalColumns.Result);

            DUsTotals.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = DUsTotalColumns.DUs, DisplayName = "ДОВЕРИТЕЛЬНОЕ УПРАВЛЕНИЕ", SortOrder = 0},
                new ViewElementAttr{ColumnName = DUsTotalColumns.StartValue, DisplayName = $"АКТИВЫ НА {Dfrom.ToString("dd.MM.yyyy")}", SortOrder = 1 },
                new ViewElementAttr{ColumnName = DUsTotalColumns.EndValue, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = DUsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ*  ЗА {Period}", SortOrder = 3 }
            };
            DUsTotals.Ths.Where(t => t.ColumnName == DUsTotalColumns.DUs).First().AttrRow.Add("width", "520px");

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.DUsDt].Rows)
            {
                DataRow row = DUsTotals.Table.NewRow();
                row[DUsTotalColumns.DUs] = dr["ContractName"];
                row[DUsTotalColumns.StartValue] = dr["BeginValue"].DecimalToStr();
                row[DUsTotalColumns.EndValue] = dr["EndValue"].DecimalToStr();
                row[DUsTotalColumns.Result] = $"{dr["ProfitValue"].DecimalToStr()} {dr["Valuta"]} ({dr["ProfitProcentValue"].DecimalToStr("#,##0.00")}%)";
                DUsTotals.Table.Rows.Add(row);
            }
        }
        private void InitDivsNCoupons()
        {
            DivsNCoupons = new TableView();
            DivsNCoupons.Table = new DataTable(); 
            DivsNCoupons.Table.Columns.Add(DivsNCouponsColumns.NameObject);
            DivsNCoupons.Table.Columns.Add(DivsNCouponsColumns.INPUT_DIVIDENTS);
            DivsNCoupons.Table.Columns.Add(DivsNCouponsColumns.INPUT_COUPONS);
            DivsNCoupons.Table.Columns.Add(DivsNCouponsColumns.Summ);

            DivsNCoupons.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = DivsNCouponsColumns.NameObject, DisplayName = "Продукт", SortOrder = 1},
                new ViewElementAttr{ColumnName = DivsNCouponsColumns.INPUT_DIVIDENTS, DisplayName = "Дивиденды", SortOrder = 2},
                new ViewElementAttr{ColumnName = DivsNCouponsColumns.INPUT_COUPONS, DisplayName = "Купоны", SortOrder = 3},
                new ViewElementAttr{ColumnName = DivsNCouponsColumns.Summ, DisplayName = "Сумма", SortOrder = 4}
            };

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.DivsNCoupons].Rows)
            {
                DataRow row = DivsNCoupons.Table.NewRow(); 
                row[DivsNCouponsColumns.NameObject] = dr["NameObject"];
                row[DivsNCouponsColumns.INPUT_DIVIDENTS] = $"{dr["INPUT_DIVIDENTS"].DecimalToStr()} {dr["Valuta"]}";
                row[DivsNCouponsColumns.INPUT_COUPONS] = $"{dr["INPUT_COUPONS"].DecimalToStr()} {dr["Valuta"]}";
                row[DivsNCouponsColumns.Summ] = $"{(dr["INPUT_DIVIDENTS"].ToDecimal() + dr["INPUT_COUPONS"].ToDecimal()).DecimalToStr()} {dr["Valuta"]}";
                DivsNCoupons.Table.Rows.Add(row);
            }
        }
        private void InitDivsNCouponsChart()
        {
            var cl = new CultureInfo("ru-RU", false);

            DivsNCouponsChart = new ChartDiaramnClass($"DivsNCoupons_main")
            {
                Lables = _invFullDS.Tables[InvestFullTables.DivsNCouponsChart].Rows.Cast<DataRow>().ToList()
                    .Select(r => ((DateTime)r["Date"]).ToString("MMM yy", cl).ToUpper()).ToList(),
                Type = "bar",
                DataSets = new List<ChartDiaramnClass.DataSetClass>()
                    {
                        new ChartDiaramnClass.DataSetClass
                        {
                            data = _invFullDS.Tables[InvestFullTables.DivsNCouponsChart].Rows.Cast<DataRow>().ToList()
                                .Select(r => new ChartDiaramnClass.DataClass
                                {
                                    value = (r["Dividends"] as decimal?) ?? 0,
                                    borderColor = "#E9F3F8"
                                }).ToList(),
                            backgroundColor = "#E9F3F8",
                            lable = "Дивиденды"
                        },
                        new ChartDiaramnClass.DataSetClass
                        {
                            data = _invFullDS.Tables[InvestFullTables.DivsNCouponsChart].Rows.Cast<DataRow>().ToList()
                                .Select(r => new ChartDiaramnClass.DataClass
                                {
                                    value = (r["Coupons"] as decimal?) ?? 0,
                                    borderColor = "#09669A"
                                }).ToList(),
                            backgroundColor = "#09669A",
                            lable = "Купоны"
                        }
                    }
            };
        }
        private void InitDivsNCouponsDetails()
        {
            DivsNCouponsDetails = new TableView();
            DivsNCouponsDetails.Table = new DataTable(); 
            DivsNCouponsDetails.Table.Columns.Add(DivsNCouponsDetailsColumns.Date);
            DivsNCouponsDetails.Table.Columns.Add(DivsNCouponsDetailsColumns.ToolName);
            DivsNCouponsDetails.Table.Columns.Add(DivsNCouponsDetailsColumns.PriceType);
            DivsNCouponsDetails.Table.Columns.Add(DivsNCouponsDetailsColumns.ContractName);
            DivsNCouponsDetails.Table.Columns.Add(DivsNCouponsDetailsColumns.Price);

            DivsNCouponsDetails.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = DivsNCouponsDetailsColumns.Date, DisplayName = "Дата", SortOrder = 1},
                new ViewElementAttr{ColumnName = DivsNCouponsDetailsColumns.ToolName, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = DivsNCouponsDetailsColumns.PriceType, DisplayName = "Тип выплаты", SortOrder = 3},
                new ViewElementAttr{ColumnName = DivsNCouponsDetailsColumns.ContractName, DisplayName = "НАЗВАНИЕ ДОГОВОРА", SortOrder = 4},
                new ViewElementAttr{ColumnName = DivsNCouponsDetailsColumns.Price, DisplayName = "Сумма сделки", SortOrder = 5},
            };

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.DivsNCouponsDetails].Rows)
            {
                DataRow row = DivsNCouponsDetails.Table.NewRow(); 
                row[DivsNCouponsDetailsColumns.Date] = ((DateTime)dr["Date"]).ToString("dd.MM.yyyy");
                row[DivsNCouponsDetailsColumns.ToolName] = dr["ToolName"];
                row[DivsNCouponsDetailsColumns.PriceType] = dr["PriceType"];
                row[DivsNCouponsDetailsColumns.ContractName] = dr["ContractName"];
                row[DivsNCouponsDetailsColumns.Price] = $"{dr["Price"].DecimalToStr()} {dr["Valuta"]}";
                DivsNCouponsDetails.Table.Rows.Add(row);
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
            AllAssets.Table.Columns.Add(AllAssetsColumns.Redemption);
            AllAssets.Table.Columns.Add(AllAssetsColumns.EndAssets);
            AllAssets.Table.Columns.Add(AllAssetsColumns.CurrencyProfit);

            AllAssets.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = AllAssetsColumns.Product, DisplayName = "Вид продукта", SortOrder = 1},
                new ViewElementAttr{ColumnName = AllAssetsColumns.BeginAssets, DisplayName = $"АКТИВЫ НА {Dfrom.ToString("dd.MM.yyyy")}", SortOrder = 2},
                new ViewElementAttr{ColumnName = AllAssetsColumns.InVal, DisplayName = "ПОПОЛНЕНИЯ", SortOrder = 3},
                new ViewElementAttr{ColumnName = AllAssetsColumns.OutVal, DisplayName = "ВЫВОД СРЕДСТВ", SortOrder = 4},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Dividents, DisplayName = "ДИВИДЕНДЫ", SortOrder = 5},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Coupons, DisplayName = "КУПОНЫ", SortOrder = 6},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Redemption, DisplayName = "Погашения", SortOrder = 7},
                new ViewElementAttr{ColumnName = AllAssetsColumns.EndAssets, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 8},
                new ViewElementAttr{ColumnName = AllAssetsColumns.CurrencyProfit, DisplayName = "ДОХОД В ВАЛЮТЕ", SortOrder = 9},
            };

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.FundsResultDt].Rows)
            {
                DataRow row = AllAssets.Table.NewRow();
                row[AllAssetsColumns.Product] = dr["NameObject"];
                row[AllAssetsColumns.BeginAssets] = dr["StartDateValue"].DecimalToStr();
                row[AllAssetsColumns.InVal] = dr["INPUT_VALUE"].DecimalToStr();
                row[AllAssetsColumns.OutVal] = "";
                row[AllAssetsColumns.Dividents] = dr["INPUT_DIVIDENTS"].DecimalToStr();
                row[AllAssetsColumns.Coupons] = dr["INPUT_COUPONS"].DecimalToStr();
                row[AllAssetsColumns.Redemption] = dr["OUTPUT_VALUE"].DecimalToStr();
                row[AllAssetsColumns.EndAssets] = dr["EndDateValue"].DecimalToStr();
                row[AllAssetsColumns.CurrencyProfit] = $"{dr["ProfitValue"].DecimalToStr()} {dr["Valuta"]} ({dr["ProfitProcentValue"].DecimalToStr("#,##0.00")}%)";
                AllAssets.Table.Rows.Add(row);
            }

            foreach (DataRow dr in _invFullDS.Tables[InvestFullTables.DUsResultDt].Rows)
            {
                DataRow row = AllAssets.Table.NewRow();
                row[AllAssetsColumns.Product] = dr["NameObject"];
                row[AllAssetsColumns.BeginAssets] = dr["StartDateValue"].DecimalToStr();
                row[AllAssetsColumns.InVal] = dr["INPUT_VALUE"].DecimalToStr();
                row[AllAssetsColumns.OutVal] = dr["OUTPUT_VALUE"].DecimalToStr();
                row[AllAssetsColumns.Dividents] = dr["INPUT_DIVIDENTS"].DecimalToStr();
                row[AllAssetsColumns.Coupons] = dr["INPUT_COUPONS"].DecimalToStr();
                row[AllAssetsColumns.Redemption] = "";
                row[AllAssetsColumns.EndAssets] = dr["EndDateValue"].DecimalToStr();
                row[AllAssetsColumns.CurrencyProfit] = $"{dr["ProfitValue"].DecimalToStr()} {dr["Valuta"]} ({dr["ProfitProcentValue"].DecimalToStr("#,##0.00")}%)";
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
                    .OrderByDescending(r => r["Result"].ToDecimal().ToDecimal())
                    .Take(7)
                    .Select(r => 
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r["CategoryName"]}",
                            data = r["VALUE_RUR"].ToDecimal().ToDecimal(),
                            backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainAssetsCircle[i],
                            result = $"{(r["Result"].ToDecimal().ToDecimal() * 100).DecimalToStr("#,##0.00")}%"
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
                        .Sum(r => r["Result"].ToDecimal().ToDecimal()) * 100;

                Assets.Data.RemoveAt(Assets.Data.Count - 1);

                Assets.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = _circleAssetsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => r["Result"].ToDecimal().ToDecimal())
                        .Skip(6)
                        .Sum(r => r["VALUE_RUR"].ToDecimal().ToDecimal()),
                    backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                    result = $"{otherPerent.DecimalToStr()}%"
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
                    .OrderByDescending(r => r["Result"].ToDecimal().ToDecimal())
                    .Take(7)
                    .Select(r =>
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r["Investment"]}",
                            data = r["VALUE_RUR"].ToDecimal().ToDecimal(),
                            backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                            result = $"{(r["Result"].ToDecimal().ToDecimal() * 100).DecimalToStr("#,##0.00")}%"
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
                        .OrderByDescending(r => r["Result"].ToDecimal().ToDecimal())
                        .Skip(6)
                        .Sum(r => r["Result"].ToDecimal().ToDecimal()) * 100;

                Instruments.Data.RemoveAt(Instruments.Data.Count - 1);

                Instruments.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = _circleInstrumentsDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => r["Result"].ToDecimal())
                        .Skip(6)
                        .Sum(r => r["VALUE_RUR"].ToDecimal()),
                    backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                    result = $"{otherPerent.DecimalToStr()}%"
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
                    .OrderByDescending(r => r["Result"].ToDecimal())
                    .Take(7)
                    .Select(r =>
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r["CurrencyName"]}",
                            data = r["VALUE_RUR"].ToDecimal(),
                            backgroundColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                            result = $"{(r["Result"].ToDecimal() * 100).DecimalToStr("#,##0.00")}%"
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
                        .Sum(r => r["Result"].ToDecimal()) * 100;

                Currencies.Data.RemoveAt(Currencies.Data.Count - 1);

                Currencies.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = _circleCurrenciesDS.Tables[0].Rows.Cast<DataRow>().ToList()
                        .OrderByDescending(r => r["Result"].ToDecimal())
                        .Skip(6)
                        .Sum(r => r["VALUE_RUR"].ToDecimal()),
                    backgroundColor = CircleDiagramsColorCodes.MainCurrenciesCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainCurrenciesCircle[7],
                    result = $"{otherPerent.DecimalToStr()}%"
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
        public const int DivsNCoupons = 7;
        public const int DivsNCouponsDetails = 8;
        public const int DivsNCouponsChart = 9;
    }
}
