using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class Report
    {
        #region Свойства
        public string rootStr { get; set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public DateTime Dfrom => (DateTime)_invFullDS.GetValue(0, "StartDate");
        public DateTime Dto => (DateTime)_invFullDS.GetValue(0, "EndDate");
        public string ReportCurrency => "RUB";
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
        public CircleDiagram Currency { get; set; }
        public List<PIF> PIFs { get; set; }
        public List<DU> DUs { get; set; }
        #endregion
        #region Классы
        public class Headers
        {
            public string TotalSum { get; set; }
            public string ProfitSum { get; set; }
            public string Return { get; set; }
        }
        public class CircleDiagram { }
        public class PIF
        {

        }
        public class DU { }
       
        #endregion
        #region Поля
        private SQLData _data;
        private DataSet _invFullDS => _data.DataSet_InvestorFull;
        #endregion
        public Report(int InvestorId, DateTime DateFrom, DateTime DateTo)
        {
            _data = new SQLData(InvestorId, DateFrom, DateTo);

            MainHeader = new Headers
            {
                TotalSum = $"{_invFullDS.DecimalToStr(0, "ActiveDateToValue", "#,##0")} {CurrChar}",
                ProfitSum = $"{_invFullDS.DecimalToStr(0, "ProfitValue", "#,##0")} {CurrChar}",
                Return = $"{_invFullDS.DecimalToStr(0, "ProfitProcentValue", aWithSign: true)}%"
            };
            InitMainDiagram();
            InitPIFsTotalTable();
            InitDUsTotalTable();
            InitAllAssetsTable();
        }
        public void InitMainDiagram()
        {
            MainDiagram = new Dictionary<string, string>();
            MainDiagram.Add(MainDiagramParams.Begin, _invFullDS.DecimalToStr(1, "Snach", "#,##0"));
            MainDiagram.Add(MainDiagramParams.InVal, _invFullDS.DecimalToStr(1, "InVal", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.OutVal, _invFullDS.DecimalToStr(1, "OutVal", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.Dividents, _invFullDS.DecimalToStr(1, "Dividents", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.Coupons, _invFullDS.DecimalToStr(1, "Coupons", "#,##0", true));
            MainDiagram.Add(MainDiagramParams.ReVal, "");
            MainDiagram.Add(MainDiagramParams.Taxes, "");
            MainDiagram.Add(MainDiagramParams.Fee, "");
            MainDiagram.Add(MainDiagramParams.End, _invFullDS.DecimalToStr(0, "ActiveDateToValue", "#,##0"));
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
                new ViewElementAttr{ColumnName = PIFsTotalColumns.PIFs, DisplayName = "ПИФЫ", AttrRow = @"width=""520px""", SortOrder = 1},
                new ViewElementAttr{ColumnName = PIFsTotalColumns.AssetsToEnd, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = PIFsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ ЗА {Period}", SortOrder = 3 }
            };

            foreach (DataRow dr in _invFullDS.Tables[4].Rows)
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
                new ViewElementAttr{ColumnName = DUsTotalColumns.DUs, DisplayName = "ДОВЕРИТЕЛЬНОЕ УПРАВЛЕНИЕ", AttrRow = @"width=""520px""", SortOrder = 1},
                new ViewElementAttr{ColumnName = DUsTotalColumns.AssetsToEnd, DisplayName = $"АКТИВЫ НА {Dto.ToString("dd.MM.yyyy")}", SortOrder = 2 },
                new ViewElementAttr{ColumnName = DUsTotalColumns.Result, DisplayName = $"РЕЗУЛЬТАТЫ ЗА {Period}", SortOrder = 3 }
            };

            foreach (DataRow dr in _invFullDS.Tables[5].Rows)
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
                new ViewElementAttr{ColumnName = AllAssetsColumns.Product, DisplayName = "ПРОДУКТ", AttrRow = @"width=""520px""", SortOrder = 1},
                new ViewElementAttr{ColumnName = AllAssetsColumns.BeginAssets, DisplayName = "АКТИВЫ НА НАЧАЛО ПЕРИОДА", SortOrder = 2},
                new ViewElementAttr{ColumnName = AllAssetsColumns.InVal, DisplayName = "ПОПОЛНЕНИЕ", SortOrder = 3},
                new ViewElementAttr{ColumnName = AllAssetsColumns.OutVal, DisplayName = "ВЫВОД", SortOrder = 4},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Dividents, DisplayName = "СРЕДСТВ", SortOrder = 5},
                new ViewElementAttr{ColumnName = AllAssetsColumns.Coupons, DisplayName = "ДИВИДЕНДЫ", SortOrder = 6},
                new ViewElementAttr{ColumnName = AllAssetsColumns.EndAssets, DisplayName = "КУПОНЫ", SortOrder = 7},
                new ViewElementAttr{ColumnName = AllAssetsColumns.CurrencyProfit, DisplayName = "ДОХОД В ВАЛЮТЕ", SortOrder = 8},
                new ViewElementAttr{ColumnName = AllAssetsColumns.ProfitPercent, DisplayName = "ДОХОД В %", SortOrder = 9},
            };

            foreach (DataRow dr in _invFullDS.Tables[6].Rows)
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

            foreach (DataRow dr in _invFullDS.Tables[7].Rows)
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
    }
    public class MainDiagramParams
    {
        public const string Begin = "В начале";
        public const string InVal = "Зачисления";
        public const string OutVal = "Выводы";
        public const string Dividents = "Дивиденты";
        public const string Coupons = "Купоны";
        public const string ReVal = "Переоценка";
        public const string Taxes = "Налоги";
        public const string Fee = "Комиссия";
        public const string End = "В конце";
    }
    public class PIFsTotalColumns
    {
        public const string PIFs = "PIFs";
        public const string AssetsToEnd = "AssetsToEnd";
        public const string Result = "Result";
    }

    public class DUsTotalColumns
    {
        public const string DUs = "DUs";
        public const string AssetsToEnd = "AssetsToEnd";
        public const string Result = "Result";
    }

    public class AllAssetsColumns
    {
        public const string Product = "Product";
        public const string BeginAssets = "BeginAssets";
        public const string InVal = "InVal";
        public const string OutVal = "OutVal";
        public const string Dividents = "Dividents";
        public const string Coupons = "Coupons";
        public const string EndAssets = "EndAssets";
        public const string CurrencyProfit = "CurrencyProfit";
        public const string ProfitPercent = "ProfitPercent";
    }

    public class TableView
    {
        public List<ViewElementAttr> Ths { get; set; }
        public DataTable Table { get; set; }

    }
    public class ViewElementAttr
    {
        public int SortOrder { get; set; }
        public string ColumnName { get; set; }
        public string DisplayName { get; set; }
        public string AttrRow { get; set; }
    }
}
