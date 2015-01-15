(function($){
	var Renderer = function(canvas)
	{
		var canvas = $(canvas).get(0);
		var ctx = canvas.getContext("2d");
		var particleSystem;

		var that = {
			init:function(system){
				//начальная инициализация
				particleSystem = system;
				particleSystem.screenSize(canvas.width, canvas.height); 
				particleSystem.screenPadding(80);
				that.initMouseHandling();
			},
      
			redraw:function(){
				//действия при перересовке
				ctx.fillStyle = "white";	//белым цветом
				ctx.fillRect(0,0, canvas.width, canvas.height); //закрашиваем всю область
			
				particleSystem.eachEdge(	//отрисуем каждую грань
					function(edge, pt1, pt2){	//будем работать с гранями и точками её начала и конца
 //                                             ctx.strokeStyle = "rgba(0,0,0, .333)";	//грани будут чёрным цветом с некой прозрачностью
						ctx.strokeStyle = edge.data.color;
                                                ctx.lineWidth = 1;	//толщиной в один пиксель
						ctx.beginPath();		//начинаем рисовать
                                                ctx.moveTo(edge.data.coordx1,edge.data.coordy1);//от точки один
                                                ctx.lineTo(edge.data.coordx2,edge.data.coordy2);//до точки два
						ctx.stroke();
				});
	
				particleSystem.eachNode(	//теперь каждую вершину
					function(node, pt){		//получаем вершину и точку где она
						//var w = 15;			//ширина квадрата
                                                //var h = 15;
                                                var imageob = new Image();
                                                imageob.src = node.data.image; 
                                                var imageH = node.data.image_h;
                                                var imageW = node.data.image_w;
                                                var sv1 = parseInt(node.data.coordx)-(imageW/2);
                                                var sv2 = parseInt(node.data.coordy)-parseInt(imageH/2);
                                                var sv3 = parseInt(node.data.coordy)+parseInt(imageH/2)+10;
                                                var sv4 = parseInt(node.data.coordx)-(imageW/2)+16;
//						ctx.fillStyle = node.data.color;	//с его цветом понятно
//                                                ctx.fillRect(node.data.coordx-w/2, node.data.coordy-h/2, w,h);
                                                ctx.drawImage(imageob, sv1, sv2, imageW, imageH);
						ctx.fillStyle = "black";	//цвет для шрифта
						ctx.font = 'italic 13px sans-serif'; //шрифт
                                                ctx.fillText (node.name,sv4, sv3)
				});    			
			},
		
			initMouseHandling:function(){	//события с мышью
				var dragged = null;			//вершина которую перемещают
				var handler = {
					clicked:function(e){	//нажали
						var pos = $(canvas).offset();	//получаем позицию canvas
                                                 
						_mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top); //и позицию нажатия кнопки относительно canvas
                                                var min =1000000;
                                                particleSystem.eachNode(
                                                        function(node){
                                                            var x1= node.data.coordx - _mouseP.x;
                                                            var y1= node.data.coordy - _mouseP.y;
                                                            var dist2= x1 * x1 + y1 * y1;
                                                            var dist = Math.sqrt(dist2);
                                                            if(dist < min)
                                                            {
                                                                min = dist;
                                                                dragged = node;
                                                            }
                                                        });
                                                   
						if (dragged && dragged !== null && min <30){
                                                    
                                                    var routerHtml = "<table><tr><th width='35%'align='left'>Name</th><th width='35%' align='left'>IP address</th><th width='30%'>Mask</th></tr>";
                                                    var dataInterface = dragged.data.interfaces;
                                                    var dataHw = dragged.data.hw;
                                                    var dataSw = dragged.data.sw;
                                                    for(var i=0 in dataInterface)
                                                    {
                                                        routerHtml += "<tr><td>"+dataInterface[i].name+"</td><td>"+dataInterface[i].ip_addr+"</td><td>"+dataInterface[i].mask+"</td></tr>";
                                                    }
                                                    routerHtml +="</table>";
                                                    var routerHw = "<table><tr><th width='35%'align='left'>Part type</th><th width='65%' align='left'>Details</th></tr>";
                                                    for(var i=0 in dataHw)
                                                    {
                                                        routerHw += "<tr><td>"+dataHw[i].type+"</td><td>"+dataHw[i].details+"</td></tr>";
                                                    }
                                                    routerHw +="</table>";
                                                    var routerSw = "<table><tr><th width='35%'align='left'>Part type</th><th width='35%' align='left'>Name</th><th width='30%'>Version</th></tr>";
                                                    for(var i=0 in dataSw)
                                                    {
                                                        routerSw += "<tr><td>"+dataSw[i].type+"</td><td>"+dataSw[i].name+"</td><td align ='center'>"+dataSw[i].version+"</td></tr>";
                                                    }
                                                    routerSw +="</table>";
                                                    var headerM =  dragged.name+" ("+dragged.data.eq_vendor+ " " +dragged.data.eq_type+ ")";
                                                    $("#routerModal .modal-header h4").html(headerM);
                                                    $("#routerModal .modal-body .routerinterfaces").html(routerHtml);
                                                    $("#routerModal .modal-body .hwinv").html(routerHw);
                                                    $("#routerModal .modal-body .swinv").html(routerSw);
                                                    $("#routerModal").modal("show");
							dragged.fixed = true;	//фиксируем её
                                                         
						}
                                                
						return false;
					},
                                        moved:function(e){
                                            var pos = $(canvas).offset();
                                            _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
                                             var min =1000000;
                                             
                                            particleSystem.eachNode(
                                                        function(node){
                                                            var x1= node.data.coordx - _mouseP.x;
                                                            var y1= node.data.coordy - _mouseP.y;
                                                            var dist2= x1 * x1 + y1 * y1;
                                                            var dist = Math.sqrt(dist2);
                                                            if(dist < min)
                                                            {
                                                                min = dist;
                                                                dragged = node;
                                                            }
                                                        });
                                            if (dragged && dragged !== null && min <30){
                                                
                                                $(this).css('cursor','pointer');
                                                //var id = dragged;
                                                //console.log(id)
 //                                               alert("Node selected:" + id);
                                            }
                                            else
                                            {
                                                $(this).css('cursor','');
                                            }
                                            return false;
                                          },
                                        
				}
				// слушаем события нажатия мыши
				$(canvas).mousedown(handler.clicked);
                                $(canvas).mousemove(handler.moved);
			},
      
		}
		return that;
	}    

	$(document).ready(function(){
		sys = arbor.ParticleSystem(1000); // создаём систему
		sys.parameters({gravity:true}); // гравитация вкл
		sys.renderer = Renderer("#viewport") //начинаем рисовать в выбраной области
                data = JSON.parse(arr_json);
                
			
				$.each(data.nodes, function(i,node){
					sys.addNode(node.name,node.data);	//добавляем вершину
				});
		  
				$.each(data.edges, function(i,edge){
					sys.addEdge(sys.getNode(edge.src),sys.getNode(edge.dest),edge.data);	//добавляем грань
				});
		
    
	})

})(this.jQuery)



