<?php

$this->widget('bootstrap.widgets.TbBreadcrumbs', array(
    'links' => array('Routers' => 'index.php?r=routers/index', 'SW Inventory'),
));
?>
<script type="text/javascript">
    var arr_sw_names = '<?php echo $sw_names;?>';
    var arr_sw_versions = '<?php echo $sw_versions;?>';
    var arr_sw_items = '<?php echo $sw_items;?>';   
</script>
<?php
$this->beginWidget('bootstrap.widgets.TbModal', array('id'=>'SwResSearch','htmlOptions' => array('style'=>'width: 900px;max-height:800px'))); ?>
 
        <div class="modal-header">
            <a class="close" data-dismiss="modal">&times;</a>
            <h4>SW Inventory : Search Results</h4>
        </div>

        <div class="modal-body">
        </div>       

        <div class="modal-footer">
            <?php $this->widget('bootstrap.widgets.TbButton', array(
                'label'=>'Close',
                'url'=>'#',
                'htmlOptions'=>array('data-dismiss'=>'modal'),
            )); ?>
        </div>

        <?php $this->endWidget(); ?>
<script>    
    
        function submitForm() {
            $.ajax({
                url     : '<?php echo Yii::app() -> createUrl('routers/swinventory'); ?>',
                type    : 'POST',
                data    : $('#inlineSwForm').serialize(),
                cache   : false,
                dataType:'json',
                success : function(data) {
                    var arr = data;
                    var htmlCont ='';
                            
                    if(arr.length > 0){

                        htmlCont += '<a class="exportdatacsv" href="/index.php?r=routers/swexportfindxls&type=csv&'+$('#inlineSwForm').serialize()+'"><img alt="csv" src="images/csv32.png"></a>';
                        htmlCont += '<a class="exportdataxls" href="/index.php?r=routers/swexportfindxls&type=xls&'+$('#inlineSwForm').serialize()+'"><img alt="xls" src="images/excel_32_01.png"></a>';
                        htmlCont += '<a class="exportdataxls" href="/index.php?r=routers/swexportfindpdf&'+$('#inlineSwForm').serialize()+'"><img alt="xls" src="images/pdf_32.png"></a>';

                                        }
                    htmlCont+='<div id="yw0" class="grid-view">'+
                    '<table class="items table table-bordered">'+
                    '<thead>'+
                    '<tr>'+
                    '<th id="yw0_c0">Item</th><th id="yw0_c1">Name</th><th id="yw0_c2">Version</th><th id="yw0_c3">Router</th></tr>'+
                    '</thead>'+
                    '<tbody>';
                    if(arr.length > 0)
                    {
                        for(i=0;i<arr.length;i++)
                        {
                            if(i % 2)
                            {
                                htmlCont+='<tr class="odd">';
                            }
                            else
                            {
                                htmlCont+='<tr class="even">';
                            }
                            htmlCont+= '<td>'+arr[i].item+'</td><td>'+arr[i].name+'</td><td>'+arr[i].version+'</td><td>'+arr[i].router_name+'</td></tr>'
                        }
                    }
                    else
                    {
                        htmlCont+='<tr class="odd">'+'<td colspan = 4>'+'<font color="red"><b>No results'+'</b></font></td></tr>'
                    }
                    htmlCont+='</tbody>'+
                    '</table>'+
                    '<div class="keys" style="display:none" title="/index.php?r=routers/hwinventory"><span>1</span><span>2</span></div>'+
                    '</div>';
                    $("#SwResSearch .modal-body ").html(htmlCont);
                    $("#SwResSearch").modal("show");
                    
                }
            });
        }   
</script>


<div style="width:840px;">
    <div style = "float:left; display:inline-block; margin-right : 160px;">
<?php    
$imghtml=CHtml::image('images/csv32.png', 'csv');
echo CHtml::link($imghtml, array('swinventoryexportxls','type'=>'csv'),array ('class'=>'exportdatacsv' ));
$imghtml=CHtml::image('images/excel_32_01.png', 'xls');
echo CHtml::link($imghtml, array('swinventoryexportxls','type'=>'xls'),array ('class'=>'exportdataxls' ));
$imghtml=CHtml::image('images/pdf_32.png', 'pdf');
echo CHtml::link($imghtml, array('swinventoryexportpdf'),array ('class'=>'exportdatapdf' ));
?>
</div>
    <div style ="float:left; display:inline-block;">    
        <?php

        $form = $this->beginWidget(
                'bootstrap.widgets.TbActiveForm', array(
            'id' => 'inlineSwForm',
            'type' => 'inline',
                )
        );
        $this->widget(
                'bootstrap.widgets.TbButtonGroup', array(
            'type' => 'primary',
            'toggle' => 'radio',
            'buttons' => array(
                array('label' => 'by Item','htmlOptions' => array(
                                            'data-field' => 'Model_serial',
                                            'data-value' => 3,
                        )),
                array('label' => 'by Name',
                      'active' => true,
                      'htmlOptions' => array(
                                 'data-field' => 'Model_name',
                                 'data-value' => 1,
                        )),
                array('label' => 'by Version','htmlOptions' => array(
                                            'data-field' => 'Model_serial',
                                            'data-value' => 2,
                        )),
            ),
                )
        );
        ?>
    <input type="hidden" name="tumbler" id="tumbler" value="1">
    </div>
    <div style = "float:right; display:inline-block;">    
        <?php
        $this->widget(
                'bootstrap.widgets.TbButton', array('buttonType' => 'ajaxSubmit', 'label' => 'Find SW',
                     'htmlOptions'=>array('onclick' => "js: submitForm();return false;"),)
        );
        ?>
    </div>
    <div style = "float:right; display:inline-block;">        
        <?php
        $this->widget(
                'bootstrap.widgets.TbTypeahead', array(
                'name' => 'hwtypeahead',
                'id' => 'hwcontsearch',
                'options' => array(
                'source' => new CJavaScriptExpression('
                            function () {
                                            var flag = $("#tumbler").val();
                                            if(flag == 1)
                                            {
                                                return JSON.parse(arr_sw_names);
                                            }
                                            else if(flag == 2)
                                            {
                                                return JSON.parse(arr_sw_versions);
                                            }
                                            else
                                            {
                                                return JSON.parse(arr_sw_items);
                                            }
                                        }'),
                'hint' => true,
                'highlight' => true,
                'minLength' => 1
            ),
                )
        );

        $this->endWidget();
        unset($form);
?>
        
    </div>
</div>
<?php
$gridColumns = array(array('name'=>'ip_addr', 'header'=>'IP address'));
$this->widget('bootstrap.widgets.TbExtendedGridView', array(
    'type' => 'striped bordered',
    'id' => 'hw-grid',
    'dataProvider' => new CArrayDataProvider($model),
    'enablePagination' => true,
    'template' => "{items}\n{pager}",
    'columns' => array_merge(array(
        array(
            'class' => 'bootstrap.widgets.TbRelationalColumn',
            'name' => 'name',
            'url' => $this->createUrl('routers/relationalsw'),
            'value' => '$data["name"]',
        )
            ), $gridColumns),
));
?>