var http = require('http');
http.createServer(function (request, response) {
    response.statusCode = 200;
    response.setHeader("Content-Type", "text/html");
    var content = '';
    content += '<html><body><h1>';
    content += '<p>HTTP_VERSION: '+request.httpVersionMajor+'.'+request.httpVersionMinor+'</p>';
    content += '<p>HTTP_METHOD: '+request.method+'</p>';
    content += '<p>REQUEST_URL: '+request.url+'</p>';
    content += '<p>HEADERS:</p>';
    content += '<ul>';
    for (var header in request.headers) {
      content += '<li>'+header+': '+request.headers[header]+'</li>'
    }
    content += '</ul>';
    content += '</body></html>\r\n';
    response.end(content);
}).listen(8081);
console.log("Listening on port 8081");
