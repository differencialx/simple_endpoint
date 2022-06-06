# frozen_string_literal: true

module SimpleEndpoint
  class Endpoint
    class EndpointOptions
      attr_reader :options

      def initialize(**options)
        @options = options
      end

      def invoker
        options[:invoker]
      end

      def result
        options[:result]
      end

      def renderer_options
        @renderer_options ||= options[:renderer_options] || {}
      end

      def before_response
        @before_response ||= (options[:before_response] || invoker.__before_response) || {}
      end

      def handler
        @handler ||= options[:default_handler].merge(options[:different_handler] || invoker.__different_handler || {})
      end

      def cases
        @cases ||= options[:default_cases].merge(options[:different_cases] || invoker.__different_cases || {})
      end
    end
  end
end
