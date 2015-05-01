(function($){
    $( "li.routertab1" ).on('click',function() { 
       
        $("#swinventory").hide();  
        $("#logicinterfaces").hide();
        $("#phisicalinterfaces").hide();
        $("#currentconfig").hide();  
        $("#graphrouter").hide();   
        $("#hwinventory").show();
    });
    $( "li.routertab2" ).on('click',function() { 
        $("#hwinventory").hide();
        $("#logicinterfaces").hide();
        $("#phisicalinterfaces").hide();
        $("#currentconfig").hide(); 
        $("#graphrouter").hide();   
        $("#swinventory").show();         
    });
    $( "li.routertab3" ).on('click',function() { 
        $("#hwinventory").hide();
        $("#swinventory").hide();
        $("#phisicalinterfaces").hide();
        $("#currentconfig").hide(); 
        $("#graphrouter").hide();   
        $("#logicinterfaces").show();         
    });
    $( "li.routertab4" ).on('click',function() { 
        $("#hwinventory").hide();
        $("#swinventory").hide();
        $("#logicinterfaces").hide();
        $("#currentconfig").hide();  
        $("#graphrouter").hide();   
        $("#phisicalinterfaces").show();         
    });
    $( "li.routertab5" ).on('click',function() { 
        $("#hwinventory").hide();
        $("#swinventory").hide();
        $("#logicinterfaces").hide();
        $("#phisicalinterfaces").hide();     
        $("#graphrouter").hide();   
        $("#currentconfig").show();   
    });
    $( "li.routertab6" ).on('click',function() { 
        $("#hwinventory").hide();
        $("#swinventory").hide();
        $("#logicinterfaces").hide();
        $("#phisicalinterfaces").hide();        
        $("#currentconfig").hide();   
        $("#graphrouter").show();   
    });
})(this.jQuery)





