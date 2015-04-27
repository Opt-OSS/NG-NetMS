<?php
/* @var $this RoutersController */

 
 $this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Devices'=>'index.php?r=routers/index', $model->name),
)); 

?>
<script src="<?php echo Yii::app()->baseUrl; ?>/js/libs/arbor.js"></script>
<script type="text/javascript">
    var arr_json = '<?php echo $arr_json;?>';
</script>

<div></div>


<?php
    $this->widget('bootstrap.widgets.TbLabel', array(
    'type'=>'info', // 'success', 'warning', 'important', 'info' or 'inverse'
    'label'=>'Vendor/Model',
    'htmlOptions' =>array('style'=>'font-size: 24px; line-height: 24px;'),
)); 
?>
<h5>
    <?php  if(!empty($model->eq_vendor))
            {
                echo $model->eq_vendor;
            }
            else
            {
                echo "Unknown";
            }

            echo " / ";

            $mod_c = trim($model->eq_type);
            if(!empty($mod_c))
            {
                echo $model->eq_type;
            }
            else
            {
                echo "Unknown";
            }
    ?>
</h5>


<?php
    $this->widget(
    'bootstrap.widgets.TbTabs',
    array(
    'type' => 'pills', // 'tabs' or 'pills'
    'tabs' => array(
    array(
    'label' => 'HW Inventory',
    'content' => '',
    'active' => true,
    'itemOptions' => array('class' => 'routertab1')
    ),
    array('label' => 'SW Inventory', 'content' => '','itemOptions' => array('class' => 'routertab2')),
    array('label' => 'Logical Interfaces', 'content' => '','itemOptions' => array('class' => 'routertab3')),
    array('label' => 'Physical Interfaces', 'content' => '','itemOptions' => array('class' => 'routertab4')),
    array('label' => 'Configuration', 'content' => '','itemOptions' => array('class' => 'routertab5')),
    array('label' => 'Connections', 'content' => '','itemOptions' => array('class' => 'routertab6')),
    ),
    )
    );
?>

<div id="logicinterfaces" style =" display:none">
<?php

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'bordered',
        'id'              => 'router-one-grid-intf',
        'dataProvider'    => $interfaces,
        'template'=>"{items}",
        'columns'         => array(
        array('name'=>'id', 'header'=>'#'),
        array('name'=>'name', 'header'=>'Name'),
        array('name'=>'ip_addr', 'header'=>'IP address'),
        array('name'=>'mask', 'header'=>'Mask'),
        array('name'=>'state', 'header'=>'State','type' => 'raw','value'=>'$data["state"]'),
        array('name'=>'status', 'header'=>'Status','type' => 'raw','value'=>'$data["status"]'),
        array('name'=>'speed', 'header'=>'Speed'),
        array('name'=>'descr', 'header'=>'Description'),
        ),
        
    ));
?>
</div>
<div id="phisicalinterfaces" style =" display:none">
<?php

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'bordered',
        'id'              => 'router-one-grid-phintf',
        'dataProvider'    => $phinterfaces,
        'template'=>"{items}",
        'columns'         => array(
        array('name'=>'id', 'header'=>'#'),
        array('name'=>'name', 'header'=>'Name'),
        array('name'=>'state', 'header'=>'State','type' => 'raw','value'=>'$data["state"]'),
        array('name'=>'status', 'header'=>'Status','type' => 'raw','value'=>'$data["status"]'),
        array('name'=>'speed', 'header'=>'Speed'),
        array('name'=>'descr', 'header'=>'Description'),
        ),
        
    ));
?>
</div>
<div id="hwinventory" >
<?php    

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'bordered',
        'id'              => 'router-one-grid-hwinv',
        'dataProvider'    => $hw_inventory,
        'template'=>"{items}",
        'columns'         => array(
        array('name'=>'id', 'header'=>'#'),
        array('name'=>'type', 'header'=>'Type part'),
        array('name'=>'details', 'header'=>'Details'),
        ),
        
    ));
?>
</div>
<div id="swinventory" style="display:none">    
<?php    

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'bordered',
        'id'              => 'router-one-grid-swinv',
        'dataProvider'    => $sw_inventory,
        'template'=>"{items}",
        'columns'         => array(
        array('name'=>'id', 'header'=>'#'),
        array('name'=>'type', 'header'=>'Type'),
        array('name'=>'name', 'header'=>'Name'),
        array('name'=>'version', 'header'=>'Version'),
        ),
        
    ));
?>
</div>
<div id="currentconfig" style="display:none">  

<?php
    if($current_config)
    {
        echo '<div style ="float :right"> ';
        $this->widget('bootstrap.widgets.TbButton', array(
            'type'=>'success',
            'label'=>'Compare configurations',
            'url'=>Yii::app()->createUrl("routers/configuration", array("id"=>$current_config["router_id"])),
        ));
        echo "</div>";
        echo "<pre>";
        echo (htmlentities(stream_get_contents($current_config['data'])));
        echo "</pre>";
    }
    else
    {
        echo "<div class='well'>";
        echo "<h3>Configuration not found</h3>";
        echo "</div>";
    }
?>
</div>    
<div id="graphrouter" style =" display:none">
<canvas id="viewport" width="800" height="600"></canvas>
</div>