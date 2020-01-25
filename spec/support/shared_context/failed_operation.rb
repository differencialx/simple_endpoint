# frozen_string_literal: true

shared_context 'when operation failed' do
  before do
    allow(result).to receive(:failure?).and_return(true)
    endpoint
  end
end
