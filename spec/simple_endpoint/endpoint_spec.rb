# frozen_string_literal: true

RSpec.describe SimpleEndpoint::Endpoint do
  describe '.call' do
    subject(:endpoint) { described_class.call(endpoint_options) }

    let(:endpoint_options) do
      SimpleEndpoint::Endpoint::EndpointOptions.new(
        result: result, invoker: invoker, default_handler: handler, default_cases: cases
      )
    end
    let(:invoker) do
      Class.new do
        include SimpleEndpoint::Controller
      end.new
    end
    let(:result) { { success: true, value: :value } }
    let(:handler) { { success: ->(result, **) { result[:value] } } }
    let(:cases) { { success: ->(result) { result[:success] } } }

    context 'when result is successful' do
      it 'returns handler result' do
        expect(endpoint).to eq(result[:value])
      end

      context 'when handler contains invoker method' do
        let(:endpoint_options) do
          SimpleEndpoint::Endpoint::EndpointOptions.new(
            result: result, invoker: invoker, default_handler: handler, default_cases: cases
          )
        end
        let(:handler) { { success: ->(_, **) { handle_status } } }
        let(:invoker) do
          Class.new do
            include SimpleEndpoint::Controller

            def handle_status
              :value
            end
          end.new
        end

        it 'returns handler result' do
          expect(endpoint).to eq(result[:value])
        end
      end

      context 'when cases contains invoker method' do
        let(:endpoint_options) do
          SimpleEndpoint::Endpoint::EndpointOptions.new(
            result: result, invoker: invoker, default_handler: handler, default_cases: cases
          )
        end
        let(:cases) { { success: ->(_) { success_result? } } }
        let(:invoker) do
          Class.new do
            include SimpleEndpoint::Controller

            def success_result?
              true
            end
          end.new
        end

        it 'returns handler result' do
          expect(endpoint).to eq(result[:value])
        end
      end
    end

    context 'with renderer options' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases,
          renderer_options: { option: :option_value }
        )
      end
      let(:handler) { { success: ->(result, **options) { result[:options] = options } } }

      before { endpoint }

      it 'passes renderer options to handler' do
        expect(result.dig(:options, :option)).to eq(:option_value)
      end
    end

    context 'with before response that is not match result status' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases,
          before_response: { failure: ->(result, **) { result[:value] = :modified_value } }
        )
      end

      it 'does not modify result' do
        endpoint
        expect(result[:value]).not_to eq(:modified_value)
      end
    end

    context 'with before response that is stored inside invoker' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases
        )
      end
      let(:invoker) do
        Class.new do
          include SimpleEndpoint::Controller
        end.new
      end

      before do
        invoker.__before_response = { success: ->(result, **) { result[:value] = :modified_value } }
        endpoint
      end

      it 'modifies result' do
        expect(result[:value]).to eq(:modified_value)
      end
    end

    context 'with before response' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases,
          before_response: { success: ->(result, **) { result[:value] = :modified_value } }
        )
      end

      it 'modifies result' do
        endpoint
        expect(result[:value]).to eq(:modified_value)
      end
    end

    context 'with different_handler that is stored inside invoker' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases
        )
      end
      let(:invoker) do
        Class.new do
          include SimpleEndpoint::Controller
        end.new
      end

      before do
        invoker.__different_handler = { success: ->(result, **) { result[:value] = :modified_value } }
        endpoint
      end

      it 'modifies result' do
        expect(result[:value]).to eq(:modified_value)
      end
    end

    context 'with different_handler' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases,
          different_handler: { success: ->(result, **) { result[:value] = :modified_value } }
        )
      end
      let(:invoker) do
        Class.new do
          include SimpleEndpoint::Controller
        end.new
      end

      before { endpoint }

      it 'modifies result' do
        expect(result[:value]).to eq(:modified_value)
      end
    end

    context 'with different_cases that are stored inside invoker' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases
        )
      end
      let(:invoker) do
        Class.new do
          include SimpleEndpoint::Controller
        end.new
      end

      before { invoker.__different_cases = { success: ->(result) { result[:value] == :value } } }

      it 'modifies result' do
        expect(endpoint).to eq(:value)
      end
    end

    context 'with different_cases' do
      let(:endpoint_options) do
        SimpleEndpoint::Endpoint::EndpointOptions.new(
          result: result, invoker: invoker, default_handler: handler, default_cases: cases,
          different_cases: { success: ->(result) { result[:value] == :value } }
        )
      end
      let(:invoker) do
        Class.new do
          include SimpleEndpoint::Controller
        end.new
      end

      it 'modifies result' do
        expect(endpoint).to eq(:value)
      end
    end

    context 'when there is no matched case' do
      let(:cases) { {} }

      it 'raises OperationIsNotHandled error with message' do
        expect { endpoint }.to raise_error(
          SimpleEndpoint::OperationIsNotHandled, SimpleEndpoint::OperationIsNotHandled::OPERATION_IS_NOT_HANDLED_ERROR
        )
      end
    end

    context 'when there is no matched case handler' do
      let(:handler) { {} }

      it 'raises UnhandledResultError error with message' do
        expect { endpoint }.to raise_error(SimpleEndpoint::UnhandledResultError)
      end
    end
  end
end
