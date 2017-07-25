<?php

/**
 * This is the model class for table "router_access".
 *
 * The followings are the available columns in table 'router_access':
 * @property integer $id
 * @property integer $id_access
 * @property integer $id_router
 *
 * The followings are the available model relations:
 * @property Access $idAccess
 * @property Routers $idRouter
 */
class RouterAccess extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'router_access';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('id_access, id_router', 'numerical', 'integerOnly'=>true),
			// The following rule is used by search().
			array('id, id_access, id_router', 'safe', 'on'=>'search'),
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
			'idAccess' => array(self::BELONGS_TO, 'Access', 'id_access'),
			'idRouter' => array(self::BELONGS_TO, 'Routers', 'id_router'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'id_access' => 'Id Access',
			'id_router' => 'Id Router',
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
		$criteria->compare('id_access',$this->id_access);
		$criteria->compare('id_router',$this->id_router);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

    /**
     * returns list of routers for access
     *
     * @return mixed
     */
    public function getRouterByAccess()
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('r.router_id,r.name ')
            ->from(' router_access ra,routers r')
            ->where("ra.id_access ='".$this->id_access."' AND r.router_id = ra.id_router")
            ->order(' r.router_id ')
            ->queryAll();

        return $arr_data;
    }

    /**
     * return name of access
     *
     * @return mixed
     */
    public function getAccessName()
    {
        return   Yii::app()->db->createCommand()
            ->select('name ')
            ->where(" id ='".$this->id_access ."'")
            ->from(' access  ')
            ->queryScalar();
    }

    /**
     * check existing record
     *
     * @param $id_a
     * @param $id_r
     * @return mixed
     */
    public function checkAttr($id_a,$id_r)
    {
        $count = RouterAccess::Model()->count("id_access=:id_access AND id_router=:id_router",array("id_access" => $id_a,"id_router"=>$id_r));
        return $count;
    }

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return RouterAccess the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
