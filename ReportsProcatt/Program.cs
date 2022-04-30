using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using System.IO;
using Newtonsoft.Json.Linq;
using Microsoft.EntityFrameworkCore;

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

        public static string GetReportSqlConnection(string FileName)
        {
            string connectionString = String.Empty;

            string SettingsStr = System.IO.File.ReadAllText(FileName);

            var parsed = JObject.Parse(SettingsStr);

            string DataSource = parsed.SelectToken("SqlConnect.DataSource").Value<string>();
            string InitialCatalog = parsed.SelectToken("SqlConnect.InitialCatalog").Value<string>();
            string UserID = parsed.SelectToken("SqlConnect.UserID").Value<string>();
            string Password = parsed.SelectToken("SqlConnect.Password").Value<string>();

            connectionString += "Data Source=" + DataSource + ";";
            connectionString += "Initial Catalog=" + InitialCatalog + ";";

            if (UserID.Length > 0)
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
    }
}
namespace ReportsProcatt.ModelDB
{
    public partial class CachedbContext : DbContext
    {
        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
                optionsBuilder.UseSqlServer("Data Source=DESKTOP-5UV8RM5;Initial Catalog=CacheDB;Integrated Security=True");
            }
        }
    }
}