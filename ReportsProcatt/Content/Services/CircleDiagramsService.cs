using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;

namespace ReportsProcatt.Content.Services
{
    public class CircleDiagramsService
    {
        private List<CircleDiagramsResult> _data;
        public CircleDiagramsService(CircleDiaramsServiceParams vParams)
        {
            _data = RepositoryDB.GetCircleDiagramsResult(vParams);
        }
        public List<CircleDiagramsResult> TotalAssets => _data.Where(x => x.ISPIF == -1 && x.ContractId == -1 && x.GroupType == "AssetName").ToList();
        public List<CircleDiagramsResult> TotalCategory => _data.Where(x => x.ISPIF == -1 && x.ContractId == -1 && x.GroupType == "CategoryName").ToList();
        public List<CircleDiagramsResult> TotalCurrency => _data.Where(x => x.ISPIF == -1 && x.ContractId == -1 && x.GroupType == "CurrencyName").ToList();
        public List<CircleDiagramsResult> Assets(int ContractId) => 
            _data.Where(x => x.ISPIF == -1 && x.ContractId == -1 && x.GroupType == "AssetName" && x.ContractId == ContractId).ToList();
        public List<CircleDiagramsResult> Category(int ContractId) =>
            _data.Where(x => x.ISPIF == -1 && x.ContractId == -1 && x.GroupType == "CategoryName" && x.ContractId == ContractId).ToList();
        public List<CircleDiagramsResult> Currency(int ContractId) =>
            _data.Where(x => x.ISPIF == -1 && x.ContractId == -1 && x.GroupType == "CurrencyName" && x.ContractId == ContractId).ToList();

    }
}
