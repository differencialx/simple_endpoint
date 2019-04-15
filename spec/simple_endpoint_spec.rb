# frozen_string_literal: true

RSpec.describe SimpleEndpoint do
  Dummy = Class.new do
    include SimpleEndpoint::Controller

    attr_accessor :instance_context, :before_context

    def initialize
      @instance_context = nil
      @before_context = nil
    end

    def default_handler
      {
        success: ->(result) { @instance_context = result.success },
        invalid: ->(result) { @instance_context = result.failure }
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

  let(:operation_class) { double('Operation class', call: result) }
  let(:result) { double('Trailbalzer operation result', success: 'Success', failure: 'Failure') }

  let(:args) { { operation: operation_class } }
  let(:dummy_instance) { Dummy.new }

  subject(:endpoint) { dummy_instance.endpoint(**args) }

  context 'Redefining cases' do
    context 'default behavior' do
      it do
        expect(result).to receive(:success?) { true }
        endpoint
        expect(dummy_instance.before_context).to be_nil
        expect(dummy_instance.instance_context).to eq 'Success'
      end
    end

    context 'redefined cases' do
      let(:different_cases) do
        {
          success: ->(result) { result.failure? },
          invalid: ->(result) { result.success? }
        }
      end
      let(:args) do
        {
          operation: operation_class,
          different_cases: different_cases
        }
      end

      it do
        expect(result).to receive(:failure?) { true }
        endpoint
        expect(dummy_instance.before_context).to be_nil
        expect(dummy_instance.instance_context).to eq 'Success'
      end
    end

    context 'Redefining handler' do
      context 'default behavior' do
        it do
          expect(result).to receive(:success?) { true }
          endpoint
          expect(dummy_instance.before_context).to be_nil
          expect(dummy_instance.instance_context).to eq 'Success'
        end
      end

      context 'redefined handler' do
        let(:expected_instance_context) { 'Another context value' }
        let(:args) do
          {
            operation: operation_class,
            different_handler: { success: ->(_result) { dummy_instance.instance_context = expected_instance_context } }
          }
        end

        it do
          expect(result).to receive(:success?) { true }
          endpoint
          expect(dummy_instance.before_context).to be_nil
          expect(dummy_instance.instance_context).to eq expected_instance_context
        end
      end
    end

    context 'Pass additional params' do
      let(:args) do
        {
          operation: operation_class,
          options: { some_key: 'some value' }
        }
      end

      it do
        expect(result).to receive(:success?) { true }
        expect(operation_class).to receive(:call).with(
          params: { controller_param: 'controller_param' },
          some_key: 'some value'
        )
        endpoint
      end
    end

    context 'before response actions' do
      let(:args) do
        {
          operation: operation_class,
          before_response: { success: ->(result) { dummy_instance.before_context = result.success } }
        }
      end

      it do
        expect(result).to receive(:success?) { true }
        dummy_instance.endpoint(**args)
        expect(dummy_instance.before_context).to eq 'Success'
        expect(dummy_instance.instance_context).to eq 'Success'
      end
    end

    context 'raises errors' do
      context 'OperationIsNotHandled' do
        it do
          expect(result).to receive(:success?) { false }
          expect(result).to receive(:failure?) { false }
          expect { endpoint }.to raise_error SimpleEndpoint::OperationIsNotHandled,
                                             'Current operation result is not handled at #default_cases method'
        end
      end

      context 'UnhadledResultError' do
        let(:args) do
          {
            operation: operation_class,
            different_cases: {
              not_found: ->(result) { result.not_found? }
            }
          }
        end

        it do
          expect(result).to receive(:success?) { false }
          expect(result).to receive(:failure?) { false }
          expect(result).to receive(:not_found?) { true }
          expect { endpoint }.to raise_error SimpleEndpoint::UnhadledResultError,
                                             /Key: not_found is not present at/
        end
      end
    end
  end
end
