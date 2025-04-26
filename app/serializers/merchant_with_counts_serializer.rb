class MerchantWithCountsSerializer
  include JSONAPI::Serializer
  attributes :name, :coupons_count, :invoice_coupon_count
end