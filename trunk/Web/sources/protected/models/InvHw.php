<?php

/**
 * This is the model class for table "inv_hw".
 *
 * The followings are the available columns in table 'inv_hw':
 * @property integer $router_id
 * @property string $hw_item
 * @property string $hw_name
 * @property string $hw_version
 * @property string $hw_amount
 *
 * The followings are the available model relations:
 * @property Routers $router
 */
class InvHw extends CActiveRecord
{
    public $router_name;

    /**
     * @return string the associated database table name
     */
    public function tableName()
    {
        return 'inv_hw';
    }

    /**
     * @return array validation rules for model attributes.
     */
    public function rules()
    {
        // NOTE: you should only define rules for those attributes that
        // will receive user inputs.
        return array(
            array('router_id, hw_item', 'required'),
            array('router_id', 'numerical', 'integerOnly' => true),
            array('hw_item', 'length', 'max' => 50),
            array('hw_name, hw_version', 'length', 'max' => 100),
            array('hw_amount', 'length', 'max' => 30),
            // The following rule is used by search().
            // @todo Please remove those attributes that should not be searched.
            array('router_id, hw_item, hw_name, hw_version, hw_amount,router_name', 'safe', 'on' => 'search'),
        );
    }

    public function setPrimaryKey()
    {
        return 'router_id';
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
            'hw_item' => 'Hw Item',
            'hw_name' => 'Hw Name',
            'hw_version' => 'Hw Version',
            'hw_amount' => 'Hw Amount',
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

        $criteria = new CDbCriteria;
        $criteria->with = array('router');
        $criteria->compare('router_id', $this->router_id);
        $criteria->compare('hw_item', $this->hw_item, true);
        $criteria->compare('hw_name', $this->hw_name, true);
        $criteria->compare('hw_version', $this->hw_version, true);
        $criteria->compare('hw_amount', $this->hw_amount, true);
        $criteria->compare('router.name', $this->router_name, true);

        return new CActiveDataProvider($this, array(
            'criteria' => $criteria,
        ));
    }

    public function searchGroup()
    {

        $criteria = new CDbCriteria;
        $criteria->select = 'router_id,hw_item,hw_name,hw_version,hw_amount';
        $criteria->group = 'router_id';
        $this->setPrimaryKey();
        return new CActiveDataProvider($this, array(
            'criteria' => $criteria,
        ));

    }

    /**
     * Return results of searching by HW name
     *
     * @param $str
     * @return mixed
     */
    public function searchByName($str)
    {
        $sql = 'SELECT t.router_id AS r_id1, trim(t.hw_name) AS name, trim(t.hw_version) AS version, trim(router.name) AS router_name, '
            . 'router.router_id AS r_id2 FROM inv_hw t  '
            . 'LEFT OUTER JOIN routers router ON (t.router_id=router.router_id)  '
            . 'WHERE (lower(hw_name) LIKE \'%' . strtolower($str) . '%\') '
            . 'GROUP BY t.router_id,t.hw_name,t.hw_version,router.name,router.router_id';

        $arr_hw = Yii::app()->db->createCommand($sql)
            ->queryAll();
        return ($arr_hw);

    }

    /**
     * Return results of searching by HW version
     *
     * @param $str
     * @return mixed
     */
    public function searchByVersion($str)
    {
        $sql = "SELECT t.router_id AS r_id1, CASE WHEN trim(t.hw_name)='' THEN 'N/A' ELSE trim(t.hw_name) END AS name, t.hw_version AS version, router.name AS router_name, "
            . 'router.router_id AS r_id2 FROM inv_hw t  '
            . 'LEFT OUTER JOIN routers router ON (t.router_id=router.router_id)  '
            . 'WHERE (lower(hw_version) LIKE \'%' . strtolower($str) . '%\') '
            . 'GROUP BY t.router_id,t.hw_name,t.hw_version,router.name,router.router_id';

        $arr_hw = Yii::app()->db->createCommand($sql)
            ->queryAll();

        return ($arr_hw);

    }

    /**
     * Return report by part number
     *
     * @param int $number_of_page
     * @return CArrayDataProvider
     */
    public function reportByPartNumber($number_of_page = 25)
    {
        $amount = 0;
        $cond = array();
        $this->isNoEmpty($this->hw_name, 'hw_name', $amount, $cond);
        $this->isNoEmpty($this->hw_version, 'hw_version', $amount, $cond);
        $this->isNoEmpty($this->router_name, 'r.name', $amount, $cond);
        $this->isNoEmpty($this->hw_item, 'hw_item', $amount, $cond);
        $cond[$amount] = "h.router_id=r.router_id ";
        $condition = implode(" and ", $cond);
        $sql = "select h.router_id as id,CASE WHEN trim(hw_name)='' THEN 'N/A' ELSE trim(hw_name) END as hw_name,CASE WHEN trim(hw_version)='' THEN 'N/A' ELSE trim(hw_version) END as hw_version, count(*) as amount,r.name as router_name,hw_item "
            . "from inv_hw h,routers r "
            . "where " . $condition
            . "group by h.router_id,hw_name,hw_version,r.name,hw_item "
            . "order by 2,1";

        $arr_hw = Yii::app()->db->createCommand($sql)
            ->queryAll();

        return new CArrayDataProvider($arr_hw, array(
                'sort' => array(
                    'attributes' => array(
                        'hw_name', 'hw_version', 'router_name', 'amount', 'hw_item'
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
     * @return InvHw the static model class
     */
    public static function model($className = __CLASS__)
    {
        return parent::model($className);
    }
}
