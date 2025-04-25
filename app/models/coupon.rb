class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :value, presence: true
  validates :value_type, inclusion: { in: %w[dollar percent] }
  validates :active, inclusion: { in: [true, false] }

  def times_used
    invoices.count 
  end

end
