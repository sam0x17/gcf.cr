module GCF::DeployTemplate
  PACKAGE_INFO = <<-JSON
  {
    "name": "deploy-template",
    "version": "1.0.0",
    "description": "",
    "main": "crystal.js",
    "scripts": {},
    "author": ""
  }
  JSON

  CRYSTAL_JS = <<-JS
  const fs = require('fs');
  const child_process = require('child_process');

  function cmd(command) {
    console.log('$ '+command);
    var ret = child_process.execSync(command).toString();
    if(ret.length > 0) console.log(ret);
    return ret;
  }

  exports.init = function(req, res) {
    var proc = child_process.spawn('./crystal_function');
    var exception_lines = [];
    var params = JSON.stringify(req.body);
    fs.writeFileSync('/tmp/.gcf_params', params);

    proc.stdout.on('data', function(data) {
      var lines = data.toString().trim().split('\\n');
      lines.forEach(function(line) {
        if(line.startsWith("gcf-info: ")) {
          console.log(line.substring(10));
        } else if(line.startsWith("gcf-warn: ")) {
          console.warn(line.substring(10));
        } else if(line.startsWith("gcf-error: ")) {
          console.error(line.substring(11));
        } else if(line.startsWith("gcf-exception: ")) {
          console.log('exception line:', line);
          exception_lines.push(line.substring(15));
        } else {
          throw 'invalid console type: ' + line
        }
      });
    });

    proc.on('exit', function (code) {
      if(code) console.log('[gcf] crystal function exited with code ' + code.toString());
      if(!fs.existsSync('/tmp/.gcf_status')) throw 'missing status code';
      var status = parseInt(fs.readFileSync('/tmp/.gcf_status').toString().trim());
      if(status.toString() == "NaN") {
        //console.error(exception_lines.join("\\n"));
        console.error("[gcf] an error occurred in your crystal function, but unfortunately we are not yet able to display the exception.")
        res.status(500).send();
       } else if(fs.existsSync('/tmp/.gcf_text_output')) {
        var output = fs.readFileSync('/tmp/.gcf_text_output').toString();
        console.log('[gcf] sending text output with status', status);
        res.status(status).send(output);
      } else if(fs.existsSync('/tmp/.gcf_file_output')) {
        var path = fs.readFileSync('/tmp/.gcf_file_output').toString().trim();
        console.log('[gcf] sending file data from ', path);
        res.status(status).sendFile(path, { root: __dirname });
      } else if(fs.existsSync('/tmp/.gcf_redirect_url')) {
        var url = fs.readFileSync('/tmp/.gcf_redirect_url').toString().trim();
        console.log('[gcf] sending ' + status + ' redirect to ' + url);
        res.redirect(status, url);
      } else {
        throw 'invalid state -- no text output, file output, redirect, or exception specified';
      }
    });
  }
  JS
end
