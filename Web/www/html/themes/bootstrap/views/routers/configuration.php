<?php
/* @var $this RoutersController */

$this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links' => array('Devices' => 'index.php?r=routers/index', 'Device Configuration' => 'index.php?r=routers/viewconf', "Device ".$router->name),
));
?>

<?php if($config_current){ ?>
<?php
    $form = $this->beginWidget(
    'bootstrap.widgets.TbActiveForm',
    array(
        'id' => 'inlineForm',
        'type' => 'inline',
        'htmlOptions' => array('class' => 'well'),
    )
);

    echo "Compare    ";
    echo $form->dropDownListRow($model, 'id', $arr_conf,array(
    'prompt'=>'select first configuration',
)); 
    echo " with ";
    echo $form->dropDownListRow($model1, 'id', $arr_conf1,array(
    'prompt'=>'select second configuration',
)); 

$this->widget(
    'bootstrap.widgets.TbButton',
    array('buttonType' => 'submit', 'label' => 'Run')
);
 
$this->endWidget();
if($flag_alert == 1)
{
Yii::app()->user->setFlash('error', '<strong>ERROR!</strong> Select two configurations for comparison and try submitting again.');
$this->widget('bootstrap.widgets.TbAlert', array(
        'block'=>true, // display a larger alert block?
        'fade'=>true, // use transitions?
        'closeText'=>'&times;', // close link text - if set to false, no close link is displayed
        'alerts'=>array( // configurations per alert type
            'error'=>array('block'=>true, 'fade'=>true, 'closeText'=>'&times;'), // success, info, warning, error or danger
        ),
    )); 
}
?>
<?php


if($flag > 0){
/*echo "<pre>";
echo (stream_get_contents($config_compare1['data']));
echo "</pre>";
echo "<pre>";
echo (stream_get_contents($config_compare2['data']));
echo "</pre>";*/
?>    
<div style="top:0px;left:0px;z-index:10;background:#373737; width:140%;min-height:100%;font-size:8pt;margin-left:-20%;">
        <div class="listM_Oriz" style="float:left;margin-left:2%;">
            <ul>
               <li style="width:470px;">
                <a id="fn1" href="" style="background:#00BFFF;" ><?php echo $dat_conf1?></a>
               </li>
             </ul>
        </div>
        <div class="listM_Oriz" style="float:right;margin-right:2%;">
            <ul>
               <li style="width:470px;"> 
               <a id="fn2" href="" style=""><?php echo $dat_conf2?></a>
               </li>
            </ul>
        </div>
        <div style="clear:both;"></div>
        <hr>
        <div id="textEditor1" style="">
            <div style="float:left;width:48%;margin-right:1%;margin-left:1%;">
            <div >                         
               
<?php

echo ($config_compare1);

?>
              
             
           
      </div>
</div>
</div>
<div id="textEditor2" style ="">
    
    <div style="float:left;width:48%;margin-right:1%;margin-left:1%;">
        
        <div id="difference" style="font-size:8pt;">
           
            <?php
                echo $diff_configs;
            //echo (stream_get_contents($config_compare2['data']));
            ?>
            
        </div>
    </div>
    
</div>
        <div style="clear:both;"> 
        </div>           
</div>
<?php

}
 else 
{
     echo "<h5>Current:</h5><pre>";
    echo (stream_get_contents($config_current['data']));
    echo "</pre>";
}
}
else
{
    echo "<div class='well'>";
    echo "<h3>Configuration not found</h3>";
    echo "</div>";
}
?>



        