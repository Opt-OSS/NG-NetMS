<?php

/**
 * This is the model class for table "attr_value".
 *
 * The followings are the available columns in table 'attr_value':
 * @property integer $id
 * @property integer $id_attr_access
 * @property integer $id_access
 * @property string $value
 */
class AttrValue extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'attr_value';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('id_attr_access, id_access', 'numerical', 'integerOnly'=>true),
			array('value', 'safe'),
			// The following rule is used by search().
			array('id, id_attr_access, id_access, value', 'safe', 'on'=>'search'),
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
			'id_attr_access' => 'Id Attr Access',
			'id_access' => 'Id Access',
			'value' => 'Value',
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
		$criteria->compare('id_attr_access',$this->id_attr_access);
		$criteria->compare('id_access',$this->id_access);
		$criteria->compare('value',$this->value,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return AttrValue the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

    /**
     * Return value of attribute for defined access
     * @return mixed
     */
    public function getAttrValByAccId()
    {
        $arr_data  = Yii::app()->db->createCommand()
            ->select('ar.name,av.value,av.id')
            ->where(" a.id ='".$this->id_access ."' ")
            ->from(' access a  ')
            ->leftJoin('access_type  at','a.id_access_type = at.id ')
            ->leftJoin('attr_access aa','at.id = aa.id_access_type ')
            ->leftJoin('attr_value av',"av.id_attr_access = aa.id and av.id_access ='".$this->id_access ."' ")
            ->leftJoin('attr ar','aa.id_attr = ar.id')
            ->order(' aa.id ')
            ->queryAll();

        return $arr_data;
    }

    /**
     * check existing of value attribute for defined access
     *
     * @return int
     */
    public function checkValueAttr()
    {
        $id_av = 0;
        $count = AttrValue::Model()->count("id_access=:id_access AND id_attr_access=:id_attr_access",array("id_access" => $this->id_access,"id_attr_access"=>$this->id_attr_access));
        if($count > 0)
        {
            $id_av = Yii::app()->db->createCommand()
                    ->select('id')
                    ->from('attr_value')
                    ->where("id_access ='".$this->id_access."' AND id_attr_access='".$this->id_attr_access."'")
                    ->queryScalar();
        }
        return $id_av;
    }
}
