using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using System;
using Newtonsoft.Json.Linq;
using Microsoft.EntityFrameworkCore;
using System.IO;

namespace ReportsProcatt
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}
namespace ReportsProcatt.ModelDB
{

    public partial class CachedbContext : DbContext
    {
        public static string GetReportSqlConnection(string FileName)
        {
            string connectionString = String.Empty;

            string SettingsStr = File.ReadAllText(FileName);

            var parsed = JObject.Parse(SettingsStr);

            string DataSource = parsed.SelectToken("SqlConnect.DataSource").Value<string>();
            string InitialCatalog = parsed.SelectToken("SqlConnect.InitialCatalog").Value<string>();
            string UserID = parsed.SelectToken("SqlConnect.UserID")?.Value<string>();
            string Password = parsed.SelectToken("SqlConnect.Password")?.Value<string>();

            connectionString += "Data Source=" + DataSource + ";";
            connectionString += "Initial Catalog=" + InitialCatalog + ";";

            if (UserID?.Length > 0)
            {
                connectionString += "User ID=" + UserID + ";";
                connectionString += "Password=" + Password + ";";
            }
            else
            {
                connectionString += "Integrated Security = true;";
            }

            return connectionString;
        }
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                var ReportPath = Environment.GetEnvironmentVariable("ReportPath");
                var connectionString = GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));
                optionsBuilder.UseSqlServer(connectionString);
            }
        }
    }
}