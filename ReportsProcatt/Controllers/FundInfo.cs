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
using System.Globalization;


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
            [FromQuery] string InvestorId,
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

                System.Drawing.Bitmap image1;

                using (SqlConnection connection =
                new SqlConnection(connectionString))
                {


                    connection.Open();

                    string queryString1 = System.IO.File.ReadAllText(Path.Combine(ReportPath, "FundInfo.sql"));


                    SqlCommand command1 = new SqlCommand(queryString1, connection);
                    command1.CommandType = CommandType.Text;

                    if (DateTo == null)
                    {
                        command1.Parameters.AddWithValue("@DateToSharp", DBNull.Value);
                    }
                    else
                    {
                        command1.Parameters.AddWithValue("@DateToSharp", DateTo);
                    }

                    if (DateFrom == null)
                    {
                        command1.Parameters.AddWithValue("@DateFromSharp", DBNull.Value);
                    }
                    else
                    {
                        command1.Parameters.AddWithValue("@DateFromSharp", DateFrom);
                    }


                    command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                    command1.Parameters.AddWithValue("@FundIdSharp", FundId);

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

                            vDataSet.Tables[1].TableName = "Second";
                            report.RegisterData(vDataSet.Tables[1], "Second");

                            vDataSet.Tables[2].TableName = "Third";
                            report.RegisterData(vDataSet.Tables[2], "Third");





                            // формирование графика
                            int pointCount = vDataSet.Tables[3].Rows.Count;

                            double[] values = new double[pointCount];
                            DateTime[] dates = new DateTime[pointCount];

                            for (var ii = 0; ii < values.Length; ii++)
                            {
                                values[ii] = Convert.ToDouble(vDataSet.Tables[3].Rows[ii]["RATE"]);
                                dates[ii] = Convert.ToDateTime(vDataSet.Tables[3].Rows[ii]["Date"]);
                            }

                            double[] xs = dates.Select(x => x.ToOADate()).ToArray();

                            var plt = new ScottPlot.Plot(600, 400);
                            plt.AddScatter(xs, values);

                            plt.YAxis.TickLabelNotation(offset: false, multiplier: false);
                            plt.YAxis.TickLabelFormat(".", false);
                            
                            plt.XAxis.DateTimeFormat(true);
                            plt.XAxis.SetCulture(CultureInfo.GetCultureInfo("ru-RU"));

                            plt.Title("График стоимости");
                            image1 = plt.Render();
                        }
                    }
                }

                var graph = report.FindObject("Picture1") as PictureObject;
                graph.Image = image1;

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
