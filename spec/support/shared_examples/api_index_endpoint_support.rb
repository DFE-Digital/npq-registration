# frozen_string_literal: true

RSpec.shared_examples "an API index endpoint" do
  context "when authorized" do
    context "when 2 resources exist for current_lead_provider" do
      let!(:resource1) { create_resource(lead_provider: current_lead_provider) }
      let!(:resource2) { create_resource(lead_provider: current_lead_provider) }

      before do
        create_resource(lead_provider: LeadProvider.where.not(id: current_lead_provider.id).first)
      end

      it "returns 2 resources" do
        api_get(path)

        expect(response.status).to eq 200
        expect(response.content_type).to eql("application/json")
        expect(response_ids).to contain_exactly(resource1[resource_id_key], resource2[resource_id_key])
      end

      it "calls the correct query/serializer" do
        serializer_params = { root: "data" }
        serializer_params[:view] = serializer_version if defined?(serializer_version)
        serializer_params[:lead_provider] = serializer_lead_provider if defined?(serializer_lead_provider)

        expect(serializer).to receive(:render).with([resource1, resource2], **serializer_params).and_call_original
        expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider)).and_call_original

        api_get(path)
      end
    end

    context "when no resources exist" do
      it "returns empty" do
        api_get(path)

        expect(response.status).to eq 200
        expect(parsed_response["data"]).to be_empty
      end
    end
  end

  context "when unauthorized" do
    it "returns 401 - unauthorized" do
      api_get(path, token: "incorrect-token")

      expect(response.status).to eq 401
      expect(parsed_response["error"]).to eql("HTTP Token: Access denied")
      expect(response.content_type).to eql("application/json")
    end
  end
end

RSpec.shared_examples "an API index endpoint on a parent resource" do |parent, child|
  context "when 2 #{child.pluralize} exist for current_lead_provider" do
    let!(:resource) { create_resource(lead_provider: current_lead_provider) }

    before do
      create_resource_with_different_parent(lead_provider: current_lead_provider)
    end

    it "only returns the #{child} nested on the requested #{parent}" do
      api_get(path)

      expect(response.status).to eq 200
      expect(response.content_type).to eql("application/json")
      expect(response_ids).to contain_exactly(resource[resource_id_key])
    end
  end
end

RSpec.shared_examples "an API index endpoint with sorting" do
  it "calls the correct query" do
    expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, sort: "-created_at")).and_call_original

    api_get(path, params: { sort: "-created_at" })
  end
end

RSpec.shared_examples "an API index endpoint with pagination" do
  context "with pagination" do
    before do
      8.times { create_resource(lead_provider: current_lead_provider) }
    end

    it "returns 5 resources on page 1" do
      api_get(path, params: { page: { per_page: 5, page: 1 } })

      expect(response.status).to eq 200
      expect(parsed_response["data"].size).to eq(5)
    end

    it "returns 3 resources on page 2" do
      api_get(path, params: { page: { per_page: 5, page: 2 } })

      expect(response.status).to eq 200
      expect(parsed_response["data"].size).to eq(3)
    end

    it "returns empty for page 3" do
      api_get(path, params: { page: { per_page: 5, page: 3 } })

      expect(response.status).to eq 200
      expect(parsed_response["data"].size).to eq(0)
    end

    it "returns error when requesting page -1" do
      api_get(path, params: { page: { per_page: 5, page: -1 } })

      expect(response.status).to eq 400
      expect(parsed_response["errors"].size).to eq(1)
      expect(parsed_response["errors"][0]["title"]).to eql("Bad request")
      expect(parsed_response["errors"][0]["detail"]).to eql("The '#/page[page]' and '#/page[per_page]' parameter values must be a valid positive number")
    end
  end
end

RSpec.shared_examples "an API index endpoint with filter by cohort" do
  context "when fitlering by cohort" do
    let(:cohort_2023) { create(:cohort, start_year: 2023) }
    let(:cohort_2024) { create(:cohort, start_year: 2024) }
    let(:cohort_2025) { create(:cohort, start_year: 2025) }

    it "returns resources for the specified cohorts" do
      create_resource(lead_provider: current_lead_provider, cohort: cohort_2023)
      create_resource(lead_provider: current_lead_provider, cohort: cohort_2024)
      create_resource(lead_provider: current_lead_provider, cohort: cohort_2025)

      api_get(path, params: { filter: { cohort: "2023,2024" } })

      expect(parsed_response["data"].size).to eq(2)
    end

    it "calls the correct query" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, cohort_start_years: "2023,2024")).and_call_original

      api_get(path, params: { filter: { cohort: "2023,2024" } })
    end
  end
end

RSpec.shared_examples "an API index endpoint with filter by updated_since" do
  context "when fitlering by updated_since" do
    it "returns resources updated since the specified date" do
      create_resource(lead_provider: current_lead_provider, updated_at: 2.hours.ago)
      create_resource(lead_provider: current_lead_provider, updated_at: 1.minute.ago)

      api_get(path, params: { filter: { updated_since: 1.hour.ago.iso8601 } })

      expect(parsed_response["data"].size).to eq(1)
    end

    it "calls the correct query" do
      updated_since = 1.hour.ago.iso8601
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, updated_since: Time.iso8601(updated_since))).and_call_original

      api_get(path, params: { filter: { updated_since: } })
    end

    it "returns 400 - bad request for invalid updated_since" do
      api_get(path, params: { filter: { updated_since: "invalid" } })

      expect(response.status).to eq 400
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => "The filter '#/updated_since' must be a valid ISO 8601 date",
          "title" => "Bad request",
        },
      ])
    end
  end
end

RSpec.shared_examples "an API index endpoint with filter by created_since" do
  context "when fitlering by created_since" do
    it "returns resources created since the specified date" do
      travel_to(2.hours.ago) { create_resource(lead_provider: current_lead_provider) }
      travel_to(1.minute.ago) { create_resource(lead_provider: current_lead_provider) }

      api_get(path, params: { filter: { created_since: 1.hour.ago.iso8601 } })

      expect(parsed_response["data"].size).to eq(1)
    end

    it "calls the correct query" do
      created_since = 1.hour.ago.iso8601
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, created_since: Time.iso8601(created_since))).and_call_original

      api_get(path, params: { filter: { created_since: } })
    end

    it "returns 400 - bad request for invalid created_since" do
      api_get(path, params: { filter: { created_since: "invalid" } })

      expect(response.status).to eq 400
      expect(parsed_response["errors"]).to eq([
        {
          "detail" => "The filter '#/created_since' must be a valid ISO 8601 date",
          "title" => "Bad request",
        },
      ])
    end
  end
end

RSpec.shared_examples "an API index endpoint with filter by participant_id" do
  context "when fitlering by participant_id" do
    it "returns resources with the given `participant_id`" do
      resource1 = create_resource(lead_provider: current_lead_provider, user: create(:user))
      resource2 = create_resource(lead_provider: current_lead_provider, user: create(:user))
      create_resource(lead_provider: current_lead_provider, user: create(:user))

      api_get(path, params: { filter: { participant_id: [resource1.user.ecf_id, resource2.user.ecf_id].join(",") } })

      expect(parsed_response["data"].size).to eq(2)
    end

    it "calls the correct query" do
      participant_id = [SecureRandom.uuid, SecureRandom.uuid].join(",")
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, participant_ids: participant_id)).and_call_original

      api_get(path, params: { filter: { participant_id: } })
    end
  end
end

RSpec.shared_examples "an API index endpoint with filter by training_status" do
  context "when fitlering by training_status" do
    let!(:resource) { create_resource(lead_provider: current_lead_provider) }
    let(:training_status) { ApplicationState.states[:withdrawn] }

    before { resource.applications.first.update!(training_status:) }

    it "returns resources with the given `training_status`" do
      create_resource(lead_provider: current_lead_provider)

      api_get(path, params: { filter: { training_status: } })

      expect(parsed_response["data"].size).to eq(1)
    end

    it "calls the correct query" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, training_status:)).and_call_original

      api_get(path, params: { filter: { training_status: } })
    end
  end
end

RSpec.shared_examples "an API index endpoint with filter by from_participant_id" do
  context "when fitlering by from_participant_id" do
    let!(:resource) { create_resource(lead_provider: current_lead_provider) }
    let(:participant_id_change) { create(:participant_id_change, user: resource, to_participant: resource) }
    let(:from_participant_id) { participant_id_change.from_participant.ecf_id }

    it "returns resources with the given `from_participant_id`" do
      create_resource(lead_provider: current_lead_provider)

      api_get(path, params: { filter: { from_participant_id: } })

      expect(parsed_response["data"].size).to eq(1)
    end

    it "calls the correct query" do
      expect(query).to receive(:new).with(a_hash_including(lead_provider: current_lead_provider, from_participant_id:)).and_call_original

      api_get(path, params: { filter: { from_participant_id: } })
    end
  end
end
