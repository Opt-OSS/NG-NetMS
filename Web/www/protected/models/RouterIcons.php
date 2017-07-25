<?php

/**
 * This is the model class for table "router_icons".
 *
 * The followings are the available columns in table 'router_icons':
 * @property integer $id
 * @property string $vendor_name
 * @property integer $router_state
 * @property string $img_path
 * @property integer $size_w
 * @property integer $size_h
 *
 * The followings are the available model relations:
 * @property RouterStates $routerState
 */
class RouterIcons extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'router_icons';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_state, size_w, size_h', 'numerical', 'integerOnly'=>true),
			array('vendor_name', 'length', 'max'=>40),
			array('img_path', 'length', 'max'=>255),
			// The following rule is used by search().
			array('id, vendor_name, router_state, img_path, size_w, size_h,layer ', 'safe', 'on'=>'search'),
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
			'routerState' => array(self::BELONGS_TO, 'RouterStates', 'router_state'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'vendor_name' => 'Vendor Name',
			'router_state' => 'Router State',
			'img_path' => 'Img Path',
			'size_w' => 'Size W',
			'size_h' => 'Size H',
            'layer' => 'Layer'
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
		$criteria->compare('vendor_name',$this->vendor_name,true);
		$criteria->compare('router_state',$this->router_state);
		$criteria->compare('img_path',$this->img_path,true);
		$criteria->compare('size_w',$this->size_w);
		$criteria->compare('size_h',$this->size_h);
        $criteria->compare('layer',$this->layer);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return RouterIcons the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

    /**
     * check existing of icons for vendor and state
     *
     * @param $r_state
     * @param $vendor_name
     * @return mixed
     */
    public function isImg($r_state,$vendor_name,$layer)
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('count(*) ')
            ->from(' router_icons')
            ->where("vendor_name='".$vendor_name."' AND router_state='".$r_state."' AND layer='".$layer."'")
            ->queryScalar();

        return $arr_data;
    }
}
