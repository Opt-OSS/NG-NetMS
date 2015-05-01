$(document).ready(function () {
    $("#right-search").keyup(function () {
        //split the current value of searchInput

        var data = this.value.split(" ");
        var counter0 = 0;
        $("#select_right_fake").hide();
        $("#select_right").show();
        //create a jquery object of the rows
        var jo = $("#select_right").find("option");
        if (this.value == "") {
            jo.show();
            return;
        }
        //hide all the rows
        jo.hide();

        //Recusively filter the jquery object to get results.
        jo.filter(function (i, v) {
            var $t = $(this);
            for (var d = 0; d < data.length; ++d) {
                if ($t.is(":contains('" + data[d] + "')")) {
                    counter0++;
                    return true;
                }
            }
            return false;
        })
            //show the rows that match.
            .show();
        if(counter0 == 0)
        {
            $("#select_right").hide();
            $("#select_right_fake").show();
        }
    }).focus(function () {
        this.value = "";
        $(this).css({
            "color": "black"
        });
        $(this).unbind('focus');
    }).css({
        "color": "#C0C0C0"
    });
    $("#left-search").keyup(function () {
        //split the current value of searchInput
        var data = this.value.split(" ");
        var counter = 0;
        //create a jquery object of the rows
        $("#select_left_fake").hide();
        $("#select_left").show();
        var jo = $("#select_left").find("option");
        if (this.value == "") {
            jo.show();
            return;
        }
        //hide all the rows
        jo.hide();

        //Recusively filter the jquery object to get results.
        jo.filter(function (i, v) {
            var $t = $(this);
            for (var d = 0; d < data.length; ++d) {
                if ($t.is(":contains('" + data[d] + "')")) {
                    counter++;
                    return true;
                }
            }
            return false;
        })
            //show the rows that match.
            .show();
        if(counter == 0)
        {
            $("#select_left").hide();
            $("#select_left_fake").show();
        }
    }).focus(function () {
        this.value = "";
        $(this).css({
            "color": "black"
        });
        $(this).unbind('focus');
    }).css({
        "color": "#C0C0C0"
    });

})
