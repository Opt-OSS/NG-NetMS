<?php
/**
 * installText.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The installation text.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.install
 * @since 1.0.0
 */
 ?>
<div align="left">
  Press install to create the tables needed for srbac module.<br />
  You must have a database, authManager component and the srbac module
  configured in your application's configuration.<br />
  The module configuration must be like this:
  (For more detailed information check the srbac guide)
  <?php $this->beginWidget('CTextHighlighter',array('language'=>'php')) ?>
  'modules'=>array('srbac'=>
  array(
      // Your application's user class (default: User)
      "userclass"=>"User",
      // Your users' table user_id column (default: userid)
      "userid"=>"user_id",
      // your users' table username column (default: username)
      "username"=>"user_name",
      // If in debug mode (default: false)
      // In debug mode every user (even guest) can admin srbac, also
      //if you use internationalization untranslated words/phrases
      //will be marked with a red star
      "debug"=>true,
      //The delimeter between modulename and auth item name for authitems in modules
      // (default "-")
      "delimeter"=>"@",
      // The number of items shown in each page (default:15)
      "pageSize"=>8,
      // The name of the super user
      "superUser" =>"Authority",
      //The name of the css to use
      "css"=>"",
      //The layout to use
      "layout"=>"application.views.layouts.admin",
      //The not authorized page
      "notAuthorizedView"=>"application.views.site.unauthorized",
      // The always allowed actions
      "alwaysAllowed"=>array(
        'SiteLogin','SiteLogout','SiteIndex','SiteAdmin','SiteError',
        'SiteContact'),
      // The operationa assigned to users
      "userActions"=>array(
        "Show","View","List"
      ),
      // The number of lines of the listboxes
      "listBoxNumberOfLines" => 10,
      // The path to the custom images relative to basePath (default the srbac images path)
      //"imagesPath"=>"../images",
      //The icons pack to use (noia, tango)
      "imagesPack"=>"noia",
      // Whether to show text next to the menu icons (default false)
      "iconText"=>true,
    )
  ),
  <?php $this->endWidget('CTextHighlighter') ?>
  The names of the tables are set in your authManager configuration.<br />
  You may change the names of the tables there as you like:
  <?php $this->beginWidget('CTextHighlighter',array('language'=>'php')) ?>
  'authManager'=>array(
  // The type of Manager (Database)
  'class'=>'CDbAuthManager',
  // The database connection used
  'connectionID'=>'db',
  // The itemTable name (default:authitem)
  'itemTable'=>'items',
  // The assignmentTable name (default:authassignment)
  'assignmentTable'=>'assignments',
  // The itemChildTable name (default:authitemchild)
  'itemChildTable'=>'itemchildren',
  ),
  <?php $this->endWidget('CTextHighlighter') ?>
</div>

