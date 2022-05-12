using ReportsProcatt.Content;
using System;
using System.IO;
using System.Linq;

namespace ReportsProcatt.Models
{
    public class Contract
    {
        public DU DU { get; set; }
        public string rootStr { get; set; }
        public Contract(int InvestorId,int ContractId,DateTime? DateFrom,DateTime? DateTo,string CurrencyCode)
        {
            DU = new DU(null, DateFrom, DateTo, CurrencyClass.GetCurrency(CurrencyCode), ContractId, InvestorId);
        }
    }
}
