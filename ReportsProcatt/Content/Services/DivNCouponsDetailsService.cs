using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ReportsProcatt.Content.Services
{
    public class DivNCouponsDetailsService
    {
        private List<DivNCouponsDetailsResult> _data;
        public DivNCouponsDetailsService(DivNCouponsDetailsServiceParams vParams)
        {
            _data = RepositoryDB.GetDivNCouponsDetails(vParams);
        }
        public List<DivNCouponsDetailsResult> Totals => _data.OrderBy(c => c.Date).ToList();
        public List<DivNCouponsDetailsResult> ContractDetails(int ContractId) => 
            _data.Where(c => c.ContractId == ContractId).OrderBy(c => c.Date).ToList();
    }
}
