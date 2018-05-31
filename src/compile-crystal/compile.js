const child_process = require('child_process');
const process = require('process');
const tmp = require('tmp');
const fs = require('fs-extra');
const unzipper = require('unzipper');

const tagPrefix = '<html><body>You are being <a href="https://github.com/crystal-lang/crystal/releases/tag/';
const tagSuffix = '">redirected</a>.</body></html>';
const downloadCmd = 'curl -L --silent https://github.com/crystal-lang/crystal/releases | grep "linux-x86_64.tar.gz" | grep VERSION | grep href'

var req;
var res;

function silentCmd(command) {
  return child_process.execSync(command).toString();
}

function cmd(command) {
  console.log('$ '+command);
  var ret = silentCmd(command);
  if(ret.length > 0) console.log(ret);
  return ret;
}

function latestCrystalVersion() {
  var html = silentCmd('curl --silent https://github.com/crystal-lang/crystal/releases/latest');
  var tag = html.replace(tagPrefix, '').replace(tagSuffix, '');
  if(tag.includes('<')) throw 'encountered unexpected markup or a server error';
  return tag;
}

function getCrystalDownloadLink(version) {
  if(version == null) version = latestCrystalVersion();
  var targetCmd = downloadCmd.replace('VERSION', version);
  var result = silentCmd(targetCmd).trim().replace('<a href="', '').replace('" rel="nofollow">', '');
  return 'https://github.com'+result;
}

function addTo(path, variable) {
  process.env[variable] = path + ':' + silentCmd('echo $' + variable).trim();
  console.log('added ' + path + ' to ' + variable);
}

var _req, _res;

function compile(projectId, payload, version) {
  console.log('preparing to compile...');
  var pwd = silentCmd('pwd').trim();
  console.log();
  console.log('injecting pcre into environment...')
  cmd('tar -xzf ./pcre.tar.gz -C /tmp');
  addTo('/tmp/pcre/bin', 'PATH');
  addTo('/tmp/pcre/lib', 'LD_LIBRARY_PATH');
  addTo('/tmp/pcre/lib', 'LIBRARY_PATH');
  addTo('/tmp/pcre/include', 'C_INCLUDE_PATH');
  addTo('/tmp/pcre/include', 'CPP_INCLUDE_PATH');
  console.log();
  console.log('injecting libevent into environment...')
  cmd('tar -xzf ./libevent.tar.gz -C /tmp');
  addTo('/tmp/libevent/bin', 'PATH');
  addTo('/tmp/libevent/lib', 'LD_LIBRARY_PATH');
  addTo('/tmp/libevent/lib', 'LIBRARY_PATH');
  addTo('/tmp/libevent/include', 'C_INCLUDE_PATH');
  addTo('/tmp/libevent/include', 'CPP_INCLUDE_PATH');
  console.log();
  var dir = tmp.dirSync();
  process.chdir(dir.name);
  if(!version) {
    console.log('crystal version not specified, finding latest version...');
    version = latestCrystalVersion();
    console.log('latest version: ' + version);
    console.log();
  }
  console.log('downloading linux x64 binary for Crystal ' + version);
  var downloadLink = getCrystalDownloadLink(version);
  cmd('curl -O -L --silent ' + downloadLink);
  console.log();
  var filename = silentCmd('ls *.tar.gz').trim();
  console.log('extracting "' + filename + '"...');
  cmd('tar -xzf *.tar.gz');
  console.log();
  console.log('injecting crystal binaries into environment...')
  addTo(dir.name + '/crystal-'+version+'/bin', 'PATH');
  console.log();
  console.log('testing that crystal binary is installed and runnable...');
  var test = cmd('crystal --version');
  if(!test.includes('Crystal ' + version)) throw 'crystal binary was not installed correctly';
  console.log('extracting payload...');
  var dir2 = tmp.dirSync();
  process.chdir(dir2.name);
  fs.writeFileSync('./payload.zip', payload);
  fs.createReadStream('./payload.zip').pipe(unzipper.Extract({ path: dir2.name })).on('finish', function() {
    process.chdir(dir2.name);
    fs.removeSync('./payload.zip');
    var executable_name = fs.readdirSync('.')[0];
    process.chdir(executable_name);
    console.log('finished extracting payload');
    console.log('installing shards...');
    cmd('shards install --release');
    console.log();
    console.log('compiling with crystal ' + version + '...');
    cmd('crystal  build ./src/*.cr -o ' + executable_name + ' --release');
    console.log();
    cmd('./'+executable_name);
    setTimeout(function() {
      console.log('cleaning up...');
      try { fs.removeSync(dir2.name); } catch(e) {}
      try { fs.removeSync(dir.name); } catch(e) {}
      try { fs.removeSync('/tmp/pcre'); } catch(e) {}
      try { fs.removeSync('/tmp/libevent'); } catch(e) {}
      console.log('done');
      if(res) res.status(200).send('OK');
    }, 10);
  });
}


exports.init = function(_req, _res) {
  req = _req;
  res = _res;
  compile(req.body.project_id, fs.readFileSync('./payload.zip'), req.body.crystal_version);
}

function test() {
  compile('test-project', fs.readFileSync('./test.zip'), '0.24.1');
}
