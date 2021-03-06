module Polyfill
  module V2_5
    module String
      def casecmp(other_str)
        super
      rescue TypeError
        nil
      end

      def casecmp?(other_str)
        super
      rescue TypeError
        nil
      end

      def delete_prefix(prefix)
        sub(/\A#{InternalUtils.to_str(prefix)}/, ''.freeze)
      end

      def delete_prefix!(prefix)
        prev = dup
        current = sub!(/\A#{InternalUtils.to_str(prefix)}/, ''.freeze)
        prev == current ? nil : current
      end

      def delete_suffix(suffix)
        chomp(suffix)
      end

      def delete_suffix!(suffix)
        chomp!(suffix)
      end

      def start_with?(*prefixes)
        super if prefixes.grep(Regexp).empty?

        prefixes.any? do |prefix|
          prefix.is_a?(Regexp) ? self[/\A#{prefix}/] : super(prefix)
        end
      end
    end
  end
end
