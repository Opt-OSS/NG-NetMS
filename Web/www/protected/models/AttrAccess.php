<?php

/**
 * This is the model class for table "attr_access".
 *
 * The followings are the available columns in table 'attr_access':
 * @property integer $id
 * @property integer $id_access_type
 * @property integer $id_attr
 */
class AttrAccess extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'attr_access';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('id_access_type, id_attr', 'numerical', 'integerOnly'=>true),
			// The following rule is used by search().
			array('id, id_access_type, id_attr', 'safe', 'on'=>'search'),
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
			'id' => 'ID',
			'id_access_type' => 'Id Access Type',
			'id_attr' => 'Id Attr',
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
		$criteria->compare('id_access_type',$this->id_access_type);
		$criteria->compare('id_attr',$this->id_attr);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

    public function getAttrByAccType()
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('ar.id,ar.name ')
            ->where(" aa.id_access_type ='".$this->id_access_type ."' and aa.id_attr = ar.id ")
            ->from(' attr_access as aa, attr as ar  ')
            ->order(' ar.id ')
            ->queryAll();

        return $arr_data;
    }

    /**
     * Check existing of attribute
     *
     * @param $id_t
     * @param $id_a
     * @return mixed
     */
    public function checkAttr($id_t,$id_a)
    {
        $count = AttrAccess::Model()->count("id_access_type=:id_access_type AND id_attr=:id_attr",array("id_access_type" => $id_t,"id_attr"=>$id_a));
        return $count;
    }

    /**
     * Return attributes list for defined access type
     *
     * @param $id_t
     * @return mixed
     */
    public function getListAttrByAccType($id_t)
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('ar.id,ar.name,aa.id as id_t ')
            ->where(" aa.id_access_type ='".$id_t ."' and aa.id_attr = ar.id ")
            ->from(' attr_access as aa, attr as ar  ')
            ->order(' ar.id ')
            ->queryAll();

        return $arr_data;
    }

    /**
     * return attribute values for access type
     *
     * @param $id_t
     * @param $id_a
     * @return mixed
     */
    public function getListAttrValByAccType($id_t,$id_a)
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('ar.id,ar.name,aa.id as id_t,av.value ')
            ->join ('attr as ar','aa.id_attr = ar.id')
            ->leftJoin('attr_value av',"av.id_attr_access = aa.id and av.id_access ='".$id_a."'" )
            ->where(" aa.id_access_type ='".$id_t ."'")
            ->from(' attr_access as aa   ')
            ->order(' ar.id ')
            ->queryAll();

        return $arr_data;
    }



    /**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return AttrAccess the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
