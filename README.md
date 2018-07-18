# gcf.cr

[![CircleCI](https://circleci.com/gh/sam0x17/gcf.cr.svg?style=svg)](https://circleci.com/gh/sam0x17/gcf.cr)

GCF provides managed execution of crystal language code within Google Cloud Functions.
GCF compiles your crystal code statically using the [durosoft/crystal-alpine](https://hub.docker.com/r/durosoft/crystal-alpine/)
docker image or optionally using your local crystal installation (if it is capable of static compilation) via the `--local` option.
It then bundles your compiled crystal code in a thin node.js wrapper function and deploys it to GCP using
the options you specify. An API is also provided for writing to the console, throwing errors, and returning
the final response.

## Installation

1. set up a Google Cloud Platform account if you don't have one already and create an initial project
2. install the [gcloud sdk](https://cloud.google.com/sdk/install) if you haven't already
3. log in to gcloud locally via `gcloud init` if you haven't already
4. install docker (if you haven't already)
5. set up docker [to not require sudo](https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user)
6. start the docker daemon (e.g. `sudo systemctl start docker`) if it isn't already running
7. clone the repo `git clone git@github.com:sam0x17/gcf.cr.git`
8. run `./setup`. This will compile and install a `gcf` binary in `/usr/bin`.

If you plan to use docker-based static compilation (default option), you don't need to install crystal on your system
as long as you have a statically compiled `gcf` binary. You can use the `build_static` script included in the repo
to build a static binary for gcf using docker. That said, having crystal locally installed will make it easier
to write tests.

## Getting Started

All cloud functions should consist of a crystal app project (created via `crystal init app`)
where the main project file (e.g `src/my_project.cr`) meets the requirements outlined below.

Add the following to your `shard.yml` file and run `shards install`:

```yaml
# shard.yml
...
dependencies:
  gcf:
    github: sam0x17/gcf.cr
    branch: master
```

Create a class that inherits from `GCF::CloudFunction` and defines a `run` method that accepts
an argument of type `JSON::Any`:

```crystal
# src/example.cr
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    # your code here
  end
end
```

Once you have a setup like this, you can use the various API functions from within your run method,
which makes up the body of your cloud function. The available API functions are listed below. Note
that methods like `send`, `send_file`, and `redirect` stop execution when they are run, meaning
any code after these methods will not run unless it was already defined in an `at_exit` block. If
you do not call one of these methods in your function, your function will run until it times out.

Once you are done writing your function, you can deploy it using `gcf --deploy`.

## Crystal API

A crystal-based API is provided for communicating with the Google Cloud Function host process so you can do
things like log to the console redirect the browser, or send textual or file-based data to the browser.
The API is a thin layer on top of the underlying ExpressJS API used by Google Cloud Functions, and uses
a combination of inter-process communication and files to send data to/from the host process.

### console.log(msg)

Logs whatever you pass it to the GCF console with `info` priority. Equivalent to using `console.log`
in JavaScript. `msg` is interpolated so non-strings may be passed in.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    console.log "some info here"
  end
end
```

### console.warn(msg)

Logs whatever you pass it to the GCF console with `warn` priority. Equivalent to using `console.warn`
in JavaScript. `msg` is interpolated so non-strings may be passed in.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    console.warn "woah, warning"
  end
end
```

### console.error(msg)

Logs whatever you pass it to the GCF console with `error` priority. Equivalent to using `console.error`
in JavaScript. `msg` is interpolated so non-strings may be passed in.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    console.error "GASP! an error"
  end
end
```

### send(content)

An alias for `send(200, content)`, where 200 is the HTTP OK/ready status code.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    send "OK, done executing"
  end
end
```

### send(status : Int, content)

Sends the interpolated version of `content` as output to the browser with an HTTP status code
of `status`, and stops execution of the cloud function. This is forwarded to `req.send` in ExpressJS.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    send 200, "<h1>YO</h1>"
  end
end
```

### redirect(url : String)

An alias for `redirect false, url`, since temporary redirects are usually preferable when used
with cloud functions.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    redirect "https://google.com"
  end
end
```

### redirect(permanent : Bool, url : String)

Redirects the browser to the specified `url`. If `permanent` is true, it will do a 301 redirect.
If `permanent` is false, it will do a 302 redirect.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    redirect true, "https://google.com"
  end
end
```

### send_file(path : String)

An alias for `send_file 200, path`, since typically you will only want to send file
content with a status code of 200.

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    send_file "van_gogh.jpg"
  end
end
```

### send_file(status : Int, path : String)

Sends the file at the specified path to the browser with an HTTP status code of `status`
(to write files from crystal in a cloud function, you need to write to something in `/tmp`).

```crystal
require "gcf"

class Example < GCF::CloudFunction
  def run(params : JSON::Any)
    send_file 200, "van_gogh.jpg"
  end
end
```

### Note on puts

If you call `puts` directly from within a cloud function's run method, this gets mapped to `console.log`.
This does not apply to `puts` calls that are made indirectly (e.g. calling code outside of this class),
so the contents of these `puts` calls will not be handled correctly and lead to undefined behavior.

### Note on exceptions

Right now exceptions work locally but not in a deployed function. We are working on this but
please feel free to take a look at #1 and help out if you have any ideas. From what we can
tell, all execution stops the second an exception is thrown, even from within a try-catch
block, when a function is executing on GCP. For now we are logging a generic message
stating that an error occurred, however we are unable to retrieve the error stacktrace
or name (locally we are able to do this).

## Deploying

Note that GCF expects your crystal function to follow the directory structure imposed by `crystal init app`, in that
all of your crystal code should reside in `project_name/src/`. During compilation, GCF uses the `src/*.cr` glob to
compile all crystal files in the src directory.

Note also that GCF will automatically consult `gcloud` to discover the current GCP project id if one isn't specified.

Below you can find some basic usage examples fo rcommon use cases. For full usage information, please see the output
of `gcf --help`.

Compile the current directory using the docker image and deploy as a function named after the current directory (default):

```bash
gcf --deploy
```

Specifying the source directory, static compilation using the local crystal installation, the function name, the
memory capacity of the deployed function, and the google project ID respectively.

```bash
gcf --deploy --source /home/sam/proj --local --name hello-world --memory 2GB --project cool-project
```

Or using shorthand:

```bash
gcf -d -s /home/sam/proj -l -n hello-world -m 2GB -p cool-project
```

## TODO

1. attribute API so we don't need command line params
2. fix exceptions logging bug (#1)
3. more testing
