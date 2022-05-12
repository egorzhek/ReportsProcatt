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
using ReportsProcatt.Content.Services;

namespace ReportsProcatt.Models
{
    public class Report
    {
        #region Public properties
        public string rootStr { get; set; }
        public int InvestorId { get; private set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public DateTime Dfrom => _mainService.DateFrom;
        public DateTime Dto => _mainService.DateTo;
        public CurrencyClass ReportCurrency { get; set; }
        public Headers MainHeader { get; private set; }
        public Dictionary<string, string> MainDiagram { get; private set; }
        public TableView PIFsTotals { get; set; }
        public TableView DUsTotals { get; set; }
        public TableView AllAssets { get; set; }
        public TableView DivsNCoupons { get; set; }
        public ChartDiagramClass DivsNCouponsChart { get; set; }
        public TableView DivsNCouponsDetails { get; set; }
        public CircleDiagram Assets { get; set; }
        public CircleDiagram Instruments { get; set; }
        public CircleDiagram Currencies { get; set; }
        public List<PIF> PIFs { get; set; }
        public List<DU> DUs { get; set; }
        #endregion
        #region Services
        private ContractsDataSumService _mainService;
        private DivNCouponsChartDiagramsService _chartService;
        private DivNCouponsDetailsService _divNCouponsDetailsService;
        private CircleDiagramsService _circleDiagramsService;
        #endregion
        public Report(int aInvestorId, DateTime? aDateFrom, DateTime? aDateTo,string CurrencyCode)
        {
            Currency cur;
            var a = Enum.TryParse(CurrencyCode, out cur);
            _mainService = new ContractsDataSumService(
                new MainServiceParams
                {
                    CurrencyCode = Enum.TryParse(CurrencyCode, out cur) ? cur : Currency.RUB,
                    DateFrom = aDateFrom,
                    DateTo = aDateTo,
                    InvestorId = aInvestorId
                });

            _chartService = new DivNCouponsChartDiagramsService( 
                new DivNCouponsGraphServiceParams
                {
                    CurrencyCode = Enum.TryParse(CurrencyCode, out cur) ? cur : Currency.RUB,
                    DateFrom = aDateFrom,
                    DateTo = aDateTo,
                    InvestorId = aInvestorId
                } );

            _divNCouponsDetailsService = new DivNCouponsDetailsService(
                new DivNCouponsDetailsServiceParams
                {
                    CurrencyCode = Enum.TryParse(CurrencyCode, out cur) ? cur : Currency.RUB,
                    DateFrom = aDateFrom,
                    DateTo = aDateTo,
                    InvestorId = aInvestorId
                });

            _circleDiagramsService = new CircleDiagramsService(
                new CircleDiaramsServiceParams
                {
                    CurrencyCode = Enum.TryParse(CurrencyCode, out cur) ? cur : Currency.RUB,
                    DateTo = aDateTo,
                    InvestorId = aInvestorId
                });

            ReportCurrency = CurrencyClass.GetCurrency(CurrencyCode);

            InvestorId = aInvestorId;

            MainHeader = new Headers
            {
                TotalSum = $"{_mainService.Totals.SItog.DecimalToStr()} {ReportCurrency.Char}",
                ProfitSum = $"{_mainService.Totals.Income.DecimalToStr()} {ReportCurrency.Char}",
                Return = $"{_mainService.Totals.Res.DecimalToStr("#0.00", aWithSign: true)}%"
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
            MainDiagram.Add(MainDiagramParams.Begin, $"{_mainService.Totals.SNach.DecimalToStr()} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.InVal, $"{_mainService.Totals.InVal.DecimalToStr(aWithSign: true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.OutVal, $"{_mainService.Totals.OutVal_DU.DecimalToStr(aWithSign: true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.Dividents, $"{_mainService.Totals.Dividends.DecimalToStr(aWithSign: true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.Coupons, $"{_mainService.Totals.Coupons.DecimalToStr(aWithSign: true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.OutVal1, $"{_mainService.Totals.OutVal_PIF.DecimalToStr(aWithSign: true)} {ReportCurrency.Char}");
            MainDiagram.Add(MainDiagramParams.End, $"{_mainService.Totals.SItog.DecimalToStr()} {ReportCurrency.Char}");
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
                new ViewElementAttr{ColumnName = PIFsTotalColumns.StartValue, DisplayName = $"АКТИВЫ НА {Dfrom.ToString("dd.MM.yyyy")}", SortOrder = 1 },
                new ViewElementAttr{ColumnName = PIFsTotalColumns.EndValue, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = PIFsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ* ЗА {Period}", SortOrder = 3 }
            };
            PIFsTotals.Ths.Where(t => t.ColumnName == PIFsTotalColumns.PIFs).First().AttrRow.Add("width", "520px");

            _mainService.PIFs.ForEach(p => 
            {
                DataRow row = PIFsTotals.Table.NewRow();
                row[PIFsTotalColumns.PIFs] = p.Name;
                row[PIFsTotalColumns.StartValue] = p.SNach.DecimalToStr();
                row[PIFsTotalColumns.EndValue] = p.SItog.DecimalToStr();
                row[PIFsTotalColumns.Result] = $"{p.Income.DecimalToStr()} {ReportCurrency.Code} ({p.Res.DecimalToStr("#,##0.00")}%)";
                PIFsTotals.Table.Rows.Add(row);
            });
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

            _mainService.DUs.ForEach(f => 
            {
                DataRow row = DUsTotals.Table.NewRow();
                row[DUsTotalColumns.DUs] = f.Name;
                row[DUsTotalColumns.StartValue] = f.SNach.DecimalToStr();
                row[DUsTotalColumns.EndValue] = f.SItog.DecimalToStr();
                row[DUsTotalColumns.Result] = $"{f.Income.DecimalToStr()} {ReportCurrency.Code} ({f.Res.DecimalToStr("#,##0.00")}%)";
                DUsTotals.Table.Rows.Add(row);
            });
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

            DataRow row = DivsNCoupons.Table.NewRow(); 
            row[DivsNCouponsColumns.NameObject] = "DU";
            row[DivsNCouponsColumns.INPUT_DIVIDENTS] = $"{_mainService.DUsTotals.Dividends.DecimalToStr()} {ReportCurrency.Code}";
            row[DivsNCouponsColumns.INPUT_COUPONS] = $"{_mainService.DUsTotals.Coupons.DecimalToStr()} {ReportCurrency.Code}";
            row[DivsNCouponsColumns.Summ] = $"{(_mainService.DUsTotals.Dividends + _mainService.DUsTotals.Coupons).DecimalToStr()} {ReportCurrency.Code}";
            DivsNCoupons.Table.Rows.Add(row);
        }
        private void InitDivsNCouponsChart()
        {
            var cl = new CultureInfo("ru-RU", false);

            DivsNCouponsChart = new ChartDiagramClass($"DivsNCoupons_main")
            {
                Lables = _chartService.DivsNCouponsChartTotals
                    .Select(r => ((DateTime)r.Date).ToCharString()).ToList(),
                Type = "bar",
                DataSets = new List<ChartDiagramClass.DataSetClass>()
                    {
                        new ChartDiagramClass.DataSetClass
                        {
                            data = _chartService.DivsNCouponsChartTotals
                                .Select(r => new ChartDiagramClass.DataClass
                                {
                                    value = r.Dividends ?? 0,
                                    borderColor = "#E9F3F8"
                                }).ToList(),
                            backgroundColor = "#E9F3F8",
                            lable = "Дивиденды"
                        },
                        new ChartDiagramClass.DataSetClass
                        {
                            data = _chartService.DivsNCouponsChartTotals
                                .Select(r => new ChartDiagramClass.DataClass
                                {
                                    value = r.Coupons ?? 0,
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

            _divNCouponsDetailsService.Totals.ForEach(dr =>
            {
                DataRow row = DivsNCouponsDetails.Table.NewRow();
                row[DivsNCouponsDetailsColumns.Date] = ((DateTime)dr.Date).ToString("dd.MM.yyyy");
                row[DivsNCouponsDetailsColumns.ToolName] = dr.ShareName;
                row[DivsNCouponsDetailsColumns.PriceType] = dr.PaymentType;
                row[DivsNCouponsDetailsColumns.ContractName] = dr.ContractName;
                row[DivsNCouponsDetailsColumns.Price] = $"{dr.INPUT_VALUE.DecimalToStr("#,##0.00")} {dr.Valuta}";
                DivsNCouponsDetails.Table.Rows.Add(row);
            });
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

            {
                var dr = _mainService.PIFsTotals;
                DataRow row = AllAssets.Table.NewRow();
                row[AllAssetsColumns.Product] = "ПИФы";
                row[AllAssetsColumns.BeginAssets] = dr.SNach.DecimalToStr();
                row[AllAssetsColumns.InVal] = dr.InVal.DecimalToStr();
                row[AllAssetsColumns.OutVal] = "";
                row[AllAssetsColumns.Dividents] = "";
                row[AllAssetsColumns.Coupons] = "";
                row[AllAssetsColumns.Redemption] = dr.OutVal_PIF.DecimalToStr();
                row[AllAssetsColumns.EndAssets] = dr.SItog.DecimalToStr();
                row[AllAssetsColumns.CurrencyProfit] = $"{dr.Income.DecimalToStr()} {ReportCurrency.Code} " +
                    $"({dr.Res.DecimalToStr("#,##0.00")}%)";
                AllAssets.Table.Rows.Add(row);
            }

            {
                var dr = _mainService.DUsTotals;
                DataRow row = AllAssets.Table.NewRow();
                row[AllAssetsColumns.Product] = "ДУ";
                row[AllAssetsColumns.BeginAssets] = dr.SNach.DecimalToStr();
                row[AllAssetsColumns.InVal] = dr.InVal.DecimalToStr();
                row[AllAssetsColumns.OutVal] = dr.OutVal_DU.DecimalToStr();
                row[AllAssetsColumns.Dividents] = dr.Dividends.DecimalToStr();
                row[AllAssetsColumns.Coupons] = dr.Coupons.DecimalToStr();
                row[AllAssetsColumns.Redemption] = "";
                row[AllAssetsColumns.EndAssets] = dr.SItog.DecimalToStr();
                row[AllAssetsColumns.CurrencyProfit] = $"{dr.Income.DecimalToStr()} {ReportCurrency.Code} " +
                    $"({dr.Res.DecimalToStr("#,##0.00")}%)";
                AllAssets.Table.Rows.Add(row);
            }
        }
        public void InitAssets()
        {
            int i = 1;
            var ChartData = _circleDiagramsService.TotalCategory;
            string CatTypeName = "АКТИВА(ов)";
            Assets = new CircleDiagram("MainAssetsCircle")
            {
                LegendName = "Активы",
                MainText = $"{ChartData.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {ReportCurrency.Char}",
                Footer = $"{ChartData.Count().DecimalToStr()} {CatTypeName}",
                Data = ChartData
                    .OrderByDescending(r => r.Res.ToDecimal())
                    .Take(7)
                    .Select(r => 
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r.CategoryName}",
                            data = r.VALUE_CUR.ToDecimal(),
                            backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainAssetsCircle[i],
                            result = $"{r.Res.DecimalToStr("#,##0.00")}%"
                        };
                        i++;
                        return el;
                    }).ToList(),
                Type= "doughnut"
                
            };

            if (ChartData.Count > 7)
            {
                decimal otherPerent = ChartData
                        .OrderByDescending(r => (double)r.Res)
                        .Skip(6)
                        .Sum(r => r.Res.ToDecimal());

                Assets.Data.RemoveAt(Assets.Data.Count - 1);

                Assets.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = ChartData
                        .OrderByDescending(r => r.Res)
                        .Skip(6)
                        .Sum(r => r.VALUE_CUR.ToDecimal()),
                    backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                    result = $"{otherPerent.DecimalToStr()}%"
                });
            }
        }
        public void InitInstruments()
        {
            int i = 1;
            var ChartData = _circleDiagramsService.TotalAssets;
            string CatTypeName = "инструментов";
            Instruments = new CircleDiagram("MainInstrumentsCircle")
            {
                LegendName = "Инструменты",
                MainText = $"{ChartData.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {ReportCurrency.Char}",
                Footer = $"{ChartData.Count().DecimalToStr()} {CatTypeName}",
                Data = ChartData
                    .OrderByDescending(r => r.Res.ToDecimal())
                    .Take(7)
                    .Select(r =>
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r.CategoryName}",
                            data = r.VALUE_CUR.ToDecimal(),
                            backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[i],
                            result = $"{r.Res.DecimalToStr("#,##0.00")}%"
                        };
                        i++;
                        return el;
                    }).ToList(),
                Type = "doughnut"

            };

            if (ChartData.Count > 7)
            {
                decimal otherPerent = ChartData
                        .OrderByDescending(r => (double)r.Res)
                        .Skip(6)
                        .Sum(r => r.Res.ToDecimal());

                Instruments.Data.RemoveAt(Instruments.Data.Count - 1);

                Instruments.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = ChartData
                        .OrderByDescending(r => r.Res)
                        .Skip(6)
                        .Sum(r => r.VALUE_CUR.ToDecimal()),
                    backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                    borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                    result = $"{otherPerent.DecimalToStr()}%"
                });
            }
        }

        public void InitCurrencies()
        {
            int i = 1;
            var ChartData = _circleDiagramsService.TotalCurrency;
            Currencies = new CircleDiagram("MainCurrenciesCircle")
            {
                LegendName = "Валюта",
                MainText = $"{ChartData.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {ReportCurrency.Char}",
                Data = ChartData
                    .OrderByDescending(r => r.Res.ToDecimal())
                    .Take(7)
                    .Select(r =>
                    {
                        var el = new CircleDiagram.DataClass
                        {
                            lable = $"{r.CategoryName}",
                            data = r.VALUE_CUR.ToDecimal(),
                            backgroundColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                            borderColor = CircleDiagramsColorCodes.MainCurrenciesCircle[i],
                            result = $"{r.Res.DecimalToStr("#,##0.00")}%"
                        };
                        i++;
                        return el;
                    }).ToList(),
                Type = "doughnut"

            };

            if (ChartData.Count > 7)
            {
                decimal otherPerent = ChartData
                        .OrderByDescending(r => (double)r.Res)
                        .Skip(6)
                        .Sum(r => r.Res.ToDecimal());

                Currencies.Data.RemoveAt(Currencies.Data.Count - 1);

                Currencies.Data.Add(new CircleDiagram.DataClass
                {
                    lable = @$"Прочее",
                    data = ChartData
                        .OrderByDescending(r => r.Res)
                        .Skip(6)
                        .Sum(r => r.VALUE_CUR.ToDecimal()),
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
                _mainService.PIFs
                .Select(r => Task.Run(() =>
                {
                    PIFs.Add(new PIF(r.Name.ToString(), Dfrom, Dto, ReportCurrency, r.ContractId, InvestorId));
                })).ToArray()
            );
        }
        public void InitDUs()
        {
            DUs = new List<DU>();
            Task.WaitAll
            (
                _mainService.DUs
                .Select(r => Task.Run(() =>
                {
                    DUs.Add(new DU(r.Name.ToString(), Dfrom, Dto, ReportCurrency, r.ContractId, InvestorId));
                })).ToArray()
            );
        }
        #endregion
    }
}
