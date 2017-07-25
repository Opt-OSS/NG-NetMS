<?php
/* @var $this RoutersController */


//$this->widget('bootstrap.widgets.TbBreadcrumbs', array(
//    'links' => array('Map' => 'index.php?r=routers/ipmap', 'IP Connectivity Map'),
//));

?>
<style>
    .graph {

        box-sizing: border-box;
        overflow: hidden;
        position: absolute;
        top: 50px;
        left: 0;
        bottom: 0;
        right: 0;
    }

    .vis-network-tooltip {
        position: absolute;
        /* color: #efff97; */
        background: rgb(255, 254, 219);
        border: 1px solid rgb(255, 252, 144);
        padding: 0.5em;
    }

    #network {

        height: 100%;
        width: 100%;

        max-height: 100%;
        overflow: hidden;

    }
</style>

<script>
    var options = <?=$options?>;

    var data_ngnms =<?=$network?>;
    var allNodes;
    var highlightActive = false;

    var nodesDataset = new vis.DataSet(data_ngnms.nodes); // these come from WorldCup2014.js
    var edgesDataset = new vis.DataSet(data_ngnms.edges); // these come from WorldCup2014.js
    var data = {nodes: nodesDataset, edges: edgesDataset};

    var network;
    var container;

    var options1 = {
//        nodes: {
//            shape: 'dot',
//            scaling: {
//                min: 10,
//                max: 30,
//                label: {
//                    min: 8,
//                    max: 30,
//                    drawThreshold: 12,
//                    maxVisible: 20
//                }
//            },
//            font: {
//                size: 12,
//                face: 'Tahoma'
//            }
//        },
//        edges: {
////            width: 0.15,
//            color: {inherit: 'from'},
//            smooth: {
//                type: 'continuous'
//            }
//        },
        physics: true,
        interaction: {
            tooltipDelay: 200,
            hideEdgesOnDrag: true
        }
    };
    $.extend(options, options1);

    function drawNetwork() {

        network = new vis.Network(container, data, options);

        // get a JSON object
        allNodes = nodesDataset.get({returnType: "Object"});
        allEdges = edgesDataset.get({returnType: "Object"});

        network.on("click", neighbourhoodHighlight);
    }


    $(document).ready(function () {
        container = document.getElementById('network');


        drawNetwork();

    });
    function restore_node(node) {
        node.font.color=0;
        if (node.hiddenLabel !== undefined) {
            node.label = node.hiddenLabel;
            node.hiddenLabel = undefined;
        }
        if (node.hiddenColor !== undefined) {
            if (node.icon === undefined){
                node.color = node.hiddenColor;
            }else{
                node.icon.color = node.hiddenColor;
            }
            node.hiddenColor = undefined;
        }

    }
    function restore_edge(node){
        node.font.color=0;
        if (node.hiddenLabel !== undefined) {
            node.label = node.hiddenLabel;
            node.hiddenLabel = undefined;
        }
        if (node.hiddenColor !== undefined) {
            node.color = node.hiddenColor;
            node.hiddenColor = undefined;
        }
    }
    function neighbourhoodHighlight(params) {
        // if something is selected:
        if (params.nodes.length > 0) {
            highlightActive = true;
            var i, j;
            var selectedNode = params.nodes[0];
            var degrees = 2;
            var node;
            var first_degree_color = 'rgba(50,50,50,0.8)';
            var third_degree_color = 'rgba(200,200,200,0.4)';
            // mark all nodes as hard to read.
            for (var nodeId in allNodes) {
                node = allNodes[nodeId];
                if (node.hiddenColor === undefined) {
                    if (node.icon === undefined) {
                        node.hiddenColor = node.color;
                        node.color = third_degree_color;
                    }else{
                        node.hiddenColor = node.icon.color;
                        node.icon.color= third_degree_color;
                    }
                }
                if (node.hiddenLabel === undefined) {
                    node.hiddenLabel = node.label;
                    node.label = undefined;
                }

            }

            // mark all edges as hard to read.
            for (var nodeId in allEdges) {
                node = allEdges[nodeId];
                if (node.hiddenColor === undefined) {
                    node.hiddenColor = node.color;
                    node.color = third_degree_color;
                }
                if (node.hiddenLabel === undefined) {
                    node.hiddenLabel = node.label;
                    node.label = undefined;
                }
            }


            var connectedNodes = network.getConnectedNodes(selectedNode);
            var connectedEdges  = network.getConnectedEdges(selectedNode);

            var allConnectedNodes = [];
            var allConnectedEdges = [];

            // get the second degree nodes
            for (i = 1; i < degrees; i++) {
                for (j = 0; j < connectedNodes.length; j++) {
                    allConnectedNodes = allConnectedNodes.concat(network.getConnectedNodes(connectedNodes[j]));
                    allConnectedEdges = allConnectedEdges.concat(network.getConnectedEdges(connectedNodes[j]));
                }
            }

            // all second degree nodes get a different color and their label back
            for (i = 0; i < allConnectedNodes.length; i++) {
                node = allNodes[allConnectedNodes[i]];
                node.font.color = first_degree_color;
                if (node.hiddenColor === undefined) {
                    node.hiddenColor = node.color;
                    node.color = first_degree_color;
                }
                if (node.hiddenLabel !== undefined) {
                    node.label = node.hiddenLabel;
                    node.hiddenLabel = undefined;
                }
            }

            // all second degree edges get a different color and their label back
            for (i = 0; i < allConnectedEdges.length; i++) {
                node = allEdges[allConnectedEdges[i]];
                node.font.color = first_degree_color;
                if (node.hiddenColor === undefined) {
                    node.hiddenColor = node.color;
                    node.color = first_degree_color;
                }
                if (node.hiddenLabel !== undefined) {
                    node.label = node.hiddenLabel;
                    node.hiddenLabel = undefined;
                }
            }

            // all first degree nodes get their own color and their label back
            for (i = 0; i < connectedNodes.length; i++) {
                restore_node(allNodes[connectedNodes[i]]);
            }
//             all first degree edges get their own color and their label back
            for (i = 0; i < connectedEdges.length; i++) {
                restore_edge( allEdges[connectedEdges[i]] );
            }


            // the main node gets its own color and its label back.
            restore_node( allNodes[selectedNode]);



        }
        else if (highlightActive === true) {
            // reset all nodes
            for (var nodeId in allNodes) {
                restore_node( allNodes[nodeId] );
            }

            // reset all edges
            for (var nodeId in allEdges) {
                restore_edge( allEdges[nodeId] );

            }

            highlightActive = false
        }

        // transform the object into an array
        var updateArray = [];
        for (nodeId in allNodes) {
            if (allNodes.hasOwnProperty(nodeId)) {
                updateArray.push(allNodes[nodeId]);
            }
        }
        nodesDataset.update(updateArray);

        // transform the object into an array
        updateArray = [];
        for (nodeId in allEdges) {
            if (allEdges.hasOwnProperty(nodeId)) {
                updateArray.push(allEdges[nodeId]);
            }
        }
        edgesDataset.update(updateArray);

    }
</script>
<div class="graph">
    <div id="network">Drawing....</div>
</div>
<!--<pre>-->
<!--    --><? //=$dbg ?>
<!--</pre>-->

