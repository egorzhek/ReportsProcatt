﻿// <auto-generated> This file has been auto generated by EF Core Power Tools. </auto-generated>
#nullable disable
using System;
using System.Collections.Generic;

namespace ReportsProcatt.ModelDB
{
    public partial class VAssetsContracts
    {
        public int InvestorId { get; set; }
        public int ContractId { get; set; }
        public DateTime Date { get; set; }
        public decimal? Usdrate { get; set; }
        public decimal? Eurorate { get; set; }
        public decimal? ValueRur { get; set; }
        public decimal? ValueUsd { get; set; }
        public decimal? ValueEuro { get; set; }
        public decimal? DailyIncrementRur { get; set; }
        public decimal? DailyIncrementUsd { get; set; }
        public decimal? DailyIncrementEuro { get; set; }
        public decimal? DailyDecrementRur { get; set; }
        public decimal? DailyDecrementUsd { get; set; }
        public decimal? DailyDecrementEuro { get; set; }
        public decimal? InputDividentsRur { get; set; }
        public decimal? InputDividentsUsd { get; set; }
        public decimal? InputDividentsEuro { get; set; }
        public decimal? InputCouponsRur { get; set; }
        public decimal? InputCouponsUsd { get; set; }
        public decimal? InputCouponsEuro { get; set; }
        public decimal? InputValueRur { get; set; }
        public decimal? InputValueUsd { get; set; }
        public decimal? InputValueEuro { get; set; }
        public decimal? OutputValueRur { get; set; }
        public decimal? OutputValueUsd { get; set; }
        public decimal? OutputValueEuro { get; set; }
        public bool? IsArchive { get; set; }
    }
}