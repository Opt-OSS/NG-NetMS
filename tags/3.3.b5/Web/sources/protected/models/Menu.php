<?php

/**
 * Manages  ui application menu
 * 
 */
class Menu extends Controller{
    
    /**
     * Return menu depend on rights of user
     */
    public static function getMainMenu( ){
        $id = array();
        
         $menu  = Yii::app()->db->createCommand()
                     ->select('label, route, name, id, accesslevel')
                     ->where("parentid is NULL")
                     ->from('menuitem')
                     ->order('ordervalue')
                     ->queryAll();         
         
         $_menu = array();
         
         foreach( $menu as $item ) {

                 $id[] = $item['id'];
             
             $_menu[] = array(
                 'label' => $item['label'],
                 'url'   => array($item['route']),
//                 'active' => true,
                 'visible' => ( $item['accesslevel'] ) ? Yii::app()->user->checkAccess( $item['accesslevel'] ) : true,
             );
         }
         
         return  array( 
             'id' => $id, 
             'items' => $_menu 
         ) ;
    }
    
    /**
     * Return submenumenu depend on rights of user
     */
    public static function getSubMenu( $parentid ){
         $menu  = Yii::app()->db->createCommand()
                     ->select('label, route, name, accesslevel')
                     ->where("parentid = '$parentid'")
                     ->from('menuitem')
                     ->order('ordervalue')
                     ->queryAll();

         $_menu = array();
         
         foreach( $menu as $item ) {
             $_menu[] = array(
                 'label' => $item['label'],
                 'url'   => array($item['route']),
                 'visible' => ( $item['accesslevel'] ) ? Yii::app()->user->checkAccess( $item['accesslevel'] ) : true,
             );
         }
         
         return $_menu;        
    }

	/**
	 * Return menu depend on rights of user for EMenu module
	 */
	public static function getMainEMenu( ){
		$id = array();

		$menu  = Yii::app()->db->createCommand()
			->select('label, route, name, id, accesslevel,icon')
			->where("parentid is NULL")
			->from('menuitem')
			->order('ordervalue')
			->queryAll();

		$_menu = array();

		foreach( $menu as $item ) {
            $flag_visible=( $item['accesslevel'] ) ? Yii::app()->user->checkAccess( $item['accesslevel'] ) : true;
			if($flag_visible){
			$id[] = $item['id'];

			$_menu[] = array(
				'name' => $item['label'],
				'link'   => $item['route'],
				'icon'  =>  $item['icon']
				);
			}
		}

		return  array(
			'id' => $id,
			'items' => $_menu
		) ;
	}

	/**
	 * Return submenu depend on rights of user for EMenu module
	 */
	public static function getSubEMenu( $parentid ){
		$menu  = Yii::app()->db->createCommand()
			->select('label, route, name, accesslevel,icon')
			->where("parentid = '$parentid'")
			->from('menuitem')
			->order('ordervalue')
			->queryAll();

		$_menu = array();

		foreach( $menu as $item ) {
			$flag_visible= ($item['accesslevel'] ) ? Yii::app()->user->checkAccess( $item['accesslevel'] ) : true;
			if($flag_visible)
			{
			$_menu[] = array(
				'name' => $item['label'],
				'link'   => $item['route'],
				'icon'  =>  $item['icon']
			);
			}
		}

		return $_menu;
	}

    /**
     * Return item menu with prent item
     *
     * @return mixed
     */
    public static function getMenu(){
        $sql = "
            SELECT
                menuitem.*,
                menu.name as menutype
            FROM    
                menu
            JOIN
                menuitem
            ON  
                menuitem.menutypeid = menu.name
            ORDER BY 
                menuitem.ordervalue
        ";

        return Yii::app()->db->createCommand($sql)
                        ->queryAll();        
    }
}