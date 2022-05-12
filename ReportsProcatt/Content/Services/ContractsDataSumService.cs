using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ReportsProcatt.Content.Services
{
    public class ContractsDataSumService
    {
        private List<ContractsDataSumResult> _data;
        private MainServiceParams _params;
        public ContractsDataSumService(MainServiceParams vParams)
        {
            _data = RepositoryDB.GetContractsDataSum(vParams);
            _params = vParams;
        }
        public DateTime DateFrom => _params.DateFrom ?? (DateTime)_data.Where(c => c.DATE_OPEN != null).Min(c => c.DATE_OPEN);
        public DateTime DateTo => _params.DateTo ?? (DateTime)_data.Where(c => c.DATE_CLOSE != null && c.DATE_CLOSE < new DateTime(2070, 1, 1)).Max(c => c.DATE_CLOSE);
        public ContractsDataSumResult Totals => _data.FirstOrDefault(c => c.ISPIF == -1 && c.ContractId == -1);
        public ContractsDataSumResult PIFsTotals => _data.FirstOrDefault(c => c.ISPIF == 1 && c.ContractId == -1);
        public ContractsDataSumResult DUsTotals => _data.FirstOrDefault(c => c.ISPIF == 0 && c.ContractId == -1);
        public List<ContractsDataSumResult> PIFs => _data.Where(c => c.ISPIF == 1 && c.ContractId != -1).ToList();
        public List<ContractsDataSumResult> DUs => _data.Where(c => c.ISPIF == 0 && c.ContractId != -1).ToList();
        public ContractsDataSumResult PIF(int ContractId) => PIFs.FirstOrDefault(c => c.ContractId == ContractId);
        public ContractsDataSumResult DU(int ContractId) => DUs.FirstOrDefault(c => c.ContractId == ContractId);

    }
}
