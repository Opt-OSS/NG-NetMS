<?php

class AttrAccessController extends Controller
{
    /**
     * Render attributes for defined access type
     */
    public function actionIndex()
	{
        $acc_type_id = (int) Yii::app()->getRequest()->getParam('id');
        $attr_access = new AttrAccess('search');
        $attr_access->unsetAttributes();
        $attr_access->id_access_type = $acc_type_id;
        $arr_r = $attr_access->getAttrByAccType();
        $amount1 = count($arr_r);
        $arr_ing = array();


        for ($k1 = 0; $k1 < $amount1; $k1++) {
            $arr_ing[$k1]['id'] = $k1+1;
            $arr_ing[$k1]['name'] = $arr_r[$k1]['name'];
        }

        $this->renderPartial('_relational', array(
            'id' => $acc_type_id,
            'gridDataProvider' => new CArrayDataProvider($arr_ing),
            'gridColumns' => array(array('name' => 'id', 'header' => '#','value' => '$data["id"]','htmlOptions'=>array('width'=>'10%'),),
                array('name' => 'name', 'header' => 'Name', 'type' => 'raw', 'value' => '$data["name"]','htmlOptions'=>array('width'=>'25%'),),
            )
        ));
	}

}