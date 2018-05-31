require "baked_file_system"

class FileStorage
  extend BakedFileSystem
  zip_result = !{{`rm bake/compile-crystal.zip && cd src && zip -r ../bake/compile-crystal.zip compile-crystal/`.includes?("error")}}
  bake_folder "../../bake"
end
