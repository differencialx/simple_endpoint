# frozen_string_literal: true

shared_context 'when operation success' do
  before do
    allow(result).to receive(:success?).and_return(true)
    endpoint
  end
end
