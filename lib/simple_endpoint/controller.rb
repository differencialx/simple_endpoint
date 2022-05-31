# frozen_string_literal: true

module SimpleEndpoint
  module Controller
    attr_accessor :__different_cases, :__different_handler, :__before_response

    def self.included(object)
      super
      object.extend(ClassMethods)
    end

    def endpoint(operation:, options: {}, **kwargs)
      result = operation.call(**endpoint_options, **options)
      options = Endpoint::EndpointOptions.new(
        result: result, default_handler: default_handler, default_cases: default_cases, invoker: self, **kwargs
      )
      Endpoint.call(options)
    end

    private

    def endpoint_options
      { params: params }
    end

    def default_handler
      raise NotImplementedError, HANDLER_ERROR_MESSAGE
    end

    def default_cases
      raise NotImplementedError, CASES_ERROR_MESSAGE
    end

    def cases(&block)
      self.__different_cases = Builder.new(&block).to_h
    end

    def handler(&block)
      self.__different_handler = Builder.new(&block).to_h
    end

    def before_response(&block)
      self.__before_response = Builder.new(&block).to_h
    end
  end
end
