using Microsoft.Extensions.Caching.Memory;
using System;
using System.Collections.Concurrent;
using System.Threading;
using System.Threading.Tasks;

namespace ReportsProcatt.Content
{
    public class Cache<TItem>
    {
        private static MemoryCache _cache = new MemoryCache(new MemoryCacheOptions());
        private static ConcurrentDictionary<object, SemaphoreSlim> _locks = new ConcurrentDictionary<object, SemaphoreSlim>();

        public async Task<TItem> Get(object key, Func<Task<TItem>> createItem, MemoryCacheEntryOptions? options = null)
        {
            if (options == null)
                options = new MemoryCacheEntryOptions().SetSlidingExpiration(TimeSpan.FromMinutes(5));

            TItem cacheEntry;
            
            if (!_cache.TryGetValue(key, out cacheEntry)) // Ищем ключ в кэше.
            {
                SemaphoreSlim mylock = _locks.GetOrAdd(key, k => new SemaphoreSlim(1, 1));

                await mylock.WaitAsync();
                try
                {
                    if (!_cache.TryGetValue(key, out cacheEntry))
                    { 
                        cacheEntry = await createItem();

                        _cache.Set(key, cacheEntry, options);
                    }
                }
                finally
                {
                    mylock.Release();
                }
            }
            return cacheEntry;
        }
    }
}
