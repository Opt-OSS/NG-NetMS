<?php
/**
 * Controller is the customized base controller class.
 * All controller classes for this application should extend from this base class.
 */
class Controller extends CController
{
	/**
	 * @var string the default layout for the controller view. Defaults to '//layouts/column1',
	 * meaning using a single column layout. See 'protected/views/layouts/column1.php'.
	 */
	public $layout='//layouts/column2';
//	public $layout='//layouts/page/default';
	/**
	 * @var array context menu items. This property will be assigned to {@link CMenu::items}.
	 */
	public $menu=array();
	/**
	 * @var array the breadcrumbs of the current page. The value of this property will
	 * be assigned to {@link CBreadcrumbs::links}. Please refer to {@link CBreadcrumbs::links}
	 * for more details on how to specify this property.
	 */
	public $breadcrumbs=array();
	
	protected $mainMenu = array();
        protected $subMenu = array();
	protected $mainEMenu = array();
        protected $subEMenu = array();
	public function init(){
       
        
        $mainMenu = Menu::getMainMenu( );
        $this->mainMenu = $mainMenu['items'];
		
	   foreach($mainMenu['id'] as $chiave=>$valore)
	{   
       $this->subMenu[$chiave] = Menu::getSubMenu( $valore);
	   $this->mainMenu[$chiave]['items'] = $this->subMenu[$chiave] ;
	
	}
	
		$mainEMenu = Menu::getMainEMenu( );
        $this->mainEMenu = $mainEMenu['items'];
		
		foreach($mainEMenu['id'] as $chiaveE=>$valoreE)
	{   
       $this->subEMenu[$chiaveE] = Menu::getSubEMenu( $valoreE);
	   $this->mainEMenu[$chiaveE]['sub'] = $this->subEMenu[$chiaveE] ;
	
	}
	 array_push($this->mainEMenu,array('name'=>'Logout ('.Yii::app()->user->name.')', 'link'=>array('/site/logout')));
    }
    
	/**
     * Check whether user has access to action or not. 
     * 
     * @param CAction $action
     * @return boolean true if has access
     */
    protected function hasAccess ( $action ){
        return Yii::app()->user->checkAccess( $action );
    }
}