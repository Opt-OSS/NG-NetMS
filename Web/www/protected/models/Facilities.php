<?php
/**
 * Class Facilities
 */

class Facilities extends Events
{
    public $numofevents;
    public $sumseverity;

    public function search()
    {

        $criteria=new CDbCriteria;

        if(!empty($this->from_date) && empty($this->to_date))
        {
            $criteria->condition = "receiver_ts >= '$this->from_date'";  // date is database date column field
        }
        elseif(!empty($this->to_date) && empty($this->from_date))
        {
            $criteria->condition = "receiver_ts <= '$this->to_date'";
        }
        elseif(!empty($this->to_date) && !empty($this->from_date))
        {
            $criteria->condition = "receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date'";
        }

        $criteria->select = array(
            't.facility,
            count(*) as numofevents,
            sum(severity)  as sumseverity');
        $criteria->compare('facility',$this->facility,true);
        $criteria->group ='facility';


        if(!empty($this->numofevents) && empty($this->sumseverity))
        {
            $criteria->having = 'COUNT(*) > '.$this->numofevents;
        }
        else if (empty($this->numofevents) && !empty($this->sumseverity))
        {
            $criteria->having = 'sum(severity) > '.$this->sumseverity;
        }
        else if(!empty($this->numofevents) && !empty($this->sumseverity))
        {
            $criteria->having = 'COUNT(*) > '.$this->numofevents." AND ".'sum(severity) > '.$this->sumseverity;
        }

        // And add to the CActiveDataProvider
        return new CActiveDataProvider($this, array(
            'criteria'=>$criteria,
            'sort'=>array(
                'defaultOrder'=>'sumseverity DESC',
                'attributes'=>array(
                    'numofevents'=>array(
                        'asc'=>'numofevents',
                        'desc'=>'numofevents DESC',
                    ),
                    'sumseverity'=>array(
                        'asc'=>'sumseverity',
                        'desc'=>'sumseverity DESC',
                    ),
                    'facility'=>array(
                        'asc'=>'facility',
                        'desc'=>'facility DESC',
                    ),
                ),
            ),
            'pagination'=>array(
                'pageSize'=>10,
            ),
        ));
    }

    /**
     * return all events grouped by facility
     *
     * @return mixed
     */
    public function allEventsByFacility()
    {
        $condition = '';

        if(!empty($this->from_date) && empty($this->to_date))
        {
            $condition = "WHERE receiver_ts >= '$this->from_date' ";  // date is database date column field
        }
        elseif(!empty($this->to_date) && empty($this->from_date))
        {
            $condition = "WHERE receiver_ts <= '$this->to_date' ";
        }
        elseif(!empty($this->to_date) && !empty($this->from_date))
        {
            $condition = "WHERE receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date' ";
        }

        $sql = "SELECT facility, count(event_id) as numofevents, sum(severity) as sumseverity ".
            "FROM events ".$condition.
            "group by facility order by sumseverity DESC, numofevents DESC,facility";
        $arr_events = Yii::app()->db->createCommand($sql)
            ->queryAll();

        return $arr_events;
    }

    /**
     * return all events for defined facility
     *
     * @return mixed
     */
    public function allEventsForFacility(){
        $condition = "WHERE facility='".$this->facility."' ";

        if(!empty($this->from_date) && empty($this->to_date))
        {
            $condition .= " AND receiver_ts >= '$this->from_date' ";  // date is database date column field
        }
        elseif(!empty($this->to_date) && empty($this->from_date))
        {
            $condition .= " AND receiver_ts <= '$this->to_date' ";
        }
        elseif(!empty($this->to_date) && !empty($this->from_date))
        {
            $condition .= " AND receiver_ts  >= '$this->from_date' and receiver_ts <= '$this->to_date' ";
        }

        $sql = "SELECT origin, count(event_id) as numofevents, sum(severity) as sumseverity ".
            "FROM events ".$condition.
            "group by origin order by sumseverity DESC, numofevents DESC, origin";
        $arr_events = Yii::app()->db->createCommand($sql)
            ->queryAll();

        return $arr_events;
    }

}