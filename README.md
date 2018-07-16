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
8. run `./build` (a binary named `gcf` will be created in the root directory). For a static binary, run `./build_static`.
9. `sudo cp gcf /usr/bin` or add a directory containing the `gcf` binary to your `PATH` via your bash profile.

If you plan to use docker-based static compilation (default option), you don't need to install crystal on your system
as long as you have a statically compiled `gcf` binary. You can find pre-compiled linux binaries in the releases page.
Otherwise you can use the `build_static` script included in the repo to build a static binary for gcf using docker.

## Usage

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

1. provide params to gcf template
2. document API and provide examples
3. more testing
