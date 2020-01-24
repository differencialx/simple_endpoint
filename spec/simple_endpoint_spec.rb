# frozen_string_literal: true

RSpec.describe SimpleEndpoint do
  subject(:endpoint) { dummy_instance.endpoint(**args) }

  let(:operation_class) { instance_double('Operation class', call: result) }
  let(:result) { instance_double('Trailbalzer operation result', success: 'Success', failure: 'Failure') }

  let(:args) { { operation: operation_class } }
  let(:dummy_instance) { Dummy.new }

  context 'when cases are redefined' do
    context 'with default behavior' do
      include_context 'when operation success'

      specify { expect(dummy_instance.before_context).to be_nil }
      specify { expect(dummy_instance.instance_context).to eq 'Success' }
    end

    context 'with redefined cases' do
      include_context 'when operation failed'
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

      specify { expect(dummy_instance.before_context).to be_nil }
      specify { expect(dummy_instance.instance_context).to eq 'Success' }
    end

    context 'when handler is redefined' do
      context 'with default behavior' do
        include_context 'when operation success'

        specify { expect(dummy_instance.before_context).to be_nil }
        specify { expect(dummy_instance.instance_context).to eq 'Success' }
      end

      context 'with redefined handler' do
        include_context 'when operation success'

        let(:expected_instance_context) { 'Another context value' }
        let(:args) do
          {
            operation: operation_class,
            different_handler: {
              success: ->(_result, **) { dummy_instance.instance_context = expected_instance_context }
            }
          }
        end

        specify { expect(dummy_instance.before_context).to be_nil }
        specify { expect(dummy_instance.instance_context).to eq expected_instance_context }
      end
    end

    context 'when additional params are passed' do
      include_context 'when operation success'

      let(:args) do
        {
          operation: operation_class,
          options: { some_key: 'some value' }
        }
      end

      specify do
        expect(operation_class).to have_received(:call).with(
          params: { controller_param: 'controller_param' },
          some_key: 'some value'
        )
      end
    end

    context 'when before response action is defined' do
      include_context 'when operation success'

      let(:args) do
        {
          operation: operation_class,
          before_response: { success: ->(result, **) { dummy_instance.before_context = result.success } }
        }
      end

      specify { expect(dummy_instance.before_context).to eq 'Success' }
      specify { expect(dummy_instance.instance_context).to eq 'Success' }
    end

    context 'when raises error' do
      context 'with OperationIsNotHandled' do
        before do
          allow(result).to receive(:success?).and_return(false)
          allow(result).to receive(:failure?).and_return(false)
        end

        specify do
          expect { endpoint }.to raise_error SimpleEndpoint::OperationIsNotHandled,
                                             'Current operation result is not handled at #default_cases method'
        end
      end

      context 'with UnhadledResultError' do
        let(:args) do
          {
            operation: operation_class,
            different_cases: {
              not_found: ->(result) { result.not_found? }
            }
          }
        end

        before do
          allow(result).to receive(:success?).and_return(false)
          allow(result).to receive(:failure?).and_return(false)
          allow(result).to receive(:not_found?).and_return(true)
        end

        specify do
          expect { endpoint }.to raise_error SimpleEndpoint::UnhadledResultError,
                                             /Key: not_found is not present at/
        end
      end
    end

    context 'when serializer is passed' do
      before do
        allow(result).to receive(:success?).and_return(true)
        endpoint
      end

      let(:renderer_options) do
        {
          serializer_class: 'SomeClass',
          include: 'include_options'
        }
      end
      let(:args) do
        {
          operation: operation_class,
          different_handler: { success: ->(_result, **opts) { dummy_instance.instance_context = opts } },
          renderer_options: renderer_options
        }
      end

      specify do
        expect(dummy_instance.instance_context).to eq renderer_options
      end
    end
  end
end
