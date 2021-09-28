using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using ReportsProcatt.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Wkhtmltopdf.NetCore;

namespace ReportsProcatt.Controllers
{
    [Route("[controller]")]
    [ApiController]
    public class NewController : Controller
    {
        readonly IGeneratePdf _generatePdf;

        public NewController(IGeneratePdf generatePdf)
        {
            _generatePdf = generatePdf;
        }

        [HttpGet]
        [Route("Report")]
        public async Task<IActionResult> Report
        (
            [FromQuery] int? InvestorId,
            [FromQuery] DateTime? DateFrom,
            [FromQuery] DateTime? DateTo,
            [FromQuery] string Currency
        )
        {
            try
            {
                var data = new Report(InvestorId ?? 2149652, DateFrom, DateTo, Currency)
                {
                    rootStr = "/app/wwwroot"
                };

                return await _generatePdf.GetPdf("Views/New/Index.cshtml", data);
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
                writer.Write(message);
                writer.Flush();
                stream.Position = 0;
                return File(stream, "application/json");
            }
        }

        [HttpGet]
        [Route("Report_Win")]
        public async Task<IActionResult> Report_Win
        (
            [FromQuery] int? InvestorId,
            [FromQuery] DateTime? DateFrom,
            [FromQuery] DateTime? DateTo,
            [FromQuery] string Currency
        )
        {
            var data = new Report(InvestorId ?? 2149652, DateFrom, DateTo, Currency)
            {
                rootStr = "file:///c:/Users/Света/source/Ingos/ReportsProcatt/ReportsProcatt/wwwroot"
            };

            return await _generatePdf.GetPdf("Views/New/Index.cshtml", data);
        }

        [HttpGet]
        [Route("Test_Report")]
        public async Task<IActionResult> Test_Report()
        {
            return await _generatePdf.GetPdf("Views/New/Test.cshtml");
        }

        [HttpGet]
        [Route("Test")]
        public IActionResult Test()
        {
            return View("Test");
        }
        [HttpGet]
        [Route("Test2_Report")]
        public async Task<IActionResult> Test2_Report()
        {
            string rootStr = "file:///c:/Users/D/source/Ingos/ReportsProcatt/ReportsProcatt/wwwroot";
            return await _generatePdf.GetPdf("Views/New/Test2.cshtml", rootStr);
        }

        [HttpGet]
        [Route("Test2")]
        public IActionResult Test2()
        {
            return View("Test2","");
        }
        [HttpGet]
        public IActionResult Index
        (
            [FromQuery] int? InvestorId,
            [FromQuery] DateTime? DateFrom,
            [FromQuery] DateTime? DateTo,
            [FromQuery] string Currency
        )
        {
            return View(new Report(InvestorId, DateFrom, DateTo, Currency));
        }
        [HttpGet]
        [Route("Api")]
        public JsonResult Api
        (
            [FromQuery] int InvestorId,
            [FromQuery] DateTime? DateFrom,
            [FromQuery] DateTime? DateTo,
            [FromQuery] string Currency
        )
        {
            return Json(new Report(InvestorId, DateFrom, DateTo, Currency));
        }
    }
}
