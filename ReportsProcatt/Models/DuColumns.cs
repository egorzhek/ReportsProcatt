using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class DuDiagramColumns
    {
        public const string Begin = "В начале периода";
        public const string InVal = "Пополнения";
        public const string Dividents = "Дивиденты";
        public const string Coupons = "Купоны";
        public const string OutVal = "Выводы";
        public const string End = "В конце периода";
    }
    public class CurrentSharesColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Today_Price = "Today_Price";
        public const string Dividends = "Dividends";
        public const string Value_NOM = "Value_NOM";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }
    public class CurrentBondsColumns
    {
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string Oblig_Date_end = "Oblig_Date_end";
        public const string Oferta_Date = "Oferta_Date";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa_UKD = "In_Summa_UKD";
        public const string UKD = "UKD";
        public const string In_Summa = "In_Summa";
        public const string Today_Price = "Today_Price";
        public const string NKD = "NKD";
        public const string Amortizations = "Amortizations";
        public const string Value_Nom = "Value_Nom";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Oferta_Type = "Oferta_Type";
        public const string Valuta = "Valuta";
        public const string Coupons = "Coupons";
    }



    public class CurrentFundsColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Today_Price = "Today_Price";
        public const string Value_NOM = "Value_NOM";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }

    public class CurrentBillsColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string Oblig_Date_end = "Oblig_Date_end";
        public const string Oferta_Date = "Oferta_Date";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string UKD = "UKD";
        public const string In_Summa_UKD = "In_Summa_UKD";
        public const string Today_Price = "Today_Price";
        public const string NKD = "NKD";
        public const string Amortizations = "Amortizations";
        public const string Value_Nom = "Value_Nom";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Oferta_Type = "Oferta_Type";
        public const string Valuta = "Valuta";
        public const string Coupons = "Coupons";
    }


    public class CurrentDerivativesColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Today_Price = "Today_Price";
        public const string Dividends = "Dividends";
        public const string Value_NOM = "Value_NOM";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }

    public class CurrentCashColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Today_Price = "Today_Price";
        public const string Value_NOM = "Value_NOM";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }
    public class ClosedSharesColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Out_Price = "Out_Price";
        public const string Dividends = "Dividends";
        public const string Out_Date = "Out_Date";
        public const string Out_Summa = "Out_Summa";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }

    public class ClosedBondsColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string Oblig_Date_end = "Oblig_Date_end";
        public const string Oferta_Date = "Oferta_Date";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string UKD = "UKD";
        public const string In_Summa_UKD = "In_Summa_UKD";
        public const string Out_Price = "Out_Price";
        public const string NKD = "NKD";
        public const string Amortizations = "Amortizations";
        public const string Out_Date = "Out_Date";
        public const string Out_Summa = "Out_Summa";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Oferta_Type = "Oferta_Type";
        public const string Valuta = "Valuta";
        public const string Coupons = "Coupons";
    }

    public class ClosedFundsColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE ";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Out_Price = "Out_Price";
        public const string Out_Date = "Out_Date";
        public const string Out_Summa = "Out_Summa";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }

    public class ClosedDerivativesColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Out_Price = "Out_Price";
        public const string Dividends = "Dividends";
        public const string Out_Date = "Out_Date";
        public const string Out_Summa = "Out_Summa";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }

    public class ClosedBillsColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string ISIN = "ISIN";
        public const string Investment = "Investment";
        public const string Oblig_Date_end = "Oblig_Date_end";
        public const string Oferta_Date = "Oferta_Date";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string UKD = "UKD";
        public const string In_Summa_UKD = "In_Summa_UKD";
        public const string Out_Price = "Out_Price";
        public const string NKD = "NKD";
        public const string Amortizations = "Amortizations";
        public const string Out_Date = "Out_Date";
        public const string Out_Summa = "Out_Summa";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Oferta_Type = "Oferta_Type";
        public const string Valuta = "Valuta";
    }


    public class ClosedCashColumns
    {
        public const string IN_DATE = "IN_DATE";
        public const string Investment = "Investment";
        public const string IN_PRICE = "IN_PRICE";
        public const string Amount = "Amount";
        public const string In_Summa = "In_Summa";
        public const string Out_Price = "Out_Price";
        public const string Out_Date = "Out_Date";
        public const string Out_Summa = "Out_Summa";
        public const string FinRes = "FinRes";
        public const string FinResProcent = "FinResProcent";
        public const string Valuta = "Valuta";
    }
    public class DividedtsCouponsColumns
    {
        public const string Date = "Date";
        public const string ToolName = "ToolName";
        public const string PriceType = "PriceType";
        public const string ContractName = "ContractName";
        public const string Price = "Price";
        public const string Valuta = "Valuta";
    }
    public class DuOperationsHistoryColumns
    {
        public const string Date = "Date";
        public const string OperName = "OperName";
        public const string Price = "Price";
        public const string PaperAmount = "PaperAmount";
        public const string Cost = "Cost";
        public const string Fee = "Fee";
    }



}
