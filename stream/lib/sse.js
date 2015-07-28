var url = require('url'),
	fs = require('fs');

var SSE = function(http, options){
	this.http = http;
	var old_listeners = this.http.listeners('request');
	this.http.removeAllListeners('request');
	var self = this;

	this.clients = [];
	this.options = options;

	if (typeof this.options.path === 'string') {
		this.options.mount_point = this.options.path;
		this.options.path = new RegExp('^'+this.options.path+'/?[a-z0-9\.:\-_]*', 'i');
	}
	this.client_path = self.options.mount_point+"/client.js";

	this.http.on('request', function(req, res){
		var u = url.parse(req.url);
		var path = u.pathname;

		if (path == self.client_path) {
			res.writeHead(200, {'Content-type': 'application/javascript'});
			res.write(SSE.client_code());
			res.end();
		} else if (self.options.path.test(path)){
			var chans = path.replace(self.options.mount_point, '').replace('/', '').split(',');
			var client = new SSE.Client(chans, res);

			console.log('Joined: '+client.channels.join(','));
			self.clients.push(client);
			console.log(self.clients.length);

			req.on('close', function(){
				var index = self.clients.indexOf(client);
				console.log('Left: '+client.channels.join(','));
				self.clients.splice(index, 1);
			});
		} else {
			old_listeners.forEach(function(listener){
				listener.call(self.http, req, res);
			});
		}
	});
};

SSE.prototype.broadcast = function(channel, event, data) {

	switch(arguments.length) {
		case 2:
			data = event;
			event = channel;
			channel = null;
			break;
		case 1:
			data = channel;
			channel = event = null;
	}

	var wrote = 0;
	this.clients.forEach(function(client){
		if (channel === null || (channel && client.within(channel))){
			client.write({channel: channel, event: event}, data);
			++wrote;
		}
	});

	console.log(''+wrote+": "+channel+"/"+event);
};


SSE.mount = function(http, endpoint){
	return new SSE(http, {path: endpoint});
};

SSE.client_code = fs.readFileSync(__dirname+'/sse-client.js');

SSE.Client = function(channels, stream) {
	this.channels = channels;
	this.stream = stream;

	this.stream.socket.setNoDelay(true);
	this.stream.writeHead(200, {
		'Access-Control-Allow-Origin': '*',
		'Content-type': 'text/event-stream',
		'Connection': 'keep-alive',
		'X-Accel-Buffering' : 'off',
		'Cache-control': 'no-cache'
	});
	this.stream.write(':joined '+channels.join(',')+'\n\n');
};

SSE.Client.prototype.within = function(channel) {
	return this.channels.indexOf(channel) > -1;
};

SSE.Client.prototype.write = function(ns, data) {
	var msg = {
		c: false,
		n: null,
		d: null
	};

	if (ns && data === null) {
		msg.d = ns;
	} else {
		msg.c = ns.channel;
		msg.n = ns.event;
		msg.d = data;
	}

	var buffer = "data: "+JSON.stringify(msg)+'\n\n';
	this.stream.write(buffer);
};

SSE.Client.prototype.close = function() {
	this.stream.end();
};

module.exports = SSE;