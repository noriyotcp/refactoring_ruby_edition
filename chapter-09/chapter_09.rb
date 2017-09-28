# Chapter 9: Simplifying Conditional Expressions

## Decompose Conditional
if not_summer(date)
  charge = winter_charge(quantity)
else
  charge = summer_charge(quantity)
end

### Example
if not_summer(date)
  charge = winter_charge(quantity)
else
  charge = summer_charge(quantity)
end

def not_summer(date)
  date < SUMMER_START || date > SUMMER_END
end

def winter_charge(quantity)
  quantity * @winter_rate + @winter_service_charge
end

def summer_charge(quantity)
  quantity * @summer_rate
end

## Recompose Conditional
paramters = params || []

### Example: Replace Conditional with Explicit Return
def reward_points
  return 2 if days_rented > 2
  1
end

## Consolidate Conditional Expression
def diability_amount
  return 0 if ineligable_for_diability?
  # compute the diability amount
end

### Example: Ors
def disability_amount
  return 0 if ineligable_for_diability?
  # compute the disability amount
end

def ineligable_for_diability?
  @seniority < 2 || @months_disabled > 12 || @is_part_time
end

### Example: Ands

return 1 if on_vacation? && length_of_service > 10
0.5

## Consolidate Duplicate Conditional Fragments
if special_deal?
  total = price * 0.95
else
  total = price * 0.98
end
send_order

## Remove Control Flag
# More trouble than they are worth...
done = false # control flag
until done do
  if (condition)
    # do something
    done = true
  end
  value -= 1
end

### Simple Control Flag Replaced with Break
def check_security(people)
  people.each do |person|
    if person == "Don"
      send_alert
      break
    end

    if person == "John"
      send_alert
      break
    end
  end
end

### Example: Using Return with a Control Flag Result
def check_security(people)
  found = found_miscreant(people)
  some_later_code(found)
end

def found_miscreant(people)
  people.each do |person|
    if person == "Don"
      send_alert
      return "Don"
    end

    if person == "John"
      send_alert
      return "John"
    end
  end
end

## Replace Nested Conditional with Guard Clauses
def pay_amount
  return dead_amount if @dead
  return separated_amount if @separated
  return retired_amount if @retired
  normal_pay_amount
end

### Example: Reversing the Conditions
def adjusted_capital
  return 0.0 if @capital <= 0.0
  return 0.0 if @interest_rate <= 0.0 || @duration <= 0.0
  # return 0.0 if !(@interest_rate > 0.0 && @duration > 0.0)
  # Without wrapping @duration with parenthesis, Sublime Text syntax highlighting becomes weird...
  (@income / (@duration)) * ADJ_FACTOR
end

## Replace Conditional with Polymorphism
module MountainBike
end

class RigidMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price
  end
end

class FrontSuspensionMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price + @front_suspension_price
  end
end

class FullSuspensionMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price + @front_suspension_price +
    @rear_suspension_price
  end
end

## Introduce Null Object
# If you like, you can signal the use of a null object by means of a module:
module Nullable
  def missing?
    false
  end
end

class Site
  attr_reader :customer

  def customer
    @customer || Customer.new_missing
  end
end

class Customer
  attr_reader :name, :plan, :history
  def self.new_missing
    MissingCustomer.new
  end

  def missing?
    false
  end
end

class MissingCustomer
  def missing?
    true
  end
end

class NullCustomer
  def name
    'occupant'
  end

  def plan=
  end
end

class PaymentHistory
  def self.new_null
    NullPaymentHistory.new
  end

  def weeks_delinquent_in_last_year
  end
end

class NullPaymentHistory
  def history
    PaymentHistory.new_null
  end
end

customer = site.customer
customer.plan = BillingPlan.special

customer_name = customer.name

weeks_delinquent = customer.history.weeks_delinquent_in_last_year

customer.plan = BillingPlan.special

## Introduce Assertion
module Assertions
  class AssertionFailedError < StandardError
  end

  def assert(&condition)
    raise AssertionFailedError.new("Assertion Failed") unless condition.call
  end
end

# on production
Assertions.class_eval do
  def assert
  end
end
