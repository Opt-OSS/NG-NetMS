$(function(){
                    $('.btn-group a').click(function(){
                        var fieldId = $(this).data('field');
                        var value = $(this).data('value');
                        $('#tumbler').val(value);
                    });
                });


