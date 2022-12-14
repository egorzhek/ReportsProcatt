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
    public class SQLData
    {

        public DataSet DataSet_InvestorFull { get; private set; }
        public DataSet DataSet_CircleInstruments { get; private set; }
        public DataSet DataSet_CircleCurrencies { get; private set; }
        public DataSet DataSet_CircleAssets { get; private set; }
        private string _path;
        private string _cnnStr;
        public SQLData(string Currency, int InvestorId, DateTime? DateFrom, DateTime? DateTo, string cnnStr, string ReportPath)
        {
            _path = ReportPath;
            _cnnStr = cnnStr;

            DataSet_InvestorFull = new DataSet();
            DataSet_CircleAssets = new DataSet();
            DataSet_CircleCurrencies = new DataSet();
            DataSet_CircleInstruments = new DataSet();

            Task.WaitAll
            (
                Task.Run(() => InitFullData(Currency, InvestorId, DateFrom, DateTo))
            );

            try
            {
                DateFrom = (DateTime)DataSet_InvestorFull.GetValue(InvestFullTables.MainResultDT, "StartDate");
                DateTo = (DateTime)DataSet_InvestorFull.GetValue(InvestFullTables.MainResultDT, "EndDate");
            }
            catch { }

            Task.WaitAll
            (
                Task.Run(() => InitAssetsData(Currency, InvestorId, DateTo)),
                Task.Run(() => InitCurrenciesData(Currency, InvestorId, DateTo)),
                Task.Run(() => InitInstrumentsData(Currency, InvestorId, DateTo))
            );
        }
        private async Task InitFullData(string Currency, int InvestorId, DateTime? DateFrom, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"InverstorFull.sql"));

            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                connection.Open();
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@DateFromSharp", DateFrom == null ? DBNull.Value : DateFrom);
                command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_InvestorFull));
                }
            }
        }
        private async Task InitAssetsData(string Currency, int InvestorId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"CircleAssets.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                connection.Open();
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_CircleAssets));
                }
            }
        }
        private async Task InitCurrenciesData(string Currency, int InvestorId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"CircleCurrencies.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                connection.Open();
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_CircleCurrencies));
                }
            }
        }
        private async Task InitInstrumentsData(string Currency, int InvestorId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"CircleInstruments.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                connection.Open();
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_CircleInstruments));
                }
            }
        }
    }

    public class SQLDataDU
    {
        public DataSet DataSet_TrustManagement { get; private set; }
        public DataSet DataSet_DU { get; private set; }
        public DataSet DataSet_DU2 { get; private set; }
        private string _path;
        private string _cnnStr;
        public SQLDataDU(string Currency, int ContractId, int InvestorId, DateTime? DateFrom, DateTime? DateTo, string cnnStr, string ReportPath)
        {
            _path = ReportPath;
            _cnnStr = cnnStr;

            DataSet_TrustManagement = new DataSet();
            DataSet_DU = new DataSet();
            DataSet_DU2 = new DataSet();

            if (DateTo == null)
            {
                Task.WaitAll
                (
                    Task.Run(() => InitTrustManagement(Currency, ContractId, InvestorId, DateFrom, DateTo))
                );

                DateTo = (DateTime)DataSet_TrustManagement.GetValue(DuTables.DuParams, DuParams.MaxDate);

                Task.WaitAll
                (
                    Task.Run(() => InitDU(Currency, ContractId, DateTo)),
                    Task.Run(() => InitDU2(Currency, ContractId, DateTo))
                );
            }
            else
            {
                Task.WaitAll
                (
                    Task.Run(() => InitTrustManagement(Currency, ContractId, InvestorId, DateFrom, DateTo)),
                    Task.Run(() => InitDU(Currency, ContractId, DateTo)),
                    Task.Run(() => InitDU2(Currency, ContractId, DateTo))
                );
            }
        }
        private async Task InitTrustManagement(string Currency, int ContractId,int InvestorId, DateTime? DateFrom, DateTime? DateTo) 
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"TrustManagement.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@DateFromSharp", DateFrom == null ? DBNull.Value : DateFrom);
                command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                command1.Parameters.AddWithValue("@ContractIdSharp", ContractId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_TrustManagement));
                }
            }
        }
        private async Task InitDU(string Currency, int ContractId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"DU.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@ContractIdSharp", ContractId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_DU));
                }
            }
        }
        private async Task InitDU2(string Currency, int ContractId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"DU2.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;
                
                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@ContractIdSharp", ContractId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_DU2));
                }
            }
        }
    }
    public class SQLDataPIF
    {
        public DataSet DataSet_FundInfo { get; private set; }
        public DataSet DataSet_PIF { get; private set; }
        public DataSet DataSet_PIF2 { get; private set; }
        private string _path;
        private string _cnnStr;
        public SQLDataPIF(string Currency, int FundId, int InvestorId, DateTime? DateFrom, DateTime? DateTo, string cnnStr, string ReportPath)
        {
            _path = ReportPath;
            _cnnStr = cnnStr;

            DataSet_FundInfo = new DataSet();
            DataSet_PIF = new DataSet();
            DataSet_PIF2 = new DataSet();

            if (DateTo == null)
            {
                Task.WaitAll
                (
                    Task.Run(() => InitFundInfo(Currency, FundId, InvestorId, DateFrom, DateTo))
                );

                DateTo = (DateTime)DataSet_FundInfo.GetValue(PifTables.MainResultDT, "MaxDate");

                Task.WaitAll
                (
                    Task.Run(() => InitPIF(Currency, FundId, DateTo)),
                    Task.Run(() => InitPIF2(Currency, FundId, DateTo))
                );
            }
            else
            {
                Task.WaitAll
                (
                    Task.Run(() => InitFundInfo(Currency, FundId, InvestorId, DateFrom, DateTo)),
                    Task.Run(() => InitPIF(Currency, FundId, DateTo)),
                    Task.Run(() => InitPIF2(Currency, FundId, DateTo))
                );
            }
        }
        private async Task InitFundInfo(string Currency, int FundId, int InvestorId, DateTime? DateFrom, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"FundInfo.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@DateFromSharp", DateFrom == null ? DBNull.Value : DateFrom);
                command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                command1.Parameters.AddWithValue("@FundIdSharp", FundId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_FundInfo));
                }
            }
        }
        private async Task InitPIF(string Currency, int FundId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"PIF.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@FundIdSharp", FundId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_PIF));
                }
            }
        }
        private async Task InitPIF2(string Currency, int FundId, DateTime? DateTo)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"PIF2.sql"));
            using (SqlConnection connection = new SqlConnection(_cnnStr))
            {
                SqlCommand command1 = new SqlCommand(queryString1, connection);
                command1.CommandType = CommandType.Text;
                command1.CommandTimeout = 600;

                command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
                command1.Parameters.AddWithValue("@FundIdSharp", FundId);
                command1.Parameters.AddWithValue("@ValutaSharp", Currency);

                using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                {
                    await Task.Run(() => sda.Fill(DataSet_PIF2));
                }
            }
        }
    }

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
