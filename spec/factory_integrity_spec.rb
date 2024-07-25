require "rails_helper"

RSpec.describe "Factory integrity check" do
  FactoryBot.factories.each do |factory|
    describe factory.name do
      it { expect(create(factory.name)).to be_valid }

      factory.definition.defined_traits.each do |trait|
        context "when specifying the #{trait.name} trait" do
          it { expect(create(factory.name, trait.name)).to be_valid }
        end
      end
    end
  end
end
