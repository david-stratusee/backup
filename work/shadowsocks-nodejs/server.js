// Generated by CoffeeScript 1.8.0
(function() {
  var Encryptor, KEY, LOCAL_ADDRESS, METHOD, PORT, WebSocket, WebSocketServer, config, configContent, configFile, configFromArgs, fs, http, inetNtoa, k, net, options, parseArgs, path, server, timeout, v, wss, util, wstream;

  net = require("net");

  fs = require("fs");

  path = require("path");

  http = require("http");

  WebSocket = require('ws');

  WebSocketServer = WebSocket.Server;

  parseArgs = require("minimist");

  Encryptor = require("./encrypt").Encryptor;

  util = require('util');
  moment = require("moment");
  
  wstream = fs.createWriteStream('/tmp/shadowsocks.log', {flags : 'w'});
  //var log_stdout = process.stdout;
  console.log = function(d) {
      wstream.write("[" + moment().format("YYYY-MM-DDTHH:mm") + "] " + util.format(d) + '\n');
      //log_stdout.write(util.format(d) + '\n');
  };

  console.warn = function(d) {
      wstream.write("[WARN][" + moment().format("YYYY-MM-DDTHH:mm") + "] " + util.format(d) + '\n');
      //log_stdout.write("[WARN]" + util.format(d) + '\n');
  };

  //console.log(process.env.OPENSHIFT_REPO_DIR + 'shadowsocks.log');
  console.log('/tmp/shadowsocks.log');

  options = {
    alias: {
      'b': 'local_address',
      'r': 'remote_port',
      'k': 'password',
      'c': 'config_file',
      'm': 'method'
    },
    string: ['local_address', 'password', 'method', 'config_file'],
    "default": {
      'config_file': path.resolve(__dirname, "config.json")
    }
  };

  inetNtoa = function(buf) {
    return buf[0] + "." + buf[1] + "." + buf[2] + "." + buf[3];
  };

  configFromArgs = parseArgs(process.argv.slice(2), options);

  configFile = configFromArgs.config_file;

  configContent = fs.readFileSync(configFile);

  config = JSON.parse(configContent);

  if (process.env.OPENSHIFT_NODEJS_IP) {
    config['local_address'] = process.env.OPENSHIFT_NODEJS_IP;
  }

  if (process.env.OPENSHIFT_NODEJS_PORT) {
    config['remote_port'] = +process.env.OPENSHIFT_NODEJS_PORT;
  }

  if (process.env.PORT) {
    config['remote_port'] = +process.env.PORT;
  }

  if (process.env.KEY) {
    config['password'] = process.env.KEY;
  }

  if (process.env.METHOD) {
    config['method'] = process.env.METHOD;
  }

  for (k in configFromArgs) {
    v = configFromArgs[k];
    config[k] = v;
  }

  timeout = Math.floor(config.timeout * 1000);

  LOCAL_ADDRESS = config.local_address;

  PORT = config.remote_port;

  KEY = config.password;

  METHOD = config.method.toLowerCase();

  console.log("get method: " + METHOD + ", key: " + KEY);

  if (METHOD === "" || METHOD === "null") {
    METHOD = null;
  }

  setInterval(function() {
    if (global.gc) {
      return gc();
    }
  }, 1000);

  server = http.createServer(function(req, res) {
    res.writeHead(200, {
      'Content-Type': 'text/plain'
    });
    return res.end("asdf.");
  });

  wss = new WebSocketServer({
    server: server
  });

  wss.on("connection", function(ws) {
    var addrLen, cachedPieces, encryptor, headerLength, remote, remoteAddr, remotePort, stage;
    encryptor = new Encryptor(KEY, METHOD);
    stage = 0;
    headerLength = 0;
    remote = null;
    cachedPieces = [];
    addrLen = 0;
    remoteAddr = null;
    remotePort = null;

    //console.log("server connected, stage = 0");
    //console.log("concurrent connections:" + wss.clients.length + ", stage = 0");

    ws.on("message", function(data, flags) {
      var addrtype, buf, e;
      //console.log("[1]recv " + data.length + " data from ws, stage: " + stage);
      data = encryptor.decrypt(data);
      if (stage === 5) {
        //console.log("[2]send " + data.length + " data to " + remote.remoteAddress + ":" + remote.remotePort + ", stage = 5");
        if (!remote.write(data)) {
          //console.log("pause ws");
          ws._socket.pause();
        }
        return;
      }
      if (stage === 0) {
        try {
          addrtype = data[0];
          if (addrtype === 3) {
            addrLen = data[1];
          } else if (addrtype !== 1) {
            console.warn("[3]unsupported addrtype: " + addrtype + ", stage: " + stage);
            ws.close();
            return;
          }
          if (addrtype === 1) {
            remoteAddr = inetNtoa(data.slice(1, 5));
            remotePort = data.readUInt16BE(5);
            headerLength = 7;
          } else {
            remoteAddr = data.slice(2, 2 + addrLen).toString("binary");
            remotePort = data.readUInt16BE(2 + addrLen);
            headerLength = 2 + addrLen + 2;
          }
          remote = net.connect(remotePort, remoteAddr, function() {
            var i, piece;
            //console.log("[4]connecting " + remoteAddr + ":" + remotePort + ", stage: " + stage);
            i = 0;
            while (i < cachedPieces.length) {
              piece = cachedPieces[i];
              remote.write(piece);
              //console.log("[5]send " + piece.length + " data to remote " + remoteAddr + ":" + remotePort + "#" + remote.remoteAddress + ":" + remote.remotePort + ", stage: " + stage);
              i++;
            }
            cachedPieces = null;
            return stage = 5;
          });
          remote.on("data", function(data) {
            //console.log("[6]recv " + data.length + " data from remote " + remoteAddr + ":" + remotePort + "#" + remote.remoteAddress + ":" + remote.remotePort + ", stage: " + stage);
            data = encryptor.encrypt(data);
            if (ws.readyState === WebSocket.OPEN) {
                //console.log("[7]send " + data.length + " data from remote " + remoteAddr + ":" + remotePort + "#" + remote.remoteAddress + ":" + remote.remotePort + "# to ws" + ", stage: " + stage);
                ws.send(data, {
                    binary: true
                });
              if (ws.bufferedAmount > 0) {
                //console.log("pause remote");
                remote.pause();
              }
            }
          });
          remote.on("end", function() {
            ws.close();
            //return console.log("[8]remote disconnected" + ", stage: " + stage);
            return;
          });
          remote.on("drain", function() {
            //console.log("resume ws");
            return ws._socket.resume();
          });
          remote.on("error", function(e) {
            ws.terminate();
            return console.log("[9]remote: " + e + ", stage: " + stage);
          });
          remote.setTimeout(timeout, function() {
            console.log("[10]remote timeout" + ", stage: " + stage);
            remote.destroy();
            return ws.close();
          });
          if (data.length > headerLength) {
            buf = new Buffer(data.length - headerLength);
            data.copy(buf, 0, headerLength);
            cachedPieces.push(buf);
            buf = null;
          }
          return stage = 4;
        } catch (_error) {
          e = _error;
          console.warn("[11]" + e + ", stage: " + stage);
          if (remote) {
            remote.destroy();
          }
          return ws.close();
        }
      } else {
        if (stage === 4) {
          return cachedPieces.push(data);
        }
      }
    });
    ws.on("ping", function() {
      return ws.pong('', null, true);
    });
    ws._socket.on("drain", function() {
      if (stage === 5) {
        //console.log("resume remote");
        return remote.resume();
      }
    });
    ws.on("close", function() {
      //console.log("[12]server disconnected" + ", stage: " + stage);
      //console.log("[13]concurrent connections:" + wss.clients.length + ", stage: " + stage);
      if (remote) {
        return remote.destroy();
      }
    });
    return ws.on("error", function(e) {
      console.warn("[14]server: " + e + ", stage: " + stage);
      console.log("[15]concurrent connections:" + wss.clients.length + ", stage: " + stage);
      if (remote) {
        return remote.destroy();
      }
    });
  });

  server.listen(PORT, LOCAL_ADDRESS, function() {
    var address;
    address = server.address();
    return console.log("server listening at #" + address.address + "#" + address.port + "#");
  });

  server.on("error", function(e) {
    if (e.code === "EADDRINUSE") {
      console.log("address in use, aborting");
    }
    return process.exit(1);
  });

}).call(this);
