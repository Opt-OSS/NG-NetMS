/**
 * Created by andrew on 9/19/14.
 */
// Load the Visualization API and the piechart package.
google.load('visualization', '1.0', {'packages':['corechart']});

// Set a callback to run when the Google Visualization API is loaded.
//google.setOnLoadCallback(drawChart);

// Callback that creates and populates a data table,
// instantiates the pie chart, passes in the data and
// draws it.
function bindFunctions()
{
    drawChart(arr);
}
function drawChart(arr) {

    // Create the data table.
  /*  var data = new google.visualization.DataTable();
    data.addColumn('string', 'Router');
    data.addColumn('number', 'Events');
    data.addRows([
    ['Mushrooms', 3],
    ['Onions', 1],
    ['Olives', 1],
    ['Zucchini', 1],
    ['Pepperoni', 2]
    ]);*/
    var dat_pie = JSON.parse(arr);
    var data = google.visualization.arrayToDataTable(dat_pie);

    // Set chart options
    var options = {
    'width':500,
    'height':400};

    var options1 = {
        'width':500,
        'height':400};

// Instantiate and draw our chart, passing in some options.
var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
chart.draw(data, options);
var chart1 = new google.visualization.BarChart(document.getElementById('chart1_div'));
    chart1.draw(data, options1);
    var dat_pie1 = JSON.parse(arr1);
    var data1 = google.visualization.arrayToDataTable(dat_pie1);
    console.log(data1);
    // Set chart options
    var options2 = {
        'width':500,
        'height':400};

    var options3 = {
        'width':500,
        'height':400};

// Instantiate and draw our chart, passing in some options.
    var chart2 = new google.visualization.PieChart(document.getElementById('chart_div1'));
    chart2.draw(data1, options2);
    var chart3 = new google.visualization.BarChart(document.getElementById('chart1_div1'));
    chart3.draw(data1, options3);
}
