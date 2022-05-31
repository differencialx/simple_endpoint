# frozen_string_literal: true

module SimpleEndpoint
  module Controller
    module ClassMethods
      attr_accessor :default_handler, :default_cases

      def inherited(subclass)
        super
        subclass.default_handler = default_handler.dup
        subclass.default_cases = default_cases.dup
      end

      def handler(inherit: true, &block)
        builder = Builder.new(&block)
        self.default_handler = ((inherit && default_handler) || {}).merge(builder.to_h)
        define_method(:default_handler) { self.class.default_handler }
      end

      def cases(inherit: true, &block)
        builder = Builder.new(&block)
        self.default_cases = ((inherit && default_cases) || {}).merge(builder.to_h)
        define_method(:default_cases) { self.class.default_cases }
      end

      def endpoint_options(inherit: true, &block)
        define_method(:endpoint_options) do
          (inherit ? super() : {}).merge(instance_exec(&block))
        end
      end
    end
  end
end
