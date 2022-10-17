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
using System.Drawing;

using Microsoft.AspNetCore.Hosting;

using System.Xml;

using Newtonsoft.Json.Linq;

namespace ReportsProcatt.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class Portfolio : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        public Portfolio(IWebHostEnvironment env)
        {
            _env = env;
        }

        [HttpGet]
        public IActionResult Get(
            [FromQuery] string Investor_Id,
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
                report.Load(Path.Combine(ReportPath, "Portfolio.frx"));

                decimal[] values;
                string[] labels;
                Color[] sliceColors;

                using (SqlConnection connection =
                new SqlConnection(connectionString))
                {
                    

                    connection.Open();


                    string activeString = @"
declare
	@Investor_Id int = " + Investor_Id + @",
	@BeginDate Date = CONVERT(Date, '" + DateFrom + @"', 103),
	@BeginAssetsValue numeric(28, 7),
	@EndDate Date = CONVERT(Date, '" + DateTo + @"', 103),
	@EndAssetsValue numeric(28, 7);

select top 1
	@BeginAssetsValue = AssetsValue
from [CacheDB].[dbo].[InvestorDateAssets]
where Investor_Id = @Investor_Id
and [Date] <= @BeginDate
order by [Date] desc;

select top 1
	@EndAssetsValue = AssetsValue
from [CacheDB].[dbo].[InvestorDateAssets]
where Investor_Id = @Investor_Id
and [Date] <= @EndDate
order by [Date] desc;

select
	BeginAssetsValue = isnull(@BeginAssetsValue,0),
	EndAssetsValue = isnull(@EndAssetsValue,0);
";

                    string BeginAssetsValue, EndAssetsValue;

                    SqlCommand accommand = new SqlCommand(activeString, connection);
                    //command.Parameters.AddWithValue("@pricePoint", paramValue);

                    using (SqlDataAdapter sda = new SqlDataAdapter(accommand))
                    {
                        using (DataSet vDataSet = new DataSet())
                        {
                            sda.Fill(vDataSet);

                            BeginAssetsValue = vDataSet.Tables[0].Rows[0]["BeginAssetsValue"].ToString();
                            EndAssetsValue = vDataSet.Tables[0].Rows[0]["EndAssetsValue"].ToString();
                        }
                    }





                    string queryString = @"
select
[ActiveName] = 'Активы на " + DateTo + @"', [ActiveValue] = " + EndAssetsValue + @"
union all
select 'Пополнения', 85000.45
union all
select 'Выводы', 85000.45
union all
select 'Дивиденты', 85000.45
union all
select 'Купоны', 2120.11";
                    SqlCommand command = new SqlCommand(queryString, connection);
                    //command.Parameters.AddWithValue("@pricePoint", paramValue);

                    using (SqlDataAdapter sda = new SqlDataAdapter(command))
                    {
                        using (DataSet vDataSet = new DataSet())
                        {
                            // это датасет из БД
                            sda.Fill(vDataSet);

                            vDataSet.Tables[0].TableName = "Employees";


                            report.RegisterData(vDataSet.Tables[0], "Employees");
                            
                        }
                    }

                    string queryString2 = @"
select [ActiveName] = 'Акции', [ActiveValue] = 50.00
union all
select 'Облигации', 20.00
union all
select 'Валюта', 20.00
union all
select 'Фонды', 10.00";

                    SqlCommand command2 = new SqlCommand(queryString2, connection);
                    using (SqlDataAdapter sda2 = new SqlDataAdapter(command2))
                    {
                        using (DataSet vDataSet2 = new DataSet())
                        {
                            // это датасет из БД
                            sda2.Fill(vDataSet2);

                            vDataSet2.Tables[0].TableName = "Seconddata";

                            

                            values = vDataSet2.Tables[0].AsEnumerable().Select(s => s.Field<decimal>("ActiveValue")).ToArray<decimal>();
                            labels = vDataSet2.Tables[0].AsEnumerable().Select(s => s.Field<string>("ActiveName")).ToArray<string>();


                            // формирование графика для определения массива цветов
                            var plt0 = new ScottPlot.Plot(600, 400);

                            // to double[]
                            var ary0 = new double[values.Length];
                            for (var ii = 0; ii < values.Length; ii++)
                            {
                                ary0[ii] = Convert.ToDouble(values[ii]);
                            }


                            var pie0 = plt0.AddPie(ary0);
                            pie0.SliceLabels = labels;
                            pie0.ShowPercentages = true;
                            //pie.ShowValues = true;
                            pie0.ShowLabels = true;


                            pie0.DonutSize = .45;
                            pie0.OutlineSize = 2;

                            //plt.Legend();
                            var image10 = plt0.Render();

                            vDataSet2.Tables[0].Columns.Add("Color", typeof(String));
                            var ddd = pie0.SliceFillColors;

                            sliceColors = new Color[vDataSet2.Tables[0].Rows.Count];

                            for (int i = 0; i < vDataSet2.Tables[0].Rows.Count; i++)
                            {
                                vDataSet2.Tables[0].Rows[i]["Color"] = ddd[i].Name;
                                sliceColors[i] = ColorTranslator.FromHtml("#" + ddd[i].Name);
                            }

                            report.RegisterData(vDataSet2.Tables[0], "Seconddata");
                        }
                    }


                    string queryString3 = @"
select
[InvestorName] = 'Дмитрий Иванович - " + Investor_Id + @"',
[ActiveValue] = 50.00,
[BeginActive] = 'Активы на " + DateFrom + @"',
[BeginActiveVal] = " + BeginAssetsValue + @",
[ProfitPeriod] = 'Доход за период " + DateFrom + @" - " + DateTo + @"',
[ProfitPeriodVal] = 14885.67,
[ProfitProcent] = 12.33
";

                    SqlCommand command3 = new SqlCommand(queryString3, connection);
                    using (SqlDataAdapter sda2 = new SqlDataAdapter(command3))
                    {
                        using (DataSet vDataSet3 = new DataSet())
                        {
                            // это датасет из БД
                            sda2.Fill(vDataSet3);

                            vDataSet3.Tables[0].TableName = "Thirddata";

                            report.RegisterData(vDataSet3.Tables[0], "Thirddata");
                        }
                    }

                }

                // формирование графика
                var plt = new ScottPlot.Plot(600, 400);

                // to double[]
                var ary = new double[values.Length];
                for (var ii = 0; ii < values.Length; ii++)
                {
                    ary[ii] = Convert.ToDouble(values[ii]);
                }


                var pie = plt.AddPie(ary);
                //pie.SliceLabels = labels;
                //pie.ShowPercentages = true;
                //pie.ShowValues = true;
                pie.SliceFillColors = sliceColors;
                //pie.ShowLabels = true;
                //pie.CenterFont.Color = color1;
                pie.DonutLabel = @"100%
4 актива";


                pie.DonutSize = .8;
                pie.OutlineSize = 2;

                //plt.Legend();
                var image1 = plt.Render();


                // передача графика в картинку
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
                        string file_name = "Employees.pdf";

                        return File(stream.ToArray(), file_type, file_name);
                    }
                }

                // Creating the HTML export
                /*
                using (HTMLExport html = new HTMLExport())
                {
                     using (MemoryStream stream = new MemoryStream())
                     {
                           report.Export(html, stream);

                           // Тип файла - content-type
                           string file_type = "application/octet-stream";
                           // Имя файла - необязательно
                           string file_name = "Test.html";

                           return File(stream.ToArray(), file_type, file_name);
                     }
                }
                */
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