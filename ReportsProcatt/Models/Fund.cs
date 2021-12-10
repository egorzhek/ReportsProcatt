using ReportsProcatt.Content;
using System;
using System.IO;
using System.Linq;

namespace ReportsProcatt.Models
{
    public class Fund
    {
        public PIF PIF { get; set; }
        public string rootStr { get; set; }
        private string connectionString;
        private string ReportPath;

        public Fund(int InvestorId,int ContractId,DateTime? DateFrom,DateTime? DateTo,string CurrencyCode)
        {
            ReportPath = Environment.GetEnvironmentVariable("ReportPath");
            connectionString = Program.GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));
            PIF = new PIF(null, DateFrom, DateTo, CurrencyClass.GetCurrency(CurrencyCode), ContractId, InvestorId, connectionString, ReportPath);
        }
    }
}
