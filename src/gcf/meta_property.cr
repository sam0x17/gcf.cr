
macro meta_property(name, value)
  @@{{name}} = {{value}}

  def self.{{name}}
    @@{{name}}
  end

  def self.{{name}}=(val)
    @@{{name}} = val
  end
end