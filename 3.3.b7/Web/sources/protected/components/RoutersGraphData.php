<?php

/**
 * Class RoutersGraphData is class to create Topology Map
 */
class RoutersGraphData extends CApplicationComponent
{
    public $_id_router ;
    
    /**
     * get routers List
     *
     * @return array
     */
    public function getRoutersList()
    {
        $routers=Routers::model()->with('interfaces')->findAll();
        
        return $routers;
    }
 
    /**
     * get coords of router from DB
     * 
     * @param type $id_router
     * @return type
     */
    public function getRouterCoords()
    {
        $coords= RouterGraph::model()->findByAttributes(array('router_id'=>$this->_id_router));
        
        return $coords;
    }

    /**
     * Get edges list
     *
     * @return mixed
     */
    public function getEdgesList()
    {
        $edges = Network::model()->findAll();
        
        return $edges;
    }

    /**
     * Get all rows contain data about hardware inventory
     *
     * @return mixed
     */
    public function getHwInventoryAll()
    {
        $hwinv = InvHw::model()->findAll();
        
        return $hwinv;
    }

    /**
     * Get hw inventory for defined router
     *
     * @return mixed
     */
    public function getHwInventory()
    {
        $hwinv = InvHw::model()->findAllByAttributes(array('router_id'=>$this->_id_router));
        
        return $hwinv;
    }

    /**
     * Get sw inventory for defined router
     *
     * @return mixed
     */
    public function getSwInventory()
    {
        $swinv = InvSw::model()->findAllByAttributes(array('router_id'=>$this->_id_router));
        
        return $swinv;
    }


    /**
     * set current router id
     *
     * @param $id_router
     */
    public function setIdRouter($id_router)
    {
        $this->_id_router = $id_router;
    }

    /**
     * calculate graph size
     *
     * @return array
     */
    public function getGraphSize()
    {
        $arr_ret = array();
        $arr_size = Yii::app()->db->createCommand()
                ->select('max(x) as xmax,max(y) as ymax,min(x) as xmin,min(y) as ymin')
                ->from('router_graph')
                ->queryAll();
        $arr_ret['x'] = $arr_size[0]['xmax'] - $arr_size[0]['xmin'];
        $arr_ret['y'] = $arr_size[0]['ymax'] - $arr_size[0]['ymin'];
        $arr_ret['x_norm'] = $arr_size[0]['xmin'];
        $arr_ret['y_norm'] = $arr_size[0]['ymin'];
        
        return $arr_ret;
    }
}

