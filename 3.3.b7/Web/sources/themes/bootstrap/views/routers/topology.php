<?php
/* @var $this RoutersController */

 
 $this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Map'=>'index.php?r=routers/routermap', 'Topology Map'),
)); 

?>
<script src="<?php echo Yii::app()->baseUrl; ?>/js/libs/arbor.js"></script>
<script type="text/javascript">
    var arr_json = '<?php echo $arr_json;?>';
</script>
<?php $this->beginWidget('bootstrap.widgets.TbModal', array('id'=>'routerModal')); ?>
 
<div class="modal-header">
    <a class="close" data-dismiss="modal">&times;</a>
    <h4></h4>
</div>
 
<div class="modal-body">
    <h4>Intefaces :</h4>
    <div class = "routerinterfaces">             
    </div>
    <h4>HW inventory :</h4>
    <div class = "hwinv">             
    </div>
    <h4>SW Inventory :</h4>
    <div class = "swinv">             
    </div>
</div>
 
<div class="modal-footer">
    <?php $this->widget('bootstrap.widgets.TbButton', array(
        'label'=>'Close',
        'url'=>'#',
        'htmlOptions'=>array('data-dismiss'=>'modal'),
    )); ?>
</div>
 
<?php $this->endWidget(); ?>
<div style="margin:15px">
<canvas id="viewport" width="<?php echo $schema['x']; ?>" height="<?php echo $schema['y']; ?>"></canvas>
</div>


