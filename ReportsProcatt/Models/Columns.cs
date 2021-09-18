﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
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
}