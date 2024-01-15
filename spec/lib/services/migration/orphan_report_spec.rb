require "rails_helper"

RSpec.describe Migration::OrphanReport do
  before { allow(Rails.logger).to receive(:info) }

  let(:indexes) { %i[foo bar] }
  let(:reconciler) { instance_double(Migration::Reconciler, indexes:, orphaned_matches:) }
  let(:instance) { described_class.new(reconciler) }

  describe "#to_yaml" do
    subject(:to_yaml) { instance.to_yaml }

    context "when there are no orphans" do
      let(:orphaned_matches) { [] }

      it { is_expected.to eq([].to_yaml) }
    end

    context "when there are orphans" do
      let(:orphaned_matches) do
        [
          create_orphaned_match(foo: :baz, bar: :qux),
          create_orphaned_match(foo: :quux),
        ]
      end

      it "returns orphans and potential matches in YAML format" do
        expect(subject).to eq(
          <<~YAML,
            ---
            - :orphan:
                :class: OpenStruct
                :foo: baz
                :bar: qux
              :potential_matches:
              - :class: OpenStruct
                :foo: baz
                :bar: qux
              - :class: OpenStruct
                :foo: baz
                :bar: qux
            - :orphan:
                :class: OpenStruct
                :foo: quux
              :potential_matches:
              - :class: OpenStruct
                :foo: quux
              - :class: OpenStruct
                :foo: quux
          YAML
        )
      end

      it "logs the progress" do
        to_yaml
        expect(Rails.logger).to have_received(:info).with("Processing orphan 1 of 2 for #{reconciler.class}")
        expect(Rails.logger).to have_received(:info).with("Processing orphan 2 of 2 for #{reconciler.class}")
      end
    end
  end

  def create_orphaned_match(attributes)
    orphan = OpenStruct.new(attributes)
    potential_matches = 2.times.collect { OpenStruct.new(attributes) }
    Migration::OrphanMatch.new(orphan, potential_matches)
  end
end
