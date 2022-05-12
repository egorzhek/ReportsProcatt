using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;
namespace ReportsProcatt.Content.Services
{
    public class DuPositionByGroupService
    {
        private List<DuPositionGrouByElementResult> _data;
        public DuPositionByGroupService(DuPositionGrouByElementServiceParams vParams)
        {
            _data = RepositoryDB.GetDuPositionGrouByElement(vParams);
        }
        public List<DuPositionGrouByElementResult> Totals => _data.OrderBy(c => c.FinRes).ToList();
        public List<DuPositionGrouByElementResult> ContractDetails(int Id) =>
            _data.Where(c => c.VALUE_ID == Id).OrderBy(c => c.FinRes).ToList();
    }
}
