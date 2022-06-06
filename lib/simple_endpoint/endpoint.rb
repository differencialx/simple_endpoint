# frozen_string_literal: true

module SimpleEndpoint
  class Endpoint
    extend Forwardable

    attr_reader :options

    def_delegators :options, :result, :invoker, :renderer_options, :before_response, :handler, :cases

    def self.call(options)
      new(options).call
    end

    def initialize(options)
      @options = options
    end

    def call
      procees_handler(before_response)
      procees_handler(handler, strict: true)
    end

    def matched_case
      @matched_case ||= cases.detect { |_kase, condition| invoker.instance_exec(result, &condition) }&.first
      @matched_case || raise(OperationIsNotHandled)
    end

    def procees_handler(handler, strict: false)
      return invoker.instance_exec(result, **renderer_options, &handler[matched_case]) if handler.key?(matched_case)
      raise UnhandledResultError.new(matched_case, handler) if strict
    end
  end
end
