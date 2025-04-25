class Api::V1::CouponsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
  rescue_from ActiveRecord::RecordInvalid, with: :incomplete_response
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :malformed_json_response
  
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
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.find(params[:id])

    if Coupon.prevent_deactivation?(coupon, coupon_params)
      raise ActiveRecord::RecordInvalid.new(coupon), "Coupon cannot be deactivated due to pending invoices"
    end

    if Coupon.exceeds_active_limit?(merchant, coupon_params)
      raise ActiveRecord::RecordInvalid.new(coupon), "This Merchant already has 5 active coupons"
    end

    coupon.update!(coupon_params)
    render json: CouponSerializer.new(coupon)
  end

  private
    def coupon_params
      params.require(:coupon).permit(:name, :code, :value, :value_type, :active)
    end

    def not_found_response(exception)
      render json: ErrorSerializer.serialize(exception), status: :not_found
    end

    def incomplete_response(exception)
      render json: ErrorSerializer.serialize(exception), status: :bad_request
    end

    def malformed_json_response(exception)
      render json: ErrorSerializer.serialize(exception), status: :bad_request
    end
end