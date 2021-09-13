using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class PifDiagramColumns
    {
        public const string Begin = "В начале периода";
        public const string InVal = "Пополнения";
        public const string OutVal = "Выводы";
        public const string End = "В конце периода";
    }
    public class OperationsHistoryColumns
    {
        public const string Wdate = "Wdate";
        public const string Btype = "Btype";
        public const string Rate_rur = "Rate_rur";
        public const string Amount = "Amount";
        public const string Value_rur = "Value rur";
        public const string Fee_rur = "Fee_rur";
    }
}
