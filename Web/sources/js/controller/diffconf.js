(function($){
    var h01 = $('.diff1').height();  
    var h02 = $('.diff2').height();
    var h = h01;
    if(h01 < h02)
    {
        h= h02;
    }
    
    $('pre').each(function(){
        var h1= "height:"+h+"px";
        $(this).attr('style',h1);
    })
})(this.jQuery)

