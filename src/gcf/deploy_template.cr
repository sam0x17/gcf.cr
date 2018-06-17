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
  const child_process = require('child_process');
  
  function cmd(command) {
    console.log('$ '+command);
    var ret = child_process.execSync(command).toString();
    if(ret.length > 0) console.log(ret);
    return ret;
  }
  
  exports.init = function(req, res) {
    res.status(200).send(cmd('./crystal_function'));
  }
  JS
end
