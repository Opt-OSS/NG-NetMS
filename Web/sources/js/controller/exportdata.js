$(function(){
                   $( ".exportdataxls1" ).click(function() {
                       $(".exportdataxls").replaceWith('<a class="exportdataxls" href="/index.php?r=routers/exportxls&type=xls&item='+$('#InvHw_hw_item').val()+'"><img alt="xls" src="images/excel_32_01.png"><\/a>'); 
                       $(".exportdataxls").click();    
                        });
                         
                    
                });

