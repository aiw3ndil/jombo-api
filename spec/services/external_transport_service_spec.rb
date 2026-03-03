require 'rails_helper'

RSpec.describe ExternalTransportService do
  describe ".search" do
    it "exists and responds to search" do
      expect(ExternalTransportService).to respond_to(:search)
    end
  end
end
