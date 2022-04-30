using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ReportsProcatt.Content.Services
{
    public class DivNCouponsChartDiagramsService
    {
        private List<DivNCouponsGraphResult> _data;
        private DivNCouponsGraphServiceParams _params;
        public DivNCouponsChartDiagramsService(DivNCouponsGraphServiceParams vParams)
        {
            _data = RepositoryDB.GetDivNCouponsGraph(vParams);
            _params = vParams;
        }
        public List<DivNCouponsGraphResult> DivsNCouponsChartTotals => _data
            .GroupBy(l => l.Date)
            .Select(c => new DivNCouponsGraphResult
            {
                ContractId = -1,
                Coupons = c.Sum(c => c.Coupons),
                Dividends = c.Sum(c => c.Dividends),
                Date = c.First().Date,
                Valuta = c.First().Valuta
            }).OrderBy(c => c.Date).ToList();
        public List<DivNCouponsGraphResult> ContractDivsNCouponsChart(int ContractId) =>
            _data.Where(c => c.ContractId == ContractId).OrderBy(c => c.Date).ToList();
    }
}
