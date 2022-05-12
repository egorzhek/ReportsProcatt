using ReportsProcatt.ModelDB;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Content
{
    public class RepositoryDB
    {
        public static List<ContractsDataSumResult> GetContractsDataSum(MainServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<ContractsDataSumResult>>();

                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.ContractsDataSum(vParams.InvestorId, vParams.CurrencyCode.ToString(), vParams.DateFrom, vParams.DateTo).ToList())).Result;
            }
        }
        public static List<CircleDiagramsResult> GetCircleDiagramsResult(CircleDiaramsServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<CircleDiagramsResult>>();
                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.CircleDiagrams(vParams.InvestorId, vParams.CurrencyCode.ToString(), vParams.DateTo).ToList())).Result;
            }
        }
        public static List<DuPositionGrouByElementResult> GetDuPositionGrouByElement(DuPositionGrouByElementServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<DuPositionGrouByElementResult>>();
                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.DuPositionGrouByElement(vParams.InvestorId,vParams.ContractId,vParams.CurrencyCode.ToString(),vParams.DateTo).ToList())).Result;
            }
        }
        public static List<DuPositionsResult> GetDuPosition(DuPositionServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var query = _db.DuPositions(vParams.InvestorId,vParams.ContractId,vParams.DateFrom,vParams.DateTo,vParams.CurrencyCode.ToString())
                               .Where(x => x.IsActive == (vParams.PositionType == DuPositionType.Current));

                switch (vParams.TableTypeName)
                {
                    case DuPositionAssetTableName.Shares:
                        query = query.Where(x => x.CategoryId == 1);
                        break;
                    case DuPositionAssetTableName.Derivatives:
                        query = query.Where(x => x.CategoryId == 6);
                        break;
                    case DuPositionAssetTableName.Bonds:
                        query = query.Where(x => x.CategoryId == 2);
                        break;
                    case DuPositionAssetTableName.Bills:
                        query = query.Where(x => x.CategoryId == 3);
                        break;
                    case DuPositionAssetTableName.Fund:
                        query = query.Where(x => x.CategoryId == 5);
                        break;
                    case DuPositionAssetTableName.Cash:
                        query = query.Where(x => x.CategoryId == 4);
                        break;
                    case DuPositionAssetTableName.All:
                        break;
                    default:
                        throw new Exception("DuPositionAssetTableName unknown type");
                }

                var _cache = new Cache<List<DuPositionsResult>>();
                return _cache.Get(vParams, async () => await Task.Run(() =>
                        query.Select(x => x).ToList())).Result;
            }
        }

        public static List<DuOperationHistoryResult> GetDuOperationHistory(DuServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<DuOperationHistoryResult>>();
                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.DuOperationHistory(vParams.InvestorId, vParams.ContractId, vParams.CurrencyCode.ToString(), vParams.DateFrom, vParams.DateTo)
                           .ToList())).Result;
            }
        }

        public static List<FundOperationHistoryResult> GetFundOperationHistory(FundServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<FundOperationHistoryResult>>();
                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.FundOperationHistory(vParams.InvestorId, vParams.FundId, vParams.CurrencyCode.ToString(), vParams.DateFrom, vParams.DateTo)
                           .ToList())).Result;
            }
        }

        public static List<DivNCouponsGraphResult> GetDivNCouponsGraph(DivNCouponsGraphServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<DivNCouponsGraphResult>>();
                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.DivNCouponsGraph(vParams.InvestorId, vParams.CurrencyCode.ToString(), vParams.DateFrom, vParams.DateTo).ToList())).Result;
            }
        }
        public static List<DivNCouponsDetailsResult> GetDivNCouponsDetails(DivNCouponsDetailsServiceParams vParams)
        {
            using (var _db = new CachedbContext())
            {
                var _cache = new Cache<List<DivNCouponsDetailsResult>>();

                return _cache.Get(vParams, async () => await Task.Run(() =>
                        _db.DivNCouponsDetails(vParams.InvestorId, vParams.CurrencyCode.ToString(), vParams.DateFrom, vParams.DateTo)
                           .ToList())).Result;
            }
        }
    }
}
