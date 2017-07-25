<?php

/**
 * Class RoutersGraphData is class to create Topology Map
 */
class RoutersGraphData extends CApplicationComponent
{
    public $_id_router;

    /**
     * get routers List
     *
     * @return array
     */
    public function getRoutersList()
    {
        $routers = Routers::model()->with('interfaces')->findAll();

        return $routers;
    }

    /**
     * get routers List  with Ph and Logical interfaces
     *
     * @return array
     */
    public function getRouterListWithInterfaces()
    {
        $routers = Routers::model()->with('interfaces')->with('PhInt')->findAll();

        return $routers;
    }

    /**
     * get coords of router from DB
     *
     * @param type $id_router
     *
     * @return type
     */
    public function getRouterCoords()
    {
        $coords = RouterGraph::model()->findByAttributes(array('router_id' => $this->_id_router));

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
        $hwinv = InvHw::model()->findAllByAttributes(array('router_id' => $this->_id_router));

        return $hwinv;
    }

    /**
     * Get sw inventory for defined router
     *
     * @return mixed
     */
    public function getSwInventory()
    {
        $swinv = InvSw::model()->findAllByAttributes(array('router_id' => $this->_id_router));

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
        $arr_ret           = array();
        $arr_size          = Yii::app()->db->createCommand()
                                           ->select('max(x) as xmax,max(y) as ymax,min(x) as xmin,min(y) as ymin')
                                           ->from('router_graph')
                                           ->queryAll();
        $arr_ret['x']      = $arr_size[0]['xmax'] - $arr_size[0]['xmin'];
        $arr_ret['y']      = $arr_size[0]['ymax'] - $arr_size[0]['ymin'];
        $arr_ret['x_norm'] = $arr_size[0]['xmin'];
        $arr_ret['y_norm'] = $arr_size[0]['ymin'];

        return $arr_ret;
    }



    /**
     *
     * from https://mebsd.com/coding-snipits/php-ipcalc-coding-subnets-ip-addresses.html
     */


    /**
     * convert cidr to netmask
     * e.g. 21 = 255.255.248.0
     *
     * @param string $cidr
     *
     * @return bool|string
     */
    public function cidr2netmask($cidr)
    {
        $bin = "";
        for ($i = 1; $i <= 32; $i ++) {
            $bin .= $cidr >= $i ? '1' : '0';
        }

        $netmask = long2ip(bindec($bin));

        if ($netmask == "0.0.0.0") {
            return false;
        }

        return $netmask;
    }

    /**
     * get network address from cidr subnet
     * e.g. 10.0.2.56/21 = 10.0.0.0
     *
     * @param string $ip
     * @param string $cidr
     *
     * @return string
     */
    public function cidr2network($ip, $cidr)
    {
        $network = long2ip(( ip2long($ip) ) & ( ( - 1 << ( 32 - (int) $cidr ) ) ));

        return $network;
    }


    /**
     * convert netmask to cidr
     * e.g. 255.255.255.128 = 25
     *
     * @param string $netmask
     *
     * @return int
     */
    public function netmask2cidr($netmask)
    {
        $bits    = 0;
        $netmask = explode(".", $netmask);

        foreach ($netmask as $octect) {
            $bits += strlen(str_replace("0", "", decbin($octect)));
        }

        return $bits;
    }

    /**
     * is ip in subnet
     *  e.g. is 10.5.21.30 in 10.5.16.0/20 == true
     *       is 192.168.50.2 in 192.168.30.0/23 == false
     *
     * @param $ip
     * @param $network
     * @param $cidr
     *
     * @return bool
     */
    public function cidr_match($ip, $network, $cidr)
    {
        if (( ip2long($ip) & ~( ( 1 << ( 32 - $cidr ) ) - 1 ) ) == ip2long($network)) {
            return true;
        }

        return false;
    }

}

