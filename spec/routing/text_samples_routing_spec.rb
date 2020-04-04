require "rails_helper"

RSpec.describe TextSamplesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/text_samples").to route_to("text_samples#index")
    end

    it "routes to #new" do
      expect(get: "/text_samples/new").to route_to("text_samples#new")
    end

    it "routes to #show" do
      expect(get: "/text_samples/1").to route_to("text_samples#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/text_samples/1/edit").to route_to("text_samples#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/text_samples").to route_to("text_samples#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/text_samples/1").to route_to("text_samples#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/text_samples/1").to route_to("text_samples#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/text_samples/1").to route_to("text_samples#destroy", id: "1")
    end
  end
end
