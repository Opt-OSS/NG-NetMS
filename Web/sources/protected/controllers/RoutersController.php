<?php

class RoutersController extends Controller {
    /**
     * render main page for routers
     * 
     * @throws CHttpException
     */
    public function actionIndex() {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                $model = new Routers('search');
                $model->unsetAttributes();
                if (isset($_GET['Routers']))
                    $model->attributes = $_GET['Routers'];

                $this->render('index', array(
                    'model' => $model,
                ));
            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * view details for selected routers
     * 
     * @throws CHttpException
     */
    public function actionView() {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                $arr_prenodes = array();
                $arr_nodes = array();
                $arr_edges = array();
                $arr_ret = array();
                $cs = Yii::app()->clientScript;
                $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/routers.js', CClientScript::POS_HEAD);
                $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/routerviewtab.js', CClientScript::POS_END);
                if (Yii::app()->request->isAjaxRequest) {
                    $this->renderPartial('view', array(
                        'model' => $this->loadModel($_GET['id']),
                            ), false, true);
                } else {
                    // get router id                   
                    $router_id = $_GET['id'];   // get router id      
                    $model = $this->loadModel($router_id);  // load model
                    $arr_net = array_merge($model->networks, $model->networks1); // create array with all relations for selected router
                    $k = 0;

                    // created arrays of nodes and array of edges

                    for ($i = 0; $i < count($arr_net); $i++) {
                        $arr_prenodes[] = $arr_net[$i]->router_id_a;
                        $arr_prenodes[] = $arr_net[$i]->router_id_b;
                        $arr_edges[$k]['src'] = $arr_net[$i]->router_id_a;
                        $arr_edges[$k]['dest'] = $arr_net[$i]->router_id_b;
                        $k++;
                    }

                    $arr_prenodes[] = $_GET['id'];
                    $arr_prenodes = array_unique($arr_prenodes);
                    $k1 = 0;
                    $arr_perekod = array();

                    foreach ($arr_prenodes as $node) {
                        $router = Routers::model()->findByPk($node);
                        $arr_perekod[$router->router_id] = $router->name;
                        $arr_nodes[$k1]['name'] = $router->name;
                        $vendor_name = trim($router->eq_vendor);
                        // define color of router
                        $cur_state = strtoupper(trim($router->status));
                        if(empty($cur_state))
                        {
                            $cur_state = 'UNKNOWN';
                        }
                        $rt_state = RouterStates::model()->findByAttributes(array('name'=>$cur_state));
                        $amount = RouterIcons::model()->isImg($rt_state->id, $vendor_name,$router->layer);
                        if($amount < 1)
                        {
                            if(!isset($vendor_name) || empty($vendor_name) )
                            {
                                $vendor_name = "DEFAULT";
                            }
                            else if(preg_match("/nix/i", $vendor_name) || preg_match("/ubuntu/i", $vendor_name))
                            {
                                $vendor_name = "Linux";
                            }
                        }

                        $cur_icons = RouterIcons::model()->findByAttributes(array('vendor_name'=>$vendor_name,'router_state'=>$rt_state->id,'layer'=>$router->layer));
                        $arr_nodes[$k1]['data']['image'] = Yii::app()->baseUrl . '/images' .$cur_icons->img_path;
                        $arr_nodes[$k1]['data']['image_w'] = $cur_icons->size_w;
                        $arr_nodes[$k1]['data']['image_h'] = $cur_icons->size_h;

                        $k1++;
                    }

                    $amount_edge = count($arr_edges);
                    if ($amount_edge > 0) {
                        for ($j1 = 0; $j1 < $amount_edge; $j1++) {
                            $fk = $arr_edges[$j1]['src'];
                            $arr_edges[$j1]['src'] = $arr_perekod[$fk];
                            $fk1 = $arr_edges[$j1]['dest'];
                            $arr_edges[$j1]['dest'] = $arr_perekod[$fk1];
                        }
                    }


                    // selected information about router interfaces 
                    $arr_interfaces = array();
                    $arr_ph_interfaces = array();
                    $k2 = 0;
                    $k3 = 0;
                    if (count($model->interfaces) > 0) {
                        $amount_ph_int = count($model->phInts);
                        if ($amount_ph_int > 0) {
                            foreach ($model->phInts as $phInterface) {
                                $arr_ph_interfaces[$phInterface->ph_int_id]['id'] = $k3 + 1;
                                $arr_ph_interfaces[$phInterface->ph_int_id]['name'] = $phInterface->name;
                                $arr_ph_interfaces[$phInterface->ph_int_id]['state'] = CHtml::openTag('font', array('encode' => false, 'style' => 'color:' . Yii::app()->params['colorsStatus'][$phInterface->state])) . $phInterface->state . CHtml::closeTag('font');
                                $arr_ph_interfaces[$phInterface->ph_int_id]['status'] = CHtml::openTag('font', array('encode' => false, 'style' => 'color:' . Yii::app()->params['colorsStatus'][$phInterface->condition])) . $phInterface->condition . CHtml::closeTag('font');
                                $arr_ph_interfaces[$phInterface->ph_int_id]['speed'] = $phInterface->speed;
                                $arr_ph_interfaces[$phInterface->ph_int_id]['colorstate'] = Yii::app()->params['colorsStatus'][$phInterface->state];
                                $arr_ph_interfaces[$phInterface->ph_int_id]['colorstatus'] = Yii::app()->params['colorsStatus'][$phInterface->condition];
                                $arr_ph_interfaces[$phInterface->ph_int_id]['descr'] = $phInterface->descr;
                                $k3++;
                            }
                        }
                        foreach ($model->interfaces as $interf) {
                            $arr_interfaces[$k2]['id'] = $k2 + 1;
                            ;
                            $arr_interfaces[$k2]['name'] = $interf->name;
                            $arr_interfaces[$k2]['ip_addr'] = $interf->ip_addr;
                            $arr_interfaces[$k2]['mask'] = $interf->mask;
                            $arr_interfaces[$k2]['state'] = CHtml::openTag('font', array('encode' => false, 'style' => 'color:' . $arr_ph_interfaces[$interf->ph_int_id]['colorstate'])) . $arr_ph_interfaces[$interf->ph_int_id]['state'] . CHtml::closeTag('font');
                            $arr_interfaces[$k2]['status'] = CHtml::openTag('font', array('encode' => false, 'style' => 'color:' . $arr_ph_interfaces[$interf->ph_int_id]['colorstatus'])) . $arr_ph_interfaces[$interf->ph_int_id]['status'] . CHtml::closeTag('font');
                            $arr_interfaces[$k2]['speed'] = $arr_ph_interfaces[$interf->ph_int_id]['speed'];
                            $arr_interfaces[$k2]['descr'] = $interf->descr;
                            $k2++;
                        }
                    }
/*ksort($arr_ph_interfaces);
echo "<pre>";
print_r($arr_ph_interfaces);
echo "</pre>";
exit;*/
                    // get info abou HW invertory
                    Yii::app()->graph->setIdRouter($router_id);
                    $invHws = Yii::app()->graph->HwInventory;
                    $amount1 = count($invHws);
                    $arr_hwi = array();

                    for ($k1 = 0; $k1 < $amount1; $k1++) {
                        $arr_hwi[$k1]['id'] = $k1 + 1;
                        $arr_hwi[$k1]['type'] = $invHws[$k1]->hw_item;
                        $arr_hwi[$k1]['details'] = $invHws[$k1]->hw_name . " " . $invHws[$k1]->hw_version . " " . $invHws[$k1]->hw_amount;
                    }

                    // get info abou SW invertory
                    $invSws = Yii::app()->graph->SwInventory;
                    $amount2 = count($invSws);
                    $arr_swi = array();

                    for ($k2 = 0; $k2 < $amount2; $k2++) {
                        $arr_swi[$k2]['id'] = $k2 + 1;
                        $arr_swi[$k2]['type'] = $invSws[$k2]->sw_item;
                        $arr_swi[$k2]['name'] = $invSws[$k2]->sw_name;
                        $arr_swi[$k2]['version'] = $invSws[$k2]->sw_version;
                    }

                    // create arrays to show 
                    $gridDataProvider_i = new CArrayDataProvider($arr_interfaces, array(
                        'pagination' => array(
                            'pageSize' => 50,
                        )
                    ));
                    $gridDataProvider_h = new CArrayDataProvider($arr_hwi, array(
                        'pagination' => array(
                            'pageSize' => 50,
                        )
                    ));
                    $gridDataProvider_s = new CArrayDataProvider($arr_swi, array(
                        'pagination' => array(
                            'pageSize' => 50,
                        )
                    ));
                    
                    $gridDataProvider_p = new CArrayDataProvider($arr_ph_interfaces, array(
                        'pagination' => array(
                            'pageSize' => 150,
                        )
                    ));
                    
                    // get configuration 
                    $config0 = RouterConfiguration::model()->getRouterCurrentConfig($router_id);
                    if($config0)
                    {
                        $config =  RouterConfiguration::model()->findByAttributes(array('id'=>$config0['id']));
                    }
                    else
                    {
                        $config = false;
                    }
                    
                    $arr_ret = array('nodes' => $arr_nodes, 'edges' => $arr_edges);
                    $this->render('view', array(
                        'model' => $model,
                        'arr_json' => json_encode($arr_ret),
                        'interfaces' => $gridDataProvider_i,
                        'phinterfaces' => $gridDataProvider_p,
                        'hw_inventory' => $gridDataProvider_h,
                        'sw_inventory' => $gridDataProvider_s,
                        'current_config' => $config,
                    ));
                }
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Create HW Inventory
     *
     * @throws CHttpException
     */
    public function actionHwinventory() {

        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                if (Yii::app()->request->isAjaxRequest && isset($_POST['tumbler'])) {
                    $modelhw = new InvHw();
                    if ($_POST['tumbler'] == 1) {
                        $data = $modelhw->searchByName($_POST['hwtypeahead']);
                    } else {
                        $data = $modelhw->searchByVersion($_POST['hwtypeahead']);
                    }
                    
                    echo json_encode($data);
                } else {
                    $cs = Yii::app()->clientScript;
                    $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/buttonGroup.js', CClientScript::POS_END);
                    $arr_hw = array();
                    $arr_hw_name = array();
                    $arr_hw_version = array();
                    $arr_hw_name_ret = array();
                    $arr_hw_version_ret = array();
                    $model = new Routers('search');
                    $model->unsetAttributes();

                    if (isset($_GET['Routers']))
                        $model->attributes = $_GET['Routers'];

                    $model1 = Routers::model()->findAll();
                    $i = 0;
                    $j = 0;
                    $j1 = 0;
                    foreach ($model1 as $router) {
                        $arr_hw[$i]['id'] = $router['router_id'];
                        $arr_hw[$i]['name'] = $router['name'];
                        $arr_hw[$i]['ip_addr'] = $router['ip_addr'];
                        $i++;
                        Yii::app()->graph->setIdRouter($router['router_id']);
                        $invHws = Yii::app()->graph->HwInventory;
                        $amount1 = count($invHws);
                        /* variant for hwinventory1.php */
                        for ($k1 = 0; $k1 < $amount1; $k1++) {
                            /* $arr_hw[$i]['id'] = $router['router_id'];
                              $arr_hw[$i]['name'] = $router['name'];
                              $arr_hw[$i]['type'] = $invHws[$k1]->hw_item;
                              $arr_hw[$i]['details'] = $invHws[$k1]->hw_name . " " . $invHws[$k1]->hw_version . " " . $invHws[$k1]->hw_amount;
                              $i++; */
                            if (!empty($invHws[$k1]->hw_name)) {
                                $arr_hw_name[$j] = trim($invHws[$k1]->hw_name);
                                $j++;
                            }

                            if (!empty($invHws[$k1]->hw_version)) {
                                $arr_hw_version[$j1] = trim($invHws[$k1]->hw_version);
                                $j1++;
                            }
                        }
                        /**/
                    }

                    $arr_hw_name = array_unique($arr_hw_name);
                    $arr_hw_version = array_unique($arr_hw_version);

                    foreach ($arr_hw_name as $valore) {
                        if (!empty($valore))
                            $arr_hw_name_ret[] = $valore;
                    }

                    foreach ($arr_hw_version as $valore) {
                        if (!empty($valore))
                            $arr_hw_version_ret[] = $valore;
                    }

                    $model_hw = Yii::app()->graph->HwInventoryAll;
                    $this->render('hwinventory', array(
                        //    variant for hwinventory1.php              'model' => new CArrayDataProvider($arr_hw),
                        'model' => $arr_hw,
                        'model_hw' => $model_hw,
                        'hw_names' => json_encode($arr_hw_name_ret),
                        'hw_versions' => json_encode($arr_hw_version_ret),
                    ));
                }
            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Create SW inventory
     *
     * @throws CHttpException
     */
    public function actionSwinventory() {

        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                if (Yii::app()->request->isAjaxRequest &&  isset($_POST['tumbler'])) {
                    $modelsw = new InvSw();
                    if ($_POST['tumbler'] == 1) {
                        $data = $modelsw->searchByName($_POST['hwtypeahead']);
                    } else if ($_POST['tumbler'] == 2) {
                        $data = $modelsw->searchByVersion($_POST['hwtypeahead']);
                    } else {
                        $data = $modelsw->searchByItem($_POST['hwtypeahead']);
                    }

                    echo json_encode($data);
                } else {
                    $cs = Yii::app()->clientScript;
                    $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/buttonGroup.js', CClientScript::POS_END);
//                    $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/exportpdf.js', CClientScript::POS_HEAD);
                    $arr_sw = array();
                    $arr_sw_name = array();
                    $arr_sw_version = array();
                    $arr_sw_item = array();
                    $arr_sw_name_ret = array();
                    $arr_sw_version_ret = array();
                    $arr_sw_item_ret = array();
                    $model = new Routers('search');
                    $model->unsetAttributes();
                    if (isset($_GET['Routers']))
                        $model->attributes = $_GET['Routers'];

                    $model1 = Routers::model()->findAll();
                    $i = 0;
                    $j = 0;
                    $j1 = 0;
                    $j2 = 0;

                    foreach ($model1 as $router) {
                        $arr_sw[$i]['id'] = $router['router_id'];
                        $arr_sw[$i]['name'] = $router['name'];
                        $arr_sw[$i]['ip_addr'] = $router['ip_addr'];
                        $i++;
                        Yii::app()->graph->setIdRouter($router['router_id']);
                        $invSws = Yii::app()->graph->SwInventory;
                        $amount1 = count($invSws);
                        for ($k1 = 0; $k1 < $amount1; $k1++) {
                            if (!empty($invSws[$k1]->sw_name)) {
                                $arr_sw_name[$j] = trim($invSws[$k1]->sw_name);
                                $j++;
                            }

                            if (!empty($invSws[$k1]->sw_version)) {
                                $arr_sw_version[$j1] = trim($invSws[$k1]->sw_version);
                                $j1++;
                            }

                            if (!empty($invSws[$k1]->sw_item)) {
                                $arr_sw_item[$j1] = trim($invSws[$k1]->sw_item);
                                $j1++;
                            }
                        }
                    }

                    $arr_sw_name = array_unique($arr_sw_name);
                    $arr_sw_version = array_unique($arr_sw_version);
                    $arr_sw_item = array_unique($arr_sw_item);

                    foreach ($arr_sw_name as $valore) {
                        if (!empty($valore))
                            $arr_sw_name_ret[] = $valore;
                    }

                    foreach ($arr_sw_version as $valore) {
                        if (!empty($valore))
                            $arr_sw_version_ret[] = $valore;
                    }

                    foreach ($arr_sw_item as $valore) {
                        if (!empty($valore))
                            $arr_sw_item_ret[] = $valore;
                    }

                    $this->render('swinventory', array(
                        'model' => $arr_sw,
                        'sw_names' => json_encode($arr_sw_name_ret),
                        'sw_versions' => json_encode($arr_sw_version_ret),
                        'sw_items' => json_encode($arr_sw_item_ret),
                    ));
                }
            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }


    /**
     * Render "_relational" view for HW
     */
    public function actionRelationalhw() {
        // partially rendering "_relational" view
        Yii::app()->graph->setIdRouter(Yii::app()->getRequest()->getParam('id'));
        $invHws = Yii::app()->graph->HwInventory;
        $amount1 = count($invHws);
        $arr_hw = array();

        for ($k1 = 0; $k1 < $amount1; $k1++) {
            $arr_hw[$k1]['id'] = $k1 + 1;
            $arr_hw[$k1]['type'] = $invHws[$k1]->hw_item;
            //                  $arr_hw[$k1]['details'] = $invHws[$k1]->hw_name . " " . $invHws[$k1]->hw_version . " " . $invHws[$k1]->hw_amount;
            $arr_hw[$k1]['name'] = $this->setNoEmptyValue($invHws[$k1]->hw_name);
            $arr_hw[$k1]['version'] = $this->setNoEmptyValue($invHws[$k1]->hw_version);
            $arr_hw[$k1]['amount'] = $this->setNoEmptyValue($invHws[$k1]->hw_amount);
        }

        $this->renderPartial('_relational', array(
            'id' => Yii::app()->getRequest()->getParam('id'),
            'gridDataProvider' => new CArrayDataProvider($arr_hw),
            'gridColumns' => array(array('name' => 'type', 'header' => 'Part Type','htmlOptions'=>array('width'=>'25%'),),
                //                        array('name'=>'details', 'header'=>'Details'),
                array('name' => 'name', 'header' => 'Name', 'type' => 'raw', 'value' => '$data["name"]','htmlOptions'=>array('width'=>'25%'),),
                array('name' => 'version', 'header' => 'Details/Serial Number', 'type' => 'raw', 'value' => '$data["version"]','htmlOptions'=>array('width'=>'25%'),),
                array('name' => 'amount', 'header' => 'Info', 'type' => 'raw', 'value' => '$data["amount"]','htmlOptions'=>array('width'=>'25%'),),
            )
        ));
    }

    /**
     * Render "_relational" view for SW
     */
    public function actionRelationalsw() {
        // partially rendering "_relational" view
        Yii::app()->graph->setIdRouter(Yii::app()->getRequest()->getParam('id'));
        $invSws = Yii::app()->graph->SwInventory;
        $amount1 = count($invSws);
        $arr_sw = array();

        for ($k1 = 0; $k1 < $amount1; $k1++) {
            $arr_sw[$k1]['id'] = $k1 + 1;
            $arr_sw[$k1]['type'] = $invSws[$k1]->sw_item;
            $arr_sw[$k1]['name'] = $invSws[$k1]->sw_name;
            $arr_sw[$k1]['version'] = $invSws[$k1]->sw_version;
        }

        $this->renderPartial('_relational', array(
            'id' => Yii::app()->getRequest()->getParam('id'),
            'gridDataProvider' => new CArrayDataProvider($arr_sw),
            'gridColumns' => array(array('name' => 'type', 'header' => 'Type','htmlOptions'=>array('width'=>'20%'),),
                array('name' => 'name', 'header' => 'Name','htmlOptions'=>array('width'=>'60%'),),
                array('name' => 'version', 'header' => 'Version','htmlOptions'=>array('width'=>'20%'),),
            )
        ));
    }

    /**
     * Render router map
     *
     * @throws CHttpException
     */
    public function actionRoutermap() {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewMap')) {
                $cs = Yii::app()->clientScript;
                $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/routers.js', CClientScript::POS_HEAD);
                $arr_json = array();
                $arr_nodes = array();
                $arr_nodes1 = array();
                $arr_edges = array();
                $arr_ret = array();

// Start graph
                // define size of graph's window 
                $schema = array('x' => '2214', 'y' => '1600');
                // get list of routers
                $arr_routers = Yii::app()->graph->RoutersList;

// Build array of nodes

                foreach ($arr_routers as $router) {
                    $i = (int) $router->router_id;
                    $arr_nodes[$i]['name'] = $router->name;
                    $vendor_name = trim($router->eq_vendor);
                    $cur_state = strtoupper(trim($router->status));
                    if(empty($cur_state))
                    {
                        $cur_state = 'UNKNOWN';
                    }
                    $rt_state = RouterStates::model()->findByAttributes(array('name'=>$cur_state));
                    $amount = RouterIcons::model()->isImg($rt_state->id, $vendor_name,$router->layer);
                    if($amount < 1)
                    {
                        if(!isset($vendor_name) || empty($vendor_name) )
                        {
                            $vendor_name = "DEFAULT";
                        }
                        else if(preg_match("/unix/i", $vendor_name) || preg_match("/ubuntu/i", $vendor_name))
                        {
                            $vendor_name = "Linux";
                        }
                    }

                    $cur_icons = RouterIcons::model()->findByAttributes(array('vendor_name'=>$vendor_name,'router_state'=>$rt_state->id,'layer'=>$router->layer));
/*                    echo $vendor_name."<br>";
                    print_r($cur_icons);
                    echo "<br>";*/
                    $arr_nodes[$i]['data']['image'] = Yii::app()->baseUrl . '/images' .$cur_icons->img_path;
                    $arr_nodes[$i]['data']['image_w'] = $cur_icons->size_w;
                    $arr_nodes[$i]['data']['image_h'] = $cur_icons->size_h;
                }

// Get list of edges
                $edges_list = Yii::app()->graph->EdgesList;
                $j = 0;

// Build array of edges

                foreach ($edges_list as $eedge) {
                    $arr_edges[$j]['src'] = $arr_nodes[$eedge->router_id_a]['name'];
                    $arr_edges[$j]['dest'] = $arr_nodes[$eedge->router_id_b]['name'];
                    if (isset(Yii::app()->params['colorsEdge'][$eedge->link_type])) {
                        $arr_edges[$j]['data']['color'] = Yii::app()->params['colorsEdge'][$eedge->link_type];
                    } else {
                        $arr_edges[$j]['data']['color'] = Yii::app()->params['colorsEdge']['D'];
                    }
                    $j++;
                }

                foreach ($arr_nodes as $nodes1) {
                    $arr_nodes1[] = $nodes1;
                }

// Define size of graph's window 
                if (count($arr_nodes1) > 50) {
                    $schema = array('x' => '2214', 'y' => '1600');
                } else {
                    $schema = array('x' => '1107', 'y' => '800');
                }

                $arr_ret = array('nodes' => $arr_nodes1, 'edges' => $arr_edges);
                $this->render('map', array(
                    'arr_json' => json_encode($arr_ret),
                    'schema' => $schema,
                ));
// End graph                
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Render Topology map
     */
    public function actionTopologymap()
    {
        
        $arr_json = array();
        $arr_nodes = array();
        $arr_nodes1 = array();
        $arr_edges = array();
        $arr_ret = array();
        $schema = array('x' => '1107', 'y' => '600');
        $cs = Yii::app()->clientScript;
        $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/site.js', CClientScript::POS_HEAD);
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewMap')) {
                $schema = Yii::app()->graph->GraphSize;

                if ($schema['x'] < 1107) {
                    $schema['x'] = 1107;
                }

                if ($schema['y'] < 600) {
                    $schema['y'] = 600;
                }

                $koef_norm_x = $schema['x_norm'];
                $koef_norm_y = $schema['y_norm'];
                
                $arr_routers = Yii::app()->graph->RoutersList;

                foreach ($arr_routers as $router) {
                    $i = (int) $router->router_id;
                    $arr_nodes[$i]['name'] = $router->name;
                    $vendor_name = trim($router->eq_vendor);
                    $arr_nodes[$i]['data']['eq_vendor'] = $vendor_name;
                    $arr_nodes[$i]['data']['eq_type'] = trim($router->eq_type);
// Define router icon
                    $cur_state = strtoupper(trim($router->status));
                    if(empty($cur_state))
                    {
                        $cur_state = 'UNKNOWN';
                    }
                    $rt_state = RouterStates::model()->findByAttributes(array('name'=>$cur_state));
                    $amount = RouterIcons::model()->isImg($rt_state->id, $vendor_name,$router->layer);
                    if($amount < 1)
                    {
                        if(!isset($vendor_name) || empty($vendor_name) )
                        {
                            $vendor_name = "DEFAULT";
                        }
                        else if(preg_match("/nix/i", $vendor_name) || preg_match("/ubuntu/i", $vendor_name))
                        {
                            $vendor_name = "Linux";
                        }
                    }

                    $cur_icons = RouterIcons::model()->findByAttributes(array('vendor_name'=>$vendor_name,'router_state'=>$rt_state->id,'layer'=>$router->layer));
                    $arr_nodes[$i]['data']['image'] = Yii::app()->baseUrl . '/images' .$cur_icons->img_path;
                    $arr_nodes[$i]['data']['image_w'] = $cur_icons->size_w;
                    $arr_nodes[$i]['data']['image_h'] = $cur_icons->size_h;
                    Yii::app()->graph->setIdRouter($router->router_id);
                    $coords = Yii::app()->graph->RouterCoords;
                    $arr_nodes[$i]['data']['coordx'] = $coords->x - $koef_norm_x + $arr_nodes[$i]['data']['image_w'];
                    $arr_nodes[$i]['data']['coordy'] = $coords->y - $koef_norm_y + $arr_nodes[$i]['data']['image_w'];
                    $amount = count($router->interfaces);

                    for ($k = 0; $k < $amount; $k++) {
                        $arr_nodes[$i]['data']['interfaces'][$k]['name'] = $router->interfaces[$k]->name;
                        $arr_nodes[$i]['data']['interfaces'][$k]['ip_addr'] = $router->interfaces[$k]->ip_addr;
                        $arr_nodes[$i]['data']['interfaces'][$k]['mask'] = $router->interfaces[$k]->mask;
                    }

                    $invHws = Yii::app()->graph->HwInventory;
                    $amount1 = count($invHws);

                    for ($k1 = 0; $k1 < $amount1; $k1++) {
                        $arr_nodes[$i]['data']['hw'][$k1]['type'] = $invHws[$k1]->hw_item;
                        $arr_nodes[$i]['data']['hw'][$k1]['details'] = $invHws[$k1]->hw_name . " " . $invHws[$k1]->hw_version . " " . $invHws[$k1]->hw_amount;
                    }

                    $invSws = Yii::app()->graph->SwInventory;

                    $amount2 = count($invSws);

                    for ($k2 = 0; $k2 < $amount2; $k2++) {
                        $arr_nodes[$i]['data']['sw'][$k2]['type'] = $invSws[$k2]->sw_item;
                        $arr_nodes[$i]['data']['sw'][$k2]['name'] = $invSws[$k2]->sw_name;
                        $arr_nodes[$i]['data']['sw'][$k2]['version'] = $invSws[$k2]->sw_version;
                    }
                }

                $edges_list = Yii::app()->graph->EdgesList;
                $j = 0;

                foreach ($edges_list as $eedge) {
                    $arr_edges[$j]['src'] = $arr_nodes[$eedge->router_id_a]['name'];
                    $arr_edges[$j]['dest'] = $arr_nodes[$eedge->router_id_b]['name'];
                    if (isset(Yii::app()->params['colorsEdge'][$eedge->link_type])) {
                        $arr_edges[$j]['data']['color'] = Yii::app()->params['colorsEdge'][$eedge->link_type];
                    } else {
                        $arr_edges[$j]['data']['color'] = Yii::app()->params['colorsEdge']['D'];
                    }

                    $arr_edges[$j]['data']['coordx1'] = $arr_nodes[$eedge->router_id_a]['data']['coordx'];
                    $arr_edges[$j]['data']['coordy1'] = $arr_nodes[$eedge->router_id_a]['data']['coordy'];
                    $arr_edges[$j]['data']['coordx2'] = $arr_nodes[$eedge->router_id_b]['data']['coordx'];
                    $arr_edges[$j]['data']['coordy2'] = $arr_nodes[$eedge->router_id_b]['data']['coordy'];
                    $j++;
                }

                foreach ($arr_nodes as $nodes1) {
                    $arr_nodes1[] = $nodes1;
                }
            }
        }

        $arr_ret = array("nodes" => $arr_nodes1, "edges" => $arr_edges);

        $this->render('topology', array(
            'schema' => $schema,
            'arr_json' => json_encode($arr_ret),
        ));
    }

    /**
     * Render results of  searching HW  by part number
     *
     * @throws CHttpException
     */
    public function actionHwbypartnumber() {
        $arr_ret = array();
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
//                 $cs = Yii::app()->clientScript;
//                 $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/exportdata.js', CClientScript::POS_END);
                $modelhw = new InvHw('search');
                $modelhw->unsetAttributes();
    
                if (isset($_GET['InvHw']))
                    $modelhw->attributes = $_GET['InvHw'];

                $this->render('hwreport', array(
                    'modelhw' =>   $modelhw,
                    ));
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }


    /**
     * Render results of searching SW by part number
     *
     * @throws CHttpException
     */
    public function actionSwbyrevision() {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                $modelsw = new InvSw('search');              
                $modelsw->unsetAttributes();
    
                if (isset($_GET['InvSw']))
                    $modelsw->attributes = $_GET['InvSw'];

                $this->render('swreport', array(
                   'modelsw' =>   $modelsw,
                ));
            } else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Render view configuration
     *
     * @throws CHttpException
     */
    public function actionViewconf()
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                $model = new Routers('search');
                $model->unsetAttributes();
                if (isset($_GET['Routers']))
                    $model->attributes = $_GET['Routers'];

                $this->render('viewconf', array(
                    'model' => $model,
                ));
            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Render compare two configurations
     *
     * @throws CHttpException
     */
    public function actionConfiguration(){
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('viewAssets')) {
                $baseUrl = Yii::app()->baseUrl; 
                $cs = Yii::app()->clientScript;
                $cs->registerCssFile($baseUrl.'/css/style_diff.css');
                $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/diffconf.js', CClientScript::POS_END);
                $config = array();
                $config1_content = '';
                $config2 = array();
                $diffs = '';
                $flag_alert = 0;
                $flag = 0;
                $dat_conf1 = '';
                $dat_conf2 = '';
                $model = new RouterConfiguration('search');
                $model->unsetAttributes();
                $model1 = new RouterConfigurationCompare('search');
                $model1->unsetAttributes();
                $router_id = $_GET['id'];
                $router = Routers::model()->findByPk($router_id);
                $config0 = RouterConfiguration::model()->getRouterCurrentConfig($router_id);
                if($config0)
                {
                    $config =  RouterConfiguration::model()->findByAttributes(array('id'=>$config0['id']));
                    $configs = RouterConfiguration::model()->findAllByAttributes(array('router_id'=>$router_id),array('order'=>'created desc'));
                    $arr_conf = CHtml::listData($configs, 'id', 'configname');

                    if(isset($arr_conf[$config0['id']]))
                    {
                        $arr_conf[$config0['id']] = 'Current configuration';
                    }

                    $configs1 = RouterConfigurationCompare::model()->findAllByAttributes(array('router_id'=>$router_id),array('order'=>'created desc'));
                    $arr_conf1 = CHtml::listData($configs1, 'id', 'configname');

                    if(isset($arr_conf1[$config0['id']]))
                    {
                        $arr_conf1[$config0['id']] = 'Current configuration';
                    }

                    if (isset($_POST['RouterConfiguration']) && !empty($_POST['RouterConfiguration']['id']))
                    {
                        $model->attributes = $_POST['RouterConfiguration'];
                        $arr_v1 = $_POST['RouterConfiguration'];
                        $config1 =  RouterConfiguration::model()->findByAttributes(array('id'=>$arr_v1['id']));

                        if($config1->attributes['created'] != $config0['created'])
                            $dat_conf1 = "Changes from ".$config1->attributes['created'];
                        else
                            $dat_conf1 = "Current configuration (original)";

                        $flag++;
                    }
                    else if(isset($_POST['RouterConfiguration']) && empty($_POST['RouterConfiguration']['id']))
                    {
                        $flag_alert = 1;

                    }

                    if (isset($_POST['RouterConfigurationCompare']) && !empty($_POST['RouterConfigurationCompare']['id']) )
                    {
                        $model1->attributes = $_POST['RouterConfigurationCompare'];
                        $arr_v2 = $_POST['RouterConfigurationCompare'];
                        $config2 =  RouterConfiguration::model()->findByAttributes(array('id'=>$arr_v2['id']));

                        if($config2->attributes['created'] != $config0['created'])
                            $dat_conf2 = "Changes from ".$config2->attributes['created'];
                        else
                            $dat_conf2 = "Current configuration (original)";

                        $flag++;
                    }
                    else if( isset($_POST['RouterConfigurationCompare']) && empty($_POST['RouterConfigurationCompare']['id']))
                    {

                        $flag_alert = 1;
                    }

                    if($flag_alert == 1)
                    {
                        $flag = 0;
                    }

                    if($flag > 0)
                    {
                        Yii::app()->difftools->setConfigs($config1,$config2);
                        $diffs = Yii::app()->difftools->main();
                        $file1 = Yii::app()->difftools->fullpath1;
                        $file2 = Yii::app()->difftools->fullpath2;
                        $config1_content = $this->getContentFile($file1);
                        unlink($file1);
                        unlink($file2);

                    }


                    //              echo(stream_get_contents($dd['data']));

                    $this->render('configuration', array(
                        'model' => $model,
                        'model1' => $model1,
                        'arr_conf' => $arr_conf,
                        'arr_conf1' => $arr_conf1,
                        'router' => $router,
                        'config_current' => $config,
                        'config_compare1' => $config1_content,
                        'config_compare2' => $config2,
                        'diff_configs' => $diffs,
                        'flag_alert' => $flag_alert,
                        'flag' => $flag,
                        'dat_conf1'=>$dat_conf1,
                        'dat_conf2'=>$dat_conf2
                    ));
                }
                else
                {
                    $this->render('configuration', array(
                        'model' => $model,
                        'model1' => $model1,
                        'router' => $router,
                        'config_current' => $config0,
                        'config_compare1' => $config1_content,
                        'config_compare2' => $config2,
                        'diff_configs' => $diffs,
                        'flag_alert' => $flag_alert,
                        'flag' => $flag,
                        'dat_conf1'=>$dat_conf1,
                        'dat_conf2'=>$dat_conf2
                    ));
                }

            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Create xls report for HW
     */
    public function actionHwexportxls()
    {
        Yii::import('ext.EExcelView');
        $model = new InvHw('search');
        $type = $_GET['type'];
        if($type == 'xls')
        {
            $exptype = 'Excel5';
        }
        else 
        {
            $exptype = 'CSV';
        }
        
        $fn = 'report_hw_'.time();       
        $factory = new CWidgetFactory();
        $widget = $factory->createWidget($this, 'EExcelView', array(
            'dataProvider' => $model->reportByPartNumber(),
            'grid_mode' => 'export',
            'title' => 'HW Report',
            'filename' => $fn,
            'stream' => true,
            'exportType' => $exptype,
            'columns'         => array(
        array('name'=>'hw_item', 'header'=>'Part Type'),
        array('name'=>'hw_name', 'header'=>'Name'),
        array('name'=>'amount', 'header'=>'Qtty'),
        array('name'=>'hw_version', 'header'=>'Serial numbers'),
        array('name'=>'router_name', 'header'=>'Routers'),
        ),
        ));
        $widget->init();      
        $widget->run();
        
        exit;

    }

    /**
     * Render page for  HW inventory export in xls file
     */
    public function actionHwinventoryexportxls() {
        Yii::import('ext.EExcelView');              
        $arr_hw = $this->gethwlist();
        $type = $_GET['type'];
        if($type == 'xls')
        {
            $exptype = 'Excel5';
        }
        else 
        {
            $exptype = 'CSV';
        }
        
        $fn = 'report_hwinventory_'.time();       
        $factory = new CWidgetFactory();
        $widget = $factory->createWidget($this, 'EExcelView', array(
            'dataProvider' => new CArrayDataProvider($arr_hw),
            'grid_mode' => 'export',
            'title' => 'HW Inventory',
            'filename' => $fn,
            'stream' => true,
            'exportType' => $exptype,
            'columns'         => array(
                array('name'=>'type', 'header'=>'Part Type'),
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'details', 'header'=>'Details/Serial Number'),
                array('name'=>'info', 'header'=>'Info'),
                ),
        ));
        $widget->init();      
        $widget->run();
        
        exit;
    }

    /**
     * Render page for  HW inventory export in pdf file
     */
    public function actionHwinventoryexportpdf() 
    {
        $arr_hw = $this->gethwlist();
        $fn = 'report_hwinventory_'.time(); 
        $this->widget('ext.pdfGrid.EPDFGrid', array(
            'id'        => 'informe-pdf',
            'fileName'  => $fn,
            'dataProvider'  => new CArrayDataProvider($arr_hw,array('pagination' => array(
                                                                    'pageSize' => 10000,
                                                         ),)
                    ),
            'columns'         => array(
                array('name'=>'type', 'header'=>'Part Type'),
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'details', 'header'=>'Details/Serial Number'),
                array('name'=>'info', 'header'=>'Info'),
                ),
            'config'    => array(
                'pdfSize'   => 'A4', 
                'title'     => 'HW Inventory',
                'colWidths' => array(70, 80,60, 55),
                'showLogo'  => false,
                'showBackground' => true,
                'imagePath' => YiiBase::getPathOfAlias('webroot').'/images/logo_blue.png',//logo
                'imageBackground' => YiiBase::getPathOfAlias('webroot').'/images/background_light_150.png',//background
            ),
        ));
    }

    /**
     * Create list of HW
     *
     * @return mixed
     */
    private function gethwlist()
    {
        $model1 = Routers::model()->findAll();
        $i = 0;
        
        foreach ($model1 as $router) {
            $arr_hw[$i]['id'] = $router['router_id'];
            $arr_hw[$i]['type'] = $router['name'];
            $arr_hw[$i]['name'] = $router['ip_addr'];
            $arr_hw[$i]['details'] = '';
            $arr_hw[$i]['info'] = '';
            $arr_hw[$i]['subtitle'] = 1;
            $i++;
            Yii::app()->graph->setIdRouter($router['router_id']);
            $invHws = Yii::app()->graph->HwInventory;
            $amount1 = count($invHws);
            for ($k1 = 0; $k1 < $amount1; $k1++) {
                $arr_hw[$i]['id'] = $router['router_id'];
                $arr_hw[$i]['type'] = trim($invHws[$k1]->hw_item);
                $nname = trim($invHws[$k1]->hw_name);
                $ndet = trim($invHws[$k1]->hw_version);
                $ninfo = trim($invHws[$k1]->hw_amount);
                
                if(empty($nname))
                {
                     $arr_hw[$i]['name'] = 'N/A';
                }                  
                else {
                    $arr_hw[$i]['name'] = $nname;
                }
                
                if(empty($ndet))
                {
                    $arr_hw[$i]['details'] = 'N/A';
                }
                else 
                {
                    $arr_hw[$i]['details'] = $ndet ;
                }
                
                if(empty($ninfo))
                {
                    $arr_hw[$i]['info'] = 'N/A';
                }
                else 
                {
                    $arr_hw[$i]['info'] = $ninfo;
                }
                
                $arr_hw[$i]['subtitle'] = 0;
                $i++;               
            }
        }
        
        return $arr_hw;
    }

    /**
     * Create xls file for HW search results
     */
    public function actionHwexportfindxls()
    {
        Yii::import('ext.EExcelView');
        
        $modelhw = new InvHw();
        if ($_GET['tumbler'] == 1) {
            $data = $modelhw->searchByName($_GET['hwtypeahead']);
        } else {
            $data = $modelhw->searchByVersion($_GET['hwtypeahead']);
        }                            
                    
        $type = $_GET['type'];
        if($type == 'xls')
        {
            $exptype = 'Excel5';
        }
        else 
        {
            $exptype = 'CSV';
        }
        
        $fn = 'report_hw_'.time();       
        $factory = new CWidgetFactory();
        $widget = $factory->createWidget($this, 'EExcelView', array(
            'dataProvider' => new CArrayDataProvider($data),
            'grid_mode' => 'export',
            'title' => 'HW Find',
            'filename' => $fn,
            'stream' => true,
            'exportType' => $exptype,
            'columns'         => array(
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'version', 'header'=>'Version'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
        ));
        $widget->init();      
        $widget->run();
        
        exit;

    }

    /**
     * Create pdf file for HW
     */
    public function actionHwexportpdf()
    {
        $model = new InvHw('search');
        $fn = 'report_hw_'.time();
        $this->widget('ext.pdfGrid.EPDFGrid', array(
            'id'        => 'informe-pdf',
            'fileName'  => $fn,
            'dataProvider'  => $model->reportByPartNumber(10000), //puede ser $model->search()
            'columns'         => array(
                array('name'=>'hw_item', 'header'=>'Part Type'),
                array('name'=>'hw_name', 'header'=>'Name'),
                array('name'=>'amount', 'header'=>'Qtty'),
                array('name'=>'hw_version', 'header'=>'Serial numbers'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
            'config'    => array(
                'pdfSize'   => 'A4', 
                'title'     => 'Report HW by part number',
                'colWidths' => array(40, 90,20,40, 70),
                'showLogo'  => false,
                'showBackground' => true,
                'imagePath' => YiiBase::getPathOfAlias('webroot').'/images/logo_blue.png',//logo
                'imageBackground' => YiiBase::getPathOfAlias('webroot').'/images/background_light_150.png',//background
            ),
        ));
    }

    /**
     * Create xls file for SW search results
     */
    public function actionHwexportfindpdf()
    {
       $modelhw = new InvHw();
        if ($_GET['tumbler'] == 1) {
            $data = $modelhw->searchByName($_GET['hwtypeahead']);
        } else {
            $data = $modelhw->searchByVersion($_GET['hwtypeahead']);
        } 
        
        $fn = 'report_hw_'.time();
        echo $this->widget('ext.pdfGrid.EPDFGrid', array(
            'id'        => 'informe-pdf',
            'fileName'  => $fn,
            'dataProvider'  => new CArrayDataProvider($data,array('pagination' => array(
                                                                    'pageSize' => 10000,
                                                         ),)
                    ), //puede ser $model->search()
            'columns'         => array(
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'version', 'header'=>'Version'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
            'config'    => array(
                'pdfSize'   => 'A4', 
                'title'     => 'Report SW by part number',
                'colWidths' => array(50, 100, 90),
                'showLogo'  => false,
                'showBackground' => true,
                'imagePath' => YiiBase::getPathOfAlias('webroot').'/images/logo_blue.png',//logo
                'imageBackground' => YiiBase::getPathOfAlias('webroot').'/images/background_light_150.png',//background
            ),
        ));
        
    }

    /**
     * Create xls file for SW search results
     */
    public function actionSwexportfindxls()
    {
        Yii::import('ext.EExcelView');
        
        $modelsw = new InvSw();
                    if ($_GET['tumbler'] == 1) {
                        $data = $modelsw->searchByName($_GET['hwtypeahead']);
                    } else if ($_GET['tumbler'] == 2) {
                        $data = $modelsw->searchByVersion($_GET['hwtypeahead']);
                    } else {
                        $data = $modelsw->searchByItem($_GET['hwtypeahead']);
                    }

                    
        $type = $_GET['type'];
        if($type == 'xls')
        {
            $exptype = 'Excel5';
        }
        else 
        {
            $exptype = 'CSV';
        }
        
        $fn = 'report_sw_'.time();       
        $factory = new CWidgetFactory();
        $widget = $factory->createWidget($this, 'EExcelView', array(
            'dataProvider' => new CArrayDataProvider($data),
            'grid_mode' => 'export',
            'title' => 'SW Find',
            'filename' => $fn,
            'stream' => true,
            'exportType' => $exptype,
            'columns'         => array(
                array('name'=>'item', 'header'=>'Item'),
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'version', 'header'=>'Version'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
        ));
        $widget->init();      
        $widget->run();
        
        exit;

    }

    /**
     * create xls file for SW
     */
    public function actionSwexportxls()
    {
        Yii::import('ext.EExcelView');
        $model = new InvSw('search');
        $type = $_GET['type'];
        if($type == 'xls')
        {
            $exptype = 'Excel5';
        }
        else 
        {
            $exptype = 'CSV';
        }
        
        $fn = 'report_sw_'.time();       
        $factory = new CWidgetFactory();
        $widget = $factory->createWidget($this, 'EExcelView', array(
            'dataProvider' => $model->reportByRevision(),
            'grid_mode' => 'SW Report',
            'title' => 'Title',
            'filename' => $fn,
            'stream' => true,
            'exportType' => $exptype,
            'columns'         => array(
                array('name'=>'sw_item', 'header'=>'Item'),
                array('name'=>'sw_name', 'header'=>'Name'),
                array('name'=>'sw_version', 'header'=>'Version'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
        ));
        $widget->init();      
        $widget->run();
        
        exit;

    }

    /**
     * create pdf file for SW
     */
    public function actionSwexportpdf()
    {
        $model = new InvSw('search');
        $fn = 'report_sw_'.time();
        $this->widget('ext.pdfGrid.EPDFGrid', array(
            'id'        => 'informe-pdf',
            'fileName'  => $fn,
            'dataProvider'  => $model->reportByRevision(10000), //puede ser $model->search()
            'columns'         => array(
                array('name'=>'sw_item', 'header'=>'Item'),
                array('name'=>'sw_name', 'header'=>'Name'),
                array('name'=>'sw_version', 'header'=>'Version'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
            'config'    => array(
                'pdfSize'   => 'A4', 
                'title'     => 'Report SW by part number',
                'colWidths' => array(40, 90,40, 70),
                'showLogo'  => false,
                'showBackground' => true,
                'imagePath' => YiiBase::getPathOfAlias('webroot').'/images/logo_blue.png',//logo
                'imageBackground' => YiiBase::getPathOfAlias('webroot').'/images/background_light_150.png',//background
            ),
        ));
    }

    /**
     * Create pdf file for SW search results
     */
    public function actionSwexportfindpdf()
    {
        $modelsw = new InvSw();
                    if ($_GET['tumbler'] == 1) {
                        $data = $modelsw->searchByName($_GET['hwtypeahead']);
                    } else if ($_GET['tumbler'] == 2) {
                        $data = $modelsw->searchByVersion($_GET['hwtypeahead']);
                    } else {
                        $data = $modelsw->searchByItem($_GET['hwtypeahead']);
                    }
        $fn = 'report_sw_'.time();
        echo $this->widget('ext.pdfGrid.EPDFGrid', array(
            'id'        => 'informe-pdf',
            'fileName'  => $fn,
            'dataProvider'  => new CArrayDataProvider($data,array('pagination' => array(
                                                                    'pageSize' => 10000,
                                                         ),)
                    ), //puede ser $model->search()
            'columns'         => array(
                array('name'=>'item', 'header'=>'Item'),
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'version', 'header'=>'Version'),
                array('name'=>'router_name', 'header'=>'Routers'),
                ),
            'config'    => array(
                'pdfSize'   => 'A4', 
                'title'     => 'Report SW by part number',
                'colWidths' => array(40, 90,40, 70),
                'showLogo'  => false,
                'showBackground' => true,
                'imagePath' => YiiBase::getPathOfAlias('webroot').'/images/logo_blue.png',//logo
                'imageBackground' => YiiBase::getPathOfAlias('webroot').'/images/background_light_150.png',//background
            ),
        ));
        
    }

    /**
     * Create export for SW inventory in xls/csv file
     */
    public function actionSwinventoryexportxls() {
        Yii::import('ext.EExcelView');              
        $arr_hw = $this->getswlist();
        $type = $_GET['type'];
        if($type == 'xls')
        {
            $exptype = 'Excel5';
        }
        else 
        {
            $exptype = 'CSV';
        }
        
        $fn = 'report_swinventory_'.time();       
        $factory = new CWidgetFactory();
        $widget = $factory->createWidget($this, 'EExcelView', array(
            'dataProvider' => new CArrayDataProvider($arr_hw),
            'grid_mode' => 'export',
            'title' => 'SW Invertory',
            'filename' => $fn,
            'stream' => true,
            'exportType' => $exptype,
            'columns'         => array(
                array('name'=>'type', 'header'=>'Type'),
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'version', 'header'=>'Version'),
                ),
        ));
        $widget->init();      
        $widget->run();
        
        exit;
    }

    /**
     * Create export for SW inventory in pdf file
     */
    public function actionSwinventoryexportpdf() 
    {
        $arr_hw = $this->getswlist();
        $fn = 'report_swinventory_'.time(); 
        $this->widget('ext.pdfGrid.EPDFGrid', array(
            'id'        => 'informe-pdf',
            'fileName'  => $fn,
            'dataProvider'  => new CArrayDataProvider($arr_hw,array('pagination' => array(
                                                                    'pageSize' => 10000,
                                                         ),)
                    ),
            'columns'         => array(
                array('name'=>'type', 'header'=>'Type'),
                array('name'=>'name', 'header'=>'Name'),
                array('name'=>'version', 'header'=>'Version'),
                ),
            'config'    => array(
                'pdfSize'   => 'A4', 
                'title'     => 'SW Inventory',
                'colWidths' => array(80, 90,70),
                'showLogo'  => false,
                'showBackground' => true,
                'imagePath' => YiiBase::getPathOfAlias('webroot').'/images/logo_blue.png',//logo
                'imageBackground' => YiiBase::getPathOfAlias('webroot').'/images/background_light_150.png',//background
            ),
        ));
    }

    /**
     * Create list of SW
     *
     * @return mixed
     */
    private function getswlist()
    {
        $model1 = Routers::model()->findAll();
        $i = 0;
        
        foreach ($model1 as $router) {
            $arr_hw[$i]['id'] = $router['router_id'];
            $arr_hw[$i]['type'] = $router['name'];
            $arr_hw[$i]['name'] = $router['ip_addr'];
            $arr_hw[$i]['version'] = '';
            $arr_hw[$i]['subtitle'] = 1;
            $i++;
            Yii::app()->graph->setIdRouter($router['router_id']);
            $invSws = Yii::app()->graph->SwInventory;
            $amount1 = count($invSws);
            for ($k1 = 0; $k1 < $amount1; $k1++) {
                $arr_hw[$i]['id'] = $router['router_id'];
                $arr_hw[$i]['type'] = trim($invSws[$k1]->sw_item);
                $nname = trim($invSws[$k1]->sw_name);
                $ndet = trim($invSws[$k1]->sw_version);
                
                if(empty($nname))
                {
                     $arr_hw[$i]['name'] = 'N/A';
                }                  
                else {
                    $arr_hw[$i]['name'] = $nname;
                }
                
                if(empty($ndet))
                {
                    $arr_hw[$i]['version'] = 'N/A';
                }
                else 
                {
                    $arr_hw[$i]['version'] = $ndet ;
                }
                
                $arr_hw[$i]['subtitle'] = 0;
                $i++;               
            }
        }
        
        return $arr_hw;
    }
    
    /**
     * load router model with interfaces,networks and phisical Interfaces relations 
     * 
     * @param integer $id unique id ofrouter 
     * @return object 
     * @throws CHttpException
     */
    public function loadModel($id) {
        $model = Routers::model()->with('interfaces', 'networks', 'networks1', 'phInts')->findByPk((int) $id);
        if ($model === null)
            throw new CHttpException(404, 'The requested page does not exist.');
        return $model;
    }

    protected function setNoEmptyValue($valore) {
        $val_trim = trim($valore);

        if (!empty($val_trim)) {
            return $val_trim;
        } else {
            return CHtml::openTag('font', array('encode' => false, 'style' => 'color:' . Yii::app()->params['color_na'])) . "N/A" . CHtml::closeTag('font');
        }
    }

    private function getContentFile($url)
    {
        $handle = fopen("$url",'r');
            $result="<pre class='diff1'>";
            if ($handle) {
                while (($buffer = fgets($handle, 4096)) !== false) {
                    $result .= htmlentities($buffer);
                }
                if (!feof($handle)) {
                    echo "Error: unexpected fgets() fail\n";
                }
                fclose($handle);
            }
            $result .= "</pre>";
        return $result;    
    }

    /**
     * Creates a new model.
     * If creation is successful, the browser will be redirected to the 'view' page.
     */
    public function actionCreate()
    {
        $model=new Routers;

        // Uncomment the following line if AJAX validation is needed
        // $this->performAjaxValidation($model);

        if(isset($_POST['Routers']))
        {
            $model->attributes=$_POST['Routers'];
            if($model->save())
                $this->redirect(array('admin'));
        }

        $this->render('create',array(
            'model'=>$model,
        ));
    }

    /**
     * Updates a particular model.
     * If update is successful, the browser will be redirected to the 'view' page.
     * @param integer $id the ID of the model to be updated
     */
    public function actionUpdate($id)
    {
        $model=$this->loadModel($id);

        // Uncomment the following line if AJAX validation is needed
        // $this->performAjaxValidation($model);

        if(isset($_POST['Routers']))
        {
            $model->attributes=$_POST['Routers'];
            if($model->save())
                $this->redirect(array('admin'));
        }

        $this->render('update',array(
            'model'=>$model,
        ));
    }

    /**
     * Deletes a particular model.
     * If deletion is successful, the browser will be redirected to the 'admin' page.
     * @param integer $id the ID of the model to be deleted
     */
    public function actionDelete($id)
    {
        $this->loadModel($id)->delete();

        // if AJAX request (triggered by deletion via admin grid view), we should not redirect the browser
        if(!isset($_GET['ajax']))
            $this->redirect(isset($_POST['returnUrl']) ? $_POST['returnUrl'] : array('admin'));
    }

    /**
     * Performs the AJAX validation.
     * @param Routers $model the model to be validated
     */
    protected function performAjaxValidation($model)
    {
        if(isset($_POST['ajax']) && $_POST['ajax']==='routers-form')
        {
            echo CActiveForm::validate($model);
            Yii::app()->end();
        }
    }

    /**
     * Lists all models.
     */
    public function actionAdmin()
    {
        $dataProvider=new CActiveDataProvider('Routers');
        $this->render('admin',array(
            'dataProvider'=>$dataProvider,
        ));
    }

    /**
     * Lists all models for definded access.
     */
    public function actionList()
    {
        $acc_id = Yii::app()->getRequest()->getParam('id');
        $criteria = new CDbCriteria();
        $criteria->with = array('idRouter' => array('alias'=>'pl'));
        $criteria->condition = "id_access=:id_access";
        $criteria->params = array(':id_access' => $acc_id);
        $arr_r = RouterAccess::model()->findAll($criteria);

        $amount1 = count($arr_r);
        $arr_ing = array();


        for ($k1 = 0; $k1 < $amount1; $k1++) {
            $arr_ing[$k1]['id'] = $k1+1;
            $arr_ing[$k1]['name'] = $arr_r[$k1]['idRouter']->name;
            $arr_ing[$k1]['vendor'] = $arr_r[$k1]['idRouter']->eq_vendor;
        }

        $this->renderPartial('_relational', array(
            'gridDataProvider' => new CArrayDataProvider($arr_ing),
            'gridColumns' => array(array('name' => 'id', 'header' => '#','value' => '$data["id"]','htmlOptions'=>array('width'=>'10%'),),
                array('name' => 'name', 'header' => 'Name', 'type' => 'raw', 'value' => '$data["name"]','htmlOptions'=>array('width'=>'45%'),),
                array('name' => 'value', 'header' => 'Vendor', 'type' => 'raw', 'value' => '$data["vendor"]','htmlOptions'=>array('width'=>'45%'),),
            )
        ));
    }

    /**
     * Lists all models for definded access.
     */
    public function actionListSnmp()
    {
        $acc_id = Yii::app()->getRequest()->getParam('id');
        $criteria = new CDbCriteria();
        $criteria->with = array('router' => array('alias'=>'pl'));
        $criteria->condition = "snmp_access_id=:snmp_access_id";
        $criteria->params = array(':snmp_access_id' => $acc_id);
        $arr_r = RouterSnmpAccess::model()->findAll($criteria);

        $amount1 = count($arr_r);
        $arr_ing = array();


        for ($k1 = 0; $k1 < $amount1; $k1++) {
            $arr_ing[$k1]['id'] = $k1+1;
            $arr_ing[$k1]['name'] = $arr_r[$k1]['router']->name;
            $arr_ing[$k1]['vendor'] = $arr_r[$k1]['router']->eq_vendor;
        }

        $this->renderPartial('_relational', array(
            'gridDataProvider' => new CArrayDataProvider($arr_ing),
            'gridColumns' => array(array('name' => 'id', 'header' => '#','value' => '$data["id"]','htmlOptions'=>array('width'=>'10%'),),
                array('name' => 'name', 'header' => 'Name', 'type' => 'raw', 'value' => '$data["name"]','htmlOptions'=>array('width'=>'45%'),),
                array('name' => 'value', 'header' => 'Vendor', 'type' => 'raw', 'value' => '$data["vendor"]','htmlOptions'=>array('width'=>'45%'),),
            )
        ));
    }

    /**
     * Clean DB
     *
     * @throws CHttpException
     */
    public function actionCleandb()
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('editAssets')) {
                $model = new Routers;

                if (isset($_POST['tumbler']) && $_POST['tumbler'] > 0)
                {
                    Routers::model()->deleteAll();
                    Events::model()->deleteAll();
                    Yii::app()->user->setFlash('cleandb', 'DB was cleaned.');
                    $this->refresh();
                }


                $this->render('cleandb', array(
                    'model' => $model,
                ));
            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * Run initial discovery
     *
     * @throws CHttpException
     */
    public function actionRunaudit()
    {
        if (!Yii::app()->user->isGuest) {
            if (Yii::app()->user->checkAccess('editAssets')) {
                $baseUrl = Yii::app()->baseUrl;
                $cs = Yii::app()->clientScript;
                $cs->registerCssFile($baseUrl.'/css/bootstrap-switch.css');
                $cs->registerScriptFile(Yii::app()->baseUrl . '/js/libs/bootstrap-switch.js', CClientScript::POS_HEAD);
                $model = new Routers;
                $model1 = GeneralSettings::model()->findByAttributes(array('name'=>'perioddiscovery'));
                $model2 = GeneralSettings::model()->findByAttributes(array('name'=>'scanner'));

                if (isset($_POST['tumbler']) && $_POST['tumbler'] > 0)
                {
                    $arr_attr=array();
                    $str_1 = substr(Yii::app()->db->connectionString,6);
                    $arr1 = explode(";",$str_1);

                    foreach($arr1 as $key=>$val)
                    {
                        $arr2 = explode("=",$val);
                        $arr_attr[$arr2[0]] = $arr2[1];
                    }

                    $arr_attr['username'] = Yii::app()->db->username;
                    $arr_attr['password'] = Yii::app()->db->password;
                    chdir('/home/ngnms/NGREADY/bin/');
                    putenv("NGNMS_HOME=/home/ngnms/NGREADY");
                    putenv('NGNMS_CONFIGS=/home/ngnms/NGREADY/configs');
                    putenv('PATH=/home/ngnms/NGREADY/bin:/usr/bin');
                    putenv('PERL5LIB=/usr/local/share/perl/5.18.2:/home/ngnms/NGREADY/bin:/home/ngnms/NGREADY/lib:/home/ngnms/NGREADY/lib/Net');

  /*                  chdir ('/var/www/ngnms_perl/PERL/bin/');
                    putenv("NGNMS_HOME=/var/www/ngnms_perl/PERL");
                    putenv('NGNMS_CONFIGS=/var/www/ngnms_perl/PERL/configs');
                    putenv('PATH=/var/www/ngnms_perl/PERL/bin:/usr/bin');
                    putenv('PERL5LIB=/var/www/ngnms_perl/PERL/lib:/var/www/ngnms_perl/PERL/lib/Net');
                    putenv('LD_LIBRARY_PATH=/var/www/ngnms_perl/PERL/lib');
                    putenv('MIBDIRS=/home/ngnms/NGREADY/mibs');*/


                    $command1 = 'perl audit.pl';
                    if(isset($_POST['scanner']) && $_POST['scanner'] > 0)
                    {
                        $command1 .= " -s";
                    }

                    if(isset($arr_attr['host']) )
                    {
                        $command1 .= " -L ".$arr_attr['host'];
                    }

                    if(isset($arr_attr['dbname']) )
                    {
                        $command1 .= " -D ".$arr_attr['dbname'];
                    }

                    if(isset($arr_attr['username']))
                    {
                        $command1 .= " -U ".$arr_attr['username'];
                    }

                    if(isset($arr_attr['password']))
                    {
                        $command1 .= " -W ".$arr_attr['password'];
                    }

                    if(isset($arr_attr['port']))
                    {
                        $command1 .= " -P ".$arr_attr['port'];
                    }
/*

                    $hosttype = GeneralSettings::model()->findByAttributes(array('name'=>'hostType'));

                    if(isset($hosttype->value))
                    {
                        $command1 .= " -t ".trim(Cripto::decrypt($hosttype->value));
                    }

                    $keypath = GeneralSettings::model()->findByAttributes(array('name'=>'path to key'));

                    if(isset($keypath->value))
                    {
                        $command1 .= " -K ".trim(Cripto::decrypt($keypath->value));
                    }

                    $passphr = GeneralSettings::model()->findByAttributes(array('name'=>'passphrase'));

                    if(isset($passphr->value))
                    {
                        $command1 .= " -H ".trim(Cripto::decrypt($passphr->value));
                    }

                    $seedhost = GeneralSettings::model()->findByAttributes(array('name'=>'seedHost'));

                    if(isset($seedhost->value))
                    {
                        $command1 .= " ".trim(Cripto::decrypt($seedhost->value));
                    }

                    $usr = GeneralSettings::model()->findByAttributes(array('name'=>'username'));

                    if(isset($usr->value))
                    {
                        $command1 .= " ".trim(Cripto::decrypt($usr->value));
                    }

                    $passw = GeneralSettings::model()->findByAttributes(array('name'=>'password'));

                    if(isset($passw->value))
                    {
                        $command1 .= " ".trim(Cripto::decrypt($passw->value));
                    }

                    $enpassw = GeneralSettings::model()->findByAttributes(array('name'=>'enpassword'));

                    if(isset($enpassw->value))
                    {
                        $command1 .= " ".trim(Cripto::decrypt($enpassw->value));
                    }

                    $type_a = GeneralSettings::model()->findByAttributes(array('name'=>'type access'));

                    if(isset($type_a->value))
                    {
                        $command1 .= " ".trim(Cripto::decrypt($type_a->value));
                    }
*/

                    $escaped_command1 = escapeshellcmd($command1);
                    $sss=passthru($escaped_command1);


                    Yii::app()->user->setFlash('runaudit', 'Initial discovery  was finished.');
                    $this->refresh();
                }


                $this->render('runaudit', array(
                    'model' => $model,
                    'model1' => $model1,
                    'model2' => $model2
                ));
            }
            else {
                throw new CHttpException(403, 'Forbidden');
            }
        } else {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     *
     */
    public function actionPercentage() {
        /*$status =1;
        if (Yii::app()->request->isAjaxRequest) {
            $item = DiscoveryStatus::model()->findByAttributes(array('ended'=>$status)); //obtain instance of object containing your function
            echo $item->percent; //to return value in ajax, simply echo it
            echo $status;
        }*/
        echo mt_rand(1, 100);
        exit;

    }
}
