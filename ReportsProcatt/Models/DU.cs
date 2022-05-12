using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;

using ReportsProcatt.Content.Services;

namespace ReportsProcatt.Models
{
    public class DU
    {
        public int Id { get; private set; }
        public string Name { get; private set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public DateTime Dfrom => _dFrom;
        public DateTime Dto => _dTo;
        public CurrencyClass _Currency { get; set; }
        public Headers DuHeader { get; set; }
        public Dictionary<string, string> Diagram { get; set; }

        //Дивиденды и купоны
        public string Totals { get; set; }
        public string Dividends { get; set; }
        public string Coupons { get; set; }
        public ChartDiagramClass DividedtsCouponsChart { get; set; }

        //Детализация купонов и дивидендов
        public TableView DividedtsCoupons { get; set; }

        //Информация по договору
        public string ContractNumber => _mainService.DU(Id).Name;
        public string OpenDate => _mainService.DU(Id).DATE_OPEN?.ToString("dd.MM.yyyy");
        public string ManagementFee => $"{_mainService.DU(Id).SumAmount} шт.";
        public string SuccessFee => $"{_mainService.DU(Id).WAmounr}%";

        //Текущие позиции по валютам
        public DataTable GroupPositionData { get; set; }
        public DataTable DetailPositionData { get; set; }
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
        public TableView DuOperationsHistory { get; set; }
        #region Private Fields
        private DateTime _dTo;
        private DateTime _dFrom;
        private DuServiceParams _duParams;
        #endregion
        #region Services
        private ContractsDataSumService _mainService;
        private DivNCouponsChartDiagramsService _chartService;
        private DivNCouponsDetailsService _divNCouponsDetailsService;
        private CircleDiagramsService _circleDiagramsService;
        private DuOperationHistoryService _duOperationHistoryService;
        private DuPositionByGroupService _duPositionByGroupService;
        #endregion

        public DU(string aName, DateTime? aDFrom, DateTime? aDTo, CurrencyClass aCurrency, int aContractId, int aInvestorId)
        {
            Id = aContractId;
            _Currency = aCurrency;
            
            InitServices(aName,aDFrom,aDTo,aCurrency,aContractId,aInvestorId);

            Name = aName ?? _mainService.DU(aContractId).Name;
            _dFrom = aDFrom ?? (DateTime)_mainService.DU(aContractId).DATE_OPEN;
            _dTo = aDTo ?? (DateTime)_mainService.DU(aContractId).DATE_CLOSE;

            DuHeader = new Headers
            {
                TotalSum = $"{_mainService.DU(Id).SItog.DecimalToStr()} {_Currency.Char}",
                ProfitSum = $"{_mainService.DU(Id).Income.DecimalToStr()} {_Currency.Char}",
                Return = $"{_mainService.DU(Id).Res.DecimalToStr("#0.00", aWithSign: true)}%"
            };

            Diagram = new Dictionary<string, string>
            {
                { DuDiagramColumns.Begin, $"{_mainService.DU(Id).SNach.DecimalToStr()} {_Currency.Char}" },
                { DuDiagramColumns.InVal, $"{_mainService.DU(Id).InVal.DecimalToStr("#,##0", aWithSign: true)} {_Currency.Char}" },
                { DuDiagramColumns.OutVal, $"{_mainService.DU(Id).OutVal.DecimalToStr("#,##0", aWithSign:true)} {_Currency.Char}" },
                { DuDiagramColumns.Coupons, $"{_mainService.DU(Id).Coupons.DecimalToStr("#,##0", aWithSign:true)} {_Currency.Char}" },
                { DuDiagramColumns.Dividents, $"{_mainService.DU(Id).Dividends.DecimalToStr()} {_Currency.Char}" },
                { DuDiagramColumns.End, $"{_mainService.DU(Id).SItog.DecimalToStr()} {_Currency.Char}" }
            };

            InitAssetsStruct();
            InitFundStruct();

            Totals = $"{_divNCouponsDetailsService.ContractDetails(Id).Sum(c => c.INPUT_VALUE).DecimalToStr()} {_Currency.Char}";
            Coupons = $"{_divNCouponsDetailsService.ContractDetails(Id).Where(c => c.PaymentType == "Купоны").Sum(c => c.INPUT_VALUE).DecimalToStr()} {_Currency.Char}";
            Dividends = $"{_divNCouponsDetailsService.ContractDetails(Id).Where(c => c.PaymentType == "Дивиденды").Sum(c => c.INPUT_VALUE).DecimalToStr()} {_Currency.Char}";
            InitDividedtsCouponsChart();
           
            InitDividedtsCoupons();

            InitCurrentAssetsPositions();

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

            InitOperationsHistory();
        }

        private void InitServices(string aName, DateTime? aDFrom, DateTime? aDTo, CurrencyClass aCurrency, int aContractId, int aInvestorId)
        {
            Currency cur;
            _duParams = new DuServiceParams
            {
                InvestorId = aInvestorId,
                DateFrom = aDFrom,
                DateTo = aDTo,
                CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                ContractId = aContractId
            };

            _mainService = new ContractsDataSumService(
               new MainServiceParams
               {
                   CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                   DateFrom = aDFrom,
                   DateTo = aDTo,
                   InvestorId = aInvestorId
               });

            _chartService = new DivNCouponsChartDiagramsService(
                new DivNCouponsGraphServiceParams
                {
                    CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                    DateFrom = aDFrom,
                    DateTo = aDTo,
                    InvestorId = aInvestorId
                });

            _divNCouponsDetailsService = new DivNCouponsDetailsService(
                new DivNCouponsDetailsServiceParams
                {
                    CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                    DateFrom = aDFrom,
                    DateTo = aDTo,
                    InvestorId = aInvestorId
                });

            _circleDiagramsService = new CircleDiagramsService(
                new CircleDiaramsServiceParams
                {
                    CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                    DateTo = aDTo,
                    InvestorId = aInvestorId
                });

            _duOperationHistoryService = new DuOperationHistoryService(
              new DuServiceParams
              {
                  InvestorId = aInvestorId,
                  DateTo = aDTo,
                  CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                  DateFrom = aDFrom,
                  ContractId = aContractId
              });

            _duPositionByGroupService = new DuPositionByGroupService(
                new DuPositionGrouByElementServiceParams
                {
                    InvestorId = aInvestorId,
                    ContractId = aContractId,
                    DateTo = aDTo,
                    CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB
                });
        }
        private void InitAssetsStruct()
        {
            var DUs = _circleDiagramsService.Category(Id,false);
            string CatTypeName = "АКТИВА(ов)";
            if (DUs.Count > 0)
            {
                int i = 1;
                AssetsStruct = new CircleDiagram($"Contract_{Id}_AssetsStructCircle")
                {
                    LegendName = "Активы",
                    MainText = $"{DUs.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {_Currency.Char}",
                    Footer = $"{DUs.Count().DecimalToStr()} {CatTypeName}",
                    Data = DUs
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
                    Type = "doughnut"

                };

                if (DUs.Count > 7)
                {
                    decimal otherPerent = DUs
                        .OrderByDescending(r => (double)r.Res)
                        .Skip(6)
                        .Sum(r => r.Res.ToDecimal());

                    AssetsStruct.Data.RemoveAt(AssetsStruct.Data.Count - 1);

                    AssetsStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее",
                        data = DUs
                            .OrderByDescending(r => r.Res.ToDecimal())
                            .Skip(6)
                            .Sum(r => r.VALUE_CUR.ToDecimal()),
                        backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        result = $"{otherPerent.DecimalToStr("#,##0")}%"
                    });
                }
            }
        }
        private void InitFundStruct()
        {
            var DUs2 = _circleDiagramsService.Assets(Id,false);
            string TypeName = "инструментов";
            if (DUs2.Count > 0)
            {
                int i = 1;
                ContractStruct = new CircleDiagram($"Contract_{Id}_Struct")
                {
                    LegendName = "Инструменты",
                    MainText = $"{DUs2.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {_Currency.Char}",
                    Footer = $"{DUs2.Count().DecimalToStr()} {TypeName}",
                    Data = DUs2
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

                if (DUs2.Count > 7)
                {
                    decimal otherPerent = DUs2
                            .OrderByDescending(r => r.Res.ToDecimal())
                            .Skip(6)
                            .Sum(r => r.Res.ToDecimal());

                    ContractStruct.Data.RemoveAt(ContractStruct.Data.Count - 1);

                    ContractStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее",
                        data = DUs2
                            .OrderByDescending(r => r.Res.ToDecimal())
                            .Skip(6)
                            .Sum(r => r.VALUE_CUR.ToDecimal()),
                        backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        result = $"{otherPerent.DecimalToStr("#,##0")}%"
                    });
                }
            }
        }

        private void InitDividedtsCouponsChart()
        {
            var DivsNCoupsChart = _chartService.ContractDivsNCouponsChart(Id);
            if (DivsNCoupsChart.Count > 0)
            {
                var cl = new CultureInfo("ru-RU", false);

                DividedtsCouponsChart = new ChartDiagramClass($"DividedtsCouponsChart_{Id}")
                {
                    Lables = DivsNCoupsChart
                        .Select(r => ((DateTime)r.Date).ToCharString()).ToList(),
                    Type = "bar",
                    DataSets = new List<ChartDiagramClass.DataSetClass>()
                    {
                        new ChartDiagramClass.DataSetClass
                        {
                            data = DivsNCoupsChart
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
                            data = DivsNCoupsChart
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
        }
        private void InitDividedtsCoupons()
        {
            DividedtsCoupons = new TableView();
            DividedtsCoupons.Table = new DataTable();
            DividedtsCoupons.Table.Columns.Add(DividedtsCouponsColumns.Date);
            DividedtsCoupons.Table.Columns.Add(DividedtsCouponsColumns.ToolName);
            DividedtsCoupons.Table.Columns.Add(DividedtsCouponsColumns.PriceType);
            DividedtsCoupons.Table.Columns.Add(DividedtsCouponsColumns.Price);

            DividedtsCoupons.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = DividedtsCouponsColumns.Date, DisplayName = "Дата", SortOrder = 1},
                new ViewElementAttr{ColumnName = DividedtsCouponsColumns.ToolName, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = DividedtsCouponsColumns.PriceType, DisplayName = "Тип выплаты", SortOrder = 3},
                new ViewElementAttr{ColumnName = DividedtsCouponsColumns.Price, DisplayName = "Сумма сделки", SortOrder = 5},
            };

            DividedtsCoupons.Ths.Where(t => t.ColumnName == DividedtsCouponsColumns.Date).First().AttrRow.Add("width", "200px");
            DividedtsCoupons.Ths.Where(t => t.ColumnName == DividedtsCouponsColumns.PriceType).First().AttrRow.Add("width", "150px");
            DividedtsCoupons.Ths.Where(t => t.ColumnName == DividedtsCouponsColumns.Price).First().AttrRow.Add("width", "150px");

            _divNCouponsDetailsService.ContractDetails(Id).ForEach(c =>
            {
                DataRow row = DividedtsCoupons.Table.NewRow();
                row[DividedtsCouponsColumns.Date] = c.Date.ToString("dd.MM.yyyy");
                row[DividedtsCouponsColumns.ToolName] = c.ContractName;
                row[DividedtsCouponsColumns.PriceType] = c.PaymentType;
                row[DividedtsCouponsColumns.Price] = $"{c.INPUT_VALUE.DecimalToStr()} {c.Valuta}";
                DividedtsCoupons.Table.Rows.Add(row);
            });
        }
        private void InitCurrentAssetsPositions()
        {
            GroupPositionData = new DataTable();
            GroupPositionData.Columns.Add(GrPosDtColumns.ChildName);
            GroupPositionData.Columns.Add(GrPosDtColumns.Price);
            GroupPositionData.Columns.Add(GrPosDtColumns.Valuta);
            GroupPositionData.Columns.Add(GrPosDtColumns.Ammount);
            GroupPositionData.Columns.Add(GrPosDtColumns.Result);
            GroupPositionData.Columns.Add(GrPosDtColumns.ResultProcent);
            GroupPositionData.Columns.Add(GrPosDtColumns.ChildId);
            GroupPositionData.Columns.Add(GrPosDtColumns.CategoryName);

            _duPositionByGroupService.Totals.ForEach(c =>
            {
                DataRow row = GroupPositionData.NewRow();
                row[GrPosDtColumns.ChildName] = c.ChildName;
                row[GrPosDtColumns.Price] = c.Price;
                row[GrPosDtColumns.Valuta] = c.Valuta;
                row[GrPosDtColumns.Ammount] = c.Ammount;
                row[GrPosDtColumns.Result] = c.FinRes;
                row[GrPosDtColumns.ResultProcent] = c.FinResPrcnt;
                row[GrPosDtColumns.ChildId] = c.InvestmentId;
                row[GrPosDtColumns.CategoryName] = c.CategoryName;
                GroupPositionData.Rows.Add(row);
            });

            DetailPositionData = new DataTable();
            DetailPositionData.Columns.Add(DtlPosDtColumns.ChildId);
            DetailPositionData.Columns.Add(DtlPosDtColumns.Child2Name);
            DetailPositionData.Columns.Add(DtlPosDtColumns.Price);
            DetailPositionData.Columns.Add(DtlPosDtColumns.Valuta);
            DetailPositionData.Columns.Add(DtlPosDtColumns.Ammount);
            DetailPositionData.Columns.Add(DtlPosDtColumns.FinRes);
            DetailPositionData.Columns.Add(DtlPosDtColumns.FinResProcent);

            DuPositionResultService.GetPositions(_duParams,DuPositionAssetTableName.All,DuPositionType.Current)
            .OrderBy(c => c.In_Date).ToList()
            .ForEach(c =>
            {
                DataRow row = DetailPositionData.NewRow();
                row[DtlPosDtColumns.ChildId] = c.InvestmentId;
                row[DtlPosDtColumns.Child2Name] = c.Investment;
                row[DtlPosDtColumns.Price] = c.Value_NOM + c.NKD;
                row[DtlPosDtColumns.Valuta] = c.Currency;
                row[DtlPosDtColumns.Ammount] = c.Amount;
                row[DtlPosDtColumns.FinRes] = c.FinRes;
                row[DtlPosDtColumns.FinResProcent] = c.FinResProcent;
                DetailPositionData.Rows.Add(row);
            });
        }
        private void InitClosedShares()
        {
            ClosedShares = new TableView();
            ClosedShares.Table = new DataTable();
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.IN_DATE);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Investment);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.IN_PRICE);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Amount);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.In_Summa);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Out_Price);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Dividends);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Out_Date);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.Out_Summa);
            ClosedShares.Table.Columns.Add(ClosedSharesColumns.FinRes);

            ClosedShares.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedSharesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.IN_PRICE, DisplayName = "Цена покупки 1 лота", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Out_Price, DisplayName = "Цена продажи 1 лота", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Out_Summa, DisplayName = "Стоимость на дату продажи", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedSharesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 11},
            };

            DuPositionResultService.GetPositions(_duParams,DuPositionAssetTableName.Shares,DuPositionType.Closed)
            .ForEach(c =>
            {
                DataRow row = ClosedShares.Table.NewRow();
                row[ClosedSharesColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[ClosedSharesColumns.Investment] = c.Investment;
                row[ClosedSharesColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[ClosedSharesColumns.Amount] = c.Amount.DecimalToStr();
                row[ClosedSharesColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[ClosedSharesColumns.Out_Price] = c.OutPrice.DecimalToStr("#,##0.00");
                row[ClosedSharesColumns.Dividends] = c.Dividends.DecimalToStr("#,##0.00");
                row[ClosedSharesColumns.Out_Date] = c.Out_Date?.ToString("dd.MM.yyyy");
                row[ClosedSharesColumns.Out_Summa] = c.Out_Summa.DecimalToStr("#,##0.00");
                row[ClosedSharesColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")} ({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                ClosedShares.Table.Rows.Add(row);
            });
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
            //ClosedBonds.Table.Columns.Add(ClosedBondsColumns.UKD);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.In_Summa_UKD);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Out_Price);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.NKD);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Amortizations);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Out_Date);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.Out_Summa);
            ClosedBonds.Table.Columns.Add(ClosedBondsColumns.FinRes);

            ClosedBonds.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedBondsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.In_Summa, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                //new ViewElementAttr{ColumnName = ClosedBondsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 11},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 14},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 15},
                new ViewElementAttr{ColumnName = ClosedBondsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 16},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Bonds, DuPositionType.Closed)
            .ForEach(c =>
            {
                DataRow row = ClosedBonds.Table.NewRow();
                row[ClosedBondsColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[ClosedBondsColumns.ISIN] = c.ISIN;
                row[ClosedBondsColumns.Investment] = c.Investment;
                row[ClosedBondsColumns.Oblig_Date_end] = c.Oblig_Date_end?.ToString("dd.MM.yyyy");
                row[ClosedBondsColumns.Oferta_Date] = $"{c.Oferta_Date?.ToString("dd.MM.yyyy")}{(!string.IsNullOrEmpty(c.Oferta_Type?.ToString()) ? $"({c.Oferta_Type})" : "")}";
                row[ClosedBondsColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[ClosedBondsColumns.Amount] = c.Amount.DecimalToStr();
                row[ClosedBondsColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                //row[ClosedBondsColumns.UKD] = dr["UKD"].DecimalToStr("#,##0.00");
                row[ClosedBondsColumns.In_Summa_UKD] = (c.In_Summa.ToDecimal() + c.UKD.ToDecimal()).DecimalToStr("#,##0.00");
                row[ClosedBondsColumns.Out_Price] = c.OutPrice.DecimalToStr("#,##0.00");
                row[ClosedBondsColumns.NKD] = c.NKD.DecimalToStr("#,##0.00");
                row[ClosedBondsColumns.Amortizations] = $"{c.Amortizations.DecimalToStr("#,##0.00")}{(!string.IsNullOrEmpty(c.Coupons?.ToString()) ? $"({c.Coupons.DecimalToStr("#,##0.00")})" : "")}";
                row[ClosedBondsColumns.Out_Date] = c.Out_Date?.ToString("dd.MM.yyyy");
                row[ClosedBondsColumns.Out_Summa] = c.Out_Summa.DecimalToStr("#,##0.00");
                row[ClosedBondsColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                ClosedBonds.Table.Rows.Add(row);
            });
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
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Fund, DuPositionType.Closed)
           .ForEach(c =>
           {
                DataRow row = ClosedFunds.Table.NewRow();
                row[ClosedFundsColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[ClosedFundsColumns.Investment] = c.Investment;
                row[ClosedFundsColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[ClosedFundsColumns.Amount] = c.Amount.DecimalToStr();
                row[ClosedFundsColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[ClosedFundsColumns.Out_Price] = c.OutPrice.DecimalToStr("#,##0.00");
                row[ClosedFundsColumns.Out_Date] = c.Out_Date?.ToString("dd.MM.yyyy");
                row[ClosedFundsColumns.Out_Summa] = c.Out_Summa.DecimalToStr("#,##0.00");
                row[ClosedFundsColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                ClosedFunds.Table.Rows.Add(row);
            });

        }
        private void InitClosedDerivatives()
        {
            ClosedDerivatives = new TableView();
            ClosedDerivatives.Table = new DataTable();
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.IN_DATE);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Investment);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.IN_PRICE);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Amount);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.In_Summa);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Out_Price);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Dividends);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Out_Date);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.Out_Summa);
            ClosedDerivatives.Table.Columns.Add(ClosedDerivativesColumns.FinRes);

            ClosedDerivatives.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.IN_PRICE, DisplayName = "Цена покупки 1 лота", SortOrder = 4},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Out_Price, DisplayName = "Цена продажи 1 лота", SortOrder = 7},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 8},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Out_Summa, DisplayName = "Стоимость на дату продажи", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedDerivativesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 11},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Derivatives, DuPositionType.Closed)
           .ForEach(c =>
           {
               DataRow row = ClosedDerivatives.Table.NewRow();
               row[ClosedDerivativesColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
               row[ClosedDerivativesColumns.Investment] = c.Investment;
               row[ClosedDerivativesColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
               row[ClosedDerivativesColumns.Amount] = c.Amount.DecimalToStr();
               row[ClosedDerivativesColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
               row[ClosedDerivativesColumns.Out_Price] = c.OutPrice.DecimalToStr("#,##0.00");
               row[ClosedDerivativesColumns.Dividends] = c.Dividends.DecimalToStr("#,##0.00");
               row[ClosedDerivativesColumns.Out_Date] = c.Out_Date?.ToString("dd.MM.yyyy");
               row[ClosedDerivativesColumns.Out_Summa] = c.Out_Summa.DecimalToStr("#,##0.00");
               row[ClosedDerivativesColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")} ({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
               ClosedDerivatives.Table.Rows.Add(row);
           });
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
            //ClosedBills.Table.Columns.Add(ClosedBillsColumns.UKD);
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
                //new ViewElementAttr{ColumnName = ClosedBillsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Out_Price, DisplayName = "Цена 1 бумаги на дату продажи", SortOrder = 11},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Out_Date, DisplayName = "Дата продажи", SortOrder = 14},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.Out_Summa, DisplayName = "Стоимость позиции на дату продажи", SortOrder = 15},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 16},
                new ViewElementAttr{ColumnName = ClosedBillsColumns.FinResProcent, DisplayName = "Фин.результат в %", SortOrder = 17},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Bills, DuPositionType.Closed)
           .ForEach(c =>
           {
                DataRow row = ClosedBills.Table.NewRow();
                row[ClosedBillsColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[ClosedBillsColumns.ISIN] = c.ISIN;
                row[ClosedBillsColumns.Investment] = c.Investment;
                row[ClosedBillsColumns.Oblig_Date_end] = c.Oblig_Date_end?.ToString("dd.MM.yyyy");
                row[ClosedBillsColumns.Oferta_Date] = $"{c.Oferta_Date?.ToString("dd.MM.yyyy")} ({c.Oferta_Type})";
                row[ClosedBillsColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[ClosedBillsColumns.Amount] = c.Amount.DecimalToStr();
                row[ClosedBillsColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                //row[ClosedBillsColumns.UKD] = dr["UKD"].DecimalToStr("#,##0.00");
                row[ClosedBillsColumns.In_Summa_UKD] = (c.In_Summa.ToDecimal() + c.UKD.ToDecimal()).DecimalToStr("#,##0.00");
                row[ClosedBillsColumns.Out_Price] = c.OutPrice.DecimalToStr("#,##0.00");
                row[ClosedBillsColumns.NKD] = c.NKD.DecimalToStr("#,##0.00");
                row[ClosedBillsColumns.Amortizations] = $"{c.Amortizations.DecimalToStr("#,##0.00")} ({c.Coupons.DecimalToStr("#,##0.00")})";
                row[ClosedBillsColumns.Out_Date] = c.Out_Date?.ToString("dd.MM.yyyy");
                row[ClosedBillsColumns.Out_Summa] = c.Out_Summa.DecimalToStr("#,##0.00");
                row[ClosedBillsColumns.FinRes] = c.FinRes.DecimalToStr("#,##0.00");
                row[ClosedBillsColumns.FinResProcent] = $"{c.FinResProcent.DecimalToStr("#,##0.00")}%";
                ClosedBills.Table.Rows.Add(row);
            });
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
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Cash, DuPositionType.Closed)
           .ForEach(c =>
           {
                DataRow row = ClosedCash.Table.NewRow();
                row[ClosedCashColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[ClosedCashColumns.Investment] = c.Investment;
                row[ClosedCashColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[ClosedCashColumns.Amount] = c.Amount.DecimalToStr();
                row[ClosedCashColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[ClosedCashColumns.Out_Price] = c.OutPrice.DecimalToStr("#,##0.00");
                row[ClosedCashColumns.Out_Date] = c.Out_Date?.ToString("dd.MM.yyyy");
                row[ClosedCashColumns.Out_Summa] = c.Out_Summa.DecimalToStr("#,##0.00");
                row[ClosedCashColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                ClosedCash.Table.Rows.Add(row);
            });
        }
        private void InitCurrentShares()
        {
            CurrentShares = new TableView();
            CurrentShares.Table = new DataTable();
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.IN_DATE);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Investment);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.IN_PRICE);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Amount);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.In_Summa);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Today_Price);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Dividends);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.Value_NOM);
            CurrentShares.Table.Columns.Add(CurrentSharesColumns.FinRes);

            CurrentShares.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentSharesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.IN_PRICE, DisplayName = "Цена покупки 1 лота", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Today_Price, DisplayName = "Цена на конец периода", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Value_NOM, DisplayName = "Стоимость на конец периода", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentSharesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 10},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Shares, DuPositionType.Current)
           .ForEach(c =>
           {
                DataRow row = CurrentShares.Table.NewRow();
                row[CurrentSharesColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[CurrentSharesColumns.Investment] = c.Investment;
                row[CurrentSharesColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[CurrentSharesColumns.Amount] = c.Amount.DecimalToStr();
                row[CurrentSharesColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[CurrentSharesColumns.Today_Price] = c.Today_PRICE.DecimalToStr("#,##0.00");
                row[CurrentSharesColumns.Dividends] = c.Dividends.DecimalToStr("#,##0.00");
                row[CurrentSharesColumns.Value_NOM] = c.Value_NOM.DecimalToStr("#,##0.00");
                row[CurrentSharesColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")} ({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                CurrentShares.Table.Rows.Add(row);
            });

        }
        private void InitCurrentBonds()
        {
            CurrentBonds = new TableView();
            CurrentBonds.Table = new DataTable();
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.IN_DATE);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Investment);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Oblig_Date_end);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Oferta_Date);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.IN_PRICE);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Amount);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.In_Summa_UKD);
            //CurrentBonds.Table.Columns.Add(CurrentBondsColumns.UKD);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.In_Summa);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Today_Price);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.NKD);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Amortizations);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.Value_Nom);
            CurrentBonds.Table.Columns.Add(CurrentBondsColumns.FinRes);

            CurrentBonds.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = CurrentBondsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.In_Summa, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                //new ViewElementAttr{ColumnName = CurrentBondsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 11},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.Value_Nom, DisplayName = "Стоимость на конец периода", SortOrder = 14},
                new ViewElementAttr{ColumnName = CurrentBondsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 15},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Bonds, DuPositionType.Current)
           .ForEach(c =>
           {
                DataRow row = CurrentBonds.Table.NewRow();
                row[CurrentBondsColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[CurrentBondsColumns.Investment] = c.Investment;
                row[CurrentBondsColumns.Oblig_Date_end] = c.Oblig_Date_end?.ToString("dd.MM.yyyy");
                row[CurrentBondsColumns.Oferta_Date] = $"{c.Oferta_Date?.ToString("dd.MM.yyyy")}{(!string.IsNullOrEmpty(c.Oferta_Type?.ToString()) ? $"({c.Oferta_Type})" : "")}";
                row[CurrentBondsColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[CurrentBondsColumns.Amount] = c.Amount.DecimalToStr();
                row[CurrentBondsColumns.In_Summa_UKD] = (c.In_Summa.ToDecimal() + c.UKD.ToDecimal()).DecimalToStr("#,##0.00");
                //row[CurrentBondsColumns.UKD] = dr["UKD"].DecimalToStr("#,##0.00");
                row[CurrentBondsColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[CurrentBondsColumns.Today_Price] = c.Today_PRICE.DecimalToStr("#,##0.00");
                row[CurrentBondsColumns.NKD] = c.NKD.DecimalToStr("#,##0.00");
                row[CurrentBondsColumns.Amortizations] = $"{c.Amortizations.DecimalToStr("#,##0.00")}{(!string.IsNullOrEmpty(c.Coupons?.ToString()) ? $"({c.Coupons.DecimalToStr("#,##0.00")})" : "")}";
                row[CurrentBondsColumns.Value_Nom] = c.Value_NOM.DecimalToStr("#,##0.00");
                row[CurrentBondsColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                CurrentBonds.Table.Rows.Add(row);
            });
        }
        private void InitCurrentBills()
        {
            CurrentBills = new TableView();
            CurrentBills.Table = new DataTable();
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.IN_DATE);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Investment);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Oblig_Date_end);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Oferta_Date);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.IN_PRICE);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Amount);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.In_Summa_UKD);
            //CurrentBills.Table.Columns.Add(CurrentBillsColumns.UKD);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.In_Summa);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Today_Price);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.NKD);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Amortizations);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.Value_Nom);
            CurrentBills.Table.Columns.Add(CurrentBillsColumns.FinRes);

            CurrentBills.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = CurrentBillsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Oblig_Date_end, DisplayName = "Дата погашения", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Oferta_Date, DisplayName = "Дата и тип опциона", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.In_Summa, DisplayName = "Сумма покупки без НКД", SortOrder = 8},
                //new ViewElementAttr{ColumnName = CurrentBillsColumns.UKD, DisplayName = "Уплаченный НКД", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.In_Summa_UKD, DisplayName = "Сумма покупки с НКД", SortOrder = 10},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 11},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.NKD, DisplayName = "НКД", SortOrder = 12},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Amortizations, DisplayName = "Амортизация и купоны", SortOrder = 13},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.Value_Nom, DisplayName = "Стоимость на конец периода", SortOrder = 14},
                new ViewElementAttr{ColumnName = CurrentBillsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 15},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Bills, DuPositionType.Current)
           .ForEach(c =>
           {
                DataRow row = CurrentBills.Table.NewRow();
                row[CurrentBillsColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[CurrentBillsColumns.Investment] = c.Investment;
                row[CurrentBillsColumns.Oblig_Date_end] = c.Oblig_Date_end?.ToString("dd.MM.yyyy");
                row[CurrentBillsColumns.Oferta_Date] = $"{c.Oferta_Date?.ToString("dd.MM.yyyy")}{(!string.IsNullOrEmpty(c.Oferta_Type?.ToString()) ? $"({c.Oferta_Type})" : "")}";
                row[CurrentBillsColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[CurrentBillsColumns.Amount] = c.Amount.DecimalToStr();
                row[CurrentBillsColumns.In_Summa_UKD] = (c.In_Summa.ToDecimal() + c.UKD.ToDecimal()).DecimalToStr("#,##0.00");
                //row[CurrentBillsColumns.UKD] = dr["UKD"].DecimalToStr("#,##0.00");
                row[CurrentBillsColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[CurrentBillsColumns.Today_Price] = c.Today_PRICE.DecimalToStr("#,##0.00");
                row[CurrentBillsColumns.NKD] = c.NKD.DecimalToStr("#,##0.00");
                row[CurrentBillsColumns.Amortizations] = $"{c.Amortizations.DecimalToStr("#,##0.00")}{(!string.IsNullOrEmpty(c.Coupons?.ToString()) ? $"({c.Coupons.DecimalToStr("#,##0.00")})" : "")}";
                row[CurrentBillsColumns.Value_Nom] = c.Value_NOM.DecimalToStr("#,##0.00");
                row[CurrentBillsColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                CurrentBills.Table.Rows.Add(row);
            });
        }
        private void InitCurrentCash()
        {
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

            CurrentCash.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentCashColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Investment, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentCashColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки + валюта", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentCashColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentCashColumns.Value_NOM, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentCashColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 8},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Cash, DuPositionType.Current)
           .ForEach(c =>
           {
                DataRow row = CurrentCash.Table.NewRow();
                row[CurrentCashColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[CurrentCashColumns.Investment] = c.Investment;
                row[CurrentCashColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Coupons}";
                row[CurrentCashColumns.Amount] = c.Amount.DecimalToStr();
                row[CurrentCashColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[CurrentCashColumns.Today_Price] = c.Today_PRICE.DecimalToStr("#,##0.00");
                row[CurrentCashColumns.Value_NOM] = c.Value_NOM.DecimalToStr("#,##0.00");
                row[CurrentCashColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                CurrentCash.Table.Rows.Add(row);
            });
        }
        private void InitCurrentFunds()
        {
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

            CurrentFunds.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentFundsColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Investment, DisplayName = "Инструмент", SortOrder = 2},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.IN_PRICE, DisplayName = "Цена 1 бумаги на дату покупки + валюта", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Today_Price, DisplayName = "Цена 1 бумаги на дату отчета", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.Value_NOM, DisplayName = "Стоимость позиции на дату отчета", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentFundsColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 8},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Fund, DuPositionType.Current)
           .ForEach(c =>
           {
                DataRow row = CurrentFunds.Table.NewRow();
                row[CurrentFundsColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[CurrentFundsColumns.Investment] = c.Investment;
                row[CurrentFundsColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[CurrentFundsColumns.Amount] = c.Amount.DecimalToStr();
                row[CurrentFundsColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[CurrentFundsColumns.Today_Price] = c.Today_PRICE.DecimalToStr("#,##0.00");
                row[CurrentFundsColumns.Value_NOM] = c.Value_NOM.DecimalToStr("#,##0.00");
                row[CurrentFundsColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                CurrentFunds.Table.Rows.Add(row);
            });
        }
        private void InitCurrentDerivatives()
        {
            CurrentDerivatives = new TableView();
            CurrentDerivatives.Table = new DataTable();
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.IN_DATE);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Investment);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.IN_PRICE);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Amount);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.In_Summa);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Today_Price);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Dividends);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.Value_NOM);
            CurrentDerivatives.Table.Columns.Add(CurrentDerivativesColumns.FinRes);

            CurrentDerivatives.Ths = new List<ViewElementAttr>{
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.IN_DATE, DisplayName = "Дата покупки", SortOrder = 1},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Investment, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.IN_PRICE, DisplayName = "Цена покупки 1 лота", SortOrder = 4},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Amount, DisplayName = "Кол-во, шт", SortOrder = 5},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.In_Summa, DisplayName = "Сумма покупки ", SortOrder = 6},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Today_Price, DisplayName = "Цена на конец периода", SortOrder = 7},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Value_NOM, DisplayName = "Стоимость на конец периода", SortOrder = 8},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.Dividends, DisplayName = "Дивиденды", SortOrder = 9},
                new ViewElementAttr{ColumnName = CurrentDerivativesColumns.FinRes, DisplayName = "Фин. Результат", SortOrder = 10},
            };

            DuPositionResultService.GetPositions(_duParams, DuPositionAssetTableName.Derivatives, DuPositionType.Current)
           .ForEach(c =>
           {
                DataRow row = CurrentDerivatives.Table.NewRow();
                row[CurrentDerivativesColumns.IN_DATE] = c.In_Date?.ToString("dd.MM.yyyy");
                row[CurrentDerivativesColumns.Investment] = c.Investment;
                row[CurrentDerivativesColumns.IN_PRICE] = $"{c.In_Price.DecimalToStr("#,##0.00")} {c.Currency}";
                row[CurrentDerivativesColumns.Amount] = c.Amount.DecimalToStr();
                row[CurrentDerivativesColumns.In_Summa] = c.In_Summa.DecimalToStr("#,##0.00");
                row[CurrentDerivativesColumns.Today_Price] = c.Today_PRICE;
                row[CurrentDerivativesColumns.Dividends] = c.Dividends;
                row[CurrentDerivativesColumns.Value_NOM] = c.Value_NOM;
                row[CurrentDerivativesColumns.FinRes] = $"{c.FinRes.DecimalToStr("#,##0.00")}({c.FinResProcent.DecimalToStr("#,##0.00")}%)";
                CurrentDerivatives.Table.Rows.Add(row);
            });
        }

        private void InitOperationsHistory()
        {
            DuOperationsHistory = new TableView();
            DuOperationsHistory.Table = new DataTable();
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.Date);
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.OperName);
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.ToolName);
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.Price);
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.PaperAmount);
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.Cost);
            DuOperationsHistory.Table.Columns.Add(DuOperationsHistoryColumns.Fee);

            DuOperationsHistory.Ths = new List<ViewElementAttr>
            {
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.Date, DisplayName = "Дата операции", SortOrder = 1},
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.OperName, DisplayName = "Тип операции", SortOrder = 2},
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.ToolName, DisplayName = "Инструмент", SortOrder = 3},
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.Price, DisplayName = "Цена покупки 1 лота", SortOrder = 4},
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.PaperAmount, DisplayName = "Количество", SortOrder = 5},
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.Cost, DisplayName = "Сумма сделки", SortOrder = 6},
                new ViewElementAttr{ColumnName = DuOperationsHistoryColumns.Fee, DisplayName = "Комиссия", SortOrder = 7},
            };

            DuOperationsHistory.Ths.Where(t => t.ColumnName == DuOperationsHistoryColumns.Date).First().AttrRow.Add("width", "170px");
            DuOperationsHistory.Ths.Where(t => t.ColumnName == DuOperationsHistoryColumns.OperName).First().AttrRow.Add("width", "300px");
            DuOperationsHistory.Ths.Where(t => t.ColumnName == DuOperationsHistoryColumns.Price).First().AttrRow.Add("width", "130px");
            DuOperationsHistory.Ths.Where(t => t.ColumnName == DuOperationsHistoryColumns.PaperAmount).First().AttrRow.Add("width", "96px");
            DuOperationsHistory.Ths.Where(t => t.ColumnName == DuOperationsHistoryColumns.Cost).First().AttrRow.Add("width", "145px");
            DuOperationsHistory.Ths.Where(t => t.ColumnName == DuOperationsHistoryColumns.Fee).First().AttrRow.Add("width", "117px");

            _duOperationHistoryService.Operations.ForEach(c =>
            {
                DataRow row = DuOperationsHistory.Table.NewRow();
                row[DuOperationsHistoryColumns.Date] = c.Date.ToString("dd.MM.yyyy");
                row[DuOperationsHistoryColumns.OperName] = c.OperName;
                row[DuOperationsHistoryColumns.ToolName] = c.ToolName;
                row[DuOperationsHistoryColumns.Price] = $"{(!string.IsNullOrEmpty(c.Price?.ToString()) ? $"{c.Price.DecimalToStr("#,##0.00")} {c.RowValuta}" : "")}";
                row[DuOperationsHistoryColumns.PaperAmount] = c.PaperAmount.DecimalToStr();
                row[DuOperationsHistoryColumns.Cost] = $"{(!string.IsNullOrEmpty(c.RowCost?.ToString()) ? $"{c.RowCost.DecimalToStr("#,##0.00")} {c.RowValuta}" : "")}";
                row[DuOperationsHistoryColumns.Fee] = c.Fee.DecimalToStr("#,##0.00");
                DuOperationsHistory.Table.Rows.Add(row);
            });

        }
    }
}
