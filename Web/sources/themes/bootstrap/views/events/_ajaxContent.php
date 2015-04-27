<?php
?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="language" content="en" />

    <link rel="stylesheet" type="text/css" href="<?php echo Yii::app()->theme->baseUrl; ?>/css/styles.css" />

    <title><?php echo "Events-".$origin; ?></title>

    <?php Yii::app()->bootstrap->init(); ?>

</head>

<body>
<div style ="width:90%;margin-left: 5%">
    <h2><?php echo "Events for device/host <i><font color='#68000'>".$origin."</font></i>"; ?></h2>
    <div>
        You can use operators ">", "<", ">=", "<=","<>" for searching by fields <b> <i>Severity</i>, <i>Code</i></b></br>
        and operator "<>" for searching by fields <b><i>Facility</i>,<i> Description and Time</i></b>.</br>
        Click "Help" for details
    </div>
    </br>
    <?php
    $this->widget(
        'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => "Help", 'type' => 'info',
            'htmlOptions'=>array('id'=>'btnHelp','style'=>"margin-left:35px;"),)
    );
    ?>

</br>
    <p></p>
    <div id="myAlert" class="alert alert-info" style="display:none">
        <strong>Help!</strong> You can use POSIX regex in fields <b><i>Facility</i>,<i>Description</i></b>.</br>
        You must enclose the regex in tags : &lt;regex&gt;&lt;/regex&gt;. <br/>
        <b>For example :</b><br/>
        &lt;regex&gt;(Login|PASSWORD)&lt;/regex&gt; - search all strings which contain word <b>login</b> or <b>password</b></br>
        &lt;regex&gt;<>[\d]&lt;/regex&gt; - search all strings which do not contain digits</br>
        &lt;regex&gt;^((?!CLOSE).)*$&lt;/regex&gt; - search all strings which do not contain word close</br>
        &lt;regex>^((?!192.168.3.102).)*$&lt;/regex&gt; - search all with exception of the IP address

        </br>

        <b>Note!</b> implementation of Regex here is case insensitive!
    </div>

    <script type="text/javascript">

        $(function(){
            $("button").click(function(){
                var label_t = $("#btnHelp").text();
                if(label_t == 'Help')
                {
                    $("#btnHelp").html('Close help');
                }
                else
                {
                    $("#btnHelp").html('Help');
                }
                $("#myAlert").toggle();
            });
        });
    </script>
    <?php
if(isset($model1) and count($model1)>0)
{
$this->widget('bootstrap.widgets.TbGridView', array(
    'type'            => 'bordered',
    'id'              => 'router-one-grid-events',
    'dataProvider'    => $model1->allEventsOriginPeriod(),
    'filter'          => $model1,
    'enablePagination'=>true,
    'template'=>"{items}{pager}",
    'columns'         => array(
        array('name'=>'origin_ts', 'header'=>'Time Original','htmlOptions'=>array('width'=>'210px','style'=>'font-size:12px')),
        array('name'=>'receiver_ts', 'header'=>'Time Receiver','htmlOptions'=>array('width'=>'210px','style'=>'font-size:12px')),
        array('name'=>'facility', 'header'=>'Facility','htmlOptions'=>array('style'=>'font-size:12px')),
        array('name'=>'priority', 'header'=>'Prior','filter'=>'','htmlOptions'=>array('style'=>'font-size:12px')),
        array('name'=>'severity', 'header'=>'Severity','htmlOptions'=>array('width'=>'40px','style'=>'font-size:12px')),
        array('name'=>'code', 'header'=>'Code','htmlOptions'=>array('style'=>'font-size:12px')),
        array('name'=>'descr', 'header'=>'Description','htmlOptions'=>array('style'=>'font-size:12px')),
    ),

));
}

?>
</div>


</body>