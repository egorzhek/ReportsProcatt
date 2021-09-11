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
        public SQLData(int InvestorId, DateTime? DateFrom, DateTime? DateTo, string cnnStr, string ReportPath)
        {
            _path = ReportPath;
            //connectionString = @"Data Source=host.docker.internal,49172;Encrypt=False;Initial Catalog=CacheDB;Integrated Security=True;User ID=DESKTOP-2G9NLM6\D";
            //ReportPath = Environment.GetEnvironmentVariable("ReportPath");
            //connectionString = Program.GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));

            DataSet_InvestorFull = new DataSet();
            DataSet_CircleAssets = new DataSet();
            DataSet_CircleCurrencies = new DataSet();
            DataSet_CircleInstruments = new DataSet();
            using (SqlConnection connection = new SqlConnection(cnnStr))
            {
                connection.Open();
                Task.WaitAll
                (
                Task.Run(() => InitFullData(InvestorId, DateFrom, DateTo, connection)),
                Task.Run(() => InitAssetsData(InvestorId, DateTo, connection)),
                Task.Run(() => InitCurrenciesData(InvestorId, DateTo, connection)),
                Task.Run(() => InitInstrumentsData(InvestorId, DateTo, connection))
                );
            }

        }
        private void InitFullData(int InvestorId, DateTime? DateFrom, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"InverstorFull.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@DateFromSharp", DateFrom == null ? DBNull.Value : DateFrom);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_InvestorFull);
            }
        }
        private void InitAssetsData(int InvestorId, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"CircleAssets.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_CircleAssets);
            }
        }
        private void InitCurrenciesData(int InvestorId, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"CircleCurrencies.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_CircleCurrencies);
            }
        }
        private void InitInstrumentsData(int InvestorId, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(_path, @"CircleInstruments.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_CircleInstruments);
            }
        }
    }

    public class SQLDataDU
    {
        public DataSet DataSet_TrustManagement { get; private set; }
        public DataSet DataSet_DU { get; private set; }
        public DataSet DataSet_DU2 { get; private set; }
        string ReportPath => @"c:\Users\D\source\Ingos\ReportsProcatt\Reports\";
        public SQLDataDU(int ContractId, int InvestorId, DateTime? DateFrom, DateTime? DateTo, SqlConnection connection)
        {
            DataSet_TrustManagement = new DataSet();
            DataSet_DU = new DataSet();
            DataSet_DU2 = new DataSet();
            Task.WaitAll
            (
                Task.Run(() =>InitTrustManagement(ContractId, InvestorId, DateFrom, DateTo, connection)),
                Task.Run(() => InitDU(InvestorId, DateTo, connection)),
                Task.Run(() =>InitDU2(InvestorId, DateTo, connection))
            );
        }
        private void InitTrustManagement(int ContractId,int InvestorId, DateTime? DateFrom, DateTime? DateTo, SqlConnection connection) 
        {
            string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"TrustManagement.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@DateFromSharp", DateFrom == null ? DBNull.Value : DateFrom);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
            command1.Parameters.AddWithValue("@ContractIdSharp", ContractId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_TrustManagement);
            }
        }
        private void InitDU(int InvestorId, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"DU.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_DU);
            }
        }
        private void InitDU2(int InvestorId, DateTime? DateTo, SqlConnection connection) 
        {
            string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"DU2.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_DU2);
            }
        }
    }
    public class SQLDataPIF
    {
        public DataSet DataSet_FundInfo { get; private set; }
        public DataSet DataSet_PIF { get; private set; }
        public DataSet DataSet_PIF2 { get; private set; }
        string ReportPath => @"c:\Users\D\source\Ingos\ReportsProcatt\Reports\";
        public SQLDataPIF(int ContractId, int InvestorId, DateTime? DateFrom, DateTime? DateTo, SqlConnection connection)
        {
            DataSet_FundInfo = new DataSet();
            DataSet_PIF = new DataSet();
            DataSet_PIF2 = new DataSet();
            Task.WaitAll
            (
                Task.Run(() => InitFundInfo(ContractId, InvestorId, DateFrom, DateTo, connection)),
                Task.Run(() => InitPIF(InvestorId, DateTo, connection)),
                Task.Run(() => InitPIF2(InvestorId, DateTo, connection))
            );
        }
        private void InitFundInfo(int ContractId, int InvestorId, DateTime? DateFrom, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"FundInfo.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@DateFromSharp", DateFrom == null ? DBNull.Value : DateFrom);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
            command1.Parameters.AddWithValue("@ContractIdSharp", ContractId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_FundInfo);
            }
        }
        private void InitPIF(int InvestorId, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"PIF.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_PIF);
            }
        }
        private void InitPIF2(int InvestorId, DateTime? DateTo, SqlConnection connection)
        {
            string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"PIF2.sql"));

            SqlCommand command1 = new SqlCommand(queryString1, connection);
            command1.CommandType = CommandType.Text;
            command1.CommandTimeout = 600;

            command1.Parameters.AddWithValue("@DateToSharp", DateTo == null ? DBNull.Value : DateTo);
            command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);

            using (SqlDataAdapter sda = new SqlDataAdapter(command1))
            {
                sda.Fill(DataSet_PIF2);
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
        public static string DecimalToStr(this DataSet ds, int aDataTableId, string aColumnName, string aFormat = "",bool aWithSign = false, string aDecimalSeparatot = ",", int aRowId = 0)
        {
           return ds.GetValue(aDataTableId, aColumnName, aRowId).DecimalToStr(aFormat,aWithSign,aDecimalSeparatot);
        }
        public static string DecimalToStr(this object inVal, string aFormat = "", bool aWithSign = false, string aDecimalSeparatot = ",")
        {
            decimal vVal;
            var res = decimal.TryParse(inVal.ToString(), out vVal);

            var cl = new CultureInfo("ru-RU", false).NumberFormat;
            cl.NumberDecimalSeparator = aDecimalSeparatot;

            string vSign = vVal > 0 ? "+" : "";
            return res ? $"{(aWithSign ? vSign : "")}{vVal.ToString(aFormat, cl)}" : "";
        }
    }
}
