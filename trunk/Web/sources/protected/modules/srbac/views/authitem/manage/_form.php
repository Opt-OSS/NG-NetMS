<?php
/**
 * _form.php
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @link http://code.google.com/p/srbac/
 */

/**
 * The create new auth item form.
 *
 * @author Spyros Soldatos <spyros@valor.gr>
 * @package srbac.views.authitem.manage
 * @since 1.0.0
 */
 ?>
<div class="srbacForm">

  <p>
    <?php echo Helper::translate('srbac','Fields with')?> <span class="required">*</span>
    <?php echo Helper::translate('srbac','are required')?>.
  </p>
  <?php echo SHtml::beginForm(); ?>

  <?php echo SHtml::errorSummary($model); ?>

  <div class="simple">
    <?php echo SHtml::activeLabelEx($model,'name'); ?>
    <?php echo SHtml::activeTextField($model,'name',
    $model->name == Helper::findModule('srbac')->superUser ?
    array('size'=>20,'disabled'=>"disabled"): array('size'=>20)); ?>
  </div>
  <div class="simple">
    <?php echo SHtml::activeLabelEx($model,'type'); ?>
    <?php echo SHtml::activeDropDownList($model,'type',AuthItem::$TYPES,
    $model->name == Helper::findModule('srbac')->superUser || $update
    ? array('disabled'=>"disabled"): array()); ?>
  </div>
  <div class="simple">
    <?php echo SHtml::activeLabelEx($model,'description'); ?>
    <?php echo SHtml::activeTextArea($model,'description',array('rows'=>3, 'cols'=>20)); ?>
  </div>
  <?php if(Yii::app()->user->hasFlash('updateSuccess')): ?>
  <div id="message"
       style="color:red;font-weight:bold;font-size:14px;text-align:center
       ;position:relative;border:solid black 2px;background-color:#DDDDDD"
       >
           <?php echo Yii::app()->user->getFlash('updateSuccess'); ?>
           <?php
           Yii::app()->clientScript->registerScript(
               'myHideEffect',
               '$("#message").animate({opacity: 0}, 2000).fadeOut(500);',
               CClientScript::POS_READY
           );
           ?>
  </div>
   <?php elseif(Yii::app()->user->hasFlash('updateError')): ?>
  <div id="message"
       style="color:red;font-weight:bold;font-size:14px;text-align:center
       ;position:relative;border:solid black 2px;background-color:#DDDDDD"
       >
           <?php echo Yii::app()->user->getFlash('updateError'); ?>
           <?php
           Yii::app()->clientScript->registerScript(
               'myHideEffect',
               '$("#message").animate({opacity: 0}, 6000).fadeOut(400);',
               CClientScript::POS_READY
           );
           ?>
  </div>
  <?php endif; ?>
  <div class="simple">
    <?php echo SHtml::activeLabelEx($model,'bizrule'); ?>
    <?php echo SHtml::activeTextArea($model,'bizrule',
    $model->name == Helper::findModule('srbac')->superUser ?
    array('rows'=>3, 'cols'=>20, 'disabled'=>'disabled'):array('rows'=>3, 'cols'=>20)); ?>
  </div>
  <div class="simple">
    <?php echo SHtml::activeLabelEx($model,'data'); ?>
    <?php echo SHtml::activeTextField($model,'data',
    $model->name == Helper::findModule('srbac')->superUser ?
    array('disabled'=>'disabled','size'=>30) : array('size'=>30)); ?>
  </div>
  <?php echo SHtml::hiddenField("oldName",$model->name); ?>
  <div class="action">
    <?php
    echo SHtml::ajaxSubmitButton(
    $update ? Helper::translate('srbac','Save') :
    Helper::translate('srbac','Create'),
    $update ? array('update','id'=>$model->name) : array('create') ,
    array(
    'type'=>'POST',
    'update'=>'#preview'
    ), array('name'=>'saveButton2'));
    ?>
  </div>
  <div id="mess" class="message" style="visibility:hidden">
    $message
  </div>
  <?php echo SHtml::endForm(); ?>

</div><!-- srbacForm -->
<script language="javascript">
<?php echo SHtml::ajax(array(
'type'=>'POST',
'url'=>array('manage'),
'update'=>'#list',
)); ?>
</script>
