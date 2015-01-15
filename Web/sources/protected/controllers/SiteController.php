<?php

class SiteController extends Controller {

    /**
     * Declares class-based actions.
     */
    public function actions() {
        return array(
            // captcha action renders the CAPTCHA image displayed on the contact page
            'captcha' => array(
                'class' => 'CCaptchaAction',
                'backColor' => 0xFFFFFF,
            ),
            // page action renders "static" pages stored under 'protected/views/site/pages'
            // They can be accessed via: index.php?r=site/page&view=FileName
            'page' => array(
                'class' => 'CViewAction',
            ),
        );
    }

    /**
     * This is the default 'index' action that is invoked
     * when an action is not explicitly requested by users.
     */
    public function actionIndex() {
        // renders the view file 'protected/views/site/index.php'
        // using the default layout 'protected/views/layouts/main.php'
//        $this->render('index');
        $defaultRoutes = array();
        if (!Yii::app()->user->isGuest) {
            $menu = Menu::getMenu();
            $menuByTypes = array();

            foreach ($menu as $item) {
                $menuByTypes[$item['menutype']][] = $item;
            }

            foreach ($menuByTypes as $menutype => $menu) {
                $defaultRoutes[$menutype] = $this->getDefaultRoute($menu);
            }
        }
        $this->render('index', array(
            'defaultRoutes' => $defaultRoutes,
        ));
    }

    /**
     * 
     * @param type $menu
     * @return boolean
     */
    private function getDefaultRoute($menu) {
        $menuTree = $this->getTree($menu);

        foreach ($menuTree as $menu) {
            if ($menu['accesslevel']) {
//              if( $this->hasAccess( $menu['accesslevel'] ) ){
                if (isset($menu['children']) && !empty($menu['children'])) {
                    foreach ($menu['children'] as $submenu) {
//                          echo $submenu['accesslevel'] . ' ' .(int)$this->hasAccess( $submenu['accesslevel'] ) . '<br />';
                        if ($this->hasAccess($submenu['accesslevel'])) {
                            return $submenu['route'];
                        }
                    }
                } else {
                    return $menu['route'];
                }
//              }
            }
        }

        return false;
    }

    /**
     * 
     * @param type $items
     * @return type
     */
    private function getTree($items) {
        $menuTree = array();
        $refs = array();

        foreach ($items as $data) {
            $thisref = &$refs[$data['id']];

            $thisref['parentid'] = $data['parentid'];
            $thisref['label'] = $data['label'];
            $thisref['level'] = $data['depthlevel'];
            $thisref['accesslevel'] = $data['accesslevel'];
            $thisref['route'] = $data['route'];

            if ($data['parentid'] == null) {
                $menuTree[$data['id']] = &$thisref;
            } else {
                $refs[$data['parentid']]['children'][$data['id']] = &$thisref;
            }
        }

        return $menuTree;
    }

    /**
     * This is the action to handle external exceptions.
     */
    public function actionError() {
        if ($error = Yii::app()->errorHandler->error) {
            if (Yii::app()->request->isAjaxRequest)
                echo $error['message'];
            else
                $this->render('error', $error);
        }
    }

    /**
     * Displays the contact page
     */
    public function actionContact() {
        $model = new ContactForm;
        if (isset($_POST['ContactForm'])) {
            $model->attributes = $_POST['ContactForm'];
            if ($model->validate()) {
                $name = '=?UTF-8?B?' . base64_encode($model->name) . '?=';
                $subject = '=?UTF-8?B?' . base64_encode($model->subject) . '?=';
                $headers = "From: $name <{$model->email}>\r\n" .
                        "Reply-To: {$model->email}\r\n" .
                        "MIME-Version: 1.0\r\n" .
                        "Content-Type: text/plain; charset=UTF-8";

                mail(Yii::app()->params['adminEmail'], $subject, $model->body, $headers);
                Yii::app()->user->setFlash('contact', 'Thank you for contacting us. We will respond to you as soon as possible.');
                $this->refresh();
            }
        }
        $this->render('contact', array('model' => $model));
    }

    /**
     * Displays the login page
     */
    public function actionLogin() {
        $model = new LoginForm;

        // if it is ajax validation request
        if (isset($_POST['ajax']) && $_POST['ajax'] === 'login-form') {
            echo CActiveForm::validate($model);
            Yii::app()->end();
        }

        // collect user input data
        if (isset($_POST['LoginForm'])) {
            $model->attributes = $_POST['LoginForm'];
            // validate user input and redirect to the previous page if valid
            if ($model->validate() && $model->login())
                $this->redirect(Yii::app()->user->returnUrl);
        }
        // display the login form
        $this->render('login', array('model' => $model));
    }

    /**
     * Logs out the current user and redirect to homepage.
     */
    public function actionLogout() {
        Yii::app()->user->logout();
        $this->redirect(Yii::app()->homeUrl);
    }

}
