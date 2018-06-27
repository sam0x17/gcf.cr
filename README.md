# gcf.cr

gcf.cr provides managed execution of crystal language code within Google Cloud Functions.
Functions are deployed automatically in a two stage process:

1. a "compile-crystal" function is automatically created in your current gcloud project.
   gcf.cr will upload your crystal code to this function and compile it so that all
   platform-specific optimizations are in place.

2. the resulting compiled binary is deployed as its own cloud function with an automatically
   generated Node.js loader/bootstrapper. An API is also provided for sending the final
   response back to Node.js from within crystal.

## Installation

1. set up a Google Cloud Platform account if you don't have one already and create an initial project
2. install the gcloud sdk (https://cloud.google.com/sdk/install) (if you haven't already)
3. log in to gcloud locally via `gcloud init` (if you haven't already)
4. install docker (if you haven't already)
5. set up docker to not require sudo (https://docs.docker.com/install/linux/linux-postinstall/#manage-docker-as-a-non-root-user)
6. start the docker daemon (e.g. `sudo systemctl start docker`) if it isn't already running
7. clone the repo `git clone git@github.com:sam0x17/gcf.cr.git`
8. run `./build` (a binary named `gcf` will be created in the root directory). For a static binary, run `./build_static` instead.
9. `sudo cp gcf /usr/bin` or add a directory containing the `gcf` binary to your `PATH` via your bash profile or the equivalent

If you plan to use docker-based static compilation (default option), you don't need to install crystal on your system
as long as you have a statically compiled `gcf` binary. You can find pre-compiled linux binaries in the releases page.
Otherwise you can use the `build_static` script included in the repo to build a static binary for gcf using docker.

## Usage

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/[your-github-name]/gcf/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [[your-github-name]](https://github.com/[your-github-name]) Sam Johnson - creator, maintainer
