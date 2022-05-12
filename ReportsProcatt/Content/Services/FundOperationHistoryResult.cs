using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;


namespace ReportsProcatt.Content.Services
{
    public class FundOperationHistoryService
    {
        private List<FundOperationHistoryResult> _data;
        public FundOperationHistoryService(FundServiceParams vParams)
        {
            _data = RepositoryDB.GetFundOperationHistory(vParams);
        }
        public List<FundOperationHistoryResult> Operations => _data.Where(c => c.Amount != 0).OrderBy(c => c.W_Date).ToList();
    }
}
