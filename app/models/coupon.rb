class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :value, presence: true
  validates :value_type, inclusion: { in: %w[dollar percent] }
  validates :active, inclusion: { in: [true, false] }

  def self.for_merchant_by_status(merchant_id, status)
    return none unless %w[true false].include?(status)

    where(merchant_id: merchant_id, active: status == "true")
  end

  def self.exceeds_active_limit?(merchant, params = {})
  activating = params[:active] == true || params[:active] == "true"
  activating && merchant.coupons.where(active: true).count >= 5
  end

  def self.prevent_deactivation?(coupon, params = {})
  deactivating = params[:active] == false || params[:active] == "false"
  deactivating && coupon.invoices.where(status: "pending").any?
  end

  def times_used
    invoices.count 
  end

end
