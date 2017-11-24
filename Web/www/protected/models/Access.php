 <?php

 /**
 * This is the model class for table "access".
 *
 * The followings are the available columns in table 'access':
 * @property integer $id
 * @property string $name
 * @property integer $id_access_type
 *
 * The followings are the available model relations:
 * @property AccessType $idAccessType
 */
class Access extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'access';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('id_access_type', 'numerical', 'integerOnly'=>true),
            array('name,id_access_type', 'required'),
			array('name', 'length', 'max'=>150),
			// The following rule is used by search().
			array('id, name, id_access_type', 'safe', 'on'=>'search'),
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
			'idAccessType' => array(self::BELONGS_TO, 'AccessType', 'id_access_type'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'id' => 'ID',
			'name' => 'Name',
			'id_access_type' => 'Id Access Type',
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
		$criteria->compare('name',$this->name,true);
		$criteria->compare('id_access_type',$this->id_access_type);
        $criteria->with=array('idAccessType');

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Access the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}

    public function getWrappableMethods(){
        $arr_data  = Yii::app()->db->createCommand()
            ->select('id,name')
            ->from('access')
            ->where("id_access_type in (1,2,3)")
            ->order('name')
            ->queryAll();

        return $arr_data;
    }
}
