module Pakyow
  module UI
    module Instructable
      def self.included(klass)
        (@instructables ||= []) << klass
      end

      def self.instructable?(object)
        @instructables.select { |i|
          object.is_a?(i)
        }.any?
      end

      attr_reader :instructions

      def initialize
        @instructions = []
      end

      def instruct(method, data)
        @instructions << [clean_method(method), hashify(data)]
        self
      end

      def nested_instruct(method, data, scope = nil)
        view = nested_instruct_object(method, data, scope)
        @instructions << [clean_method(method), hashify(data), view]
        view
      end

      # Returns an instruction set for all view transformations.
      #
      # e.g. a value-less transformation:
      # [[:remove, nil]]
      #
      # e.g. a transformation with a value:
      # [[:text=, 'foo']]
      #
      # e.g. a nested transformation
      # [[:scope, :post, [[:remove, nil]]]]
      def finalize
        @instructions.map { |instruction|
          if Instructable.instructable?(instruction[2])
            instruction[2] = instruction[2].finalize
          end

          instruction
        }
      end

      private

      def mixin_bindings(data, bindings = {})
        data.map { |bindable|
          datum = bindable.to_hash
          Pakyow::Presenter::Binder.instance.bindings_for_scope(scoped_as, bindings).keys.each do |key|
            datum[key] = Pakyow::Presenter::Binder.instance.value_for_scoped_prop(scoped_as, key, bindable, bindings, self)
          end

          datum
        }
      end

      def hashify(data)
        return hashify_datum(data) unless data.is_a?(Array)

        data.map { |datum|
          hashify_datum(datum)
        }
      end

      def hashify_datum(datum)
        if datum.respond_to?(:to_hash)
          datum.to_hash
        else
          datum
        end
      end

      def clean_method(method)
        method.to_s.gsub('=', '').to_sym
      end
    end
  end
end
