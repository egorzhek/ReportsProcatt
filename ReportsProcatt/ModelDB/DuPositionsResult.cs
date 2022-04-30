﻿// <auto-generated> This file has been auto generated by EF Core Power Tools. </auto-generated>
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;

namespace ReportsProcatt.ModelDB
{
    public partial class DuPositionsResult
    {
        public int InvestorId { get; set; }
        public int ContractId { get; set; }
        public int ShareId { get; set; }
        public DateTime Fifo_Date { get; set; }
        public long Id { get; set; }
        public string ISIN { get; set; }
        public int? Class { get; set; }
        public int? CUR_ID { get; set; }
        public DateTime? Oblig_Date_end { get; set; }
        public DateTime? Oferta_Date { get; set; }
        public string Oferta_Type { get; set; }
        public bool? IsActive { get; set; }
        public int? In_Wir { get; set; }
        public DateTime? In_Date { get; set; }
        public long? Ic_NameId { get; set; }
        public int? Il_Num { get; set; }
        public int? In_Dol { get; set; }
        public string Ir_Trans { get; set; }
        public decimal? Amount { get; set; }
        public decimal? In_Summa { get; set; }
        public decimal? In_Eq { get; set; }
        public decimal? In_Comm { get; set; }
        public decimal? In_Price { get; set; }
        public decimal? In_Price_eq { get; set; }
        public decimal? IN_PRICE_UKD { get; set; }
        public decimal? Today_PRICE { get; set; }
        public decimal? Value_NOM { get; set; }
        public decimal? Dividends { get; set; }
        public decimal? UKD { get; set; }
        public decimal? NKD { get; set; }
        public decimal? Amortizations { get; set; }
        public decimal? Coupons { get; set; }
        public int? Out_Wir { get; set; }
        public DateTime? Out_Date { get; set; }
        public int? Od_Id { get; set; }
        public long? Oc_NameId { get; set; }
        public int? Ol_Num { get; set; }
        public int? Out_Dol { get; set; }
        public decimal? OutPrice { get; set; }
        public decimal? Out_Summa { get; set; }
        public decimal? Out_Eq { get; set; }
        public DateTime? RecordDate { get; set; }
        public bool IsArchive { get; set; }
        public string Currency { get; set; }
        public long? InstrumentId { get; set; }
        public string Investment { get; set; }
        public int CategoryId { get; set; }
        public decimal? FinRes { get; set; }
        public decimal? FinResProcent { get; set; }
    }
}
