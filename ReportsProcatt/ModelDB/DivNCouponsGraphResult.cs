﻿// <auto-generated> This file has been auto generated by EF Core Power Tools. </auto-generated>
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace ReportsProcatt.ModelDB
{
    public partial class DivNCouponsGraphResult
    {
        public int ContractId { get; set; }
        public DateTime? Date { get; set; }
        public decimal? Dividends { get; set; }
        public decimal? Coupons { get; set; }
        public string Valuta { get; set; }
    }
}
