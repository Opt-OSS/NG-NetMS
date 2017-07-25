<?php

class ArchiveConfController extends Controller
{
	public function actionIndex()
	{
		$this->render('index');
	}

    public function actionSetconfiguration()
    {
        if (!Yii::app()->user->isGuest)
        {
            if (Yii::app()->request->isAjaxRequest )
            {
                $count = ArchiveConf::model()->count();

                if($count > 0)
                {
                    $id_conf = 1;
                    $model = ArchiveConf::model()->findByPk($id_conf);
                }
                else
                {
                    $model = new ArchiveConf;
                }
                $model->arc_expire = trim($_POST['old_period']);
                $model->arc_delete = trim($_POST['del_period']);
                $model->arc_period = trim($_POST['exp_period']);
                $model->arc_path = trim($_POST['arc_path']);
                $model->arc_enable = $_POST['arc_enable'] == 1 ? 1 : 0;
                $model->arc_gzip = $_POST['arc_gzip'] == 1 ? 1 : 0;

                if($model->save())
                {
//                    $arr_attr=array();
//                    $str_1 = substr(Yii::app()->db->connectionString,6);
//                    $arr1 = explode(";",$str_1);
//
//                    foreach($arr1 as $key=>$val)
//                    {
//                        $arr2 = explode("=",$val);
//                        $arr_attr[$arr2[0]] = $arr2[1];
//                    }
//
//                    $ngnms_params = Yii::app()->params['ngnms'];
//                    $NGHOME = $ngnms_params['home'];
//                    chdir($NGHOME.'/bin/');
//                    putenv("NGNMS_DEBUG=" . $ngnms_params['log']['level']);
//                    putenv("NGNMS_HOME=".$ngnms_params['home']);
//                    putenv('NGNMS_CONFIGS='.$ngnms_params['config']);
//                    putenv('NGNMS_LOGFILE=' . $ngnms_params['log']['file']);
//                    putenv("PATH=$NGHOME/bin:/usr/bin");
//                    putenv("PERL5LIB=$NGHOME/bin:$NGHOME/lib:$NGHOME/lib/Net:/usr/local/share/perl/5.18.2'");
//                    putenv("MIBDIRS=$NGHOME/mibs");
//
//
//                    $arr_attr['username'] = Yii::app()->db->username;
//                    $arr_attr['password'] = Yii::app()->db->password;
//
//
//                    if( $model->arc_enable > 0)
//                    {
//                        $command1 = '/usr/bin/perl archive.pl --start';
//                    }
//                    else
//                    {
//                        $command1 = '/usr/bin/perl archive.pl --stop';
//                    }
//
//                    if(isset($arr_attr['host']) )
//                    {
//                        $command1 .= " -L ".$arr_attr['host'];
//                    }
//
//                    if(isset($arr_attr['dbname']) )
//                    {
//                        $command1 .= " -D ".$arr_attr['dbname'];
//                    }
//
//                    if(isset($arr_attr['username']))
//                    {
//                        $command1 .= " -U ".$arr_attr['username'];
//                    }
//
//                    if(isset($arr_attr['password']))
//                    {
//                        $command1 .= " -W ".$arr_attr['password'];
//                    }
//
//                    if(isset($arr_attr['port']))
//                    {
//                        $command1 .= " -P ".$arr_attr['port'];
//                    }
//                    ob_start();
//                    $escaped_command1 = escapeshellcmd($command1);
//                    $sss=system($escaped_command1);
//                    $debug = ob_get_clean();
                    $data = array("ok"=>1,'debug'=>$debug);
                }
                else
                {
                    $data = array("ok"=>-1,'debug'=>$model->getErrors());
                }
                echo json_encode($data);
            }
        }
        else
        {
            $this->redirect('index.php?r=site/login');
        }
    }
}