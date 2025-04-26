class Merchant < ApplicationRecord

  has_many :items, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :coupons, dependent: :destroy
  validates :name, presence: true

  def self.sorted_by_newest
    order(created_at: :desc)
  end

  def self.with_returned_items
    joins(invoices: :transactions)
    .where(transactions: {result: "refunded" })
    .distinct
  end

  def self.with_item_counts
    left_joins(:items)
      .select("merchants.*, COUNT(items.id) AS item_count")
      .group("merchants.id")
      .order(:id)
  end

  def item_count
    self[:item_count] || items.size
  end

  def self.filter_name(name)
    where("LOWER(name) LIKE?", "%#{name.downcase}%").order("LOWER(name) ASC").first
  end

  def self.with_coupon_and_invoice_counts
    left_joins(:coupons, :invoices)
      .select(
        "merchants.*,
        COUNT(DISTINCT coupons.id) AS coupons_count,
        COUNT(DISTINCT CASE WHEN invoices.coupon_id IS NOT NULL THEN invoices.id END) AS invoice_coupon_count"
      )
      .group("merchants.id")
  end

  def coupons_count
    self[:coupons_count] || coupons.size
  end

  def invoice_coupon_count
    self[:invoice_coupon_count] || invoices.where.not(coupon_id: nil).count
  end

end