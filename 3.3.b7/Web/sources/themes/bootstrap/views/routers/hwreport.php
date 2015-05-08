<?php
/* @var $this RoutersController */

 
 $this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Devices'=>'index.php?r=routers/index', 'Hw Report by part number'),
)); 
 /*$this->hw_data = $modelhw->reportByPartNumber();
                print_r($this->hw_data);*/
$imghtml=CHtml::image('images/csv32.png', 'csv');
echo CHtml::link($imghtml, array('hwexportxls','type'=>'csv'),array ('class'=>'exportdatacsv' ));
$imghtml=CHtml::image('images/excel_32_01.png', 'xls');
echo CHtml::link($imghtml, array('hwexportxls','type'=>'xls'),array ('class'=>'exportdataxls' ));
$imghtml=CHtml::image('images/pdf_32.png', 'pdf');
echo CHtml::link($imghtml, array('hwexportpdf'),array ('class'=>'exportdatapdf' ));
?>

<?php

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'striped bordered condensed',
        'id'              => 'report_hw_part_number',
        'dataProvider'    => $modelhw->reportByPartNumber(),
        'filter'          => $modelhw,
        'enablePagination'=>true,
        'template'=>"{items}\n{pager}",
        'columns'         => array(
        array('name'=>'hw_item', 'header'=>'Part Type'),
        array('name'=>'hw_name', 'header'=>'Name'),
        array('name'=>'amount', 'header'=>'Qtty','filter' => false,),
        array('name'=>'hw_version', 'header'=>'Serial numbers'),
        array('name'=>'router_name', 'header'=>'Devices'),
        ),
        
    ));

    
    
?>


