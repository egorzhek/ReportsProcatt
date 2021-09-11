using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class PIF
    {
        public string Name { get; set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public Headers Headers { get; set; }
        public DateTime Dfrom { get; set; }
        public DateTime Dto { get; set; }
        public CurrencyClass Currency { get; set; }
        public Dictionary<string, string> Diagram { get; set; }
        public TableView AccountDetails { get; set; }
        public CircleDiagram AssetsStruct { get; set; }
        public CircleDiagram FundStruct { get; set; }
        public TableView OperationsHistory { get; set; }
        #region Поля
        private SQLDataPIF _data;
        private DataSet _FundInfoDS => _data.DataSet_FundInfo;
        private DataSet _PifDS => _data.DataSet_PIF;
        private DataSet _Pif2DS => _data.DataSet_PIF2;
        #endregion
        public PIF(DateTime aDFrom, DateTime aDTo, CurrencyClass aCurrency, int ContractId, int InvestorId, SqlConnection connection)
        {
            _data = new SQLDataPIF(ContractId, InvestorId, aDFrom, aDTo, connection);
            Dfrom = aDFrom;
            Dto = aDTo;
            Currency = aCurrency;
        }

    }
}
