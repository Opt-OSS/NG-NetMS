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
                            width: "140", header: "Router"},
                            {cellClass: "col2", value: "iname",
                            width: "140", header: "Interface"},
                            {cellClass: "col3", value: "cl",
                            width: "100", header: "Description"},
                            ],
                            resizable:false
                    },               
                 });
            });

