/**
 * Created by andrew on 9/26/14.
 */


function showButtons(flag_id,row_id)
{
    row = $('#' + row_id);

    if (flag_id < 1)
    {
        row.attr('disabled','disabled');
        row.hide()

    }
    else
    {
        row.show()
        row.removeAttr('disabled');
    }
}

function drawDashboard(dat1) {

    var dat2 = new google.visualization.DataTable();
    dat2.addColumn('datetime', 'Date');
    dat2.addColumn('number', 'Severity Level');

    for(i=0;i<dat1.length;i++)
    {
        dat2.addRow([new Date(dat1[i][0]),  dat1[i][1]]);
    }

    var formatter = new google.visualization.DateFormat({
        pattern:"d.MM.y HH:mm:s"
    })

    formatter.format(dat2,0);
    // Create a dashboard.
    var dashboard = new google.visualization.Dashboard(
        document.getElementById('dashboard_div'));

    // Create a range filter, passing some options
    var dateRange = new google.visualization.ControlWrapper({
        'controlType': 'ChartRangeFilter',
        'containerId': 'filter_div',
        'options': {
            'filterColumnIndex': 0,
            'ui': {
                'chartType': 'LineChart',
                'chartOptions': {

                    'hAxis': {
                        'baselineColor': 'none',
                        'textPosition': 'none'
                    }
                }
            }
        }
    });
    google.visualization.events.addListener(dateRange, 'statechange', function() {

            var re = dateRange.getState();
            var valued = re.range.end;

            var d = new Date(valued);
            var curr_date = d.getDate();
            var curr_month = d.getMonth()+1;
            var curr_year = d.getFullYear();
            var curr_hours = d.getHours();
            var curr_mins = d.getMinutes();
            var curr_secs = d.getSeconds();
            var value = curr_date+"/"+curr_month+"/"+curr_year+" "+curr_hours+":"+curr_mins+":"+curr_secs;
            var valuest = re.range.start;
            var d1 = new Date(valuest);
            var curr_date1 = d1.getDate();
            var curr_month1 = d1.getMonth()+1;
            var curr_year1 = d1.getFullYear();
            var curr_hours1 = d1.getHours();
            var curr_mins1 = d1.getMinutes();
            var curr_secs1 = d1.getSeconds();
            var value1 = curr_date1+"/"+curr_month1+"/"+curr_year1+" "+curr_hours1+":"+curr_mins1+":"+curr_secs1;


            $('#from_to').val(value);
            $('#firstdate').val(value1);
            $('#lastdate').val(value);



    });
    // Create a line chart, passing some options
    var lineChart = new google.visualization.ChartWrapper({
        'chartType': 'LineChart',
        'containerId': 'chart_div',
        'options': {
            pointSize: 3,
            title: 'History of event\'s Severity Levels over time',
            titleTextStyle: {
                fontSize: 24
            },
            animation : { duration:1000, easing:'out'},
            hAxis: {

                title: 'Date',
                textStyle: {
                    fontSize:12
                },
                gridlines: {
                    color: '#f3f3f3',
                    count: -1
                },
                format: 'short'
            },
            vAxis: {
                slantedText: true,
                minValue: 0,
                baselineColor:'#D3D3D3',
                format:'#'
            },

            legend: {
                'position': 'none'
            }
        }
    });
    function selectHandler() {

        var selectedItem = lineChart.getChart().getSelection()[0];
        console.log(selectedItem)
        if (selectedItem) {
            var filteredData = lineChart.getDataTable();
            var valued = filteredData.getValue(selectedItem.row,0);
            var d = new Date(valued);
            var curr_date = d.getDate();
            var curr_month = d.getMonth()+1;
            var curr_year = d.getFullYear();
            var curr_hours = d.getHours();
            var curr_mins = d.getMinutes();
            var curr_secs = d.getSeconds();
            var value = curr_date+"/"+curr_month+"/"+curr_year+" "+curr_hours+":"+curr_mins+":"+curr_secs;

            $('#from_to').val(value);
        }
    }
    google.visualization.events.addListener(lineChart, 'select', selectHandler);
    // Establish dependencies, declaring that 'filter' drives 'lineChart',
    // so that the pie chart will only display entries that are let through
    // given the chosen slider range.
    dashboard.bind(dateRange, lineChart);

    // Draw the dashboard.
    dashboard.draw(dat2);
}
