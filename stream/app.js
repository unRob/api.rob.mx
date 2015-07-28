var SSE = require('./lib/sse.js'),
	fs = require('fs'),
	url = require('url'),
	http = require('http');

var config = {};
var server = http.createServer();

var Codes = {
	400: 'Bad Request',
	401: 'Unauthorized',
	404: 'Not found'
};

http.ServerResponse.prototype.halt = function(code, msg) {
	code = code || 400;
	msg = msg || Codes[code];
	this.writeHead(code, {'Content-type': 'application/json'});
	this.end(JSON.stringify({error: msg}));
};

server.on('request', function(req, res){
	var path = url.parse(req.url).pathname;
	// if (path === '/') {
	// 	var host = '//'+req.headers.host;
	// 	config.client = host+live.client_path;
	// 	config.endpoint = host+live.options.mount_point;
	// 	res.end(JSON.stringify(config));
	// 	// res.end(fs.readFileSync('./public/index.html'));
	// } else
	if (path === '/stream/client.js'){
		res.writeHead(200, {'Content-type': 'application/javascript'});
		res.end(SSE.client_code);
	} else if (path.match(/^\/stream\/publish/)) {
		if(req.method !== 'POST' || req.headers['x-forwarded-for'] !== '127.0.0.1') {
			return res.halt(404);
		}
		var comps = path.split('/');
		comps.splice(0,3);

		var channel = comps.shift();
		var event = comps.join('/');
		var data = '';
		req.on('data', function(buff){
			data += buff.toString();
		});

		req.on('end', function(){
			try {
				live.broadcast(channel, event, JSON.parse(data));
				res.writeHead(201);
				res.end();
			} catch (err) {
				return res.halt(400, 'Esperaba datos, zoquetazo...');
			}
		});
	} else {
		res.halt(404);
	}
});

live = SSE.mount(server, '/stream/subscribe');

server.listen(3000, function(){
	console.log('Listening');
});
