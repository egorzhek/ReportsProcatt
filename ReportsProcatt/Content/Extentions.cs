using ReportsProcatt.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Content
{
    public static partial class Extentions
    {
        public static object GetValue(this DataSet ds, int aDataTableId, string aColumnName, int aRowId = 0)
        {
            if (aDataTableId <= ds.Tables.Count &&
                ds.Tables[aDataTableId].Columns[aColumnName] != null &&
                ds.Tables[aDataTableId].Rows.Count >= aRowId)
            {
                return ds.Tables[aDataTableId].Rows[aRowId][aColumnName];
            }
            else { return null; }
        }
        public static string DecimalToStr(this DataSet ds, int aDataTableId, string aColumnName, string aFormat = "#,##0",bool aWithSign = false, string aDecimalSeparatot = ",", int aRowId = 0)
        {
           return ds.GetValue(aDataTableId, aColumnName, aRowId).DecimalToStr(aFormat,aWithSign,aDecimalSeparatot);
        }
        public static string DecimalToStr(this object inVal, string aFormat = "#,##0", bool aWithSign = false, string aDecimalSeparatot = ",")
        {
            decimal vVal;
            if(inVal == null)
            {
                return null;
            }
            var res = decimal.TryParse(inVal.ToString(), out vVal);

            var cl = new CultureInfo("ru-RU", false).NumberFormat;
            cl.NumberDecimalSeparator = aDecimalSeparatot;

            string vSign = vVal > 0 ? "+" : "";
            return res ? $"{(aWithSign ? vSign : "")}{vVal.ToString(aFormat, cl)}" : "";
        }
        public static string ToCharString(this DateTime dt)
        {
            switch (dt.Month)
            {
                case 1:
                    return $"ЯНВ {dt.ToString("yy")}";
                case 2:
                    return $"ФЕВ {dt.ToString("yy")}";
                case 3:
                    return $"МАР {dt.ToString("yy")}";
                case 4:
                    return $"АПР {dt.ToString("yy")}";
                case 5:
                    return $"МАЙ {dt.ToString("yy")}";
                case 6:
                    return $"ИЮН {dt.ToString("yy")}";
                case 7:
                    return $"ИЮЛ {dt.ToString("yy")}";
                case 8:
                    return $"АВГ {dt.ToString("yy")}";
                case 9:
                    return $"СЕН {dt.ToString("yy")}";
                case 10:
                    return $"ОКТ {dt.ToString("yy")}";
                case 11:
                    return $"НОЯ {dt.ToString("yy")}";
                case 12:
                    return $"ДЕК {dt.ToString("yy")}";
                default:
                    return "ERROR";
            }
        }
        public static decimal ToDecimal(this object val)
        {
            return val as decimal? ?? 0;
        }
    }
}
