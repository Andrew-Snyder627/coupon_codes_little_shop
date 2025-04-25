require 'rails_helper'

RSpec.describe "Coupons API", type: :request do
  describe "GET /index" do
    it "returns all coupons for a merchant" do
      merchant = create(:merchant)
      create_list(:coupon, 3, merchant: merchant)

      get api_v1_merchant_coupons_path(merchant)

      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data].count).to eq(3)
      expect(json[:data].first[:attributes]).to include(:name, :code, :value, :value_type, :active)
    end
  end

  describe "GET /show" do
    it "returns a specific coupon with times used count" do
      merchant = create(:merchant)
      coupon = create(:coupon, merchant: merchant)

      get api_v1_merchant_coupon_path(merchant, coupon)

      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data][:id]).to eq(coupon.id.to_s)
      expect(json[:data][:attributes][:name]).to eq(coupon.name)
      expect(json[:data][:attributes]).to have_key(:times_used)
    end
  end

  describe "POST /create" do
    it "creates a new coupon for a merchant" do
      merchant = create(:merchant)

      coupon_params = {
        name: "Holiday Deal",
        code: "HOLIDAY2025",
        value: 25,
        value_type: "percent",
        active: true
      }

      post api_v1_merchant_coupons_path(merchant), params: { coupon: coupon_params }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data][:attributes][:name]).to eq("Holiday Deal")
      expect(json[:data][:attributes][:code]).to eq("HOLIDAY2025")
      expect(json[:data][:attributes][:value].to_f).to eq(25.0)
      expect(json[:data][:attributes][:value_type]).to eq("percent")
      expect(json[:data][:attributes][:active]).to eq(true)
    end
  end

  describe "PATCH /update" do
    it "updates a coupon to deactivate it" do
      merchant = create(:merchant)
      coupon = create(:coupon, merchant: merchant, active: true)

      patch api_v1_merchant_coupon_path(merchant, coupon), params: { coupon: { active: false } }

      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:data][:attributes][:active]).to eq(false)
    end
  end
end