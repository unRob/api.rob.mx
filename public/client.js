var API = {};
API.host = 'https://api.'+window.location.host;
API.stream_host = API.host + '/stream';
API.resolve_url = function(ep) {
	return API.host+'/'+ep.replace(/^\//, '');
};

API.serialize_object = function(obj, prefix) {
	var str = [];
	for(var p in obj) {
		if (obj.hasOwnProperty(p) && obj[p] !== null) {
			var k = prefix ? prefix + "[" + p + "]" : p, v = obj[p];
			str.push(typeof v == "object" ?
			API.serialize_object(v, k) :
			encodeURIComponent(k) + "=" + encodeURIComponent(v));
		}
	}
	return str.join("&");
};

API.call = function(method, endpoint, query, callback) {
	if (typeof method != 'string') {
		r = method;
		callback = query;
		query = endpoint;
		method = r.method;
		endpoint = r.url();
		query = query || r.query;
		callback = callback || r.callback;
	}
	var request = {
		type: method,
		url: API.resolve_url(endpoint),
		cache: true
	};

	if (query) {
		request.data = query;
	}

	if (callback) {
		request.success = r.success || function(res){
			callback(res);
		};
	}

	if (r && r.fail) {
		request.error = r.fail;
	} else {
		request.error = function(a,b,c) {
			console.log(a,b,c);
		};
	}

	var req = new Promise(function(_resolve, _reject){
		var xhr = new XMLHttpRequest();
		var url = request.url;

		if (request.type == 'GET' && request.data) {
			url += '?'+API.serialize_object(request.data);
			request.data = null;
		}

		xhr.open(request.type, url, true);
		xhr.onload = function(){
			try {
				var res = JSON.parse(this.responseText);
				_resolve(res);
			} catch (err) {
				_reject(err);
			}
		};
		xhr.send(request.data);
	});
	return req;
};

API.Request = function(method, endpoint, query){
	this.method = method.toUpperCase();
	this.endpoint = endpoint;
	this.query = query || {};
};

API.Request.prototype.url = function(){
	var exp = /\{([^\}])+\}/g;
	var url = this.endpoint;
	var self = this;
	if (url.indexOf('{') > -1){
		url = url.replace(exp, function(key) {
			return self.url_params[key.replace(/[{}]/g, '')];
		});
	}
	return url;
};

API.Request.prototype.execute = function(query, callback, url_params) {
	this.url_params = url_params;
	query = query || {};
	return API.call(this, query, callback);
};

window.API = API;