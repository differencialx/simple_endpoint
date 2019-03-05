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
        success: -> (result) { @instance_context = result.success },
        invalid: -> (result) { @instance_context = result.failure }
      }
    end

    def default_cases
      {
        success: -> (result) { result.success? },
        invalid: -> (result) { result.failure? }
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

  context 'success case' do
    before do
      expect(result).to receive(:success?).at_most(:twice) { true }
      expect(result).to receive(:failure?).at_most(:twice) { false }
    end

    context 'default behavior' do
      it do
        endpoint
        expect(dummy_instance.before_context).to be_nil
        expect(dummy_instance.instance_context).to eq 'Success'
      end
    end

    context 'redefined cases' do
      let(:different_cases) do
        {
          success: -> (result) { result.failure? },
          invalid: -> (result) { result.success? }
        }
      end
      let(:args) do
        {
          operation: operation_class,
          different_cases: different_cases
        }
      end

      it do
        endpoint
        expect(dummy_instance.before_context).to be_nil
        expect(dummy_instance.instance_context).to eq 'Failure'
      end
    end

    context 'before handler action' do
      let(:args) do
        {
          operation: operation_class,
          options: { some_key: 'some value' }
        }
      end

      it do
        expect(operation_class).to receive(:call).with(
          {
            params: { controller_param: 'controller_param' },
            some_key: 'some value'
          }
        )
        endpoint
      end
    end

    context 'before handler actions' do
      let(:args) do
        {
          operation: operation_class,
          before_render: { success: -> (result) { dummy_instance.before_context = result.success } }
        }
      end

      it do
        dummy_instance.endpoint(**args)
        expect(dummy_instance.before_context).to eq 'Success'
        expect(dummy_instance.instance_context).to eq 'Success'
      end
    end
  end
end
