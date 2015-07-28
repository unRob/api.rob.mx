API.Stream = function(mountpoint, channels) {
	var source = API.stream_host + '/' + mountpoint;
	if (channels && channels.length > 0){
		if (typeof channels === 'string') {
			channels = channels.split(',');
		}
		source += '/'+channels.join(',');
	} else {
		channels = [];
	}

	this.source = source;
	this.channels = channels;
	this.socket = new EventSource(source);
	this.callbacks = {false: {'_any': []}};
	this.setup();
};


API.Stream.prototype.setup = function(){
	var self = this;

	this.socket.onopen = function(){
		self.emit({name: 'open', channel: false, data: null});
	};

	this.socket.onerror = function(evt){
		self.emit({name: 'error', channel: false, data: evt.target.readyState});
	};

	this.socket.onmessage = function(evt) {
		var msg = JSON.parse(evt.data);
		self.emit({name: msg.n, channel: msg.c, data: msg.d});
	};

};

API.Stream.prototype.emit = function(evt) {
	// evt.channel && console.log("SSE: "+(evt.channel)+'/'+evt.name);
	var cbs = [];
	var chan = this.channels[evt.channel];
	if (!chan) {
		return false;
	}

	chan._any.concat(chan[evt.name] || []).forEach(function(callback){
		try {
			callback(evt);
		} catch (error) {
			console.error(error);
		}
	});

};

API.Stream.prototype.on = function(channel, name, callback) {
	if (typeof name !== 'string') {
		callback = name;
		name = '_any';
	}

	if (!this.channels[channel]) {
		this.channels[channel] = {'_any': []};
	}

	if (!this.channels[channel][name]) {
		this.channels[channel][name] = [];
	}

	this.channels[channel][name].push(callback);

};