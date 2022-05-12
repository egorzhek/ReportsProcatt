using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;
namespace ReportsProcatt.Content.Services
{
    public class DuOperationHistoryService
    {
        private List<DuOperationHistoryResult> _data;
        public DuOperationHistoryService(DuServiceParams vParams)
        {
            _data = RepositoryDB.GetDuOperationHistory(vParams);
        }
        public List<DuOperationHistoryResult> Operations => _data.OrderBy(c => c.Date).ToList();
    }
}
