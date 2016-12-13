var http = require('http');
var socketio = require('socket.io');
var chokidar = require('chokidar');
var fs = require('fs');

var server = http.createServer(function (request, response) {
  var url = request.url;
  if('/' == url){
  var rs = fs.createReadStream('./topology.txt');
  var readline = require('readline');
  var rl = readline.createInterface(rs, {});
  var splitter = [];
  var nodejs = [];
  var lineIndex = 0;
  var hostBegin = 0;
  var linkBegin = 0;
  rl.on('line', function(line) {
    splitter = line.split(" ");
    if(splitter[0] == 'host'){
      hostBegin = lineIndex;
    } else if (splitter[0] == 'link') {
      linkBegin = lineIndex;
    } else {
      lineIndex++;
      if (splitter[2] == null) {
        var il = {sp0: splitter[0], sp1: splitter[1]};
      } else {
        var il = {sp0: splitter[0], sp1: splitter[1], sp2: splitter[2]};
      }
      nodejs.push(il);
    }
  }).on('close', function(){
    var nodeData = new String();
    var linkData = new String();
    var colorData = ['red', 'green', 'blue', 'yellow', 'purple', 'pink', 'black'];
    var colorSlice = [];
    for (var i=0; i < hostBegin; i++) {
      nodeData += "{id:'"+nodejs[i].sp0+"',label:'"+nodejs[i].sp1+"', fixed:{x:true, y:true}, shape:'image', image:'./switch.jpg', font:'14px arial black', size:20},";
    }
    for (var i=hostBegin; i < linkBegin; i++) {
      if (colorSlice.indexOf(nodejs[i].sp2) >= 0) {
//        console.log(nodejs[i].sp2 + " already exists.");
      } else {
        colorSlice.push(nodejs[i].sp2);
//        console.log(nodejs[i].sp2 + " added.");
      }
      nodeData += "{id:'"+nodejs[i].sp0+"',label:'"+nodejs[i].sp1+"',color:'"+colorData[colorSlice.indexOf(nodejs[i].sp2)]+"', fixed:{x:true, y:true}, font: '14px arial "+colorData[colorSlice.indexOf(nodejs[i].sp2)]+"', shape:'image', image:'./host.jpg', size:30},";
    }
    for (var i=linkBegin; i < nodejs.length; i++) {
      linkData += "{id:'"+nodejs[i].sp0+"',from:'"+nodejs[i].sp1+"',to:'"+nodejs[i].sp2+"'},";
    }

  var data = '<!doctype html>'+
'<html>'+
'  <head>'+
'    <title>Virtual Network Topology</title>'+
'    <script type="text/javascript" src="./vis.js"></script>'+
'    <link href="./vis.css" rel="stylesheet" type="text/css" />'+
'    <script type="text/javascript" src="./socket.io/socket.io.js"></script>'+
'    <style type="text/css">'+
'      body, html {'+
'        font-family: sans-serif;'+
'      }'+
'    </style>'+
'  </head>'+
'  <body>'+
'    <div id="mynetwork"></div>'+
'    <script type="text/javascript">'+
'      var nodes = ['+
nodeData+
'      ];'+
'      var edges = ['+
linkData+
'      ];'+
"      var container = document.getElementById('mynetwork');"+
'      var data = {'+
'        nodes: nodes,'+
'        edges: edges'+
'      };'+
'      var options = {'+
"        width: '400px',"+
"        height: '400px'"+
'      };'+
'      var network = new vis.Network(container, data, options);'+
'      for(var i=0; i<nodes.length; i++){'+
'        var hoge = network.getPositions([nodes[i].id]);'+
'        nodes[i].x = hoge[nodes[i].id].x;'+
'        nodes[i].y = hoge[nodes[i].id].y;'+
'      }'+
//'      var hoge = network.getPositions([1,2,3,4]);'+
//'      nodes[0].x = hoge[1].x;'+
//'      nodes[0].y = hoge[1].y;'+
//'alert(nodes.toSource());'+
'      var socket = io.connect();'+
'      socket.on("server_to_client", function(dt){'+
'        for(var i=0; i<edges.length; i++) {'+
'          edges[i].width = 1;'+
'        }'+
'        for(var i=0; i<dt.value.length; i++) {'+
'          for(var j=0; j<edges.length; j++) {'+
'            if(edges[j].id == dt.value[i]) {'+
'              edges[j].width = 10;'+
'            }'+
'          }'+
'        }'+
'        network.setData({nodes:nodes, edges:edges});'+
'      });'+
'    </script>'+
'  </body>'+
'</html>';

  response.writeHead(200, {'Content-Type': 'text/html'});
  response.write(data);
  response.end();
  });
  } else if('/vis.js' == url) {
    fs.readFile('./vis.js', 'UTF-8', function(err, data){
      response.writeHead(200, {'Content-Type': 'text/javascript'});
      response.write(data);
      response.end();
    });
  } else if('/vis.css' == url) {
    fs.readFile('./vis.css', 'UTF-8', function(err, data){
      response.writeHead(200, {'Content-Type': 'text/css'});
      response.write(data);
      response.end();
    });
  } else if('/switch.jpg' == url) {
    fs.readFile('./switch.jpg', function(err, data) {
      response.writeHead(200, {'Content-Type': 'image/jpeg'});
      response.end(data);
    });
  } else if('/host.jpg' == url) {
    fs.readFile('./host.jpg', function(err, data) {
      response.writeHead(200, {'Content-Type': 'image/jpeg'});
      response.end(data);
    });
  }
}).listen(8174);

console.log('Server running at http://127.0.0.1:8174/');

var watcher = chokidar.watch('./watched/',{
  ignored:/[\/\\]\./,
  persistent:true
});

var io = socketio.listen(server);

watcher.on('ready', function(){

  // 準備完了
  console.log("Start watching.");

  // ファイルの追加
  watcher.on('add', function(path){
    console.log(path+" added.");
  });

  // ファイルの編集
  watcher.on('change', function(path){
    console.log(path+" changed.");
    var rs = fs.createReadStream('./watched/path.txt');
    var readline = require('readline');
    var rl = readline.createInterface(rs, {});
    var sp = [];
    rl.on('line', function(line) {
      sp = line.split(" ");
    }).on('close', function(){
      io.sockets.emit('server_to_client', {value:sp});
    });
  });

});


io.sockets.on('connection', function(socket) {
  console.log("connected.");
//  socket.on('client_to_server', function(data) {
//    io.sockets.emit('server_to_client', {value : data.value});
//  });
});
