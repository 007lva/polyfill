require 'ipaddr'
require 'stringio'
require 'polyfill/version'
require 'polyfill/internal_utils'

module Polyfill
  module Parcel; end

  def get(module_name, methods, options = {})
    if Object.const_get(module_name.to_s).is_a?(Class)
      raise ArgumentError, "#{module_name} is a class not a module"
    end

    #
    # parse options
    #
    versions = InternalUtils.polyfill_versions_to_use(options.delete(:version))

    unless options.empty?
      raise ArgumentError, "unknown keyword: #{options.first[0]}"
    end

    #
    # find all polyfills for the module across all versions
    #
    modules = InternalUtils.modules_to_use(module_name, versions)

    #
    # remove methods that were not requested
    #
    requested_methods = InternalUtils.methods_to_keep(modules, methods, '#', module_name)

    modules.each do |instance_module|
      InternalUtils.keep_only_these_methods!(instance_module, requested_methods)
    end

    #
    # build the module to return
    #
    InternalUtils.create_parcel do |mod|
      # make sure the methods get added if this module is included
      mod.singleton_class.send(:define_method, :included) do |base|
        modules.each do |module_to_add|
          base.include module_to_add unless module_to_add.instance_methods.empty?
        end
      end

      # make sure the methods get added if this module is extended
      mod.singleton_class.send(:define_method, :extended) do |base|
        modules.each do |module_to_add|
          base.extend module_to_add unless module_to_add.instance_methods.empty?
        end
      end
    end
  end
  module_function :get
end

def Polyfill(options = {}) # rubocop:disable Style/MethodName
  #
  # parse options
  #
  objects, others = options.partition { |key,| key[/\A[A-Z]/] }
  objects.sort! do |a, b|
    if !a.is_a?(Class) && b.is_a?(Class)
      -1
    elsif a.is_a?(Class) && !b.is_a?(Class)
      1
    else
      0
    end
  end
  others = others.to_h

  versions = Polyfill::InternalUtils.polyfill_versions_to_use(others.delete(:version))
  native = others.delete(:native) { false }

  unless others.empty?
    raise ArgumentError, "unknown keyword: #{others.first[0]}"
  end

  #
  # build the module to return
  #
  Polyfill::InternalUtils.create_parcel do |mod|
    objects.each do |module_name, methods|
      #
      # find all polyfills for the object across all versions
      #
      instance_modules = Polyfill::InternalUtils.modules_to_use(module_name, versions)

      class_modules = instance_modules.map do |module_with_updates|
        begin
          module_with_updates.const_get(:ClassMethods, false).clone
        rescue NameError
          nil
        end
      end.compact

      #
      # get all requested class and instance methods
      #
      if methods != :all && (method_name = methods.find { |method| method !~ /\A[.#]/ })
        raise ArgumentError, %Q("#{method_name}" must start with a "." if it's a class method or "#" if it's an instance method)
      end

      instance_methods, class_methods =
        if methods == :all
          [:all, :all]
        else
          methods
            .partition { |m| m.start_with?('#') }
            .map { |method_list| method_list.map { |name| name[1..-1].to_sym } }
        end

      requested_instance_methods =
        Polyfill::InternalUtils.methods_to_keep(instance_modules, instance_methods, '#', module_name)
      requested_class_methods =
        Polyfill::InternalUtils.methods_to_keep(class_modules, class_methods, '.', module_name)

      #
      # get the class(es) to refine
      #
      base_class = module_name.to_s
      base_classes =
        case base_class
        when 'Comparable'
          %w[Numeric String Time]
        when 'Enumerable'
          %w[Array Dir Enumerator Hash IO Range StringIO Struct]
        when 'Kernel'
          %w[Object]
        else
          [base_class]
        end

      #
      # refine in class methods
      #
      class_modules.each do |class_module|
        Polyfill::InternalUtils.keep_only_these_methods!(class_module, requested_class_methods)

        next if class_module.instance_methods.empty?

        mod.module_exec(requested_class_methods) do |methods_added|
          base_classes.each do |klass|
            refine Object.const_get(klass).singleton_class do
              include class_module

              if native
                Polyfill::InternalUtils.ignore_warnings do
                  define_method :respond_to? do |name, include_all = false|
                    return true if methods_added.include?(name)

                    super(name, include_all)
                  end

                  define_method :__send__ do |name, *args, &block|
                    return super(name, *args, &block) unless methods_added.include?(name)

                    class_module.instance_method(name).bind(self).call(*args, &block)
                  end
                  alias_method :send, :__send__
                end
              end
            end
          end
        end
      end

      #
      # refine in instance methods
      #
      instance_modules.each do |instance_module|
        Polyfill::InternalUtils.keep_only_these_methods!(instance_module, requested_instance_methods)

        next if instance_module.instance_methods.empty?

        mod.module_exec(requested_instance_methods) do |methods_added|
          base_classes.each do |klass|
            refine Object.const_get(klass) do
              include instance_module

              if native
                Polyfill::InternalUtils.ignore_warnings do
                  define_method :respond_to? do |name, include_all = false|
                    return super(name, include_all) unless methods_added.include?(name)

                    true
                  end

                  define_method :__send__ do |name, *args, &block|
                    return super(name, *args, &block) unless methods_added.include?(name)

                    instance_module.instance_method(name).bind(self).call(*args, &block)
                  end
                  alias_method :send, :__send__
                end
              end
            end
          end
        end
      end
    end
  end
end

require 'polyfill/v2_2'
require 'polyfill/v2_3'
require 'polyfill/v2_4'
