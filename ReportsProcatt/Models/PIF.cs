using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using ReportsProcatt.Content.Services;

namespace ReportsProcatt.Models
{
    public class PIF
    {
        public int Id { get; private set; }
        public string Name { get; private set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public Headers PifHeader { get; set; }
        public DateTime Dfrom => _dFrom;
        public DateTime Dto => _dTo;
        public CurrencyClass _Currency { get; set; }
        public Dictionary<string, string> Diagram { get; set; }
        public string AccountNumber => _mainService.PIF(Id).LS_NUM;
        public string OpenDate => _mainService.PIF(Id).DATE_OPEN.ToString();
        public string Amount => $"{_mainService.PIF(Id).SumAmount} шт.";
        public CircleDiagram AssetsStruct { get; set; }
        public CircleDiagram FundStruct { get; set; }
        public TableView PifOperationsHistory { get; set; }
        #region Private Fields
        private DateTime _dTo;
        private DateTime _dFrom;
        #endregion
        #region Services
        private ContractsDataSumService _mainService;
        private CircleDiagramsService _circleDiagramsService;
        private FundOperationHistoryService _fundOperationHistoryService;
        #endregion
        public PIF(string aName,DateTime? aDFrom,DateTime? aDTo,CurrencyClass aCurrency,int aFundId,int aInvestorId)
        {
            Id = aFundId;
            _Currency = aCurrency;
            Currency cur;

            Name = aName ?? _mainService.PIF(aFundId).Name;
            _dFrom = aDFrom ?? (DateTime)_mainService.PIF(aFundId).DATE_OPEN;
            _dTo = aDTo ?? (DateTime)_mainService.PIF(aFundId).DATE_CLOSE;

            _mainService = new ContractsDataSumService(
                new MainServiceParams
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
            _fundOperationHistoryService = new FundOperationHistoryService(
                new FundServiceParams
                {
                    FundId = aFundId,
                    DateFrom = aDFrom,
                    DateTo = aDTo,
                    CurrencyCode = Enum.TryParse(aCurrency.Char, out cur) ? cur : Currency.RUB,
                    InvestorId = aInvestorId
                });
            
            PifHeader = new Headers
            {
                TotalSum = $"{_mainService.PIF(Id).SItog.DecimalToStr()} {aCurrency.Char}",
                ProfitSum = $"{_mainService.PIF(Id).Income.DecimalToStr()} {aCurrency.Char}",
                Return = $"{_mainService.PIF(Id).Res.DecimalToStr("#0.00", aWithSign: true)}%"
            };

           
            Diagram = new Dictionary<string, string>
            {
                { PifDiagramColumns.Begin, $"{_mainService.PIF(Id).SNach.DecimalToStr()} {aCurrency.Char}" },
                { PifDiagramColumns.InVal, $"{_mainService.PIF(Id).InVal.DecimalToStr()} {aCurrency.Char}" },
                { PifDiagramColumns.OutVal, $"{_mainService.PIF(Id).OutVal.DecimalToStr()} {aCurrency.Char}" },
                { PifDiagramColumns.End, $"{_mainService.PIF(Id).SItog.DecimalToStr()} {aCurrency.Char}" }
            };
            //InitAccountDetails();
            InitAssetsStruct();
            InitFundStruct();
            InitOperationsHistory();
        }
        private void InitAssetsStruct()
        {
            var PIF = _circleDiagramsService.Category(Id, true);
            string TypeName = "АКТИВА(ов)";
            if (PIF.Count>0)
            {
                int i = 1;
                AssetsStruct = new CircleDiagram($"Fund_{Id}_AssetsStructCircle")
                {
                    
                    LegendName = "Активы",
                    MainText = $"{PIF.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {_Currency.Char}",
                    Footer = $"{PIF.Count().DecimalToStr()} {TypeName}",
                    Data = PIF
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

                if (PIF.Count > 7)
                {
                    decimal otherPerent =
                        PIF.
                        OrderByDescending(r => (double)r.Res)
                        .Skip(6)
                        .Sum(r => r.Res.ToDecimal());

                    AssetsStruct.Data.RemoveAt(AssetsStruct.Data.Count - 1);

                    AssetsStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее",
                        data = PIF
                        .OrderByDescending(r => r.Res)
                        .Skip(6)
                        .Sum(r => r.VALUE_CUR.ToDecimal()),
                        backgroundColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainAssetsCircle[7],
                        result = $"{otherPerent.DecimalToStr()}%"
                       
                    });
                }
            }
        }
        private void InitFundStruct()
        {
            var PIF2 = _circleDiagramsService.Assets(Id, true);
            string CatTypeName = "инструментов";
            if (PIF2.Count>0)
            {
                int i = 1;
                FundStruct = new CircleDiagram($"Fund_{Id}_StructCircle")
                {
                    LegendName = "Инструменты",
                    MainText = $"{PIF2.Sum(c => c.VALUE_CUR ?? 0).DecimalToStr()} {_Currency.Char}",
                    Footer = $"{PIF2.Count().DecimalToStr()} {CatTypeName}",
                    Data = PIF2
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

                if (PIF2.Count>7)
                {
                    decimal otherPerent = 
                       PIF2.
                       OrderByDescending(r => (double)r.Res)
                       .Skip(6)
                       .Sum(r => r.Res.ToDecimal());

                    FundStruct.Data.RemoveAt(FundStruct.Data.Count - 1);

                    FundStruct.Data.Add(new CircleDiagram.DataClass
                    {
                        lable = @$"Прочее",
                        data = PIF2
                        .OrderByDescending(r => r.Res)
                        .Skip(6)
                        .Sum(r => r.Res.ToDecimal()),
                        backgroundColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        borderColor = CircleDiagramsColorCodes.MainInstrumentsCircle[7],
                        result = $"{otherPerent.DecimalToStr()}%"
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
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Instrument, DisplayName = "Номер и дата заявки", SortOrder = 3},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Rate_rur, DisplayName = "Цена Пая", SortOrder = 4},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Amount, DisplayName = "Количество", SortOrder = 5},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Value_rur, DisplayName = "Сумма сделки", SortOrder = 6},
                new ViewElementAttr{ColumnName = PifOperationsHistoryColumns.Fee_rur, DisplayName = "Комиссия (надбавка/скидка)", SortOrder = 7}
            };
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Wdate).First().AttrRow.Add("width", "170px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Rate_rur).First().AttrRow.Add("width", "130px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Value_rur).First().AttrRow.Add("width", "145px");
            PifOperationsHistory.Ths.Where(t => t.ColumnName == PifOperationsHistoryColumns.Fee_rur).First().AttrRow.Add("width", "117px");

            _fundOperationHistoryService.Operations.ForEach(t =>
            {
                DataRow row = PifOperationsHistory.Table.NewRow();
                row[PifOperationsHistoryColumns.Wdate] = t.W_Date;
                row[PifOperationsHistoryColumns.Btype] = t.OperName;
                row[PifOperationsHistoryColumns.Instrument] = t.Order_NUM;
                row[PifOperationsHistoryColumns.Rate_rur] = $"{(!string.IsNullOrEmpty(t.RATE_RUR?.ToString()) ? $"{t.RATE_RUR.DecimalToStr("#,##0.00")} {t.Valuta}" : "")}";
                row[PifOperationsHistoryColumns.Amount] = t.Amount.DecimalToStr("#,##0.0000000"); 
                row[PifOperationsHistoryColumns.Value_rur] = $"{(!string.IsNullOrEmpty(t.VALUE_RUR?.ToString()) ? $"{t.VALUE_RUR.DecimalToStr("#,##0.00")} {t.Valuta}" : "")}";
                row[PifOperationsHistoryColumns.Fee_rur] = t.Fee_RUR.DecimalToStr("#,##0.00");
                PifOperationsHistory.Table.Rows.Add(row);
            });

        }
    }
}
