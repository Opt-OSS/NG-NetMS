<?php
 $this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links'=>array('Routers'=>'index.php?r=routers/index', 'HW Inventory'),
));

?>
<?php
/*echo "<pre>";
print_r($model);
echo "</pre>";*/

$this->widget('bootstrap.widgets.TbGridView', array(
        'type'            => 'striped bordered',
        'id'              => 'hw-grid',
        'dataProvider'    => new CArrayDataProvider($model),
        'enablePagination'=>true,
        'template'=>"{items}\n{pager}",
        'selectionChanged'=>"function(id){alert($.fn.yiiGridView.getSelection(id)); 
            var table = $('table');
alert(row.rowIndex);
                                                var curRow = $(this).closest('tr'),
                                                newRow = curRow.clone(true);
                                                console.log(newRow);
                                                curRow.after(newRow);
                                                console.log('added');
                             }",
        'columns'         => array(
        array('name'=>'name', 'header'=>'Name'),
        array('name'=>'id', 'value' => '$data["id"]',
              'headerHtmlOptions' => array('style'=>'display:none'),
              'htmlOptions' =>array('style'=>'display:none')),
        ),
        
    ));

 
 //   $groupGridColumns = $gridColumns;

  /*  $groupGridColumns[] = array(
    'name' => 'name',
    'value' => '$data["name"]',
    'headerHtmlOptions' => array('style'=>'display:none'),
    'htmlOptions' =>array('style'=>'display:none')
    );
     
    $this->widget('bootstrap.widgets.TbGroupGridView', array(
    'type'=>'striped bordered',
    'dataProvider' => $model,
    'enablePagination'=>true,
    'template' => "{items}\n{pager}",
    'extraRowColumns'=> array('name'),
    'extraRowExpression' => '"<b style=\"font-size: 2em; color: #333;\">".$data["name"]."</b>"',
    'extraRowHtmlOptions' => array('style'=>'padding:10px'),
    'columns' => array(array('name'=>'type', 'header'=>'Part Type'),
        array('name'=>'details', 'header'=>'Details'),
        )
    ));*/
?>