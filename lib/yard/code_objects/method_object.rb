module YARD::CodeObjects
  # Represents a Ruby method in source
  class MethodObject < Base
    # The visibility of the method (+:public:+, +:protected+, +:private+)
    # 
    # @return [Symbol] the method visibility
    attr_accessor :visibility
    
    # The scope of the method (+:class+ or +:instance+)
    # 
    # @return [Symbol] the scope
    attr_accessor :scope
    
    # Whether the object is explicitly defined in source or whether it was
    # inferred by a handler. For instance, attribute methods are generally
    # inferred and therefore not explicitly defined in source. 
    # 
    # @return [Boolean] whether the object is explicitly defined in source.
    attr_accessor :explicit
    
    # Returns the list of parameters parsed out of the method signature
    # with their default values.
    # 
    # @return [Array<Array(String, String)>] a list of parameter names followed
    #   by their default values (or nil)
    attr_accessor :parameters
    
    # Creates a new method object in +namespace+ with +name+ and an instance
    # or class +scope+
    # 
    # @param [NamespaceObject] namespace the namespace
    # @param [String, Symbol] name the method name
    # @param [Symbol] scope +:instance+ or +:class+
    def initialize(namespace, name, scope = :instance) 
      self.visibility = :public
      self.scope = scope
      self.parameters = []

      super
    end
    
    # Changes the scope of an object from :instance or :class
    # @param [Symbol] v the new scope
    def scope=(v) 
      reregister = @scope ? true : false
      YARD::Registry.delete(self) if reregister
      @scope = v.to_sym 
      YARD::Registry.register(self) if reregister
    end
    
    # Sets the visibility
    # @param [Symbol] v the new visibility (:public, :private, or :protected)
    def visibility=(v) @visibility = v.to_sym end
      
    # Tests if the object is defined as an attribute in the namespace
    # @return [Boolean] whether the object is an attribute
    def is_attribute?
      namespace.attributes[scope].has_key? name.to_s.gsub(/=$/, '')
    end
      
    # Tests if the object is defined as an alias of another method
    # @return [Boolean] whether the object is an alias
    def is_alias?
      namespace.aliases.has_key? self
    end
    
    # Tests boolean {#explicit} value.
    # 
    # @return [Boolean] whether the method is explicitly defined in source
    def is_explicit?
      explicit ? true : false
    end
    
    # Returns all alias names of the object
    # @return [Array<Symbol>] the alias names
    def aliases
      list = []
      namespace.aliases.each do |o, aname| 
        list << o if aname == name && o.scope == scope 
      end
      list
    end
    
    # Override path handling for instance methods in the root namespace
    # (they should still have a separator as a prefix).
    # @return [String] the path of a method
    def path
      if !namespace || namespace.path == "" 
        sep + super
      else
        super
      end
    end
    
    # Returns the name of the object.
    # 
    # @example The name of an instance method (with prefix)
    #   an_instance_method.name(true) # => "#mymethod"
    # @example The name of a class method (with prefix)
    #   a_class_method.name(true) # => "mymethod"
    # @param [Boolean] prefix if prefix is true, returns {#sep} + +name+ for
    #   an instance method.
    def name(prefix = false)
      ((prefix ? (sep == ISEP ? sep : "") : "") + super().to_s).to_sym
    end
    
    protected
    
    # Override separator to differentiate between class and instance
    # methods.
    # @return [String] "#" for an instance method, "." for class
    def sep
      if scope == :class
        namespace && namespace != YARD::Registry.root ? CSEP : NSEP
      else
        ISEP
      end
    end
  end
end