using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;
using System.IO;

using FastReport.Utils;
using FastReport;
using FastReport.Export.Html;
using FastReport.Export.PdfSimple;

using Microsoft.AspNetCore.Hosting;

using System.Xml;

using Newtonsoft.Json.Linq;

namespace ReportsProcatt.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class SecondReport : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        public SecondReport(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpGet]
        public IActionResult Get()
        {
            string connectionString = String.Empty;

            try
            {
                string ReportPath = Environment.GetEnvironmentVariable("ReportPath");
                connectionString = Program.GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));

                Report report = new Report();
                report.Load(Path.Combine(ReportPath, "SecondReport.frx"));

                using (SqlConnection connection =
                new SqlConnection(connectionString))
                {
                    string queryString = "select * from FirstReport";
                    SqlCommand command = new SqlCommand(queryString, connection);
                    //command.Parameters.AddWithValue("@pricePoint", paramValue);

                    connection.Open();

                    using (SqlDataAdapter sda = new SqlDataAdapter(command))
                    {
                        using (DataSet vDataSet = new DataSet())
                        {
                            // это датасет из БД
                            sda.Fill(vDataSet);

                            vDataSet.Tables[0].TableName = "Employees";

                            report.RegisterData(vDataSet, "NorthWind");
                        }
                    }
                }

                report.Prepare();

                using (PDFSimpleExport pdfExport = new PDFSimpleExport())
                {
                    using (MemoryStream stream = new MemoryStream())
                    {
                        pdfExport.Export(report, stream);
                        stream.Flush();

                        // Тип файла - content-type
                        string file_type = "application/pdf";
                        // Имя файла - необязательно
                        string file_name = "Employees.pdf";

                        return File(stream.ToArray(), file_type, file_name);
                    }
                }
            }
            catch (Exception exception)
            {
                var messages = new List<string>();
                do
                {
                    messages.Add(exception.Message);
                    exception = exception.InnerException;
                }
                while (exception != null);
                var message = string.Join(" - ", messages);

                var stream = new MemoryStream();
                var writer = new StreamWriter(stream);
                //writer.Write(ex.Message + " - " + rows);
                writer.Write(message);
                writer.Flush();
                stream.Position = 0;
                return File(stream, "application/json");
            }
        }
    }
}