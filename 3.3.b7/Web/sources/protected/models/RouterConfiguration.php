<?php

/**
 * This is the model class for table "router_configuration".
 *
 * The followings are the available columns in table 'router_configuration':
 * @property integer $id
 * @property integer $router_id
 * @property string $data
 * @property string $created
 *
 * The followings are the available model relations:
 * @property Routers $router
 */
class RouterConfiguration extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'router_configuration';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id, data, created', 'required'),
			array('router_id', 'numerical', 'integerOnly'=>true),
			// The following rule is used by search().
			// @todo Please remove those attributes that should not be searched.
			array('id, router_id, data, created', 'safe', 'on'=>'search'),
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
			'id' => 'ID',
			'router_id' => 'Router',
			'data' => 'Data',
			'created' => 'Created',
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

		$criteria=new CDbCriteria;

		$criteria->compare('id',$this->id);
		$criteria->compare('router_id',$this->router_id);
		$criteria->compare('data',$this->data,true);
		$criteria->compare('created',$this->created,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

        public function getConfigname()
        {
                return 'Configuration '.$this->created;
        }
        
         public function getRouterCurrentConfig($router_id)
        {
            $sql = 'SELECT * FROM router_configuration t1 '
                    . 'JOIN ( SELECT  MAX(created) AS MAXDATE  FROM router_configuration '
                    . "where router_id = '".$router_id."' ) t2 "
                    . "ON t1.created = t2.MAXDATE AND t1.router_id='".$router_id."'";         
           
            $arr = Yii::app()->db->createCommand($sql)
                ->queryAll();
            if(count($arr))
                return($arr[0]);
            else
                return false;
            
        }
        
	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return RouterConfiguration the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
class RouterConfigurationCompare extends RouterConfiguration
{
    public function __construct(){}
}