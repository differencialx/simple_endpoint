# frozen_string_literal: true

module SimpleEndpoint
  class OperationIsNotHandled < StandardError
    OPERATION_IS_NOT_HANDLED_ERROR = 'Current operation result is not handled at specified cases'

    def initialize
      super(OPERATION_IS_NOT_HANDLED_ERROR)
    end
  end

  class UnhandledResultError < StandardError
    def initialize(matched_case, handler)
      super("Key: #{matched_case} is not present at #{handler}")
    end
  end

  HANDLER_ERROR_MESSAGE = <<-LARGE_ERROR
    Please specify handler

    EXAMPLE:
    ###############################################

    # Can be put into ApplicationController and redefined in subclasses

    class Controller
      handler
        on(:<your case name>) { |result, **| <your code goes here> }
        ...
      end
    end

    ###############################################
  LARGE_ERROR

  CASES_ERROR_MESSAGE = <<-LARGE_ERROR
    Please define cases

    EXAMPLE:
    ###############################################
    # default trailblazer-endpoint logic, you can change it
    # Can be put into ApplicationController and redefined in subclasses

    class Controller
      cases do
        match(:<your case name>) { |result| <your matching code goes here> }
        ...
      end
    end

    ###############################################
  LARGE_ERROR
end
