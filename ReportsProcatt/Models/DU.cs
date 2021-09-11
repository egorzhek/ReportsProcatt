using ReportsProcatt.Content;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class DU
    {
        public string Name { get; set; }
        public string Period => $"{Dfrom.ToString("dd.MM.yyyy")} - {Dto.ToString("dd.MM.yyyy")}";
        public DateTime Dfrom { get; set; }
        public DateTime Dto { get; set; }
        public CurrencyClass Currency { get; set; }
        public Headers Headers { get; set; }
        public Dictionary<string, string> Diagram { get; set; }

        //Дивиденды и купоны
        public string Totals { get; set; }
        public string Dividends { get; set; }
        public string Coupons { get; set; }
        public ChartClass DividedtsCouponsChart { get; set; }

        //Детализация купонов и дивидендов
        public TableView DividedtsCoupons { get; set; }

        //Информация по договору
        public string ContractNumber { get; set; }
        public string OpenDate { get; set; }
        public string ManagementFee { get; set; }
        public string SuccessFee { get; set; }

        //Текущие позиции по валютам

        //Текущие позиции в периоде
        public TableView CurrentShares { get; set; }
        public TableView CurrentBonds { get; set; }
        public TableView CurrentBills { get; set; }
        public TableView CurrentCash { get; set; }
        public TableView CurrentFunds { get; set; }
        public TableView CurrentDerivatives { get; set; }

        //Закрытые позиции в периоде
        public TableView ClosedShares { get; set; }
        public TableView ClosedBonds { get; set; }
        public TableView ClosedBills { get; set; }
        public TableView ClosedCash { get; set; }
        public TableView ClosedFunds { get; set; }
        public TableView ClosedDerivatives { get; set; }

        //Состав договора
        public CircleDiagram AssetsStruct { get; set; }
        public CircleDiagram FundStruct { get; set; }

        //История операций
        public TableView OperationsHistory { get; set; }
        #region Поля
        private SQLDataDU _data;
        private DataSet _TrustManagementDS => _data.DataSet_TrustManagement;
        private DataSet _DuDS => _data.DataSet_DU;
        private DataSet _Du2DS => _data.DataSet_DU2;
        #endregion
        public DU(DateTime aDFrom, DateTime aDTo, CurrencyClass aCurrency, int ContractId, int InvestorId, SqlConnection connection)
        {
            _data = new SQLDataDU(ContractId, InvestorId, aDFrom, aDTo, connection);
            Dfrom = aDFrom;
            Dto = aDTo;
            Currency = aCurrency;
        }
    }
}
