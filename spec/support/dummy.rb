# frozen_string_literal: true

class Dummy
  include SimpleEndpoint::Controller

  attr_accessor :instance_context, :before_context

  def initialize
    @instance_context = nil
    @before_context = nil
  end

  def default_handler
    {
      success: ->(result, **) { @instance_context = result.success },
      invalid: ->(result, **) { @instance_context = result.failure }
    }
  end

  def default_cases
    {
      success: ->(result) { result.success? },
      invalid: ->(result) { result.failure? }
    }
  end

  def params
    { controller_param: 'controller_param' }
  end
end
