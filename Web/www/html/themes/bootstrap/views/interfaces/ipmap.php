<?php
/* @var $this InterfacesController */


	$this->widget('bootstrap.widgets.TbBreadcrumbs', array(
        'links'=>array('Map'=>'index.php?r=routers/routermap', 'IP Map'),
        )) ;

?>
    <script>
        var mas ='<?php echo $arr_tree ?>';
        var mas1 = JSON.parse(mas);
        console.log(mas1);
    </script>
    <div id="treeViewDiv">
    </div>
