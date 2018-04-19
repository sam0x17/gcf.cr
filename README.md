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

TODO: Write installation instructions here

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
