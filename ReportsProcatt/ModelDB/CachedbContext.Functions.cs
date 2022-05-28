﻿// <auto-generated> This file has been auto generated by EF Core Power Tools. </auto-generated>
using Microsoft.EntityFrameworkCore;
using System;
using System.Data;
using System.Linq;
using ReportsProcatt.ModelDB;

namespace ReportsProcatt.ModelDB
{
    public partial class CachedbContext
    {

        [DbFunction("CircleDiagrams", "dbo")]
        public IQueryable<CircleDiagramsResult> CircleDiagrams(int? Investor_Id, string Currency, DateTime? Date)
        {
            return FromExpression(() => CircleDiagrams(Investor_Id, Currency, Date));
        }

        [DbFunction("ContractsData", "dbo")]
        public IQueryable<ContractsDataResult> ContractsData(int? Investor_Id, string Currency, DateTime? DateFrom, DateTime? DateTo)
        {
            return FromExpression(() => ContractsData(Investor_Id, Currency, DateFrom, DateTo));
        }

        [DbFunction("ContractsDataSum", "dbo")]
        public IQueryable<ContractsDataSumResult> ContractsDataSum(int? Investor_Id, string Currency, DateTime? DateFrom, DateTime? DateTo)
        {
            return FromExpression(() => ContractsDataSum(Investor_Id, Currency, DateFrom, DateTo));
        }

        [DbFunction("DivNCouponsDetails", "dbo")]
        public IQueryable<DivNCouponsDetailsResult> DivNCouponsDetails(int? InvestorId, string Currency, DateTime? DateFrom, DateTime? DateTo)
        {
            return FromExpression(() => DivNCouponsDetails(InvestorId, Currency, DateFrom, DateTo));
        }

        [DbFunction("DivNCouponsGraph", "dbo")]
        public IQueryable<DivNCouponsGraphResult> DivNCouponsGraph(int? InvestorId, string Currency, DateTime? DateFrom, DateTime? DateTo)
        {
            return FromExpression(() => DivNCouponsGraph(InvestorId, Currency, DateFrom, DateTo));
        }

        [DbFunction("DuOperationHistory", "dbo")]
        public IQueryable<DuOperationHistoryResult> DuOperationHistory(int? InvestorId, int? ContractId, string Currency, DateTime? DateFrom, DateTime? DateTo)
        {
            return FromExpression(() => DuOperationHistory(InvestorId, ContractId, Currency, DateFrom, DateTo));
        }

        [DbFunction("DuPositionGrouByElement", "dbo")]
        public IQueryable<DuPositionGrouByElementResult> DuPositionGrouByElement(int? Investor_Id, int? Contract_Id, string Currency, DateTime? DateTo)
        {
            return FromExpression(() => DuPositionGrouByElement(Investor_Id, Contract_Id, Currency, DateTo));
        }

        [DbFunction("DuPositions", "dbo")]
        public IQueryable<DuPositionsResult> DuPositions(int? Investor_Id, int? Contract_Id, DateTime? DateFrom, DateTime? DateTo, string Currency)
        {
            return FromExpression(() => DuPositions(Investor_Id, Contract_Id, DateFrom, DateTo, Currency));
        }

        [DbFunction("FundOperationHistory", "dbo")]
        public IQueryable<FundOperationHistoryResult> FundOperationHistory(int? InvestorId, int? FundId, string Currency, DateTime? DateFrom, DateTime? DateTo)
        {
            return FromExpression(() => FundOperationHistory(InvestorId, FundId, Currency, DateFrom, DateTo));
        }

        protected void OnModelCreatingGeneratedFunctions(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<CircleDiagramsResult>().HasNoKey();
            modelBuilder.Entity<ContractsDataResult>().HasNoKey();
            modelBuilder.Entity<ContractsDataSumResult>().HasNoKey();
            modelBuilder.Entity<DivNCouponsDetailsResult>().HasNoKey();
            modelBuilder.Entity<DivNCouponsGraphResult>().HasNoKey();
            modelBuilder.Entity<DuOperationHistoryResult>().HasNoKey();
            modelBuilder.Entity<DuPositionGrouByElementResult>().HasNoKey();
            modelBuilder.Entity<DuPositionsResult>().HasNoKey();
            modelBuilder.Entity<FundOperationHistoryResult>().HasNoKey();
        }
    }
}