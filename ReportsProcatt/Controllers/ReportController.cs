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
    public class ReportController : Controller
    {
        readonly IGeneratePdf _generatePdf;

        public ReportController(IGeneratePdf generatePdf)
        {
            _generatePdf = generatePdf;
        }

        public async Task<IActionResult> Pdf
        (
            int? InvestorId,
            int? ProductId,
            string Type,
            DateTime? DateFrom,
            DateTime? DateTo,
            string Currency
        )
        {

            if (InvestorId == null)
                throw new Exception($@"{(InvestorId == null ? "InvestorId is null;" : "")}");

            if ((ProductId == null && !string.IsNullOrEmpty(Type))
                || (ProductId != null && string.IsNullOrEmpty(Type))
                || (!string.IsNullOrEmpty(Type) && !new string[] { "MF", "DU" }.Contains(Type)))
                throw new Exception($@"{(ProductId == null ? "ProductId is null;" : "")}" +
                                    $@"{((!string.IsNullOrEmpty(Type) && !new string[] { "", "" }.Contains(Type)) ?
                                        "Type must be in [MF, TM];" : "")}");
            try
            {
                if (string.IsNullOrEmpty(Type))
                {
                    var data = new Report((int)InvestorId, DateFrom, DateTo, Currency)
                    { rootStr = "/app/wwwroot" };

                    return await _generatePdf.GetPdf("Views/Report/Index.cshtml", data);
                }
                else if (Type == "MF")
                {
                    var data = new Fund((int)InvestorId, (int)ProductId, DateFrom, DateTo, Currency)
                    { rootStr = "/app/wwwroot" };

                    return await _generatePdf.GetPdf("Views/Report/Fund.cshtml", data);
                }
                else if (Type == "TM")
                {
                    var data = new Contract((int)InvestorId, (int)ProductId, DateFrom, DateTo, Currency)
                    { rootStr = "/app/wwwroot" };

                    return await _generatePdf.GetPdf("Views/Report/Contract.cshtml", data);
                }
                else
                    throw new Exception("Something goes wrong!");
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
        public async Task<IActionResult> Pdf_Win
        (
            int? InvestorId,
            int? ProductId,
            string Type,
            DateTime? DateFrom,
            DateTime? DateTo,
            string Currency
        )
        {
            if (InvestorId == null)
                throw new Exception($@"{(InvestorId == null ? "InvestorId is null;" : "")}");

            if ((ProductId == null && !string.IsNullOrEmpty(Type))
                || (ProductId != null && string.IsNullOrEmpty(Type))
                || (!string.IsNullOrEmpty(Type) && !new string[] { "MF", "DU" }.Contains(Type)))
                throw new Exception($@"{(ProductId == null ? "ProductId is null;" : "")}" +
                                    $@"{((!string.IsNullOrEmpty(Type) && !new string[] { "", "" }.Contains(Type)) ?
                                        "Type must be in [MF, TM];" : "")}");
            try
            {
                if (string.IsNullOrEmpty(Type))
                {
                    var data = new Report((int)InvestorId, DateFrom, DateTo, Currency)
                    { rootStr = "file:///c:/Users/D/source/Ingos/ReportsProcatt/ReportsProcatt/wwwroot" };

                    return await _generatePdf.GetPdf("Views/Report/Index.cshtml", data);
                }
                else if (Type == "MF")
                {
                    var data = new Fund((int)InvestorId, (int)ProductId, DateFrom, DateTo, Currency)
                    { rootStr = "file:///c:/Users/D/source/Ingos/ReportsProcatt/ReportsProcatt/wwwroot" };

                    return await _generatePdf.GetPdf("Views/Report/Fund.cshtml", data);
                }
                else if (Type == "TM")
                {
                    var data = new Contract((int)InvestorId, (int)ProductId, DateFrom, DateTo, Currency)
                    { rootStr = "file:///c:/Users/D/source/Ingos/ReportsProcatt/ReportsProcatt/wwwroot" };

                    return await _generatePdf.GetPdf("Views/Report/Contract.cshtml", data);
                }
                else
                    throw new Exception("Something goes wrong!");
                
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
        public IActionResult Web
        (
            int? InvestorId,
            int? ProductId,
            string Type,
            DateTime? DateFrom,
            DateTime? DateTo,
            string Currency
        )
        {
            try
            {
                if (InvestorId == null)
                    throw new Exception($@"{(InvestorId == null ? "InvestorId is null;" : "")}");

                if ((ProductId == null && !string.IsNullOrEmpty(Type))
                    || (ProductId != null && string.IsNullOrEmpty(Type))
                    || (!string.IsNullOrEmpty(Type) && !new string[]{ "MF", "DU" }.Contains(Type)))
                    throw new Exception($@"{(ProductId == null ? "ProductId is null;" : "")}" +
                                        $@"{((!string.IsNullOrEmpty(Type) && !new string[] { "", "" }.Contains(Type)) ? 
                                            "Type must be in [MF, TM];":"")}" );

                if (string.IsNullOrEmpty(Type))
                    return View(new Report((int)InvestorId, DateFrom, DateTo, Currency));
                else if (Type == "MF")
                    return View("Fund", new Fund((int)InvestorId, (int)ProductId, DateFrom, DateTo, Currency));
                else if (Type == "TM")
                    return View("Contract", new Contract((int)InvestorId, (int)ProductId, DateFrom, DateTo, Currency));
                else
                    throw new Exception("Something goes wrong!");
                
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
        public JsonResult Api
        (
            int InvestorId,
            DateTime? DateFrom,
            DateTime? DateTo,
            string Currency
        )
        {
            return Json(new Report(InvestorId, DateFrom, DateTo, Currency));
        }
        public IActionResult Weba
        (
            int? InvestorId,
            DateTime? DateFrom,
            DateTime? DateTo,
            string Currency
        )
        {
            try
            {
                if (InvestorId == null)
                    throw new Exception("InvestorId is null");

                var data = new Report((int)InvestorId, DateFrom, DateTo, Currency)
                {
                    rootStr = "/app/wwwroot"
                };

                return View(data);
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
        public IActionResult Adaptive_Test
        (
            int? InvestorId,
            DateTime? DateFrom,
            DateTime? DateTo,
            string Currency
        )
        {
            try
            {
                if (InvestorId == null)
                    throw new Exception("InvestorId is null");

                var data = new Report((int)InvestorId, DateFrom, DateTo, Currency);

                return View("Views/Report/Adaptive.cshtml", data);
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
    }
}
