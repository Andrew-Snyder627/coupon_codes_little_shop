class Api::V1::MerchantCoupons::CouponsController < ApplicationController
  def index
    merchant = Merchant.find(params[:merchant_id])
    coupons = merchant.coupons
    render json: CouponSerializer.new(coupons)
  end

  def show
    coupon = Merchant.find(params[:merchant_id]).coupons.find(params[:id])
    render json: CouponSerializer.new(coupon)
  end

  def create
    merchant = Merchant.find(params[:merchant_id])
    coupons = merchant.coupons.new(coupon_params)

    if Coupon.exceeds_active_limit?(merchant) && coupon.active?
      raise ActiveRecord::RecordInvalid.new(coupon), "This Merchant already has 5 active coupons"
    end

    coupon.save!
    render json: CouponSerializer.new(coupon), status: :created
  end

  def update

  end

  private

end