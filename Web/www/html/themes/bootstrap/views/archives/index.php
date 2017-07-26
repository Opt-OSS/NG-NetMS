<?php
$this->breadcrumbs = array(
    'Archive Manager',
);
?>

<h1>Archive Manager</h1>


<?php

$this->beginWidget('bootstrap.widgets.TbModal', array('id' => 'archiveset', 'htmlOptions' => array('style' => 'width: 400px;max-height:500px'))); ?>

<div class="modal-header">
    <a class="close" data-dismiss="modal">&times;</a>
    <h4>Archive</h4>
</div>

<div class="modal-body">
    New settings were saved!
    <div id="archive_debug" style="whi"></div>
</div>

<div class="modal-footer">
    <?php $this->widget('bootstrap.widgets.TbButton', array(
        'label'       => 'Close',
        'url'         => '#',
        'htmlOptions' => array('data-dismiss' => 'modal'),
    ));
    ?>
</div>

<?php $this->endWidget(); ?>

<?php
$this->beginWidget('bootstrap.widgets.TbModal', array('id' => 'archiveerror', 'htmlOptions' => array('style' => 'width: 400px;max-height:500px'))); ?>

<div class="modal-header">
    <a class="close" data-dismiss="modal">&times;</a>
    <h4>Archive </h4>
</div>

<div class="modal-body">
    Error! New settings were not saved!
</div>

<div class="modal-footer">
    <?php $this->widget('bootstrap.widgets.TbButton', array(
        'label'       => 'Close',
        'url'         => '#',
        'htmlOptions' => array('data-dismiss' => 'modal'),
    ));
    ?>
</div>

<?php $this->endWidget(); ?>
<?php
$form = $this->beginWidget(
    'bootstrap.widgets.TbActiveForm',
    array(
        'id'          => 'verticalForm',
        'htmlOptions' => array('class' => 'well'), // for inset effect
    )
);

$cur_disc = trim($model1->arc_period);
?>
<script type="text/javascript"
        src="<?php echo Yii::app()->baseUrl; ?>/js/libs/jquery-cron/cron/jquery-cron.js"></script>

<link type="text/css" href="<?php echo Yii::app()->baseUrl; ?>/js/libs/jquery-cron/cron/jquery-cron.css"
      rel="stylesheet"/>
<div class="form-group" style="overflow: auto;margin-bottom: 1em;">
    <style>
        .bootstrap-switch{
            height:2em;
        }
    </style>
    <?php
    $val = $model1->arc_enable > 0 ? 1 : 0 ?>
    <div style="float:left; width: 39%;padding-left:70px;">
        <label class="nav-header" for="arc_enable">Enable Archivation</label>
        <input id="arc_enable" type="checkbox" class="BSswitch" name="arc_enable" data-on-text="Enabled"
               data-off-text="Disabled" data-off-color="danger" data-on-color="success">
    </div>
    <div style="float:right; width: 39%">
        <label class="nav-header" for="archive-gzip">Use gzip compression for archives</label>
        <?php $val = $model1->arc_gzip > 0 ? 1 : 0 ?>
        <input id="arc_gzip" type="checkbox" class="BSswitch" name="arc_gzip" data-on-text=" Enabled"
               data-off-text="Disabled" data-off-color="danger" data-on-color="success">

    </div>
</div>
<div class="form-group clearfix">
    <label class="nav-header" style="margin-left: 70px" for="older_time"> Archive alarms older than </label>

    <div style="margin-left: 50px">
        <input type="text" style="margin-left: 20px;margin-right: 189px;margin-top:10px" name="older_time"
               id="older_time" value="<?php echo $model1->arc_expire ?>" style="width: 200px;margin-right : 170px">
    </div>
</div>

<div class="form-group">
    <label class="nav-header" style="margin-left: 70px" for="delete_time"> Delete archives older than </label>

    <div style="margin-left: 50px">

        <input type="text" style="margin-left: 20px;margin-top:9px" name="delete_time" id="delete_time"
               value="<?php echo $model1->arc_delete ?>" style="width: 200px;">

        <?php $this->widget(
            'bootstrap.widgets.TbButton',
            array(
                'label'       => 'Manage Archives',
                'type'        => 'primary',
                'url'         => array('admin'),
                'htmlOptions' => array('style' => "margin-left:192px;width : 230px")
            )
        );
        ?>
    </div>

</div>
<div class="form-group">
    <label class="nav-header" style="margin-left: 70px" for="expired_time"> Archive alarams every </label>

    <div style="margin-left: 50px">

            <div id="cron_builder_help" style='display:none;font-family:"Courier New", Courier, monospace;'>
                <div style="white-space: pre-line">
                    .---------------- minute (0 - 59)
                    | .------------- hour (0 - 23)
                    | | .---------- day of month (1 - 31)
                    | | | .------- month (1 - 12) OR jan,feb,mar,apr ...
                    | | | | .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
                    | | | | |
                    * * * * *
                </div>
                <div><?= $cur_disc ?>  Current cronjob schedule</div>
                <div><input disabled type="text" style="margin-left: 20px;margin-top:9px width: 200px;" name="expired_time"
                            id="expired_time" value="<?= $cur_disc ?>"><span id="cron_generated_value"></span> New cronjob schedule</div>
                <br><br>
            </div>
            <div id="cron_builder"></div>

    </div>
</div>
<br>
<div class="form-group">
    <div class="row">
        <div class="span6">
            <?php $this->widget('bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => 'Apply', 'type' => 'success', 'htmlOptions' => array('style' => "margin-left:3em;width : 110px", 'onclick' => "js:test();"))) ?>
            <?php $this->widget('bootstrap.widgets.TbButton', array('label' => 'Cancel', 'type' => 'default', 'url' => array('site/index'), 'htmlOptions' => array('style' => "margin-left:3em;width : 110px"))) ?>
            <a href="javascript:"  style="margin-left:3em;width : 110px" onclick="$('#cron_builder_help').slideToggle()" class="btn btn-info">Help</a>
        </div>
    </div>
</div>
<br/>
<div class="form-group">
    <div></div>
</div>

<script>

    var cron_field;
    $(document).ready(function () {
        cron_field = $('#cron_builder').cron({
                initial     : '<?=$cur_disc ?>',
                onChange    : function () {
                    $('#expired_time').val($(this).cron("value"));
                },
                customValues: {
                    "15 Minutes": "*/15 * * * *",
                    "30 Minutes": "*/30 * * * *",
                    "6 hours"   : "0 */6 * * *",
                    "12 hours"  : "0 */12 * * *",
                },
//                useGentleSelect: true,
            }
        )
        ; // apply cron with default options


        $('.BSswitch').bootstrapSwitch();
        $('#arc_enable').bootstrapSwitch('state', <?php echo($model1->arc_enable > 0 ? 'true' : 'false') ?>);
        $('#arc_gzip').bootstrapSwitch('state', <?php echo($model1->arc_gzip > 0 ? 'true' : 'false') ?>);


        $("#older_time")
            .popover({ title: 'Data format', content: "[0-59]m [0-23]h [Number]d " })
            .blur(function () {
                $(this).popover('hide');
            });

        $("#delete_time")
            .popover({ title: 'Data format', content: "[0-59]m [0-23]h [Number]d " })
            .blur(function () {
                $(this).popover('hide');
            });
    });

    function test() {
        var flag = 0;
        var b    = document.getElementById("older_time");
        if (!verificationArchDel(b.value)) {
            document.getElementById("older_time").focus();
            document.getElementById("older_time").click();
            alert("Bad value for 'ARCHIVE ALARMS OLDER THAN'");
            return;
        }

        var a = document.getElementById("expired_time");
        if (!verificationCron(a.value)) {
            document.getElementById("expired_time").focus();
            document.getElementById("expired_time").click();
            alert("Bad value for 'DELETE ARCHIVES OLDER THAN'");
            return;
        }
        var c = document.getElementById("delete_time");
        if (!verificationArchDel(c.value)) {
            document.getElementById("delete_time").focus();
            document.getElementById("delete_time").click();
            alert("Bad value for 'ARCHIVE ALARAMS EVERY'");
            return;
        }


        var arr_per = {
            old_period: $('#older_time').val(),
            exp_period: $("#expired_time").val(),
            del_period: $("#delete_time").val(),
            arc_enable: $("#arc_enable").is(':checked') ? 1 : 0,
            arc_gzip  : $('#arc_gzip').is(':checked') ? 1 : 0,
            arc_path  : 'archive'
        };
        $.ajax({
            url     : '<?php echo Yii::app()->createUrl('archiveConf/setconfiguration'); ?>',
            type    : 'POST',
            data    : arr_per,
            cache   : false,
            dataType: 'json',
            success : function (data) {
//                console.log(data);
                if (data.ok > 0) {
                    $("#archiveset").modal("show");
                }
                else {
                    $("#archiveerror").modal("show");
                }
            }
        });
    }
    function verificationCron(val) {
//        console.log(val);
//        var fCron = /^(\d{1,2})(d|h|m)$/;
//        var fCron = /(^[01]?[0-9]|2[0-3])h$|^[0-5]?[0-9]m$|^([1]?[0-9]|2[0-9]|3[0-1])d$/;
        fCron = /^[\s\d\*\/\-]+$/;

        return fCron.test(val);
    }

    function verificationArchDel(val) {
//        console.log(val);
//        var fArc = /^[0-5]?[0-9]m\s+([01]?[0-9]|2[0-3])h\s+([1]?[0-9]|2[0-9]|3[0-1])d$|^[0-5]?[0-9]m\s+([01]?[0-9]|2[0-3])h$|^[0-5]?[0-9]m\s+([1]?[0-9]|2[0-9]|3[0-1])d$|^([01]?[0-9]|2[0-3])h\s+([1]?[0-9]|2[0-9]|3[0-1])d$|(^[01]?[0-9]|2[0-3])h$|^[0-5]?[0-9]m$|^([1]?[0-9]|2[0-9]|3[0-1])d$/
        var fArc = /^[0-5]?[0-9]m\s+([01]?[0-9]|2[0-3])h\s+(\d+)d$|^[0-5]?[0-9]m\s+([01]?[0-9]|2[0-3])h$|^[0-5]?[0-9]m\s+(\d+)d$|^([01]?[0-9]|2[0-3])h\s+(\d+)d$|(^[01]?[0-9]|2[0-3])h$|^[0-5]?[0-9]m$|^(\d+)d$/
        return fArc.test(val);
    }
</script>
<?php
$this->endWidget();
unset($form);
?>

