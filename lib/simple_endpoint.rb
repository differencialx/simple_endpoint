# frozen_string_literal: true

require 'simple_endpoint/version'
# rubocop:disable Metrics/ParameterLists
module SimpleEndpoint
  module Controller
    def endpoint(operation:,
                 different_cases: {},
                 different_hander: {},
                 options: {},
                 before_response: {},
                 renderer_options: {})
      Endpoint.call(
        operation,
        default_handler.merge(different_handler),
        default_cases.merge(different_cases),
        renderer_options,
        before_response,
        endpoint_options.merge(options)
      )
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
  end

  class Endpoint
    def self.call(operation, handler, cases, renderer_options = {}, before_response = {}, **args)
      result = operation.call(**args)
      new.call(result, cases, renderer_options, handler, before_response)
    end

    def call(result, cases, renderer_options = {}, handler = {}, before_response = {})
      matched_case = matched_case(cases, result)
      procees_handler(matched_case, before_response, result, renderer_options) unless before_response.empty?
      procees_handler(matched_case, handler, result, renderer_options, UnhadledResultError)
    end

    def matched_case(cases, result)
      matched_case = obtain_matched_case(cases, result)
      raise OperationIsNotHandled, OPERATION_IS_NOT_HANDLER_ERROR unless matched_case

      matched_case
    end

    def procees_handler(matched_case, handler, result, renderer_options, exception_class = nil)
      if handler.key?(matched_case)
        handler.dig(matched_case)&.(result, **renderer_options)
      elsif exception_class
        raise exception_class, "Key: #{matched_case} is not present at #{handler}"
      end
    end

    def obtain_matched_case(cases, result)
      matched_case = cases.each { |kase, condition| break kase if condition.call(result) }
      return if matched_case.is_a?(Hash)

      matched_case
    end
  end

  class OperationIsNotHandled < StandardError; end
  class UnhadledResultError < StandardError; end

  OPERATION_IS_NOT_HANDLER_ERROR = 'Current operation result is not handled at #default_cases method'
  HANDLER_ERROR_MESSAGE = <<-LARGE_ERROR
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

  CASES_ERROR_MESSAGE = <<-LARGE_ERROR
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
# rubocop:enable Metrics/ParameterLists
