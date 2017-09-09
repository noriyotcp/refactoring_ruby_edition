# Chapter 9: Simplifying Conditional Expressions

## Decompose Conditional

条件からメソッドを切り離す

```ruby
if date < SUMMER_START || data > SUMMER_END
  charge = quantity * @winter_rate + @winter_service_charge
else
  charge = quantity * @summer_rate
end
```

-----

```ruby
if not_summer(date)
  charge = winter_charge(quantity)
else
  charge = summer_charge(quantity)
end
```

### Example

```ruby
if date < SUMMER_START || date > SUMMER_END
  charge = quantity * @winter_rate + @winter_service_charge
else
  charge = quantity * @summer_rate
end
```

-----

```ruby
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
```

## Recompose Conditional

```ruby
paramters = params ? params : []

paramters = params || []
```

### Example: Replace Conditional with Explicit Return

```ruby
def reward_points
  if days_rented > 2
    2
  else
    1
  end
end
```

-----

明示的にreturn を使って早期リターンする

```ruby
def reward_points
  return 2 if days_rented > 2
  1
end
```

## Consolidate Conditional Expression

同じ結果を返す条件分岐の連続がある

それらを１つの表現にまとめて切り出す

```ruby
def diability_amount
  return 0 if @seniority < 2
  return 0 if @months_disabled > 12
  return 0 if @is_part_time
  # compute the diability amount
end
```

-----

```ruby
def diability_amount
  return 0 if ineligable_for_diability?
  # compute the diability amount
end
```

### Example: Ors

``or`` で繋げてる

```ruby
def disability_amount
  return 0 if @seniority < 2 || @months_disabled > 12 || @is_part_time
  # compute the disability amount
end
```

-----

条件式の部分を別メソッドに切り出す

```ruby
def disability_amount
  return 0 if ineligable_for_diability?
  # compute the disability amount
end

def ineligable_for_diability?
  @seniority < 2 || @months_disabled > 12 || @is_part_time
end
```

### Example: Ands

```ruby
if on_vacation? && length_of_service > 10
  return 1
end
0.5
```

-----

```ruby
return 1 if on_vacation? && length_of_service > 10
0.5
```

## Consolidate Duplicate Conditional Fragments

```ruby
if special_deal?
  total = price * 0.95
  send_order
else
  total = price * 0.98
  send_order
end
```

-----

```ruby
if special_deal?
  total = price * 0.95
else
  total = price * 0.98
end
send_order
```

## Remove Control Flag

真偽値を格納する変数を制御フラグとして利用したりするが、それを break or return に変える

```ruby
done = false

until done do
  if (condition)
    # do something
    done = true
  end
  value -= 1
end
```

このような制御フラグはトラブルが多い

### Simple Control Flag Replaced with Break

```ruby
def check_security(people)
  found = false
  people.each do |person|
    unless found
      if person == "Don"
        send_alert
        found = true
      end
      
      if person == "John"
        send_alert
        found = true
      end
    end
  end
end
```

-----

``break`` を使ってイテレーションから抜ける

```ruby
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
```

### Example: Using Return with a Control Flag Result

```ruby
def check_security(people)
  found = ""
  people.each do |person|
    if found == ""
      if person == "Don"
        send_alert
        found = "Don"
      end

      if person == "John"
        send_alert
        found = "John"
      end
    end
  end
  some_later_code(found)
end
```

found は真偽値ではないが、制御フラグと結果（文字列）を格納する二つの役割を果たしている

found を返すためのメソッドに切り出す

```ruby
def check_security(people)
  found = found_miscreant(people)
  some_later_code(found)
end

def found_miscreant(people)
  found = ""
  people.each do |person|
    if found == ""
      if person == "Don"
        send_alert
        found = "Don"
      end

      if person == "John"
        send_alert
        found = "John"
      end
    end
  end
  found
end
```

そこからさらに制御フラグをreturn に置き換える

```ruby
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
```

## Replace Nested Conditional with Guard Clauses

```ruby
def pay_amount
  if @dead
    result = dead_amount
  else
    if @separated
      result = separated_amount
    else
      if @retired
        result = retired_amount
      else
        result = normal_pay_amount
      end
    end
  end
  result
end
```

-----

早期リターンを使用してネストされた条件式をスッキリさせる

```ruby
def pay_amount
  return dead_amount if @dead
  return separated_amount if @separated
  return retired_amount if @retired
  normal_pay_amount
end
```

### Example: Reversing the Conditions

```ruby
def adjusted_capital
  result = 0.0
  if @capital > 0.0
    if @interest_rate > 0.0 && @duration > 0.0
      result = (@income / @duration) * ADJ_FACTOR
    end
  end
  result
end
```

２箇所条件式を逆にして早期リターン

```ruby
def adjusted_capital
  result = 0.0
  return result if @capital <= 0.0
  return result if @interest_rate <= 0.0 || @duration <= 0.0
  # return result if !(@interest_rate > 0.0 && @duration > 0.0)
  result = (@income / @duration) * ADJ_FACTOR
  result
end
```

一時変数(result)を削除

```ruby
def adjusted_capital
  return 0.0 if @capital <= 0.0
  return 0.0 if @interest_rate <= 0.0 || @duration <= 0.0
  (@income / @duration) * ADJ_FACTOR
end
```

## Replace Conditional with Polymorphism

条件式の最後の部分をポリモーフィックメソッドに置き換えていく

MountainBike module をそれぞれのクラスでインクルードしているだけ  
条件分岐を MountainBike 側で行なっている

```ruby
module MountainBike
  def price
    case @type_code
      when :rigid
        (1 + @commission) * @base_price
      when :front_suspension
        (1 + @commission) * @base_price + @front_suspension_price
      when :full_suspension
        (1 + @commission) * @base_price + @front_suspension_price +
        @rear_suspension_price
    end
  end
end

class RigidMountainBike
  include MountainBike
end

class FrontSuspensionMountainBike
  include MountainBike
end

class FullSuspensionMountainBike
  include MountainBike
end
```

-----

各クラスでprice メソッドを実装

```ruby
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
```

## Introduce Null Object

nil チェックを繰り返している部分がある。nil をnull object に置き換える

```ruby
class Site
  attr_reader :customer
end

class Customer
  attr_reader :name, :plan, :history
end

class PaymentHistory
  def weeks_delinquent_in_last_year
end
```

サイトは顧客を持っているが、時々サイトが顧客を持っていない時がある  
誰がが出て行ったり、逆に誰が入ってきたかわからない  
顧客がnil を扱えるようにする必要がある

```ruby
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
```


## Introduce Assertion
別にunit test とかを使うわけではないらしい。モジュールを作成

```ruby
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
```
