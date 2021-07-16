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
    public class FundInfo : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        public FundInfo(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpGet]
        public IActionResult Get(
            [FromQuery] string FundId,
            [FromQuery] string DateFrom,
            [FromQuery] string DateTo
        )
        {
            string connectionString = String.Empty;

            try
            {
                string ReportPath = Environment.GetEnvironmentVariable("ReportPath");
                connectionString = Program.GetReportSqlConnection(Path.Combine(ReportPath, "appsettings.json"));

                Report report = new Report();
                report.Load(Path.Combine(ReportPath, "FundInfo.frx"));

                using (SqlConnection connection =
                new SqlConnection(connectionString))
                {


                    connection.Open();

                    string queryString1 =
"declare @ActionOn Nvarchar(50) = 'Активы на '; " +
"select [ActiveDateToName] = @ActionOn + @DateTo, [ActiveDateToValue] = 85000.45," +
 "[ProfitName] = 'Доход за период " + DateFrom + " - " + DateTo + "'," +
 "[ProfitValue] = 85000.45, ProfitProcentValue = 23.34";


                    SqlCommand command1 = new SqlCommand(queryString1, connection);
                    command1.CommandType = CommandType.Text;
                    command1.Parameters.AddWithValue("@DateTo", DateTo);
                    //command1.Parameters.Add("@DateTo", SqlDbType.NVarChar);
                    //command1.Parameters["@DateTo"].Value = DateTo;

                    using (SqlDataAdapter sda = new SqlDataAdapter(command1))
                    {
                        using (DataSet vDataSet = new DataSet())
                        {
                            // это датасет из БД
                            sda.Fill(vDataSet);

                            vDataSet.Tables[0].TableName = "First";

                            report.RegisterData(vDataSet.Tables[0], "First");
                        }
                    }




                    string queryString2 = @"
select
    [ActiveName] = 'Активы на " + DateFrom + @"', [ActiveValue] = 85000.45
union all
select 'Пополнения', 85000.45
union all
select 'Выводы', 2120.11";


                    SqlCommand command2 = new SqlCommand(queryString2, connection);
                    //command.Parameters.AddWithValue("@pricePoint", paramValue);

                    using (SqlDataAdapter sda = new SqlDataAdapter(command2))
                    {
                        using (DataSet vDataSet = new DataSet())
                        {
                            // это датасет из БД
                            sda.Fill(vDataSet);

                            vDataSet.Tables[0].TableName = "Second";

                            report.RegisterData(vDataSet.Tables[0], "Second");
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
                        string file_name = "FundInfo.pdf";

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
