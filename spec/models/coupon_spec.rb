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
end
