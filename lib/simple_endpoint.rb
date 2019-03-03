require "simple_endpoint/version"

module SimpleEndpoint
  class OperationIsNotHandled < StandardError ;end
  class UnhadledResultError < StandardError ;end

  module Controller
    def endpoint(operation:, different_cases: {}, options: endpoint_options, &block)
      Endpoint.(
        operation,
        default_handler,
        default_cases.merge(different_cases),
        options,
        &block
      )
    end

    private
    
    def endpoint_options(**additional_options)
      { params: params }.merge(additional_options)
    end

    def default_handler
      raise NotImplementedError, <<-LARGE_ERROR
        Please implement default_handler via case statement

        EXAMPLE:
        ###############################################

        # Can be put into ApplicationController and redefined in subclasses
        
        private

        def default_handler
          -> (kase, result) do
            case kase
            when :success then render :json ...
            else
              # just in case you forgot to add handler for some of case
              SimpleEndpoint::UnhadledResultError, 'Oh nooooo!!! Really???!!'
            end
          end
        end

        ###############################################

        OR

        You can move this logic to separate singleton class
      LARGE_ERROR
    end

    def default_cases
      raise NotImplementedError, <<-LARGE_ERROR
        Please implement default cases conditions via hash

        EXAMPLE:
        ###############################################
        # default trailblazer-endpoint logic, you can change it
        # Can be put into ApplicationController and redefined in subclasses

        private

        def default_cases
          {
            present:         -> (result) { result.success? && result["present"] }
            success:         -> (result) { result.success? },
            created:         -> (result) { result.success? && result["model.action"] == :new }
            invalid:         -> (result) { result.failure? },
            not_found:       -> (result) { result.failure? && result["result.model"] && result["result.model"].failure? },
            unauthenticated: -> (result) { result.failure? && result["result.policy.default"] && result["result.policy.default"].failure? }
          }
        end

        ###############################################

        OR

        You can move this to separate singleton class
      LARGE_ERROR
    end
  end

  class Endpoint
    def self.call(operation, handler, cases, **args, &block)
      result = operation.(**args)
      new.(result, cases, handler, &block)
    end

    def call(result, cases, handler=nil, &block)
      matcher.(result, cases, &block) if block_given?
      matcher.(result, cases, &handler)
    end

    def matcher
      -> (result, cases, &block) {
        matched_kase = cases.select { |kase, cond| cond.(result) }.to_a.flatten.first # can be optimized
        raise OperationIsNotHandled, 'Come on guys!!!' unless matched_kase
        block.(matched_kase, result)
      }
    end
  end
end
