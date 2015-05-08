<?php
$this->breadcrumbs=array(
	'List of networks not to be scanned'=>array('index'),
	'New network',
);

?>

<h1>List of networks not to be scanned</h1>
<?php if(Yii::app()->user->hasFlash('exceptupdate')){ ?>

    <?php $this->widget('bootstrap.widgets.TbAlert', array(
        'alerts'=>array('exceptupdate'),
    )); }  ?>

<?php echo $this->renderPartial('_form', array('model'=>$model)); ?>