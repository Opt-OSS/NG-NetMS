<?php
/* @var $this RoutersController */

 
 $this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Map'=>'index.php?r=routers/routermap', 'Dynamic Map'),
)); 

?>
<script src="<?php echo Yii::app()->baseUrl; ?>/js/libs/arbor.js"></script>
<script type="text/javascript">
    var arr_json = '<?php echo $arr_json;?>';
</script>
<canvas id="viewport" width="<?php echo $schema['x']; ?>" height="<?php echo $schema['y']; ?>"></canvas>
<div></div>


