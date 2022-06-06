# frozen_string_literal: true

RSpec.describe SimpleEndpoint::Controller do
  describe '#endpoint' do
    subject(:result) { klass.new.endpoint(operation: operation, options: options) }

    let(:klass) do
      Class.new do
        include SimpleEndpoint::Controller

        handler { on(:success) { |result| result[:value] = :success } }
        cases { on(:success) { |result| result[:value] = :success } }

        def params
          { param: :param_value }
        end
      end
    end
    # rubocop:disable RSpec/VerifiedDoubleReference
    let(:operation) { instance_double('dummy_operation') }
    # rubocop:enable RSpec/VerifiedDoubleReference
    let(:options) { { option: :option_value } }

    before { allow(operation).to receive(:call) }

    context 'when everything is implemented' do
      before do
        allow(SimpleEndpoint::Endpoint).to receive(:call)
        result
      end

      it 'invokes operation' do
        expect(operation).to have_received(:call).with(params: { param: :param_value }, **options)
      end

      it 'invokes Endpoint class' do
        expect(SimpleEndpoint::Endpoint).to have_received(:call).with(
          instance_of(SimpleEndpoint::Endpoint::EndpointOptions)
        )
      end
    end

    context 'when default_handler is not redefined' do
      let(:klass) do
        Class.new do
          include SimpleEndpoint::Controller

          def params
            { param: :param_value }
          end
        end
      end

      it 'raises NotImplementedError with message' do
        expect { result }.to raise_error(NotImplementedError, SimpleEndpoint::HANDLER_ERROR_MESSAGE)
      end
    end

    context 'when default_cases is not redefined' do
      let(:klass) do
        Class.new do
          include SimpleEndpoint::Controller

          handler { on(:handler_status) { :handler } }

          def params
            { param: :param_value }
          end
        end
      end

      it 'raises NotImplementedError with message' do
        expect { result }.to raise_error(NotImplementedError, SimpleEndpoint::CASES_ERROR_MESSAGE)
      end
    end
  end

  describe '.handler' do
    subject(:instance) { klass.new }

    let(:klass) do
      Class.new do
        include SimpleEndpoint::Controller

        handler { on(:handler_status) { :handler } }
      end
    end

    it 'creates default_handler method with provided settings' do
      expect(instance.default_handler[:handler_status].call).to eq(:handler)
    end

    context 'when handler is called in child class' do
      subject(:instance) { child_klass.new }

      let(:child_klass) do
        Class.new(klass) do
          handler { on(:another_handler_status) { :child_handler } }
        end
      end

      it 'copies parent default_handler' do
        expect(instance.default_handler[:handler_status].call).to eq(:handler)
      end

      it 'adds new handler settings' do
        expect(instance.default_handler[:another_handler_status].call).to eq(:child_handler)
      end
    end

    context 'when handler is called in child class with inherit: false' do
      subject(:instance) { child_klass.new }

      let(:child_klass) do
        Class.new(klass) do
          handler(inherit: false) { on(:another_handler_status) { :child_handler } }
        end
      end

      it 'does not copy parent default_handler' do
        expect(instance.default_handler).not_to include(:handler_status)
      end

      it 'adds new handler settings' do
        expect(instance.default_handler[:another_handler_status].call).to eq(:child_handler)
      end
    end
  end

  describe '.cases' do
    subject(:instance) { klass.new }

    let(:klass) do
      Class.new do
        include SimpleEndpoint::Controller

        cases { match(:case_status) { :case_handler } }
      end
    end

    it 'creates default_cases method with provided settings' do
      expect(instance.default_cases[:case_status].call).to eq(:case_handler)
    end

    context 'when cases is called in child class' do
      subject(:instance) { child_klass.new }

      let(:child_klass) do
        Class.new(klass) do
          cases { match(:another_case_status) { :child_case_handler } }
        end
      end

      it 'copies parent default_cases' do
        expect(instance.default_cases[:case_status].call).to eq(:case_handler)
      end

      it 'adds new cases settings' do
        expect(instance.default_cases[:another_case_status].call).to eq(:child_case_handler)
      end
    end

    context 'when cases is called in child class with inherit: false' do
      subject(:instance) { child_klass.new }

      let(:child_klass) do
        Class.new(klass) do
          cases(inherit: false) { match(:another_case_status) { :child_case_handler } }
        end
      end

      it 'does not copy parent default_cases' do
        expect(instance.default_cases).not_to include(:case_status)
      end

      it 'adds new cases settings' do
        expect(instance.default_cases[:another_case_status].call).to eq(:child_case_handler)
      end
    end
  end

  describe '.endpoint_options' do
    subject(:instance) { klass.new }

    let(:klass) do
      Class.new do
        include SimpleEndpoint::Controller

        endpoint_options { { option: :option_value } }

        def params
          { param: :param_value }
        end
      end
    end

    it 'creates endpoint_options method' do
      expect(instance.endpoint_options).to eq({ params: { param: :param_value }, option: :option_value })
    end

    context 'when endpoint_options uses another method' do
      let(:klass) do
        Class.new do
          include SimpleEndpoint::Controller

          endpoint_options { { option: option } }

          def params
            { param: :param_value }
          end

          def option
            :option_value
          end
        end
      end

      it 'creates endpoint_options method' do
        expect(instance.endpoint_options).to eq({ params: { param: :param_value }, option: :option_value })
      end
    end

    context 'when endpoint_options is called in child class' do
      subject(:instance) { child_klass.new }

      let(:child_klass) do
        Class.new(klass) do
          endpoint_options { { another_option: :another_option_value } }
        end
      end

      it 'returns parent and child options' do
        expect(instance.endpoint_options).to eq({ params: { param: :param_value },
                                                  option: :option_value,
                                                  another_option: :another_option_value })
      end
    end

    context 'when endpoint_options is called in child class with inherit: false' do
      subject(:instance) { child_klass.new }

      let(:child_klass) do
        Class.new(klass) do
          endpoint_options(inherit: false) { { another_option: :another_option_value } }
        end
      end

      it 'returns parent and child options' do
        expect(instance.endpoint_options).to eq({ another_option: :another_option_value })
      end
    end
  end

  describe '#handler' do
    subject(:instance) do
      Class.new do
        include SimpleEndpoint::Controller

        def action
          handler { on(:success) { |result| result } }
        end
      end.new
    end

    before { instance.action }

    it 'saves different_handler inside __diferrent_handler accessor' do
      expect(instance.__different_handler).to include(:success)
    end
  end

  describe '#cases' do
    subject(:instance) do
      Class.new do
        include SimpleEndpoint::Controller

        def action
          cases { match(:success) { |result| result[:success] } }
        end
      end.new
    end

    before { instance.action }

    it 'saves different_cases inside __diferrent_cases accessor' do
      expect(instance.__different_cases).to include(:success)
    end
  end

  describe '#before_response' do
    subject(:instance) do
      Class.new do
        include SimpleEndpoint::Controller

        def action
          before_response { on(:success) { |result| result[:value] = :modified_value } }
        end
      end.new
    end

    before { instance.action }

    it 'saves before_response inside __before_response accessor' do
      expect(instance.__before_response).to include(:success)
    end
  end
end
