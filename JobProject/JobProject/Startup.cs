using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Hangfire;
using Hangfire.MemoryStorage;
using System.Net.Http;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using Newtonsoft.Json.Linq;
using System.IO;

namespace JobProject
{
    public class Startup
    {
        public void FromUrlToDatabase()
        {
            string responseString = String.Empty;
            string SettingsPath = String.Empty;
            string FileName = String.Empty;
            string SettingsStr = String.Empty;
            string connstr = String.Empty;
            string outurl = String.Empty;
            string sqlproc = String.Empty;
            string sqlparam = String.Empty;
            string backhour = String.Empty;

            // прочитать данные с файла
            try
            {
                SettingsPath = Environment.GetEnvironmentVariable("SettingsPath");
                FileName = Path.Combine(SettingsPath, "appsettings.json");


                SettingsStr = System.IO.File.ReadAllText(FileName);

                var parsed = JObject.Parse(SettingsStr);

                connstr = parsed.SelectToken("SqlConnect").Value<string>();
                outurl = parsed.SelectToken("OutUrl").Value<string>();
                sqlproc = parsed.SelectToken("SqlProc").Value<string>();
                sqlparam = parsed.SelectToken("SqlParam").Value<string>();
                backhour = parsed.SelectToken("BackHours").Value<string>();
            }
            catch (Exception e)
            {

            }



            try
            {
                // количество часов назад
                int bkh = int.Parse(backhour, NumberStyles.AllowLeadingSign);

                // временна€ точка
                DateTime localDate = DateTime.Now;
                DateTime TimePoint = localDate.AddHours(bkh);
                string TP = TimePoint.ToString("yyyy-MM-dd HH:mm:ss");

                // дополнение адресной строки
                outurl += TP;



                using (SqlConnection con = new SqlConnection(connstr))
                {
                    using (SqlCommand cmd = new SqlCommand(sqlproc, con))
                    {
                        con.Open();

                        // получение JSON
                        using (var client = new HttpClient())
                        {
                            var response = client.GetAsync(outurl).Result;

                            if (response.IsSuccessStatusCode)
                            {
                                var responseContent = response.Content;
                                responseString = responseContent.ReadAsStringAsync().Result;
                            }
                        }

                        // передача JSON в Ѕƒ
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add(sqlparam, SqlDbType.Text).Value = responseString;
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch(Exception e)
            {

            }
        }
        // This method gets called by the runtime. Use this method to add services to the container.
        // For more information on how to configure your application, visit https://go.microsoft.com/fwlink/?LinkID=398940
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddHangfire(config =>
                config.SetDataCompatibilityLevel(CompatibilityLevel.Version_170)
                .UseSimpleAssemblyNameTypeSerializer()
                .UseDefaultTypeSerializer()
                .UseMemoryStorage());

            services.AddHangfireServer();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(
            IApplicationBuilder app,
            IWebHostEnvironment env,
            IBackgroundJobClient backgroundJobClient)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapGet("/", async context =>
                {
                    await context.Response.WriteAsync("Job!");
                });
            });

            app.UseHangfireDashboard("/hangfire");


            string SettingsPath = Environment.GetEnvironmentVariable("SettingsPath");
            string FileName = Path.Combine(SettingsPath, "appsettings.json");
            string SettingsStr = System.IO.File.ReadAllText(FileName);

            var parsed = JObject.Parse(SettingsStr);
            string CronTemplate = parsed.SelectToken("CronTemplate").Value<string>();


            RecurringJob.AddOrUpdate(() => FromUrlToDatabase(), CronTemplate);
        }
    }
}
