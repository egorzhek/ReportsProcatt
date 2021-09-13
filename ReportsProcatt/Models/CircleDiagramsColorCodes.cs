using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace ReportsProcatt.Models
{
    public class CircleDiagramsColorCodes
    {
        public static Dictionary<int, string> MainAssetsCircle = new Dictionary<int, string>
        {
            { 1,"#09669A" },
            { 2,"#00A0D0" },
            { 3,"#9DD0E6" },
            { 4,"#AEBDC3" }
        };

        public static Dictionary<int, string> MainInstrumentsCircle = new Dictionary<int, string>
        {
            { 1, "#099A80" },
            { 2, "#29B49B" },
            { 3, "#6FC3B4" },
            { 4, "#034F4F" },
            { 5, "#65D6C2" },
            { 6, "#056F58" },
            { 7, "#BBB9B9" }
        };

        public static Dictionary<int, string> MainCurrenciesCircle = new Dictionary<int, string>
        {
            { 1, "#9668D1" },
            { 2, "#B82EFA" },
            { 3, "#6FC3B4" },
            { 4, "#034F4F" },
            { 5, "#65D6C2" },
            { 6, "#056F58" },
            { 7, "#BBB9B9" }
        };
    }
}
