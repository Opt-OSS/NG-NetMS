<?php

/**
 * XMultiSelects class file
 *
 * This widget is used to transfer options between two select filed
 *
 * Usage
 * <pre>
 * $this->widget('ext.widgets.multiselects.XMultiSelects',array(
 *     'leftTitle'=>'Australia',
 *     'leftName'=>'Person[australia][]',
 *     'leftList'=>Person::model()->findUsersByCountry(14),
 *     'rightTitle'=>'New Zealand',
 *     'rightName'=>'Person[newzealand][]',
 *     'rightList'=>Person::model()->findUsersByCountry(158),
 *     'size'=>20,
 *     'width'=>'200px',
 * ));
 * </pre>
 */
class XMultiSelects extends CWidget
{
    /**
     * The label for the left mutiple select
     * option
     * @var string
     */
    public $leftTitle;
    /**
     * The label for the right mutiple select
     * option
     * @var string
     */
    public $rightTitle;
    /**
     * The name for the left mutiple select
     * require
     * @var string
     */
    public $leftName;
    /**
     * The name for the right mutiple select
     * require
     * @var string
     */
    public $rightName;
    /**
     * data for generating the left list options
     * require
     * @var array
     */
    public $leftList;
    /**
     * data for generating the right list options
     * require
     * @var array
     */
    public $rightList;
    /**
     * The size for the multiple selects.
     * option
     * @var integer
     */
    public $size = 15;

    /**
     * The width for the multiple selects.
     * option
     * @var string
     */
    public $width;

    public static $id_cnt = 1;

    /**
     * register clientside widget files
     */
    protected function registerClientScript()
    {
        $cs = Yii::app()->getClientScript();
        $cs->registerCoreScript('jquery');
        $cs->registerScriptFile(Yii::app()->getAssetManager()->publish(dirname(__FILE__) . '/jquery.multiselects.js'));
        $cs->registerScriptFile(Yii::app()->getAssetManager()->publish(dirname(__FILE__) . '/multiselectsfilter.js'));
    }

    /**
     * Initializes the widget
     */
    public function init()
    {
        if ( ! isset( $this->leftName )) {
            throw new CHttpException(500, '"leftName" have to be set!');
        }
        if ( ! isset( $this->rightName )) {
            throw new CHttpException(500, '"rightName" have to be set!');
        }
        if ( ! isset( $this->leftList )) {
            throw new CHttpException(500, '"leftList" have to be set!');
        }
        if ( ! isset( $this->rightList )) {
            throw new CHttpException(500, '"rightList" have to be set!');
        }
    }

    /**
     * Run the widget
     */
    public function run()
    {
        $id = self::$id_cnt ++;
        echo "<table border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n";
        echo "<tr>\n";
        echo "<td>\n";
        if (isset( $this->leftTitle )) {
            echo "<label for=\"leftTitle{$id}\">{$this->leftTitle}</label><br />\n";
            echo "<input class='search' id='left-search{$id}' type='text' placeholder='Search' autocomplete='off'></input><br />\n";
        }
        echo "<select name=\"{$this->leftName}\" id=\"select_left{$id}\" multiple=\"multiple\" size=\"{$this->size}\" style=\"width:{$this->width}\">\n";
        foreach ($this->leftList as $value => $label) {
            echo "<option value=\"{$value}\">{$label}</option>\n";
        }
        echo "</select>
                <select id='select_left_fake{$id}' multiple=\"multiple\" size=\"{$this->size}\" style=\"width:{$this->width};display:none\">\n</select></td>\n";

        echo "<td style=\"width:60px; text-align:center; vertical-align:middle\">\n";
        echo "<input type=\"button\" style=\"width:40px\" id=\"options_left{$id}\" value=\"&lt;\" /><br /><br />\n";
        echo "<input type=\"button\" style=\"width:40px\" id=\"options_right{$id}\" value=\"&gt;\" /><br /><br />\n";
        echo "<input type=\"button\" style=\"width:40px\" id=\"options_left_all{$id}\" value=\"&lt;&lt;\" /><br /><br />\n";
        echo "<input type=\"button\" style=\"width:40px\" id=\"options_right_all{$id}\" value=\"&gt;&gt;\" /><br /><br /></td>\n";

        echo "<td>\n";
        if (isset( $this->rightTitle )) {
            echo "<label for=\"rightTitle{$id}\">{$this->rightTitle}</label><br />\n";
            echo "<input class='search' id='right-search{$id}' type='text' placeholder='Search' autocomplete='off'></input><br />\n";
        }
        echo "<select name=\"{$this->rightName}\" id=\"select_right{$id}\" multiple=\"multiple\" size=\"{$this->size}\" style=\"width:{$this->width}\">\n";
        foreach ($this->rightList as $value => $label) {
            echo "<option value=\"{$value}\">{$label}</option>\n";
        }
        echo "</select><select id='select_right_fake{$id}' multiple=\"multiple\" size=\"{$this->size}\" style=\"width:{$this->width};display:none\">\n</select></td>\n";
        echo "</tr></table>\n";

        $this->registerClientScript();
        ?>
        <script>
            $(document).ready(function () {
                $("#right-search<?php echo $id ?>").keyup(function () {
                    //split the current value of searchInput

                    var data = this.value.split(" ");
                    var counter0 = 0;
                    $("#select_right_fake<?php echo $id ?>").hide();
                    $("#select_right<?php echo $id ?>").show();
                    //create a jquery object of the rows
                    var jo = $("#select_right<?php echo $id ?>").find("option");
                    if (this.value == "") {
                        jo.show();
                        return;
                    }
                    //hide all the rows
                    jo.hide();

                    //Recusively filter the jquery object to get results.
                    jo.filter(function (i, v) {
                            var $t = $(this);
                            for (var d = 0; d < data.length; ++d) {
                                if ($t.is(":contains('" + data[d] + "')")) {
                                    counter0++;
                                    return true;
                                }
                            }
                            return false;
                        })
                        //show the rows that match.
                        .show();
                    if (counter0 == 0) {
                        $("#select_right<?php echo $id ?>").hide();
                        $("#select_right_fake<?php echo $id ?>").show();
                    }
                }).focus(function () {
                    this.value = "";
                    $(this).css({
                        "color": "black"
                    });
                    $(this).unbind('focus');
                }).css({
                    "color": "#C0C0C0"
                });
                $("#left-search<?php echo $id ?>").keyup(function () {
                    //split the current value of searchInput
                    var data = this.value.split(" ");
                    var counter = 0;
                    //create a jquery object of the rows
                    $("#select_left_fake<?php echo $id ?>").hide();
                    $("#select_left<?php echo $id ?>").show();
                    var jo = $("#select_left<?php echo $id ?>").find("option");
                    if (this.value == "") {
                        jo.show();
                        return;
                    }
                    //hide all the rows
                    jo.hide();

                    //Recusively filter the jquery object to get results.
                    jo.filter(function (i, v) {
                            var $t = $(this);
                            for (var d = 0; d < data.length; ++d) {
                                if ($t.is(":contains('" + data[d] + "')")) {
                                    counter++;
                                    return true;
                                }
                            }
                            return false;
                        })
                        //show the rows that match.
                        .show();
                    if (counter == 0) {
                        $("#select_left<?php echo $id ?>").hide();
                        $("#select_left_fake<?php echo $id ?>").show();
                    }
                }).focus(function () {
                    this.value = "";
                    $(this).css({
                        "color": "black"
                    });
                    $(this).unbind('focus');
                }).css({
                    "color": "#C0C0C0"
                });


                $("#select_left<?php echo $id ?>").multiSelect("#select_right<?php echo $id ?>", {trigger: "#options_right<?php echo $id ?>"});
                $("#select_right<?php echo $id ?>").multiSelect("#select_left<?php echo $id ?>", {trigger: "#options_left<?php echo $id ?>"});
                $("#select_left<?php echo $id ?>").multiSelect("#select_right<?php echo $id ?>", {allTrigger: "#options_right_all<?php echo $id ?>"});
                $("#select_right<?php echo $id ?>").multiSelect("#select_left<?php echo $id ?>", {allTrigger: "#options_left_all<?php echo $id ?>"});

            });
        </script>
        <?php
        parent::init();
    }

    protected function renderContent()
    {
    }
}