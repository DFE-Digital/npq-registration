require "rails_helper"

RSpec.describe "Factory integrity check" do
  ignore_validation = %i[
    registration_wizard
    registration_state_store
    registration_repository
  ].freeze

  FactoryBot.factories.each do |factory|
    next if [Hash, "Hash"].include?(factory.build_class)

    describe factory.name do
      subject(:instance) { create(factory.name) }

      if ignore_validation.include?(factory.name)
        it { is_expected.to be_instance_of factory.build_class }
      else
        it { is_expected.to be_valid }
      end

      factory.definition.defined_traits.each do |trait|
        context "when specifying the #{trait.name} trait" do
          let(:instance) { create(factory.name, trait.name) }

          if ignore_validation.include?(factory.name)
            it { is_expected.to be_instance_of factory.build_class }
          else
            it { is_expected.to be_valid }
          end
        end
      end
    end
  end
end
