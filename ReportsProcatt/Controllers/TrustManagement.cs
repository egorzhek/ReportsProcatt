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
using System.Drawing;


namespace ReportsProcatt.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TrustManagement : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        public TrustManagement(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpGet]
        public IActionResult Get(
            [FromQuery] string InvestorId,
            [FromQuery] string ContractId,
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
                report.Load(Path.Combine(ReportPath, "TrustManagement.frx"));

                System.Drawing.Bitmap image1, image2;

                using (SqlConnection connection =
                new SqlConnection(connectionString))
                {


                    connection.Open();

                    string queryString1 = System.IO.File.ReadAllText(Path.Combine(ReportPath, "TrustManagement.sql"));


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


                    command1.Parameters.AddWithValue("@ContractIdSharp", ContractId);
                    command1.Parameters.AddWithValue("@InvestorIdSharp", InvestorId);
                    

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

                            
                            vDataSet.Tables[3].TableName = "Fourth";
                            report.RegisterData(vDataSet.Tables[3], "Fourth");

                            vDataSet.Tables[5].TableName = "Fifth";
                            report.RegisterData(vDataSet.Tables[5], "Fifth");

                            vDataSet.Tables[6].TableName = "Sixth";
                            report.RegisterData(vDataSet.Tables[6], "Sixth");


                            vDataSet.Tables[7].TableName = "tree1";
                            report.RegisterData(vDataSet.Tables[7], "tree1");

                            vDataSet.Tables[8].TableName = "tree2";
                            report.RegisterData(vDataSet.Tables[8], "tree2");

                            vDataSet.Tables[9].TableName = "tree3";
                            report.RegisterData(vDataSet.Tables[9], "tree3");

                            vDataSet.Tables[10].TableName = "tree4";
                            report.RegisterData(vDataSet.Tables[10], "tree4");


                            // формирование графика
                            int pointCount = vDataSet.Tables[2].Rows.Count;

                            double[] values = new double[pointCount];
                            DateTime[] dates = new DateTime[pointCount];

                            for (var ii = 0; ii < values.Length; ii++)
                            {
                                values[ii] = Convert.ToDouble(vDataSet.Tables[2].Rows[ii]["RATE"]);
                                dates[ii] = Convert.ToDateTime(vDataSet.Tables[2].Rows[ii]["Date"]);
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









                            var plt2 = new ScottPlot.Plot(800, 400);

                            int pointCount2 = vDataSet.Tables[4].Rows.Count;

                            // data
                            double[] valuesA = new double[pointCount2];
                            double[] valuesB = new double[pointCount2];
                            DateTime[] dates2 = new DateTime[pointCount2];

                            for (var ii = 0; ii < valuesA.Length; ii++)
                            {
                                valuesA[ii] = Convert.ToDouble(vDataSet.Tables[4].Rows[ii]["Dividends"]);
                                valuesB[ii] = Convert.ToDouble(vDataSet.Tables[4].Rows[ii]["Coupons"]);
                                dates2[ii]  = Convert.ToDateTime(vDataSet.Tables[4].Rows[ii]["Date"]);
                            }


                            double[] xs2 = dates2.Select(x => x.ToOADate()).ToArray();

                            // две колонки рядом
                            var br1 = plt2.AddBar(valuesA, xs2);
                            br1.BarWidth = br1.BarWidth / 4;
                            br1.PositionOffset = -br1.BarWidth/2;
                            br1.FillColor = ColorTranslator.FromHtml(vDataSet.Tables[3].Rows[1]["Color"].ToString());

                            var br2 = plt2.AddBar(valuesB, xs2);
                            br2.BarWidth = br2.BarWidth / 4;
                            br2.PositionOffset = br2.BarWidth/2;
                            br2.FillColor = ColorTranslator.FromHtml(vDataSet.Tables[3].Rows[2]["Color"].ToString());


                            plt2.YAxis.TickLabelNotation(offset: false, multiplier: false);
                            plt2.YAxis.TickLabelFormat(".", false);

                            plt2.XAxis.DateTimeFormat(true);
                            plt2.XAxis.SetCulture(CultureInfo.GetCultureInfo("ru-RU"));

                            plt2.SetAxisLimits(yMin: 0);

                            image2 = plt2.Render();

                        }
                    }
                }

                var graph = report.FindObject("Picture1") as PictureObject;
                graph.Image = image1;

                var graph3 = report.FindObject("Picture3") as PictureObject;
                graph3.Image = image2;

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
                        string file_name = "TrustManagement.pdf";

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
