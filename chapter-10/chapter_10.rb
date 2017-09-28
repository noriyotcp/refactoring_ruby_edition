# Chapter 10: Making Method Calls Simpler

## Rename Method
class Person
  def telephone_number
    office_telephone_number
  end

  def office_telephone_number
    "(#{@officeAreaCode}) #{@officeNumber}"
  end
end

## Add Parameter
# No code

## Remove Parameter
# No code

## Separate Query from Modifier
def found_person(people)
  people.each do |person|
    return "Don" if person == "Don"
    return "John" if person == "John"
  end
  ""
end

def send_alert_if_miscreant_in(people)
  send_alert unless found_person(people).empty?
end

def check_security(people)
  found_miscreant(people)
  found = found_person(people)
  some_later_code(found)
end

## Parameterize Method
class Employee
  def raise(factor)
    @salary *= (1 + factor)
  end
end

def base_charge
  result = (usage_in_range(0..100)) * 0.03
  result += (usage_in_range(100..200)) * 0.05
  result += (usage_in_range(200..last_usage)) * 0.07
  Dollar.new(result)
end

def last_usage
  # ...
end

def usage_in_range(range)
  if last_usage > range.begin
    [last_usage, range.end].min - range.begin
  else
    0
  end
end


## Replace Parameter with Explicit Methods
def height=(value)
  @height = value
end

def name=(value)
  @width = value
end

### Example
def self.create_engineer
  Engineer.new
end

def self.create_salesperson
  Salesperson.new
end

def self.create_manager
  Manager.new
end

kent = Employee.create_engineer

## Preserve Whole Object
plan.within_range?(days_temperature_range)

class Room
  # ...
  def within_plan?(plan)
    plan.within_temperature_range?(days_temperature_range)
  end
end

class HeatingPlan
  # ...
  def within_temperature_range?(room_temperature_range)
    @range.includes?(room_temperature_range)
  end
end

class TempRange
  def includes?(temperature_range)
    temperature_range.low >= low && temperature_range.high <= high
  end
end

## Replace Parameter with Method
base_price = @quantity * @item_price
final_price = discounted_price(base_price)

### Example
def base_price
  @quantity * @item_price
end

def price
  return base_price * 0.1 if discount_level == 2
  base_price * 0.05
end

def discount_level
  return 2 if @quantity > 100
  return 1
end

## Introduce Parameter Object
class Account
  def add_charge(charge)
    @charges << charge
  end

  def total_charge
    @charges.inject(0) { |total_for_account, charge| total_for_account + charge.total }
  end
end

class Charge
  attr_accessor :base_price, :tax_rate, :imported

  def initialize(base_price, tax_rate, imported)
    @base_price = base_price
    @tax_rate = tax_rate
    @imported = imported
  end

  def total
    result = base_price + base_price * tax_rate
    result += base_price * 0.1 if imported
    result
  end
end

# client code
account.add_charge(Charge.new(9.0, 0.1, true))
account.add_charge(Charge.new(12.0, 0.125, false))
# ...
total = account.total_charge

## Remove Setting Method
class Account
  def initialize(id)
    initialize_id(id)
  end

  def initialize_id(value)
    @id = "ZZ#{value}"
  end
end


## Hide Method
# No code
# A method is not used by any other class. Make the method private.

## Replace Constructor with Factory Method
class ProductController
  def create
    # ...
    @product = Product.create(base_price, imported)
    #...
  end
end

class Product
  def self.create(base_price, imported=false)
    if imported
      ImportedProduct.new(base_price)
    else
      if base_price > 1000
        LuxuryProduct.new(base_price)
      else
        Product.new(base_price)
      end
    end
  end
end

### Example
class ProductController
  def create
    # ...
    @product = Product.create(base_price, imported)
    #...
  end
end

class Product
  def total_price
    @base_price
  end

  def self.create(base_price, imported=false)
    if imported
      ImportedProduct.new(base_price)
    else
      if base_price > 1000
        LuxuryProduct.new(base_price)
      else
        Product.new(base_price)
      end
    end
  end
end

class LuxuryProduct < Product
  def total_price
    super + 0.1 * super
  end
end

class ImportedProduct < Product
  def total_price
    super + 0.25 * super
  end
end

## Replace Error Code with Exception
def withdraw(amount)
  raise BalanceError.new if amount > @balance
  @balance -= amount
end

### Example
### Example: Caller Checks Condition Before Calling
class Account
  include Assertions

  def withdraw(amount)
    assert("amount too large") { amount <= @balance }
    @balance -= amount
  end
end

module Assertions
  class AssertionFailedError < StandardError; end

  def assert(message, &condition)
    unless condition.call
      raise AssertionFailedError.new("Assertion Failed: #{message}")
    end
  end
end

if !account.can_withdraw?
  handle_overdrawn
else
  do_the_usual_thing
end

### Example: Caller Catches Exception
class BalanceError < StandardError ; end

# caller
begin
  account.withdraw(amount)
  do_the_usual_thing
rescue BalanceError
  handle_overdrawn
end

def withdraw(amount)
  raise BalanceError.new if amount > @balance
  @balance -= amount
end

# If there are a lot of callers...use a temporary intermediate method
class Account
  def withdraw(amount)
    raise BalanceError.new if amount > @balance
    @balance -= amount
  end
end

begin
  account.withdraw(amount)
  do_the_usual_thing
rescue BalanceError
  handle_overdrawn
end

## Replace Exception with Test
def execute(command)
  command.prepare if command.respond_to? :prepare
  command.execute
end

### Example
class ResourceStack
  def pop
    #...
    #raises EmptyStackError if the stack is empty
  end
end

class ResourcePool
  def initialize
    @available = ResourceStack.new
    @allocated = ResourceStack.new
  end

  def resource
    begin
      result = @available.pop
      @allocated.push(result)
      return result
    rescue EmptyStackError
      result = Resource.new
      @allocated.push(result)
      return result
    end
  end
end

## Introduce Gateway
class Person
  attr_accessor :first_name, :last_name, :ssn

  def save
    PostGateway.save do |persist|
      persist.subject = self
      persist.attributes = [:first_name, :last_name, :ssn]
      persist.to = 'http://www.example.com/person'
    end
  end
end

class Company
  attr_accessor :name, :tax_id

  def save
    GetGateway.save do |persist|
      persist.subject = self
      persist.attributes = [:name, :tax_id]
      persist.to = 'http://www.example.com/companies'
    end
  end
end

class Laptop
  attr_accessor :assigned_to, :serial_number

  def save
    PostGateway.save do |persist|
      persist.subject = self
      persist.attributes = [:assigned_to, :serial_number]
      persist.authenticate = true
      persist.to = 'http://www.example.com/issued_laptop'
    end
  end
end

class Gateway
  attr_accessor :subject, :attributes, :to, :authenticate

  def self.save
    gateway = self.new
    yield gateway
    gateway.execute
  end

  def execute
    request = build_request(url)
    request.basic_auth 'username', 'password' if authenticate
    Net::HTTP.new(url.host, url,port).start do |http|
      http.request(request)
    end
  end

  def url
    URI.parse(to)
  end
end

class PostGateway < Gateway
  def build_request
    request = Net::HTTP::Post.new(url.path)
    attribute_hash = attributes.inject({}) do |result, attribute|
      result[attribute.to_s] = subject.send attribute
      result
    end
    request.set_form_data(attribute_hash)
  end
end

class GetGateway < Gateway
  def build_request
    parameters = attributes.collect do |attribute|
      "#{attribute}=#{subject.send(attribute)}"
    end
    Net::HTTP::Get.new("#{url.path}?#{parameters.join("&")}")
  end
end


## Introduce Expression Builder
class Person
  attr_accessor :first_name, :last_name, :ssn

  def save
    http.post(:first, :last_name, :ssn).to(
      'http://www.example.com/person'
    )
  end

  private

  def http
    GatewayExpressionBuilder.new(self)
  end
end

class GatewayExpressionBuilder
  def initialize(subject)
    @subject = subject
  end

  def post(attributes)
    @attributes = attributes
    @gateway = PostGateway
  end

  def get(attributes)
    @attributes = attributes
    @gateway = GetGateway
  end

  def with_authentication
    @with_authentication = true
  end

  def to(address)
    @gateway.save do |persist|
      persist.subject = @subject
      persist.attributes = @attributes
      persist.authenticate = @with_authentication
      persist.to = address
    end
  end
end

class Company < DomainObject
  attr_accessor :name, :tax_id

  def save
    http.get(:name, :tax_id).to('http://www.example.com/companies')
  end
end

class DomainObject
  def http
    GatewayExpressionBuilder.new(self)
  end
end

class Laptop < DomainObject
  attr_accessor :assigned_to, :serial_number

  def save
    http.post(:assigned_to, :serial_number).with_authentication.to(
      'http://www.example.com/issued_laptop'
    )
  end
end

