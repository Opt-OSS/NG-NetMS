<?php

/**
 * This is the model class for table "events".
 *
 * The followings are the available columns in table 'events':
 * @property integer $event_id
 * @property string $origin_ts
 * @property string $receiver_ts
 * @property string $origin
 * @property integer $origin_id
 * @property string $facility
 * @property string $code
 * @property string $descr
 * @property string $priority
 * @property integer $severity
 */
class Events extends CActiveRecord
{
    public $numofevents;
    public $sumseverity;
    public $from_date;
    public $to_date;
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'events';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('origin_id, severity', 'numerical', 'integerOnly'=>true),
			array('origin, facility, code', 'length', 'max'=>64),
			array('descr', 'length', 'max'=>10000),
			array('priority', 'length', 'max'=>10),
			array('origin_ts, receiver_ts', 'safe'),
            array('sumseverity','numerical','integerOnly'=>true, 'message'=>'Value must be int','min'=>1,'tooSmall'=>'You must input value  at least 1 ','on'=>'search'),
            array('numofevents','numerical','integerOnly'=>true,'message'=>'Value must be int','min'=>1,'tooSmall'=>'You must input value  at least 1 ','on'=>'search'),
            array('numofevents', 'match', 'pattern'=>'/^[0-9]+$/','message'=>'Value must be int','on'=>'search'),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('event_id, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, priority, severity,sumseverity,numofevents', 'safe', 'on'=>'search'),
            array('event_id, origin_ts, receiver_ts, origin, origin_id, facility, code, descr, priority, severity,sumseverity,numofevents', 'safe', 'on'=>'allEventsOriginPeriod'),
		);
	}

	/**
	 * @return array relational rules.
	 */
	public function relations()
	{
		// NOTE: you may need to adjust the relation name and the related
		// class name for the relations automatically generated below.
		return array(
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'event_id' => 'Event',
			'origin_ts' => 'Origin Ts',
			'receiver_ts' => 'Receiver Ts',
			'origin' => 'Origin',
			'origin_id' => 'Origin',
			'facility' => 'Facility',
			'code' => 'Code',
			'descr' => 'Descr',
			'priority' => 'Priority',
			'severity' => 'Severity',
            'sumseverity'=>'Cumulative Severity',
            'numofevents'=>'Number of Events'
		);
	}

	/**
	 * Retrieves a list of models based on the current search/filter conditions.
	 *
	 * Typical usecase:
	 * - Initialize the model fields with values from filter form.
	 * - Execute this method to get CActiveDataProvider instance which will filter
	 * models according to data in model fields.
	 * - Pass data provider to CGridView, CListView or any similar widget.
	 *
	 * @return CActiveDataProvider the data provider that can return the models
	 * based on the search/filter conditions.
	 */
	public function search()
	{
		// @todo Please modify the following code to remove attributes that should not be searched.

/*		$criteria=new CDbCriteria;

		$criteria->compare('event_id',$this->event_id);
		$criteria->compare('origin_ts',$this->origin_ts,true);
		$criteria->compare('receiver_ts',$this->receiver_ts,true);
		$criteria->compare('origin',$this->origin,true);
		$criteria->compare('origin_id',$this->origin_id);
		$criteria->compare('facility',$this->facility,true);
		$criteria->compare('code',$this->code,true);
		$criteria->compare('descr',$this->descr,true);
		$criteria->compare('priority',$this->priority,true);
		$criteria->compare('severity',$this->severity);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));*/
        $criteria=new CDbCriteria;
/*        $events_table = Events::model()->tableName();
        $wh1 = '';*/
        if(!empty($this->from_date) && empty($this->to_date))
        {
            $criteria->condition = "receiver_ts >= '$this->from_date'";  // date is database date column field
//            $wh1 = " and events.receiver_ts >= '$this->from_date'";
        }else if(!empty($this->to_date) && empty($this->from_date))
        {
            $criteria->condition = "receiver_ts <= '$this->to_date'";
//            $wh1 = " and events.receiver_ts <= '$this->to_date'";
        }else if(!empty($this->to_date) && !empty($this->from_date))
        {
            $criteria->condition = "receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date'";
//            $wh1 = " and events.receiver_ts  >= '$this->from_date' and events.receiver_ts <= '$this->to_date'";
        }
 /*       $events_count_sql = "(select count(*) from $events_table where $events_table.origin = t.origin ".$wh1.")";
        $events_sum_severity = "(select sum(severity) from $events_table where $events_table.origin = t.origin ".$wh1.")";
        $criteria->select = array(
            't.origin,t.origin_id',
            $events_count_sql . " as numofevents",
            $events_sum_severity . " as sumseverity"
        );
        $criteria->group ='t.origin,t.origin_id';

        $criteria->compare($events_count_sql, $this->numofevents );
        $criteria->compare($events_sum_severity, $this->sumseverity );*/
        $criteria->select = array(
            't.origin,t.origin_id,
            count(*) as numofevents,
            sum(severity)  as sumseverity');


        // Set the CActiveDataProvider to order by the visitor count
//        $criteria->order = 'sumseverity DESC,numofevents DESC';
        $criteria->compare('origin',$this->origin,true);
        if(!empty($this->numofevents) && empty($this->sumseverity))
        {
            $criteria->having = 'COUNT(*) > '.$this->numofevents;
        }
        else if (empty($this->numofevents) && !empty($this->sumseverity))
        {
            $criteria->having = 'sum(severity) > '.$this->sumseverity;
        }
        else if(!empty($this->numofevents) && !empty($this->sumseverity))
        {
            $criteria->having = 'COUNT(*) > '.$this->numofevents." AND ".'sum(severity) > '.$this->sumseverity;
        }

        $criteria->group ='t.origin,t.origin_id';

        // And add to the CActiveDataProvider
        return new CActiveDataProvider($this, array(
            'criteria'=>$criteria,
            'sort'=>array(
                'defaultOrder'=>'sumseverity DESC',
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
            'pagination'=>array(
                'pageSize'=>50,
            ),
        ));
	}

    /**
     * return list of all events grouped by origin
     *
     * @return mixed
     */
    public function allEventsByOrigin()
        {
            $condition = '';
            if(!empty($this->from_date) && empty($this->to_date))
            {
                $condition = "WHERE receiver_ts >= '$this->from_date' ";  // date is database date column field
            }elseif(!empty($this->to_date) && empty($this->from_date))
            {
                $condition = "WHERE receiver_ts <= '$this->to_date' ";
            }elseif(!empty($this->to_date) && !empty($this->from_date))
            {
                $condition = "WHERE receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date' ";
            }
            $sql = "SELECT origin_id,origin, count(event_id) as numofevents, sum(severity) as sumseverity ".
                   "FROM events ".$condition.
                    "group by origin_id,origin order by sumseverity DESC, numofevents DESC,origin  ";

            $arr_events = Yii::app()->db->createCommand($sql)
                ->queryAll();

            return $arr_events;

        }

    /**
     * return all events for defined origin
     *
     * @return mixed
     */
    public function allEventsForOrigin()
        {
            if($this->origin_id > 0)
                $condition = "WHERE origin_id='".$this->origin_id."' ";
            else
                $condition = "WHERE origin='".$this->origin."' AND  origin_id='".$this->origin_id."' ";

            if(!empty($this->from_date) && empty($this->to_date))
            {
                $condition .= " AND receiver_ts >= '$this->from_date' ";  // date is database date column field
            }elseif(!empty($this->to_date) && empty($this->from_date))
            {
                $condition .= " AND receiver_ts <= '$this->to_date' ";
            }elseif(!empty($this->to_date) && !empty($this->from_date))
            {
                $condition .= " AND receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date' ";
            }
            $sql = "SELECT facility, count(event_id) as numofevents, sum(severity) as sumseverity ".
                "FROM events ".$condition.
                "group by facility order by sumseverity DESC, numofevents DESC, facility";

            $arr_events = Yii::app()->db->createCommand($sql)
                ->queryAll();

            return $arr_events;
        }

    public function allEventsOriginPeriod()
    {
        $criteria=new CDbCriteria;
        $criteria->condition = "origin_id='".$this->origin_id."' AND origin ='" .$this->origin."'";

        if(!empty($this->from_date) && empty($this->to_date))
        {
            $criteria->condition .= " AND receiver_ts >= '$this->from_date'";  // date is database date column field

        }else if(!empty($this->to_date) && empty($this->from_date))
        {
            $criteria->condition = " AND receiver_ts <= '$this->to_date'";
        }else if(!empty($this->to_date) && !empty($this->from_date))
        {
            $criteria->condition .= " AND receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date'";

        }

// Pattern for not equal
        $pattern = '/^<>/';
        $matches_r = array();

// Pattern for rexex
        $pattern_r = '#<regex>(.*?)</regex>#'; // note I changed the pattern a bit

## Block of DESCRIPTION
// Search regex tag in search string of description
        preg_match($pattern_r, $this->descr, $matches_r);

        if(count($matches_r) > 0)
        {
// String of search is regex
            preg_match($pattern, $matches_r[1], $matches_rr, PREG_OFFSET_CAPTURE);

            if(count($matches_rr) > 0)
            {
// Regex is NOT condition
                $str_sr = substr($matches_r[1],2);
                $criteria->condition .= " AND descr !~* '".$str_sr."'";
            }
            else
            {
// Regex is NORMAL(regular) condition
                $criteria->condition .= " AND descr ~* '".$matches_r[1]."'";
            }
        }
        else
        {
// String of search is not regex(plain text)
            preg_match($pattern, $this->descr, $matches1, PREG_OFFSET_CAPTURE);

            if(count($matches1) > 0)
            {
// Condition contains symbol  NOT('<>')
                $str_s1 = substr($this->descr,2);
                $criteria->addSearchCondition('descr',$str_s1 ,true, 'AND', 'NOT LIKE');
            }
            else
            {
// Condition doesn't contain symbol NOT
                $criteria->addSearchCondition('descr', $this->descr,true, 'AND', 'LIKE');
            }
        }

## END block of description

## Block of FACILITY
        $matches_r1 = array();

// Search regex tag in search string of facility
        preg_match($pattern_r, $this->facility, $matches_r1);

        if(count($matches_r1) > 0)
        {
// String of search is regex
            preg_match($pattern, $matches_r1[1], $matches_rr1, PREG_OFFSET_CAPTURE);

            if(count($matches_rr1) > 0)
            {
// Regex contains NOT symbol(<>)
                $str_sr1 = substr($matches_r1[1],2);
                $criteria->condition .= " AND facility !~* '".$str_sr1."'";
            }
            else
            {
// Regex is NORMAL condition
                $criteria->condition .= " AND facility ~* '".$matches_r1[1]."'";
            }
        }
        else
        {
// String of search is not regex, it is plain text
            preg_match($pattern, $this->facility, $matches, PREG_OFFSET_CAPTURE);

            if(count($matches) > 0)
            {
// String contains NOT symbol
                $str_s = substr($this->facility,2);
                $criteria->addSearchCondition('facility',$str_s ,true, 'AND', 'NOT LIKE');
            }
            else
            {
// String does not contain NOT symbol
                $criteria->addSearchCondition('facility', $this->facility,true, 'AND', 'LIKE');
            }
        }

## END block of FACILITY
        $criteria->compare('severity',$this->severity);
        $criteria->compare("to_char(receiver_ts, 'YYYY-MM-DD HH24:MI:SS')",$this->receiver_ts,true);
        $criteria->compare("to_cahr(origin_ts, 'YYYY-MM-DD HH24:MI:SS')",$this->origin_ts,true);

        $criteria->compare('code',$this->code,true);


        $criteria->select = array('t.*');

        return new CActiveDataProvider($this, array(
            'criteria'=>$criteria,
            'sort'=>array(
                'defaultOrder'=>'receiver_ts ASC',
                'attributes'=>array(
                    'receiver_ts'=>array(
                        'asc'=>'receiver_ts',
                        'desc'=>'receiver_ts DESC',
                    ),
                    'origin_ts'=>array(
                        'asc'=>'origin_ts',
                        'desc'=>'origin_ts DESC',
                    ),
                    'facility'=>array(
                        'asc'=>'facility',
                        'desc'=>'facility DESC',
                    ),
                    'severity'=>array(
                        'asc'=>'severity',
                        'desc'=>'severity DESC',
                    ),
                ),
            ),
            'pagination'=>array(
                'pageSize'=>10,
            ),
        ));

    }

        public function setNumofevents($num)
        {
            $this->numofevents = $num;
        }
        
        public function setSeverity($num)
        {
            $this->severity = $num;
        }

        public function setFromdate($val)
        {
            $dat1 = DateTime::createFromFormat('d/m/Y H:i:s', $val);
            $this->from_date = $dat1->format('Y-m-d H:i:s');
        }

        public function setTodate($val)
        {
            $dat1 = DateTime::createFromFormat('d/m/Y H:i:s', $val);
            $this->to_date = $dat1->format('Y-m-d H:i:s');
        }

    public function historyEvents($start,$step,$period)
    {

        $arr_dat = array();
        $arr_sev = array();
        $arr_ret = array();
        if(empty($start))
            $date2 = $this->maxDateForRouterEvenrs();
        else
            $date2 = $start;


        $d2 = new DateTime($date2);
        $d1 = new DateTime($date2);
        $d1->modify('-'.$period.' second');
        $start_data = $d1->format('Y-m-d H:i:s');
        $stop_data = $d2->format('Y-m-d H:i:s');

        $query0 = "select ceil(date_part('epoch',to_timestamp('$stop_data','YYYY-MM-DD HH24:MI:SS'))::int/$step) ";
        $maxgrp = Yii::app()->db->createCommand($query0)->queryScalar();
        $mingrp = $maxgrp - Yii::app()->params['point_on_chart'];

        $condition = ' WHERE ';

        if($this->origin_id > 0)
        {
            $condition .="origin_id ='".$this->origin_id."' ";
        }
        else
        {
            $condition .="origin ='".$this->origin."' ";
        }

        $condition .= "AND receiver_ts between '".$start_data."' and '".$stop_data."' ";
        $groupby = ' group by grp';
        $orderby = ' order by grp';

//        $query = "select date_part('epoch',max(receiver_ts))::int,sum(severity),ceil(date_part('epoch',receiver_ts)::int/$step) as grp FROM  events ".$condition.$groupby.$orderby;
        $query = "select max(receiver_ts) as dat ,sum(severity) as severity,ceil(date_part('epoch',receiver_ts)::int/$step) as grp FROM  events ".$condition.$groupby.$orderby;
        $arr_events = Yii::app()->db->createCommand($query)
            ->queryAll();

        foreach($arr_events as $event)
        {
            $arr_dat[$event['grp']] = $event['dat'];
            $arr_sev[$event['grp']] = $event['severity'];
        }

//        $arr_ret[]=array('Date','Events');


        for($i=1;$i <= Yii::app()->params['point_on_chart'];$i++)
        {
            $flag = $mingrp+$i;
            $d1->modify('+'.$step.' second');
            $dd = $d1->format('F d, Y H:i:s');

            if(isset($arr_sev[$flag]))
            {
/*                $d3 = new DateTime($arr_dat[$flag]);
                $arr_ret[]=array($d3->format('Y-m-d H:i:s'),$arr_sev[$flag]);*/
                $arr_ret[]=array($dd,$arr_sev[$flag]);
            }
            else
            {
                $arr_ret[]=array($dd,0);
            }
        }

        return $arr_ret;

    }

    public static function findEventsForRouterByPeriod($id,$dat1,$dat2)
    {
        $cond ="";
        $arr_data = array();

        if(!empty($dat1) && !empty($dat2))
        {
            $cond = "AND receiver_ts between '".$dat1."' and '".$dat2."' ";

            $arr_data = Yii::app()->db->createCommand()
                ->select('*')
                ->where("origin_id ='".$id."' ".$cond)
                ->from("events")
                ->order('receiver_ts')
                ->queryAll();
        }

        return $arr_data;
    }


    public function maxDateForRouterEvenrs()
    {
        $query = "SELECT max(receiver_ts) FROM events WHERE origin_id = '".$this->origin_id."'";

        return Yii::app()->db->createCommand($query)
            ->queryScalar();
    }

    public function minDateForRouterEvenrs()
    {
        $query = "SELECT min(receiver_ts) FROM events WHERE origin_id = '".$this->origin_id."'";

        return Yii::app()->db->createCommand($query)
            ->queryScalar();
    }

    public function getOrigin()
    {
        return $this->origin;
    }

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Events the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

}

