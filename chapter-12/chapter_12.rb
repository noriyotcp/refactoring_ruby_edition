### Separate Domain from Presentation
class OrdersController < ApplicationController
  # ...
  def create
    @order_lines = []
    params[:order_line].each_value do |order_line_params|
      unless all_values_blank?(order_line_params)
        amount = Product.find(order_line_params[:product_id]).price
        @order_lines << OrderLine.new(
          order_line_params.merge(:amount =>amount)
        )
      end
    end

    @order = Order.new(params[:order])

    begin
      Order.transaction do
        @order.order_lines = @order_lines
        @order.save!
      end
    rescue ActiveRecord::ActiveRecordError
      @order_lines = [OrderLine.new] * 5 if @order_lines.empty?
      render :action => 'new'
      return
    end
    redirect_to :action => 'index'
  end
end

class Order < ActiveRecord::Base
  MINIMUM_ORDER_AMOUNT = 100

  def validate
    if total < MINIMUM_ORDER_AMOUNT
      errors.add_to_base("An order must be at least $#{MINIMUM_ORDER_AMOUNT}")
    end
  end

  def total
    order_lines.inject(0) do |total, order_line|
      total + (order_line.amount * order_line.quantity)
    end
  end
end
