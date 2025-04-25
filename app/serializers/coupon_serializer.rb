class CouponSerializer
  include JSONAPI::Serializer
  attributes :name, :code, :value, :value_type, :active

  attribute :times_used do |coupon|
    coupon.invoices.count
  end
end