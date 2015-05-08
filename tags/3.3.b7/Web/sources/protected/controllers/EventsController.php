<?php

class EventsController extends Controller
{
	public function actionIndex()
	{
		$this->render('index');
	}

    /**
     * shows summary activities by origin
     *
     * @throws CHttpException
     */
    public function actionSummarybyorigin()
	{
            if (!Yii::app()->user->isGuest) 
            {
                if (Yii::app()->user->checkAccess('viewAssets')) 
                {
                    $this->turnOn();
                    $flag = false;
                    $arr_labels = array();
                    $arr_valore = array();
                    $arr_pollar1 = array();
                    $piegoogle = array();
                    $piegoogle1 = array();
                    $model = new Events('search');
                    $model->unsetAttributes();

                    if(isset(Yii::app()->request->cookies['from_date']))
                    {
                        $value1 =Yii::app()->request->cookies['from_date']->value;
                        $model->setFromdate($value1);
                    }

                    if(isset(Yii::app()->request->cookies['to_date']))
                    {
                        $value2 = Yii::app()->request->cookies['to_date']->value ;
                        $model->setTodate($value2);
                    }

                    if (isset($_GET['Events']))
                    {
                        $model->attributes = $_GET['Events'];
                        if(!$model->validate())
                        {

                            throw new CHttpException(500,'Value must be int');
                        }

                    }
                    if(isset($_POST) && !empty($_POST))
                    {
                        unset(Yii::app()->request->cookies['from_date']);  // first unset cookie for dates
                        unset(Yii::app()->request->cookies['to_date']);
                        $this->setCookie('from_date',$_POST['from_date']);
                        $this->setCookie('to_date',$_POST['to_date']);

                        if(isset($_POST['from_date']) && !empty($_POST['from_date']) )
                        {
                            $model->setFromdate($_POST['from_date']);
                        }

                        if(isset($_POST['to_date']) && !empty($_POST['to_date']) )
                        {
                            $model->setTodate($_POST['to_date']);
                        }

                    }

                   $model1 = $model->allEventsByOrigin();
                   $arr_pollar = $this->numofeventsArray($model1);

                   if(count($arr_pollar) > 0)
                   {
                       $flag = true;

                       foreach($arr_pollar as $key=>$val)
                       {
                           $arr_labels[$key] = $val['label'];
                           $arr_valore[$key] = $val['value'];
                       }

                       $piegoogle[0]=array('Router','Events');

                       foreach($arr_pollar as $key=>$val)
                       {
                           $piegoogle[] = array($val['label'],$val['value']);
                       }

                       $arr_pollar1 = $this->sumseverityArray($model1);

                       if(count($arr_pollar1) > 0)
                       {
                           $piegoogle1[0]=array('Router','Events');

                           foreach($arr_pollar1 as $key=>$val)
                           {
                               $piegoogle1[] = array($val['label'],$val['value']);
                           }
                       }
                   }


                    $this->render('origin',array(
                        'model'=>$model,
                        'flag' =>$flag,
                        'pollar'=>$arr_pollar,
                        'pollar1'=>$arr_pollar1,
                        'piegoogle'=> CJSON::encode($piegoogle),
                        'piegoogle1'=> CJSON::encode($piegoogle1),
                        'labels' =>$arr_labels,
                        'valore' => $arr_valore,
                        ));
                }
                else 
                {
                    throw new CHttpException(403, 'Forbidden');
                }
            }
            else 
            {
                $this->redirect('index.php?r=site/login');
            }    
	}

    /**
     * shows information aboout facilties for defined router
     *
     * @throws CHttpException
     */
    public function actionOrigindet()
    {
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->user->checkAccess('viewAssets'))
            {
                $this->turnOn();
                $piegoogle = array();
                $piegoogle1 = array();
                $model = new Events();
                $flag = false;

                if(isset($_GET) && !empty($_GET))
                {
                    $model->origin = $_GET['origin'];
                    $model->origin_id = $_GET['origin_id'];
                }
                if(isset($_POST) && !empty($_POST))
                {
                    unset(Yii::app()->request->cookies['from_date']);  // first unset cookie for dates
                    unset(Yii::app()->request->cookies['to_date']);
                    $this->setCookie('from_date',$_POST['from_date']);
                    $this->setCookie('to_date',$_POST['to_date']);
                    if(isset($_POST['from_date']) && !empty($_POST['from_date']) )
                    {
                        $model->setFromdate($_POST['from_date']);
                    }

                    if(isset($_POST['to_date']) && !empty($_POST['to_date']) )
                    {
                        $model->setTodate($_POST['to_date']);
                    }

                }
                else
                {
                    if(isset(Yii::app()->request->cookies['from_date']))
                    {
                        $value1 =Yii::app()->request->cookies['from_date']->value;
                        $model->setFromdate($value1);
                    }

                    if(isset(Yii::app()->request->cookies['to_date']))
                    {
                        $value2 = Yii::app()->request->cookies['to_date']->value ;
                        $model->setTodate($value2);
                    }
                }

                $model1 = $model->allEventsForOrigin();

                $arr_pollar = $this->numofeventsArray($model1,'facility');

                if(count($arr_pollar) > 0)
                {
                    $flag = true;

                    foreach($arr_pollar as $key=>$val)
                    {
                        $arr_labels[$key] = $val['label'];
                        $arr_valore[$key] = $val['value'];
                    }

                    $piegoogle[0]=array('Facility','Events');

                    foreach($arr_pollar as $key=>$val)
                    {
                        $piegoogle[] = array($val['label'],$val['value']);
                    }

                    $arr_pollar1 = $this->sumseverityArray($model1,'facility');

                    if(count($arr_pollar1) > 0)
                    {
                        $piegoogle1[0]=array('Router','Events');

                        foreach($arr_pollar1 as $key=>$val)
                        {
                            $piegoogle1[] = array($val['label'],$val['value']);
                        }
                    }
                }

                $this->render('facility_origin',array(
                                  'model' => new CArrayDataProvider($model1,
                                          array(
                                              'sort'=>array(
                                                  'attributes'=>array(
                                                      'numofevents'=>array(
                                                          'asc'=>'numofevents',
                                                          'desc'=>'numofevents DESC',
                                                      ),
                                                      'sumseverity'=>array(
                                                          'asc'=>'sumseverity',
                                                          'desc'=>'sumseverity DESC',
                                                      ),
                                                      'facility'=>array(
                                                          'asc'=>'facility',
                                                          'desc'=>'facility DESC',
                                                      ),
                                                  ),
                                              ),
                                              'keyField' => 'facility',
                                              'pagination'=>array(
                                                  'pageSize'=> 10,
                                              ),
                                          )),
                                   'piegoogle'=> CJSON::encode($piegoogle),
                                   'piegoogle1'=> CJSON::encode($piegoogle1),
                                   'router_id'=>$model->origin_id,
                                   'router_name'=>$model->origin,
                                   'flag'=>$flag,
                ));
            }
            else
            {
                throw new CHttpException(403, 'Forbidden');
            }
        }
        else
        {
            $this->redirect('index.php?r=site/login');
        }
    }

    /**
     * shows summary activities by facility
     *
     * @throws CHttpException
     */
    public function actionSummarybyfacility()
	{
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->user->checkAccess('viewAssets'))
            {
                $this->turnOn();
                $piegoogle = array();
                $piegoogle1 = array();
                $model = new Facilities('search');
                $flag = false;

                if(isset(Yii::app()->request->cookies['from_date']))
                {
                    $value1 =Yii::app()->request->cookies['from_date']->value;
                    $model->setFromdate($value1);
                }

                if(isset(Yii::app()->request->cookies['to_date']))
                {
                    $value2 = Yii::app()->request->cookies['to_date']->value ;
                    $model->setTodate($value2);
                }

                if (isset($_GET['Facilities']))
                {
                    $model->attributes = $_GET['Facilities'];
                    if(!$model->validate())
                    {

                        throw new CHttpException(500,'Value must be int');
                    }
                }

                if(isset($_POST) && !empty($_POST))
                {
                    unset(Yii::app()->request->cookies['from_date']);  // first unset cookie for dates
                    unset(Yii::app()->request->cookies['to_date']);
                    $this->setCookie('from_date',$_POST['from_date']);
                    $this->setCookie('to_date',$_POST['to_date']);
                    if(isset($_POST['from_date']) && !empty($_POST['from_date']) )
                    {
                        $model->setFromdate($_POST['from_date']);
                    }
                    if(isset($_POST['to_date']) && !empty($_POST['to_date']) )
                    {
                        $model->setTodate($_POST['to_date']);
                    }

                }

                $model1 = $model->allEventsByfacility();
                $arr_pollar = $this->numofeventsArray($model1,'facility');

                if(count($arr_pollar) > 0)
                {
                    $flag = true;

                    $piegoogle[0]=array('Facility','Amount');

                    foreach($arr_pollar as $key=>$val)
                    {
                        $piegoogle[] = array($val['label'],$val['value']);
                    }

                    $arr_pollar1 = $this->sumseverityArray($model1,'facility');

                    if(count($arr_pollar1) > 0)
                    {
                        $piegoogle1[0]=array('Facility','Amount');

                        foreach($arr_pollar1 as $key=>$val)
                        {
                            $piegoogle1[] = array($val['label'],$val['value']);
                        }
                    }
                }


                $this->render('facility',array(
                    'model' => $model,
                    'flag' =>$flag,
                    'piegoogle'=> CJSON::encode($piegoogle),
                    'piegoogle1'=> CJSON::encode($piegoogle1),
                ));
            }
            else
            {
               throw new CHttpException(403, 'Forbidden');
            }
        }
        else
        {
            $this->redirect('index.php?r=site/login');
        }
	}

    /**
     * shows distribution facility between routers
     *
     * @throws CHttpException
     */
    public function actionFacilitydet()
    {
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->user->checkAccess('viewAssets'))
            {
                $this->turnOn();
                $piegoogle = array();
                $piegoogle1 = array();
                $model = new Facilities();
                $flag = false;

                if(isset($_GET) && !empty($_GET))
                {
                    $model->facility = $_GET['facility'];
                }

                if(isset($_POST) && !empty($_POST))
                {
                    unset(Yii::app()->request->cookies['from_date']);  // first unset cookie for dates
                    unset(Yii::app()->request->cookies['to_date']);
                    $this->setCookie('from_date',$_POST['from_date']);
                    $this->setCookie('to_date',$_POST['to_date']);
                    if(isset($_POST['from_date']) && !empty($_POST['from_date']) )
                    {
                        $model->setFromdate($_POST['from_date']);
                    }
                    if(isset($_POST['to_date']) && !empty($_POST['to_date']) )
                    {
                        $model->setTodate($_POST['to_date']);
                    }

                }
                else
                {
                    if(isset(Yii::app()->request->cookies['from_date']))
                    {
                        $value1 =Yii::app()->request->cookies['from_date']->value;
                        $model->setFromdate($value1);
                    }

                    if(isset(Yii::app()->request->cookies['to_date']))
                    {
                        $value2 = Yii::app()->request->cookies['to_date']->value ;
                        $model->setTodate($value2);
                    }
                }

                $model1 = $model->allEventsForFacility();

                $arr_pollar = $this->numofeventsArray($model1,'origin');

                if(count($arr_pollar) > 0)
                {
                    $flag = true;

                    foreach($arr_pollar as $key=>$val)
                    {
                        $arr_labels[$key] = $val['label'];
                        $arr_valore[$key] = $val['value'];
                    }

                    $piegoogle[0]=array('Router','Amount');

                    foreach($arr_pollar as $key=>$val)
                    {
                        $piegoogle[] = array($val['label'],$val['value']);
                    }

                    $arr_pollar1 = $this->sumseverityArray($model1,'origin');

                    if(count($arr_pollar1) > 0)
                    {
                        $piegoogle1[0]=array('Router','Amount');

                        foreach($arr_pollar1 as $key=>$val)
                        {
                            $piegoogle1[] = array($val['label'],$val['value']);
                        }
                    }
                }

                $this->render('origin_facility',array(
                    'model' => new CArrayDataProvider($model1,
                            array(
                                'sort'=>array(
                                    'attributes'=>array(
                                        'numofevents'=>array(
                                            'asc'=>'numofevents',
                                            'desc'=>'numofevents DESC',
                                        ),
                                        'sumseverity'=>array(
                                            'asc'=>'sumseverity',
                                            'desc'=>'sumseverity DESC',
                                        ),
                                        'origin'=>array(
                                            'asc'=>'origin',
                                            'desc'=>'origin DESC',
                                        ),
                                    ),
                                ),
                                'keyField' => 'origin',
                                'pagination'=>array(
                                    'pageSize'=> 10,
                                ),
                            )),
                    'piegoogle'=> CJSON::encode($piegoogle),
                    'piegoogle1'=> CJSON::encode($piegoogle1),
                    'flag'=>$flag,
                ));
            }
            else
            {
                throw new CHttpException(403, 'Forbidden');
            }
        }
        else
        {
            $this->redirect('index.php?r=site/login');
        }
    }


    public function actionHistory()
    {
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->user->checkAccess('viewAssets'))
            {
                $this->turnOn();
                $model = new Events();
                $step = 3600;
                $regim = 0;
                $period = Yii::app()->params['point_on_chart']*$step;

                if (Yii::app()->request->isAjaxRequest) {
                    $regim = 1;
                    $model->origin_id = $_POST['origin_id'];
                    $model->origin = $_POST['origin'];
                    $step = $_POST['step'];
                    $start_d = $_POST['start_d'];
                    $period = Yii::app()->params['point_on_chart']*$step;
                }
                else if(isset($_GET) && !empty($_GET))
                {
                    if(isset(Yii::app()->request->cookies['to_date']))
                    {
                        $value2 = Yii::app()->request->cookies['to_date']->value ;
                        $model->setTodate($value2);
                        $start_d = $model->to_date;
                    }
                    else
                        $start_d = '';

                    $model->origin_id = $_GET['id'];
                    $model->origin = $_GET['router'];
                }

                $model1 = $model->historyEvents($start_d,$step,$period);
                $maxdate = $model->maxDateForRouterEvenrs(); // get max date of events for defined router
                $mindate = $model->minDateForRouterEvenrs(); // get min date of events for defined router

// Check if it needs to show button 'next'

                $max_d = new DateTime($maxdate);
                $max_dat = $max_d->format('F j, Y H:i:s');
                $max_d_compare = $max_d->format('Y-m-d H:i:s');
                $max_d_model = new DateTime($model1[199][0]);

                if($max_d_compare > $max_d_model->format('Y-m-d H:i:s'))
                    $flag1 = 1;
                else
                    $flag1 = 0;

// Check if it needs to show button 'prev'

                $min_d = new DateTime($mindate);
                $min_dat = $min_d->format('F j, Y H:i:s');
                $min_d_compare = $min_d->format('Y-m-d H:i:s');
                $min_d_model = new DateTime($model1[0][0]);

                if($min_d_compare < $min_d_model->format('Y-m-d H:i:s'))
                    $flag2 = 1;
                else
                    $flag2 = 0;

                $prev_d = new DateTime($model1[Yii::app()->params['prev_of_chart']][0]);
                $next_d = new DateTime($model1[Yii::app()->params['next_of_chart']][0]);
                $dat1 = $prev_d->format('Y-m-d H:i:s');
                $zsuv = Yii::app()->params['point_on_chart']*$step;
                $next_d->modify('+'.$zsuv.' second');
                $dat2 = $next_d->format('Y-m-d H:i:s');
                $dat_pick = new DateTime($start_d);
                $start_dat_pick = $dat_pick->format('d/m/Y H:i:s');

                if($regim >0)
                {
                     $arr_dat = array($dat1,$dat2,$flag1,$flag2,$start_dat_pick);
                     echo json_encode(array(CJSON::encode($arr_dat),CJSON::encode($model1)));
                }
                else
                {
                    $this->render('history',array(
                        'model' => $model,
                        'datachart'=> CJSON::encode($model1),
                        'step' => $step,
                        'stop_prev' => $prev_d->format('Y-m-d H:i:s'),
                        'stop_next' => $next_d->format('Y-m-d H:i:s'),
                        'max_dat' => $max_dat,
                        'min_dat' => $min_dat,
                        'from_to' => $start_dat_pick,
                        'flag1'=> $flag1,
                        'flag2'=> $flag2
                    ));
                }

            }
            else
            {
                throw new CHttpException(403, 'Forbidden');
            }
        }
        else
        {
            $this->redirect('index.php?r=site/login');
        }
    }

    public function actionDatatableevents()
    {
            $this->turnOn();
            $model = new Events('allEventsOriginPeriod');
            $router = new Routers('search');
            $model->unsetAttributes();

            if((isset($_GET['origin_id'])))
            {
                $model->origin_id = $_GET['origin_id'];
				$model->origin = $_GET['origin'];
                $model->from_date = $_GET['start_d'];;
                $model->to_date = $_GET['end_d'];
                $router->router_id = $_GET['origin_id'];
				$origin = $router->routerNameForId();
				$origin = $_GET['origin'];

            }
            else if((isset($_POST['origin_id'])))
            {
                $model->origin_id = $_POST['origin_id'];
				$model->origin = $_POST['origin'];
                $model->from_date = $_POST['start_d'];;
                $model->to_date = $_POST['end_d'];
                $router->router_id = $_POST['origin_id'];
				$origin = $_POST['origin'];
            }

        if (isset($_GET['Events']))
            $model->attributes = $_GET['Events'];

            
 //           $model1 = $model->allEventsOriginPeriod();
 //           echo CJSON::encode($model1);
             $this->renderPartial( '_ajaxContent', array( 'model1' =>$model,'origin'=>$origin), false,true );

    }


    /**
     * convert model to array
     *
     * @param $models
     *
     * @return array
     */
    public function convertModelToArray($models) {
        if (is_array($models))
            $arrayMode = TRUE;
        else {
            $models = array($models);
            $arrayMode = FALSE;
        }

        $result = array();
        foreach ($models as $model) {
            $attributes = $model->getAttributes();
            $relations = array();
            foreach ($model->relations() as $key => $related) {
                if ($model->hasRelated($key)) {
                    $relations[$key] = convertModelToArray($model->$key);
                }
            }
            $all = array_merge($attributes, $relations);

            if ($arrayMode)
                array_push($result, $all);
            else
                $result = $all;
        }
        return $result;
    }

    /**
     * return array for showing  chart of Numbers of events
     *
     * @param $models
     * @param string $sortfield
     * @return array
     */
    protected function numofeventsArray($models,$sortfield='origin'){

        $arr_colors =array("#F7464A","#46BFBD","#FDB45C","#949FB1","#4D5360","#2E8B57","#A0C0D1");
        $arr_ret = array();
        $max = $this->maxValore($models,'numofevents');
        $data = $this->sortData($models,'numofevents',$sortfield);

        $sum_others = 0;
        $i = 0;
        foreach ($data as $model) {
            if($i<6 && $model['numofevents']>0 && ($max/$model['numofevents'] < 100))
            {
                $arr_ret[] = array("value" => $model['numofevents'], "color" => $arr_colors[$i],
                    "label" => $model[$sortfield]);
                $i++;
            }
            else
            {
                $sum_others += $model['numofevents'];
            }
        }
        if($i > 0)
        $arr_ret[] = array("value" => $sum_others, "color" => $arr_colors[$i],
            "label" => 'Others');

        return $arr_ret;

    }

    /**
     * return array for showing  chart of summary severity
     *
     * @param $models
     * @param string $sortfield
     * @return array
     */
    protected function sumseverityArray($models,$sortfield='origin'){

        $arr_colors =array("#F7464A","#46BFBD","#FDB45C","#949FB1","#4D5360","#2E8B57","#A0C0D1");
        $arr_ret = array();
        $max = $this->maxValore($models,'sumseverity');
        $data = $this->sortData($models,'sumseverity',$sortfield);

        $sum_others = 0;
        $i = 0;
        foreach ($data as $model) {
            if($i<6 && $model['sumseverity']>0 && ($max/$model['sumseverity'] < 100))
            {
                $arr_ret[] = array("value" => $model['sumseverity'], "color" => $arr_colors[$i],
                    "label" => $model[$sortfield]);
                $i++;
            }
            else
            {
                $sum_others += $model['sumseverity'];
            }
        }
        if($i > 0)
            $arr_ret[] = array("value" => $sum_others, "color" => $arr_colors[$i],
                "label" => 'Others');

        return $arr_ret;

    }


    /**
     * return max value for defined colums multidimensional array
     *
     * @param $arr
     * @param $fieldname
     * @return int
     */
    private function maxValore($arr,$fieldname)
    {
        $max = -9999999; //will hold max val
        $found_item = null; //will hold item with max val;

        foreach($arr as $k=>$v)
        {
            if($v[$fieldname]>$max)
            {
                $max = $v[$fieldname];
                $found_item = $v;
            }
        }

        return $max;
    }

    /**
     * sort multidimensional array by two defined fields
     *
     * @param $data
     * @param $field1
     * @param $field2
     * @return array
     */
    private function sortData($data,$field1,$field2)
    {
        $arr_v = array();
        $volume = array();
        $edition = array();
        foreach ($data as $key => $row) {
            $volume[$key]  = $row[$field1];
            $edition[$key] = $row[$field2];
        }

        $arr_ret = array($volume,$edition);


        array_multisort($arr_ret[0], SORT_DESC, SORT_NUMERIC,
            $arr_ret[1],  SORT_STRING,SORT_ASC);

        $ccount = count($arr_ret[0]);

        for($i=0; $i<$ccount;$i++)
        {
            $arr_v[] = array("$field1"=>$arr_ret[0][$i],"$field2"=>$arr_ret[1][$i]);
        }

        return $arr_v;
    }

    /**
     * set cookie value
     *
     * @param $name
     * @param $val
     */
    private function setCookie($name,$val)
    {
        $cookie = new CHttpCookie($name, $val);  // define cookie for from_date
        $cookie->expire = time() + (60*60);
        Yii::app()->request->cookies[$name] = $cookie;
    }

    /**
     * added js and css file
     */
    private function turnOn()
    {
        $baseUrl = Yii::app()->baseUrl;
        $cs = Yii::app()->clientScript;
        $cs->registerCssFile($baseUrl.'/css/bootstrap-datetimepicker.min.css');
        $cs->registerCssFile($baseUrl.'/css/bootstrap-switch.css');
        $cs->registerScriptFile('https://www.google.com/jsapi');
        $cs->registerScriptFile(Yii::app()->baseUrl . '/js/libs/bootstrap-datetimepicker.min.js', CClientScript::POS_HEAD);
        $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/pie.js', CClientScript::POS_HEAD);
        $cs->registerScriptFile(Yii::app()->baseUrl . '/js/controller/history.js', CClientScript::POS_HEAD);
        $cs->registerScriptFile(Yii::app()->baseUrl . '/js/libs/bootstrap-switch.js', CClientScript::POS_HEAD);
    }

}