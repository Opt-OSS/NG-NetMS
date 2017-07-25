$(document).ready(function(){
              $('#treeViewDiv').jstree({ 
              "plugins" : ["core", "themes","json","grid"],      
              'core' : {
                'data' : mas1,
                        },
                'themes' : {
                         'theme' : 'default',
	                     'icons' : false
	        },        
                'grid': {
                            columns: [
                            {width: "275",header: "Nodes",title:"_DATA_"},
                            {cellClass: "col1", value: "rname",
                            width: "150", header: "Router"},
                            {cellClass: "col2", value: "iname",
                            width: "150", header: "Interface"},
                            {cellClass: "col3", value: "cl",
                            width: "300", header: "Information"},
                            ],
                            resizable:false
                    },               
                 });
            });

