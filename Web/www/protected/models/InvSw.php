<?php

/**
 * This is the model class for table "inv_sw".
 *
 * The followings are the available columns in table 'inv_sw':
 * @property integer $router_id
 * @property string $sw_item
 * @property string $sw_name
 * @property string $sw_version
 *
 * The followings are the available model relations:
 * @property Routers $router
 */
class InvSw extends CActiveRecord
{
    public $router_name;

    /**
     * @return string the associated database table name
     */
    public function tableName()
    {
        return 'inv_sw';
    }

    /**
     * @return array validation rules for model attributes.
     */
    public function rules()
    {
        // NOTE: you should only define rules for those attributes that
        // will receive user inputs.
        return array(
            array('router_id, sw_item', 'required'),
            array('router_id', 'numerical', 'integerOnly' => true),
            array('sw_item', 'length', 'max' => 50),
            array('sw_name, sw_version', 'length', 'max' => 100),
            // The following rule is used by search().
            array('router_id, sw_item, sw_name, sw_version,router_name', 'safe', 'on' => 'search'),
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
            'router' => array(self::BELONGS_TO, 'Routers', 'router_id'),
        );
    }

    /**
     * @return array customized attribute labels (name=>label)
     */
    public function attributeLabels()
    {
        return array(
            'router_id' => 'Router',
            'sw_item' => 'Sw Item',
            'sw_name' => 'Sw Name',
            'sw_version' => 'Sw Version',
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

        $criteria = new CDbCriteria;

        $criteria->compare('router_id', $this->router_id);
        $criteria->compare('sw_item', $this->sw_item, true);
        $criteria->compare('sw_name', $this->sw_name, true);
        $criteria->compare('sw_version', $this->sw_version, true);
        $criteria->compare('router.name', $this->router_name, true);

        return new CActiveDataProvider($this, array(
            'criteria' => $criteria,
        ));
    }

    /**
     * Return results of chearchig by SW name
     *
     * @param $str
     * @return mixed
     */
    public function searchByName($str)
    {
        $sql = 'SELECT t.router_id AS r_id1, trim(t.sw_item) AS item,trim(t.sw_name) AS name, trim(t.sw_version) AS version, trim(router.name) AS router_name, '
            . 'router.router_id AS r_id2 FROM inv_sw t  '
            . 'LEFT OUTER JOIN routers router ON (t.router_id=router.router_id)  '
            . 'WHERE (lower(sw_name) LIKE \'%' . strtolower($str) . '%\') '
            . 'GROUP BY t.router_id,t.sw_item,t.sw_name,t.sw_version,router.name,router.router_id';

        $arr_sw = Yii::app()->db->createCommand($sql)
            ->queryAll();
        return ($arr_sw);

    }

    /**
     * Return results of chearchig by SW version
     *
     * @param $str
     * @return mixed
     */
    public function searchByVersion($str)
    {
        $sql = "SELECT t.router_id AS r_id1, trim(t.sw_item) AS item,CASE WHEN trim(t.sw_name)='' THEN 'N/A' ELSE trim(t.sw_name) END AS name, t.sw_version AS version, router.name AS router_name, "
            . 'router.router_id AS r_id2 FROM inv_sw t  '
            . 'LEFT OUTER JOIN routers router ON (t.router_id=router.router_id)  '
            . 'WHERE (lower(sw_version) LIKE \'%' . strtolower($str) . '%\') '
            . 'GROUP BY t.router_id,t.sw_item,t.sw_name,t.sw_version,router.name,router.router_id';

        $arr_hw = Yii::app()->db->createCommand($sql)
            ->queryAll();
        return ($arr_hw);

    }

    /**
     * Return results of chearchig by SW item
     *
     * @param $str
     * @return mixed
     */
    public function searchByItem($str)
    {
        $sql = "SELECT t.router_id AS r_id1, trim(t.sw_item) AS item,CASE WHEN trim(t.sw_name)='' THEN 'N/A' ELSE trim(t.sw_name) END AS name, t.sw_version AS version, router.name AS router_name, "
            . 'router.router_id AS r_id2 FROM inv_sw t  '
            . 'LEFT OUTER JOIN routers router ON (t.router_id=router.router_id)  '
            . 'WHERE (lower(sw_item) LIKE \'%' . strtolower($str) . '%\') '
            . 'GROUP BY t.router_id,t.sw_item,t.sw_name,t.sw_version,router.name,router.router_id';

        $arr_hw = Yii::app()->db->createCommand($sql)
            ->queryAll();
        return ($arr_hw);

    }

    /**
     * Create report by SW revision
     *
     * @param int $number_of_page
     * @return CArrayDataProvider
     */
    public function reportByRevision($number_of_page = 25)
    {
        $amount = 0;
        $cond = array();
        $this->isNoEmpty($this->sw_name, 'sw_name', $amount, $cond);
        $this->isNoEmpty($this->sw_version, 'sw_version', $amount, $cond);
        $this->isNoEmpty($this->router_name, 'r.name', $amount, $cond);
        $this->isNoEmpty($this->sw_item, 'sw_item', $amount, $cond);

        $cond[$amount] = "s.router_id=r.router_id ";

        $condition = implode(" and ", $cond);

        $sql = "select s.router_id as id,sw_name,sw_version , count(*) as amount,r.name as router_name,sw_item "
            . "from inv_sw s,routers r "
            . "where " . $condition
            . "group by s.router_id,sw_name,sw_version,r.name,sw_item "
            . "order by 2,1";


        $arr_sw = Yii::app()->db->createCommand($sql)
            ->queryAll();

        return new CArrayDataProvider($arr_sw, array(
                'sort' => array(
                    'attributes' => array(
                        'sw_name', 'sw_version', 'router_name', 'sw_item'
                    ),
                ),

                'pagination' => array(
                    'pageSize' => $number_of_page,
                ),

            )
        );
    }

    /**
     * Check empty or no is value
     *
     * @param $valore
     * @param $name
     * @param $amount
     * @param $cond
     */
    private function isNoEmpty($valore, $name, &$amount, &$cond)
    {
        if (isset($valore) && !empty($valore)) {
            $cond[$amount] = "lower(" . $name . ") like '%" . strtolower($valore) . "%' ";
            $amount++;
        }
    }

    /**
     * Returns the static model of the specified AR class.
     * Please note that you should have this exact method in all your CActiveRecord descendants!
     * @param string $className active record class name.
     * @return InvSw the static model class
     */
    public static function model($className = __CLASS__)
    {
        return parent::model($className);
    }
}
