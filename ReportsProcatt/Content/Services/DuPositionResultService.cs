using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;


namespace ReportsProcatt.Content.Services
{
    public class DuPositionResultService
    {
        private List<DuPositionsResult> _data;
        public DuPositionResultService(DuPositionServiceParams vParams)
        {
            _data = RepositoryDB.GetDuPosition(vParams);
        }
        public List<DuPositionsResult> Totals => _data.OrderBy(c => c.In_Date).ToList();

        public static List<DuPositionsResult> GetPositions(DuServiceParams vParams, DuPositionAssetTableName vTableTypeName, DuPositionType vPositionType)
        {
            DuPositionServiceParams p = new DuPositionServiceParams
            {
                ContractId = vParams.ContractId,
                CurrencyCode = vParams.CurrencyCode,
                DateFrom = vParams.DateFrom,
                DateTo = vParams.DateTo,
                InvestorId = vParams.InvestorId,
                PositionType = vPositionType,
                TableTypeName = vTableTypeName
            };

            return new DuPositionResultService(p).Totals;
        }
    }
}
