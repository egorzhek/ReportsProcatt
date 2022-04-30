using System;
using System.Collections.Generic;

namespace ReportsProcatt.Content
{
    public class CurrentPosServiceParams
    {
        public int InvestorId { get; set; }
        public DateTime? DateTo { get; set; }
        public Currency CurrencyCode { get; set; }
    }
    public class MainServiceParams : CurrentPosServiceParams
    {
        public DateTime? DateFrom { get; set; }

        public override bool Equals(object obj)
        {
            return obj is MainServiceParams @params &&
                   InvestorId == @params.InvestorId &&
                   DateTo == @params.DateTo &&
                   CurrencyCode == @params.CurrencyCode &&
                   DateFrom == @params.DateFrom;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(InvestorId, DateTo, CurrencyCode, DateFrom);
        }
    }
    public class DivNCouponsGraphServiceParams : MainServiceParams
    {
        public override bool Equals(object obj)
        {
            return obj is DivNCouponsGraphServiceParams @params &&
                   base.Equals(obj) &&
                   InvestorId == @params.InvestorId &&
                   DateTo == @params.DateTo &&
                   CurrencyCode == @params.CurrencyCode &&
                   DateFrom == @params.DateFrom;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(base.GetHashCode(), InvestorId, DateTo, CurrencyCode, DateFrom);
        }
    }
    public class DivNCouponsDetailsServiceParams : MainServiceParams
    {
        public override bool Equals(object obj)
        {
            return obj is DivNCouponsDetailsServiceParams @params &&
                   InvestorId == @params.InvestorId &&
                   DateTo == @params.DateTo &&
                   DateFrom == @params.DateFrom &&
                   CurrencyCode == @params.CurrencyCode;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(InvestorId, DateTo, DateFrom, CurrencyCode);
        }
    }
    public class CircleDiaramsServiceParams : CurrentPosServiceParams
    {
        public override bool Equals(object obj)
        {
            return obj is CircleDiaramsServiceParams diarams &&
                   InvestorId == diarams.InvestorId &&
                   DateTo == diarams.DateTo &&
                   CurrencyCode == diarams.CurrencyCode;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(InvestorId, DateTo, CurrencyCode);
        }
    }

    public class DuServiceParams : MainServiceParams
    {
        public int ContractId { get; set; }
        public override bool Equals(object obj)
        {
            return obj is DuServiceParams @params &&
                   base.Equals(obj) &&
                   InvestorId == @params.InvestorId &&
                   DateTo == @params.DateTo &&
                   CurrencyCode == @params.CurrencyCode &&
                   DateFrom == @params.DateFrom &&
                   ContractId == @params.ContractId;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(base.GetHashCode(), InvestorId, DateTo, CurrencyCode, DateFrom, ContractId);
        }
    }
    public class FundServiceParams : MainServiceParams
    {
        public int FundId { get; set; }
        public override bool Equals(object obj)
        {
            return obj is FundServiceParams @params &&
                   base.Equals(obj) &&
                   InvestorId == @params.InvestorId &&
                   DateTo == @params.DateTo &&
                   CurrencyCode == @params.CurrencyCode &&
                   DateFrom == @params.DateFrom &&
                   FundId == @params.FundId;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(base.GetHashCode(), InvestorId, DateTo, CurrencyCode, DateFrom, FundId);
        }
    }
    public class DuPositionGrouByElementServiceParams : CurrentPosServiceParams
    {
        public int ContractId { get; set; }
        public override bool Equals(object obj)
        {
            return obj is DuPositionGrouByElementServiceParams element &&
                   InvestorId == element.InvestorId &&
                   ContractId == element.ContractId &&
                   DateTo == element.DateTo &&
                   CurrencyCode == element.CurrencyCode;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(InvestorId, ContractId, DateTo, CurrencyCode);
        }
    }

    public class DuPositionServiceParams : DuServiceParams
    {
        public DuPositionAssetTableName TableTypeName { get; set; }
        public DuPositionType PositionType { get; set; }
        public override bool Equals(object obj)
        {
            return obj is DuPositionServiceParams @params &&
                   base.Equals(obj) &&
                   InvestorId == @params.InvestorId &&
                   DateFrom == @params.DateFrom &&
                   DateTo == @params.DateTo &&
                   CurrencyCode == @params.CurrencyCode &&
                   ContractId == @params.ContractId &&
                   TableTypeName == @params.TableTypeName &&
                   PositionType == @params.PositionType;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(base.GetHashCode(), InvestorId, DateFrom, DateTo, CurrencyCode, ContractId, TableTypeName, PositionType);
        }
    }
}