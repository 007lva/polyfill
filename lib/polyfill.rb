require 'polyfill/version'
require 'polyfill/v2_4'

module Polyfill
  include V2_4
end

def Polyfill(options) # rubocop:disable Style/MethodName
  mod = Module.new

  klasses, others = options.partition { |key,| key[/\A[A-Z]/] }

  unless others.empty?
    raise ArgumentError, "unknown keyword: #{others.first[0]}"
  end

  needs_update = RUBY_VERSION[/\A(\d+\.\d+)/, 1] < '2.4'

  klasses.each do |names, methods|
    class_or_module_mod = names
      .to_s
      .split('::')
      .reduce(Polyfill::V2_4) do |current_mod, name|
        begin
          current_mod.const_get(name, false)
        rescue NameError
          raise ArgumentError, %Q("#{names}" is not a valid class or has no updates)
        end
      end

    if methods == :all
      next unless needs_update

      mod.module_eval do
        include class_or_module_mod
      end
    else
      methods.each do |method|
        type =
          case method[0]
          when '.'
            :Class
          when '#'
            :Instance
          else
            raise ArgumentError, %Q("#{method}" must start with a "." if it's a class method or "#" if it's an instance method)
          end

        method_name = method[1..-1]
        symbol_conversions = {
          '=' => 'equal',
          '<' => 'lessthan',
          '>' => 'greaterthan',
          '?' => '_q',
          '!' => '_e'
        }
        method_name.gsub!(/[#{symbol_conversions.keys.join}]/o, symbol_conversions)
        method_name.capitalize!
        method_name.gsub!(/_(.)/) { |match| match[1].capitalize }

        method_mod =
          begin
            class_or_module_mod
              .const_get(type, false)
              .const_get(method_name, false)
          rescue NameError
            raise ArgumentError, %Q("#{method}" is not a valid method on #{names} or has no updates)
          end

        next unless needs_update

        mod.module_eval do
          include method_mod
        end
      end
    end
  end

  mod
end
