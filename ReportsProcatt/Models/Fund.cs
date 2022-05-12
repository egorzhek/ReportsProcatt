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

        public Fund(int InvestorId,int ContractId,DateTime? DateFrom,DateTime? DateTo,string CurrencyCode)
        {
            PIF = new PIF(null, DateFrom, DateTo, CurrencyClass.GetCurrency(CurrencyCode), ContractId, InvestorId);
        }
    }
}
