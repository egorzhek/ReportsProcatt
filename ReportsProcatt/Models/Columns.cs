using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class MainDiagramParams
    {
        public const string Begin = "В начале периода";
        public const string InVal = "Пополнения";
        public const string OutVal = "Выводы";
        public const string Dividents = "Дивиденды";
        public const string Coupons = "Купоны";
        public const string OutVal1 = "Погашения";
        //public const string ReVal = "Переоценка";
        public const string End = "В конце периода";
    }
    public class PIFsTotalColumns
    {
        public const string PIFs = "PIFs";
        public const string StartValue = "StartValue";
        public const string EndValue = "EndValue";
        public const string Result = "Result";
    }

    public class DUsTotalColumns
    {
        public const string DUs = "DUs";
        public const string StartValue = "StartValue";
        public const string EndValue = "EndValue";
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
        public const string Redemption = "Redemption";
        public const string EndAssets = "EndAssets";
        public const string CurrencyProfit = "CurrencyProfit";
        public const string ProfitPercent = "ProfitPercent";
    }
    public class DivsNCouponsColumns
    {
        public const string NameObject = "NameObject";
        public const string INPUT_DIVIDENTS = "INPUT_DIVIDENTS";
        public const string INPUT_COUPONS = "INPUT_COUPONS";
        public const string Summ = "Summ";
        public const string Valuta = "Valuta";
    }
    public class DivsNCouponsDetailsColumns
    {
        public const string Date = "Date";
        public const string ToolName = "ToolName";
        public const string PriceType = "PriceType";
        public const string ContractName = "ContractName";
        public const string Price = "Price";
        public const string Valuta = "Valuta";
    }

}
