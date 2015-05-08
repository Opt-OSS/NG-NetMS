<?php
//echo CHtml::tag('h3',array(),'RELATIONAL DATA EXAMPLE ROW : "'.$id.'"');
$this->widget('bootstrap.widgets.TbExtendedGridView', array(
'type'=>'striped bordered',
'dataProvider' => $gridDataProvider,
'template' => "{items}",
'columns' => $gridColumns,
));