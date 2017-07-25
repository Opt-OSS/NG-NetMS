<?php

/**
 * This is the model class for table "bgp_routers".
 *
 * The followings are the available columns in table 'bgp_routers':
 * @property integer $id
 * @property string $bgp_type
 * @property integer $status
 * @property string $autonomous_system
 * @property string $ip_addr
 *
 * The followings are the available model relations:
 * @property BgpLinks[] $bgpLinks
 * @property BgpLinks[] $bgpLinks1
 */
class BgpRouters extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'bgp_routers';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('status', 'numerical', 'integerOnly'=>true),
			array('bgp_type', 'length', 'max'=>30),
			array('autonomous_system', 'length', 'max'=>10),
			array('ip_addr', 'safe'),
			// The following rule is used by search().
			array('id, bgp_type, status, autonomous_system, ip_addr', 'safe', 'on'=>'search'),
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
			'bgpLinks' => array(self::HAS_MANY, 'BgpLinks', 'side_a'),
			'bgpLinks1' => array(self::HAS_MANY, 'BgpLinks', 'side_b'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'bgp_type' => 'Bgp Type',
			'status' => 'Status',
			'autonomous_system' => 'Autonomous System',
			'ip_addr' => 'Ip Addr',
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

		$criteria=new CDbCriteria;

		$criteria->compare('id',$this->id);
		$criteria->compare('bgp_type',$this->bgp_type,true);
		$criteria->compare('status',$this->status);
		$criteria->compare('autonomous_system',$this->autonomous_system,true);
		$criteria->compare('ip_addr',$this->ip_addr,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}
    /**
     * Return list of all routers
     *
     * @return mixed
     */
    public function getAll()
    {
        $arr_data  = Yii::app()->db->createCommand()
                                   ->select('id,ip_addr ')
                                   ->from(' bgp_routers')
                                   ->order(' id ')
                                   ->queryAll();

        return $arr_data;
    }

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return BgpRouters the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
