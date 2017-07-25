<?php

/**
 * This is the model class for table "router_peers".
 *
 * The followings are the available columns in table 'router_peers':
 * @property integer $id
 * @property integer $router_id
 * @property integer $router_peer_id
 * @property string $peer_type
 * @property string $peer_info
 * @property string $description
 *
 * The followings are the available model relations:
 * @property Routers $routerId
 * @property Routers $routerPeerId
 */
class RouterPeers extends CActiveRecord
{
	/**
	 * @return string the associated database table name
	 */
	public function tableName()
	{
		return 'router_peers';
	}

	/**
	 * @return array validation rules for model attributes.
	 */
	public function rules()
	{
		// NOTE: you should only define rules for those attributes that
		// will receive user inputs.
		return array(
			array('router_id, router_peer_id, peer_type, peer_info', 'required'),
			array('router_id, router_peer_id', 'numerical', 'integerOnly'=>true),
			// The following rule is used by search().
			array('router_id, router_peer_id, peer_type, peer_info, description', 'safe', 'on'=>'search'),
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
			'routerId' => array(self::BELONGS_TO, 'Routers', 'router_id'),
			'routerIdPeer' => array(self::BELONGS_TO, 'Routers', 'router_peer_id'),
		);
	}

	/**
	 * @return array customized attribute labels (name=>label)
	 */
	public function attributeLabels()
	{
		return array(
			'routerId' => 'Host',
			'router_peer_id' => 'Peer',
			'peer_type' => 'Peer Type',
			'peer_info' => 'Peer Info',
			'description' => 'Description',
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

		$criteria->compare('router_id',$this->router_id);
		$criteria->compare('router_peer_id',$this->router_peer_id);
		$criteria->compare('peer_type',$this->peer_type,true);
		$criteria->compare('peer_info',$this->peer_info,true);
		$criteria->compare('description',$this->description,true);

		return new CActiveDataProvider($this, array(
			'criteria'=>$criteria,
		));
	}

	/**
	 * Returns the static model of the specified AR class.
	 * Please note that you should have this exact method in all your CActiveRecord descendants!
	 * @param string $className active record class name.
	 * @return Network the static model class
	 */
	public static function model($className=__CLASS__)
	{
		return parent::model($className);
	}
}
