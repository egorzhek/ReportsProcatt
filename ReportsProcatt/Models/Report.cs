using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class Report
    {
        public DateTime Dfrom { get; set; }
        public DateTime Dto { get; set; }
        public string ReportCurrency { get; set; }
        public string ReportCurrencyChar { get; set; }
        public string rootStr { get; set; }
        public Headers MainHeader { get; set; }
        public List<DiagramElement> DiagramElements { get; set; }
        public DataTable PIFsTotals { get; set; }
        public DataTable DUsTotals { get; set; }
        public DataTable AllAssets { get; set; }
        public DataTable DivsNCoupons { get; set; }
        public DataTable DivsNCouponsDetails { get; set; }
        public CircleDiagram Assets { get; set; }
        public CircleDiagram Instruments { get; set; }
        public CircleDiagram Currency { get; set; }
        public List<PIF> PIFs { get; set; }
        public List<DU> DUs { get; set; }
        public class Headers
        {
            public string TotalSum { get; set; }
            public string ProfitSum { get; set; }
            public string Return { get; set; }
        }
        public class DiagramElement
        {
            public string Code { get; set; }
            public string Name { get; set; }
            public string Value { get; set; }
        }
        public class CircleDiagram { }
        public class PIF
        {

        }
        public class DU { }
    }
}
