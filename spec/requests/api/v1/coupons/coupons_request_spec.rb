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

    it "returns only active coupons when active=true" do
      merchant = create(:merchant)
      create_list(:coupon, 2, merchant: merchant, active: true)
      create(:coupon, merchant: merchant, active: false)

      get api_v1_merchant_coupons_path(merchant), params: { active: "true" }

      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)

      expect(json[:data].length).to eq(2)
      expect(json[:data].all? { |c| c[:attributes][:active] }).to be true
    end

    it "returns only inactive coupons when active=false" do
      merchant = create(:merchant)
      create_list(:coupon, 2, merchant: merchant, active: false)
      create(:coupon, merchant: merchant, active: true)
  
      get api_v1_merchant_coupons_path(merchant), params: { active: "false" }
  
      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(json[:data].length).to eq(2)
      expect(json[:data].all? { |c| c[:attributes][:active] == false }).to be true
    end
  
    it "returns an empty array for invalid active param" do
      merchant = create(:merchant)
      create_list(:coupon, 2, merchant: merchant)
  
      get api_v1_merchant_coupons_path(merchant), params: { active: "peanut butter" }
  
      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)
  
      expect(json[:data]).to eq([])
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

    it "returns the correct times_used count for a coupon" do
      merchant = create(:merchant)
      coupon = create(:coupon, merchant: merchant)
      customer = create(:customer)
    
      create_list(:invoice, 3, merchant: merchant, customer: customer, coupon: coupon)
    
      get api_v1_merchant_coupon_path(merchant, coupon)
    
      expect(response).to be_successful
      json = JSON.parse(response.body, symbolize_names: true)
    
      expect(json[:data][:attributes][:times_used]).to eq(3)
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

  describe "SAD Path" do
    it "cannot create a 6th active coupon for a merchant" do
      merchant = create(:merchant)
      create_list(:coupon, 5, merchant: merchant, active: true)

      new_coupon_params = {
        name: "Extra Deal",
        code: "EXTRA2025",
        value: 20,
        value_type: "percent",
        active: true
      }

      post api_v1_merchant_coupons_path(merchant), params: { coupon: new_coupon_params }

      expect(response).to_not be_successful
      expect(response.status).to eq(400)

      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:message]).to eq("your query could not be completed")
      expect(json[:errors]).to include("This Merchant already has 5 active coupons")
    end

    it "does not allow duplicate coupon codes" do
      merchant = create(:merchant)
      create(:coupon, merchant: merchant, code: "DUPE")

      new_coupon_params = {
        name: "Duplicate Deal",
        code: "DUPE",
        value: 10,
        value_type: "dollar",
        active: true
      }

      post api_v1_merchant_coupons_path(merchant), params: { coupon: new_coupon_params }

      expect(response).to_not be_successful
      expect(response.status).to eq(400)

      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to include("Validation failed: Code has already been taken")
    end

    it "does not allow deactivation if coupon is ona pending invoice" do
      merchant = create(:merchant)
      coupon = create(:coupon, merchant: merchant, active: true)
      customer = create(:customer)
      create(:invoice, merchant: merchant, customer: customer, coupon: coupon, status: "pending")

      patch api_v1_merchant_coupon_path(merchant, coupon), params: { coupon: { active: false } }

      expect(response).to_not be_successful
      expect(response.status).to eq(400)

      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors]).to include("Coupon cannot be deactivated due to pending invoices")
    end

    it "returns an error when creating a coupon without a name" do
      merchant = create(:merchant)

      invalid_params = {
        code: "NONAME",
        value: 10,
        value_type: "dollar",
        active: true
      }
    
      post api_v1_merchant_coupons_path(merchant), params: { coupon: invalid_params }
    
      expect(response.status).to eq(400)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors].any? { |e| e.include?("Name can't be blank") }).to be true
    end

    it "returns an error when creating a coupon without a value" do
      merchant = create(:merchant)
    
      invalid_params = {
        name: "No Value",
        code: "NOVALUE",
        value_type: "percent",
        active: true
      }
    
      post api_v1_merchant_coupons_path(merchant), params: { coupon: invalid_params }
    
      expect(response.status).to eq(400)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors].any? { |e| e.include?("Validation failed: Value can't be blank") }).to be true
    end

    it "returns an error when creating a coupon without a value type" do
      merchant = create(:merchant)
    
      invalid_params = {
        name: "No Value Type",
        code: "NOVALUETYPE",
        value: 100,
        active: true
      }
    
      post api_v1_merchant_coupons_path(merchant), params: { coupon: invalid_params }
    
      expect(response.status).to eq(400)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors].any? { |e| e.include?("Validation failed: Value type is not included in the list") }).to be true
    end

    it "rejects a coupon with an invalid value_type" do
      merchant = create(:merchant)
    
      bad_params = {
        name: "Wrong Type",
        code: "WRONG",
        value: 30,
        value_type: "BOGO",  # not allowed
        active: true
      }
    
      post api_v1_merchant_coupons_path(merchant), params: { coupon: bad_params }
    
      expect(response.status).to eq(400)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors].any? { |e| e.include?("Value type is not included in the list") }).to be true
    end

    it "returns an error when trying to update with an invalid value_type" do
      merchant = create(:merchant)
      coupon = create(:coupon, merchant: merchant)
    
      patch api_v1_merchant_coupon_path(merchant, coupon), params: {
        coupon: { value_type: "random" }
      }
    
      expect(response.status).to eq(400)
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:errors].any? { |e| e.include?("Value type is not included in the list") }).to be true
    end

    # Error Handling Tests
    it "triggers error handling if coupon not found for show" do
      merchant = create(:merchant)
    
      get api_v1_merchant_coupon_path(merchant, 999999)
    
      expect(response).to_not be_successful
      expect(response).to have_http_status(:not_found)
    
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:message]).to eq("your query could not be completed")
      expect(json[:errors].first).to match(/Couldn't find Coupon with 'id'=999999/)
      # Had to add a regex matcher here due to an added WHERE clause from ActiveRecord
    end

    it "triggers error handling if creating a coupon with missing required fields" do
      merchant = create(:merchant)
    
      invalid_params = {
        code: nil,  # missing required code
        value: 10,
        value_type: "dollar",
        active: true
      }
    
      post api_v1_merchant_coupons_path(merchant), params: { coupon: invalid_params }
    
      expect(response).to_not be_successful
      expect(response).to have_http_status(:bad_request)
    
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:message]).to eq("your query could not be completed")
      expect(json[:errors].any? { |e| e.include?("Code can't be blank") }).to be true
    end

    it "triggers error handling if malformed JSON is sent in the request" do
      merchant = create(:merchant)
      headers = { "CONTENT_TYPE" => "application/json" } # Needed to add this for the bad json
    
      bad_json = '{ "coupon": { "name": "Bad Coupon", "code": "oops", "value": } }'  # malformed
    
      post api_v1_merchant_coupons_path(merchant), headers: headers, params: bad_json
    
      expect(response).to_not be_successful
      expect(response).to have_http_status(:bad_request)
    
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:message]).to eq("your query could not be completed")
      expect(json[:errors].first).to include("Error occurred while parsing request parameters")
    end

    it "does not allow activating a coupon if merchant already has 5 active coupons" do
      merchant = create(:merchant)
      create_list(:coupon, 5, merchant: merchant, active: true)
      inactive_coupon = create(:coupon, merchant: merchant, active: false)
    
      patch api_v1_merchant_coupon_path(merchant, inactive_coupon), params: {
        coupon: { active: true }
      }
    
      expect(response).to_not be_successful
      expect(response.status).to eq(400)
    
      json = JSON.parse(response.body, symbolize_names: true)
      expect(json[:message]).to eq("your query could not be completed")
      expect(json[:errors]).to include("This Merchant already has 5 active coupons")
    end
  end
end