using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class ChartDiagramClass 
    {
        public string ElementName { get; private set; }
        public string Type { get; set; }
        public List<DataSetClass> DataSets { get; set; }
        public List<string> Lables { get; set; }
        public class DataSetClass
        {
            public string lable { get; set; }
            public List<DataClass> data { get; set; }
            public string backgroundColor { get; set; }
        }
        public class DataClass
        {
            public decimal value { get; set; }
            public string borderColor { get; set; }
        }
        public ChartDiagramClass(string aElementName)
        {
            ElementName = aElementName;
        }
    }

    public class TableView
    {
        public bool IsTextBlock { get; set; }
        public List<ViewElementAttr> Ths { get; set; }
        public DataTable Table { get; set; }

    }
    public class ViewElementAttr
    {
        public int SortOrder { get; set; }
        public string ColumnName { get; set; }
        public string DisplayName { get; set; }
        public Dictionary<string, string> AttrRow = new Dictionary<string, string>();
    }
    public class Headers
    {
        public string TotalSum { get; set; }
        public string ProfitSum { get; set; }
        public string Return { get; set; }
    }
    public class CircleDiagram
    {
        public string ElementName { get; private set; }
        public string LegendName { get; set; }
        public string Header { get; set; }
        public string MainText { get; set; }
        public string Footer { get; set; }
        public string Type { get; set; }
        public List<DataClass> Data { get; set; }
        public class DataClass
        {
            public string lable { get; set; }
            public decimal data { get; set; }
            public string backgroundColor { get; set; }
            public string borderColor { get; set; }
            public string result { get; set; }
        }
        public CircleDiagram(string aElementName)
        {
            ElementName = aElementName;
        }
    }
    public class CircleDiagramGammaElement
    {
        public int SortIndex { get; set; }
        public string ColorCode { get; set; }
    }
    public class CurrencyClass
    {
        public string Code { get; set; }
        public string Char { get; set; }
        public string Name { get; set; }

        public static CurrencyClass GetCurrency(string Code)
        {
            return Currencies.FirstOrDefault(c => c.Code == Code) ?? Currencies.First();
        }
        private static List<CurrencyClass> Currencies = new List<CurrencyClass>()
        {
            new CurrencyClass{Code = "RUB", Char ="₽", Name = "Рубль"},
            new CurrencyClass{Code = "USD", Char ="$", Name = "Dollar"},
            new CurrencyClass{Code = "EUR", Char ="€", Name = "Euro"}

        };
    }
}
