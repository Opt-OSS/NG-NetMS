<?php

/**
 * SBaseController class file.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * SBaseController must be extended by all of the applications controllers
 * if the auto srbac should be used.
 * You can import it in your main config file as<br />
 * 'import'=>array(<br />
 * 'application.modules.srbac.controllers.SBaseController',<br />
 * ),
 *
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.controllers
 * @since 1.0.2
 */
Yii::import("srbac.components.Helper");
class SBaseController extends CController {

  	protected $mainMenu = array();
        protected $subMenu = array();
	public function init(){
       
        
        $mainMenu = Menu::getMainMenu( );
        $this->mainMenu = $mainMenu['items'];
		
	   foreach($mainMenu['id'] as $chiave=>$valore)
	{   
       $this->subMenu[$chiave] = Menu::getSubMenu( $valore);
	   $this->mainMenu[$chiave]['items'] = $this->subMenu[$chiave] ;
	
	}
    }
  /**
   * Checks if srbac access is granted for the current user
   * @param String $action . The current action
   * @return boolean true if access is granted else false
   */
  protected function beforeAction($action) {
    $del = Helper::findModule('srbac')->delimeter;
    //srbac access
    $mod = $this->module !== null ? $this->module->id . $del : "";
    $contrArr = explode($del, $this->id);
    $contrArr[sizeof($contrArr) - 1] = ucfirst($contrArr[sizeof($contrArr) - 1]);
    $controller = implode(".", $contrArr);

    $contr = str_replace($del, ".", $this->id);
	  $baseUrl = Yii::app()->baseUrl;
	  $cs = Yii::app()->getClientScript();
	  $cs->registerCssFile($baseUrl.'/themes/bootstrap/css/bootstrap.min.css');

    $access = $mod . $controller . ucfirst($this->action->id);

    //Always allow access if $access is in the allowedAccess array
    if (in_array($access, $this->allowedAccess())) {
      return true;
    }

    //Allow access if srbac is not installed yet
    if (!Yii::app()->getModule('srbac')->isInstalled()) {
      return true;
    }
    //Allow access when srbac is in debug mode
    if (Yii::app()->getModule('srbac')->debug) {
      return true;
    }
    // Check for srbac access
    if (!Yii::app()->user->checkAccess($access) || Yii::app()->user->isGuest) {
      $this->onUnauthorizedAccess();
    } else {
      return true;
    }
  }

  /**
   * The auth items that access is always  allowed. Configured in srbac module's
   * configuration
   * @return The always allowed auth items
   */
  protected function allowedAccess() {
    Yii::import("srbac.components.Helper");
    return Helper::findModule('srbac')->getAlwaysAllowed();
  }

  protected function onUnauthorizedAccess() {
    /**
     *  Check if the unautorizedacces is a result of the user no longer being logged in.
     *  If so, redirect the user to the login page and after login return the user to the page they tried to open.
     *  If not, show the unautorizedacces message.
     */
    if (Yii::app()->user->isGuest) {
      Yii::app()->user->loginRequired();
    } else {
      $mod = $this->module !== null ? $this->module->id : "";
      $access = $mod . ucfirst($this->id) . ucfirst($this->action->id);
      $error["code"] = "403";
      $error["title"] = Helper::translate('srbac', 'You are not authorized for this action');
      $error["message"] = Helper::translate('srbac', 'Error while trying to access') . ' ' . $mod . "/" . $this->id . "/" . $this->action->id . ".";
      //You may change the view for unauthorized access
      if (Yii::app()->request->isAjaxRequest) {
        $this->renderPartial(Yii::app()->getModule('srbac')->notAuthorizedView, array("error" => $error));
      } else {
        $this->render(Yii::app()->getModule('srbac')->notAuthorizedView, array("error" => $error));
      }
      return false;
    }
  }

}

