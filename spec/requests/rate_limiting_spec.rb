require 'rails_helper'

RSpec.describe "Rate Limiter", type: :request do
  let(:user_id) { "test-user" }

  context "Free plan" do
    it "allows up to 10 requests per minute" do
      10.times do
        get "/ping", headers: { "User-Id" => user_id, "Plan" => "free" }
        expect(response.status).to eq(200)
      end
    end

    it "blocks the 11th request with 429" do
      10.times do
        get "/ping", headers: { "User-Id" => user_id, "Plan" => "free" }
      end

      get "/ping", headers: { "User-Id" => user_id, "Plan" => "free" }
      expect(response.status).to eq(429)
    end
  end

  context "Paid plan" do
    it "allows up to 100 requests per minute" do
      100.times do
        get "/ping", headers: { "User-Id" => user_id, "Plan" => "paid" }
        expect(response.status).to eq(200)
      end
    end

    it "blocks the 101th request with 429" do
      100.times do
        get "/ping", headers: { "User-Id" => user_id, "Plan" => "paid" }
      end

      get "/ping", headers: { "User-Id" => user_id, "Plan" => "free" }
      expect(response.status).to eq(429)
    end
  end
end
