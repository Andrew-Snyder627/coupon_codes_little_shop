class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :value, presence: true
  validates :value_type, inclusion: { in: %w[dollar percent] }
  validates :active, inclusion: { in: [true, false] }

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
