const child_process = require('child_process');
const process = require('process');
const tmp = require('tmp');
const fs = require('fs-extra');

const tagPrefix = '<html><body>You are being <a href="https://github.com/crystal-lang/crystal/releases/tag/';
const tagSuffix = '">redirected</a>.</body></html>';
const downloadCmd = 'curl -L --silent https://github.com/crystal-lang/crystal/releases/latest | grep "linux-x86_64.tar.gz\\\" rel"';

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
  var targetCmd = downloadCmd.replace('latest', version);
  var result = silentCmd(targetCmd).trim().replace('<a href="', '').replace('" rel="nofollow">', '');
  return 'https://github.com'+result;
}

function compile() {
  console.log('preparing to compile...');
  console.log();
  var dir = tmp.dirSync();
  process.chdir(dir.name);
  var version = null;
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
  console.log('testing that crystal binary is installed and runnable...');
  var crystalBinary = dir.name + '/crystal-'+version+'/bin/crystal';
  var test = cmd(crystalBinary + ' --version');
  if(!test.includes('Crystal ' + version)) throw 'crystal binary was not installed correctly';
  console.log();
  fs.removeSync(dir.name);
}

compile();
