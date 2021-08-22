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
    public class InverstorFull : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        public InverstorFull(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpGet]
        public IActionResult Get(
            [FromQuery] string InvestorId,
            //[FromQuery] string ContractId,
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
                report.Load(Path.Combine(ReportPath, "InverstorFull.frx"));

                //System.Drawing.Bitmap image1, image2;

                decimal[] Thirdvalues;
                string[] Thirdlabels;
                Color[] ThirdsliceColors;

                using (SqlConnection connection =
                new SqlConnection(connectionString))
                {


                    connection.Open();

                    string queryString1 = System.IO.File.ReadAllText(Path.Combine(ReportPath, "InverstorFull.sql"));


                    SqlCommand command1 = new SqlCommand(queryString1, connection);
                    command1.CommandType = CommandType.Text;
                    command1.CommandTimeout = 600;

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





                            int ThirdrMax = Color.Aqua.R;
                            int ThirdrMin = Color.Purple.R;
                            int ThirdgMax = Color.Aqua.G;
                            int ThirdgMin = Color.Purple.G;
                            int ThirdbMax = Color.Aqua.B;
                            int ThirdbMin = Color.Purple.B;
                            int Thirdsize = vDataSet.Tables[2].Rows.Count;

                            ThirdsliceColors = new Color[Thirdsize];

                            
                            for (int i = 0; i < Thirdsize; i++)
                            {
                                var rAverage = ThirdrMin + (int)((ThirdrMax - ThirdrMin) * i / Thirdsize);
                                var gAverage = ThirdgMin + (int)((ThirdgMax - ThirdgMin) * i / Thirdsize);
                                var bAverage = ThirdbMin + (int)((ThirdbMax - ThirdbMin) * i / Thirdsize);
                                ThirdsliceColors[i] = Color.FromArgb(rAverage, gAverage, bAverage);
                            }




                            Thirdvalues = vDataSet.Tables[2].AsEnumerable().Select(s => s.Field<decimal>("CategoryVal")).ToArray<decimal>();
                            Thirdlabels = vDataSet.Tables[2].AsEnumerable().Select(s => s.Field<string>("CategoryName")).ToArray<string>();


                            vDataSet.Tables[2].Columns.Add("Color", typeof(String));

                            for (int i = 0; i < vDataSet.Tables[2].Rows.Count; i++)
                            {
                                vDataSet.Tables[2].Rows[i]["Color"] = ThirdsliceColors[i].Name;
                            }
                            


                            vDataSet.Tables[2].TableName = "Third";
                            report.RegisterData(vDataSet.Tables[2], "Third");

                            vDataSet.Tables[3].TableName = "Forth";
                            report.RegisterData(vDataSet.Tables[3], "Forth");
                        }
                    }
                }




                // формирование графика
                var Thirdplt = new ScottPlot.Plot(600, 400);

                // to double[]
                var ary = new double[Thirdvalues.Length];
                for (var ii = 0; ii < Thirdvalues.Length; ii++)
                {
                    ary[ii] = Convert.ToDouble(Thirdvalues[ii]);
                }


                var Thirdpie = Thirdplt.AddPie(ary);
                Thirdpie.SliceLabels = Thirdlabels;
                //pie.ShowPercentages = true;
                //pie.ShowValues = true;
                Thirdpie.SliceFillColors = ThirdsliceColors;
                //pie.ShowLabels = true;
                //pie.CenterFont.Color = color1;
                //Thirdpie.DonutLabel = @"100%4 актива";


                Thirdpie.DonutSize = .8;
                Thirdpie.OutlineSize = 2;

                //plt.Legend();
                var Thirdimage = Thirdplt.Render();


                // передача графика в картинку
                var ThirdPictureActive = report.FindObject("Picture3") as PictureObject;
                ThirdPictureActive.Image = Thirdimage;





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
                        string file_name = "InverstorFull.pdf";

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