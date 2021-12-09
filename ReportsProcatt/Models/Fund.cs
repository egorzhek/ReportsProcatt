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
            ReportPath = @"c:\Users\D\source\Ingos\ReportsProcatt\Reports\";
            connectionString = @"Data Source=(local);Encrypt=False;Initial Catalog=CacheDB;Integrated Security=True;User ID=DESKTOP-DOMSN08\D";
            PIF = new PIF(null, DateFrom, DateTo, CurrencyClass.GetCurrency(CurrencyCode), ContractId, InvestorId, connectionString, ReportPath);
        }
    }
}
