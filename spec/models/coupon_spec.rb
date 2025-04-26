require 'rails_helper'

RSpec.describe Coupon, type: :model do
  describe "relationships" do
    it { should belong_to :merchant }
    it { should have_many :invoices }
  end

  describe "validations" do
    subject { create(:coupon) } # Shouldamatchers must have something to validate against with uniqueness

    it { should validate_presence_of :name }
    it { should validate_presence_of :code }
    it { should validate_uniqueness_of :code}
    it { should validate_presence_of :value }
    it { should validate_inclusion_of(:value_type).in_array(%w[dollar percent]) }
    it { should allow_value(true).for(:active) }
    it { should allow_value(false).for(:active) }
  end

  describe "instance methods" do
    describe "#times_used" do
      it "returns the count of invoices that used the coupon" do
        coupon = create(:coupon)
        customer = create(:customer)
        merchant = coupon.merchant
        create_list(:invoice, 3, merchant: merchant, customer: customer, coupon: coupon)

        expect(coupon.times_used).to eq(3)
      end
    end
  end

  describe "class methods" do
    describe ".exceeds_active_limit?" do
      it "returns true if merchant already has 5 active coupons and new one is active" do
        merchant = create(:merchant)
        create_list(:coupon, 5, merchant: merchant, active: true)
        params = { active: true }

        expect(Coupon.exceeds_active_limit?(merchant, params)).to be true
      end

      it "returns flase if new coupon being added is inactive" do
        merchant = create(:merchant)
        create_list(:coupon, 5, merchant: merchant, active: true)
        params = { active: false }

        expect(Coupon.exceeds_active_limit?(merchant, params)).to be false
      end
    end

    describe ".prevent_deactivation?" do
      it "returns true if the coupon is used on a pending invoice and trying to deactivate" do
        coupon = create(:coupon, active: true)
        customer = create(:customer)
        create(:invoice, merchant: coupon.merchant, customer: customer, coupon: coupon, status: "pending")

        params = { active: false }

        expect(Coupon.prevent_deactivation?(coupon, params)).to be true
      end

      it "returns false if the coupon is not on any pending invoices" do
        coupon = create(:coupon, active: true)
        customer = create(:customer)
        create(:invoice, merchant: coupon.merchant, customer: customer, coupon: coupon, status: "shipped")

        params = { active: false }

        expect(Coupon.prevent_deactivation?(coupon, params)).to be false
      end
    end
  end
end
