using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using ReportsProcatt.Models;
using System;
using System.Collections.Generic;
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
        public async Task<IActionResult> Report()
        {
            var data = new Report
            {
                rootStr = "/app/wwwroot"
            };

            return await _generatePdf.GetPdf("Views/New/Index.cshtml", data);
        }

        [HttpGet]
        [Route("Report_Win")]
        public async Task<IActionResult> Report_Win()
        {
            var data = new Report
            {
                rootStr = "file:///c:/Users/D/source/Ingos/ReportsProcatt/ReportsProcatt/ReportsProcatt/wwwroot"
            };

            return await _generatePdf.GetPdf("Views/New/Index.cshtml", data);
        }

        [HttpGet]
        public IActionResult Index()
        {
            var data = new Report
            {
                
            };

            return View(data);
        }
    }
}
