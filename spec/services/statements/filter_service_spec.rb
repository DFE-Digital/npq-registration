# spec/services/statements/filter_service_spec.rb

require 'rails_helper'

RSpec.describe Statements::FilterService do
  let(:params) { {} }
  let(:service) { described_class.new(params) }

  describe '#initialize' do
    it 'initializes with default params' do
      expect(service.instance_variable_get(:@params)).to eq(params)
    end
  end
end