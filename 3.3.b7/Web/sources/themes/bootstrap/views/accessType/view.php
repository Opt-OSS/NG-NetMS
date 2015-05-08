<?php
/* @var $this AccessTypeController */
/* @var $model AccessType */

$this->breadcrumbs=array(
    'Access Types'=>array('index'),
    $model->name,
);

?>

<h1>View access type <?php echo $model->name; ?></h1>

<?php $this->widget('bootstrap.widgets.TbDetailView', array(
    'data'=>array('id'=>$model->id, 'name'=>$model->name),
    'attributes'=>array(
        array('name'=>'id', 'label'=>CHtml::encode($model->getAttributeLabel('id')),
            array('name'=>'name', 'label'=>CHtml::encode($model->getAttributeLabel('name'))),
        ),
    ),
));
?>
