<?php
/* @var $this RoutersController */

 
 $this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Routers'=>'index.php?r=routers/index', 'SW Report by revision'),
)); 

$imghtml=CHtml::image('images/csv32.png', 'csv');
echo CHtml::link($imghtml, array('swexportxls','type'=>'csv'),array ('class'=>'exportdatacsv' ));
$imghtml=CHtml::image('images/excel_32_01.png', 'xls');
echo CHtml::link($imghtml, array('swexportxls','type'=>'xls'),array ('class'=>'exportdataxls' ));
$imghtml=CHtml::image('images/pdf_32.png', 'pdf');
echo CHtml::link($imghtml, array('swexportpdf'),array ('class'=>'exportdatapdf' )); 
?>

<?php

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'striped bordered condensed',
        'id'              => 'report_sw_revision',
        'dataProvider'    => $modelsw->reportByRevision(),
        'filter'          => $modelsw,
        'enablePagination'=>true,
        'template'=>"{items}\n{pager}",
        'columns'         => array(
        array('name'=>'sw_item', 'header'=>'Item'),
        array('name'=>'sw_name', 'header'=>'Name'),
        array('name'=>'sw_version', 'header'=>'Version'),
        array('name'=>'router_name', 'header'=>'Routers'),
        ),
        
    ));

    
?>