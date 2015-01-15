<?php
$this->widget('bootstrap.widgets.TbExtendedGridView', array(
'type'=>'striped bordered',
'dataProvider' => $gridDataProvider,
'template' => "{items}",
'columns' => $gridColumns,
));