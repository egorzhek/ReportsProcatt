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
        public DataSet DataSet_InvestorFull{ get; private set; }
        public SQLData(int InvestorId, DateTime? DateFrom, DateTime? DateTo)
        {
            DataSet_InvestorFull = new DataSet();
            InitData(InvestorId, DateFrom, DateTo);
        }

        private void InitData(int InvestorId, DateTime? DateFrom, DateTime? DateTo)
        {
            //string connectionString = @"Data Source=DESKTOP-2G9NLM6\MSSQLSERVER15;Encrypt=False;Initial Catalog=CacheDB;Integrated Security=True;User ID=DESKTOP-2G9NLM6\D";

            string ReportPath = Environment.GetEnvironmentVariable("ReportPath");
            string connectionString = Program.GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                connection.Open();

                //string queryString1 = File.ReadAllText(@"c:\Users\D\source\Ingos\ReportsProcatt\Reports\InverstorFull.sql");
                string queryString1 = File.ReadAllText(Path.Combine(ReportPath, @"Reports\InverstorFull.sql"));

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
        }
    }
    public static class Extentions
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
