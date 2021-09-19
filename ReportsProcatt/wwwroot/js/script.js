'use strict';

(function(setLineDash) {
    CanvasRenderingContext2D.prototype.setLineDash = function() {
        if(!arguments[0].length){
            arguments[0] = [1,0];
        }
        // Now, call the original method
        return setLineDash.apply(this, arguments);
    };
})(CanvasRenderingContext2D.prototype.setLineDash);
Function.prototype.bind = Function.prototype.bind || function (thisp) {
    var fn = this;
    return function () {
        return fn.apply(thisp, arguments);
    };
};



const charData1 = {
      type: 'doughnut',
      data: {
        labels: ["Акции", "Облигации", "Валюта", "Фонды"],
        datasets: [{
        backgroundColor: [
                '#09669A',
                '#00A0D0',
                '#9DD0E6',
                '#AEBDC3'
            ],
            borderColor: [
                '#09669A',
                '#00A0D0',
                '#9DD0E6',
                '#AEBDC3'
            ],
          data: [69.77, 28.31, 1.86, 0.06]
        }]
      },
      options: {
    type: 'doughnut',
    cutoutPercentage: 68, 
                animation: {
                    duration: 0, // general animation time
                },
                hover: {
                    animationDuration: 0, // duration of animations when hovering an item
                },
                responsiveAnimationDuration: 0, // animation duration after a resize         
    // animation: {
    //     animateScale: true,
    //     animateRotate: true
    // },
    responsive: true,
    maintainAspectRatio: false,    
    legend: {
      display: false
    },
    //legendCallback: function(chart) {
    //  var text = [];
    //  text.push('<span>Активы</span><ul class="0-legend legend-list">');
    //  var ds = chart.data.datasets[0];
    //  var sum = ds.data.reduce(function add(a, b) { return a + b; }, 0);
    //  for (var i=0; i<ds.data.length; i++) {
    //    text.push('<li style="--theme-color:'+ ds.backgroundColor[i] + '">');
    //    var perc = 100*ds.data[i]/sum;
    //    text.push('<span style="background-color:'+ ds.backgroundColor[i] + '"></span>' + chart.data.labels[i] + '<small style="color:'+ ds.backgroundColor[i] + '">' + perc.toFixed(2) + '% </small>');
    //    text.push('</li>');
    //  }
    //  text.push('</ul>');
    //  return text.join(""); 
    //}    
}
};

const charData2 = {
      type: 'doughnut',
      data: {
        labels: ["Сегежа", "НМТП", "Нафтатранс Плюс", "Mail.ru","ЧЗПСН ао", "Alteryx", "OZON"],
        datasets: [{
            label: "Test",
            data: [7.47, 7.23, 7.16, 6.45,5.03, 4.99, 4.99],
            backgroundColor: [
                '#099A80',
                '#29B49B',
                '#6FC3B4',
                '#034F4F',
                '#65D6C2',
                '#056F58',
                '#BBB9B9',                                                
            ],
            borderColor: [
                '#099A80',
                '#29B49B',
                '#6FC3B4',
                '#034F4F',
                '#65D6C2',
                '#056F58',
                '#BBB9B9', 
            ],
            borderWidth: 1
        }]
    },
      options: {
    type: 'doughnut',
    cutoutPercentage: 68,       
    animation: {
        animateScale: true,
        animateRotate: true
    },
    responsive: true,
    maintainAspectRatio: false,    
    legend: {
      display: false
    },
    //legendCallback: function(chart) {
    //  var text = [];
    //  text.push('<span>Инструменты</span><ul class="0-legend legend-list">');
    //  var ds = chart.data.datasets[0];
    //  var sum = ds.data.reduce(function add(a, b) { return a + b; }, 0);
    //  for (var i=0; i<ds.data.length; i++) {
    //    text.push('<li style="--theme-color:'+ ds.backgroundColor[i] + '">');
    //    var perc = 100*ds.data[i]/sum;
    //    text.push('<span style="background-color:'+ ds.backgroundColor[i] + '"></span>' + chart.data.labels[i] + '<small style="color:'+ ds.backgroundColor[i] + '">' + perc.toFixed(2) + '% </small>');
    //    text.push('</li>');
    //  }
    //  text.push('</ul>');
    //  return text.join(""); 
    //}    
}
};

const charData3 = {
      type: 'doughnut',
        data: {
            labels: ["RUB", "USD"],
            datasets: [{
                label: "Test",
                data: [66.86, 33.14],
                backgroundColor: [
                    '#9668D1',
                    '#B82EFA',                                              
                ],
                borderColor: [
                    '#9668D1',
                    '#B82EFA',
                ],
                borderWidth: 1
            }]
        },
      options: {
    type: 'doughnut',
    cutoutPercentage: 68,       
    animation: {
        animateScale: true,
        animateRotate: true
    },
    responsive: true,
    maintainAspectRatio: false,    
    legend: {
      display: false
    },
    //legendCallback: function(chart) {
    //  var text = [];
    //  text.push('<span>Валюта</span><ul class="0-legend legend-list">');
    //  var ds = chart.data.datasets[0];
    //  var sum = ds.data.reduce(function add(a, b) { return a + b; }, 0);
    //  for (var i=0; i<ds.data.length; i++) {
    //    text.push('<li style="--theme-color:'+ ds.backgroundColor[i] + '">');
    //    var perc = 100*ds.data[i]/sum;
    //    text.push('<span style="background-color:'+ ds.backgroundColor[i] + '"></span>' + chart.data.labels[i] + '<small style="color:'+ ds.backgroundColor[i] + '">' + perc.toFixed(2) + '% </small>');
    //    text.push('</li>');
    //  }
    //  text.push('</ul>');
    //  return text.join(""); 
    //}    
}
};



function createChart(chartId, chartData) {
    new Chart(document.getElementById(chartId), {
      type: chartData.type,
      data: chartData.data,
      options: chartData.options,
    });

    //let myLegendContainer = ctx.nextElementSibling;
    //myLegendContainer.innerHTML = myChart.generateLegend();
    //let legendItems = myLegendContainer.getElementsByTagName('li');  
};

window.onload = function () {
    createChart('chart1', charData1);
    createChart('chart2', charData2);
    createChart('chart3', charData3);
    createChart('chart4', charData1);
    createChart('chart5', charData2);
    createChart('chart6', charData1);
    createChart('chart7', charData2);
}

// $("canvas").each(function () {
//     // Create an Image object to capture the DataURI of the canvas
//     var image = new Image();
//     image.src = this.toDataURL("image/png");

//     // Copy all styling attributes to take into account the current height
//     $(image).attr("style", $(this).attr("style"));
//     $(image).attr("width", $(this).attr("width"));
//     $(image).attr("height", $(this).attr("height"));

//     // Replace the canvas object with its corresponding img-tag
//     $(this).replaceWith($(image));
// });