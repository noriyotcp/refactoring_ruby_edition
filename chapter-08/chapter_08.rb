# Chapter 8: Organizing Data

## Self Encapsulate Field
attr_reader :base_price, :tax_rate

def total
  base_price * (1 + tax_rate)
end

### Example
class Item
  attr_reader :base_price, :tax_rate

  def raise_base_price_by(percent)
    base_price = base_price * (1 + percent / 100.0)
  end

  def total
    base_price * (1 + tax_rate)
  end
end

class Item
  def initialize(base_price, tax_rate)
    setup(base_price, tax_rate)
  end

  def setup(base_price, tax_rate)
    @base_price = base_price
    @tax_rate = tax_rate
  end
  # ...
end

class ImportedItem < Item
  attr_reader :import_duty

  def initialize(base_price, tax_rate, import_duty)
    super(base_price, tax_rate)
    @import_duty = import_duty
  end

  def tax_rate
    super + import_duty
  end
end

## Replace Data Value with Object
class Order
  # ...
  def initialize(customer_name)
    @customer = Customer.new(customer_name)
  end

  def customer_name
    @customer.name
  end

  def customer=(customer_name)
    @customer = Customer.new(customer_name)
  end
end

class Customer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

# Some client code that uses this looks like:
private
def self.number_of_orders_for(orders, customer)
  orders.select { |order| order.customer == customer }.size
end

## Change Value to Reference
class Customer
  attr_reader :name
  Instances = {}
  # コンストラクタをファクトリメソッドで置き換える
  def self.with_name(name)
    Instances[name]
  end

  def self.load_customers
    new("Lemon Car Hire").store
    new("Associated Coffee Machines").store
    new("Bilston Gasworks").store
  end

  def store
    Instances[name] = self
  end
end

# It is used by an Order class:
class Order
  # ...
  def initialize(customer_name)
    @customer = Customer.with_name(customer_name)
  end

  def customer=(customer_name)
    @customer = Customer.with_name(customer_name)
  end

  def customer_name
    @customer.name
  end
end

# some client code:
private

def self.number_of_orders_for(orders, customer)
  orders.select { |order| order.customer_name == customer.name }.size
end

## Change Reference to Value
class Currency
  attr_reader :code

  def initialize(code)
    @code = code
  end

  def self.get(code)
    # return currency from a registry
  end

  def eql?(other)
    self == (other)
  end

  def ==(other)
    other.equal?(self) ||
      (other.instance_of?(self.class) &&
       other.code == code)
      end

  def hash
    code.hash
  end
end

Currency.send(:new, "USD") == Currency.new("USD") # returns true
Currency.send(:new, "USD").eql?(Currency.new("USD")) # returns true

## Replace Array with Object
class Performance
  attr_accessor :name
  attr_writer :wins

  def wins
    @wins.to_i
  end
end

p row = Performance.new
p row.name = "Liverpool"
p row.wins = "15"

## Replace Hash with Object
class Module
  def deprecate(methodName, &block)
    module_eval <<~END
    alias_method :deprecated_#{methodName}, :#{methodName}
    def #{methodName}(*args, &block)
      $stderr.puts "Warning: calling deprecated method
        #{self}.#{methodName}. This method will be removed in a future release."
      deprecated_#{methodName}(*args, &block)
    end
    END
  end
end

class Foo
  def foo
    puts "in the foo method"
  end

  deprecate :foo
end

Foo.new.foo

## Change Unidirectional Association to Bidirectional

class Order
  attr_reader :customer

  def customer=(value)
    # friend_orders で返ってくるのはSet なのでsubtract method が使える
    customer.friend_orders.subtract(self) unless customer.nil?
    @customer = value
    customer.friend_orders.add(self) unless customer.nil?
  end

  # controlling methods
  def add_customer(customer)
    customer.friend_orders.add(self)
    # どこかで@customers を取得しないといけないか？
    @customers.add(customer)
  end

  def remove_customer(customer)
    customer.friend_orders.subtract(self)
    @customers.subtract(customer)
  end
end

# Set#subtract
# subtract(enum) -> self
# 元の集合から、enum で与えられた要素を削除します。

# 引数 enum には each メソッドが定義されている必要があります。
# https://docs.ruby-lang.org/ja/latest/method/Set/i/subtract.html

require 'set'

class Customer
  def initialize
    @orders = Set.new
  end

  def friend_orders
    @orders
  end

  def add_order(order)
    order.add_customer(self)
  end

  def remove_order(order)
    order.remove_customer(self)
  end
end

## Change Bidirectional Association to Unidirectional
class Order
  attr_reader :customer

  def customer=(value)
    # friend_orders で返ってくるのはSet なのでsubtract method が使える
    customer.friend_orders.subtract(self) unless customer.nil?
    @customer = value
    customer.friend_orders.add(self) unless customer.nil?
  end

  def discounted_price(customer)
    gross_price * (1 - customer.discount)
  end
end

require 'set'

class Customer
  def initialize
    @orders = Set.new
  end

  def friend_orders
    @orders
  end

  def add_order(order)
    order.add_customer(self)
  end

  def price_for(order)
    # なぜにいきなりassert が出てくるのか・・・
    assert { @orders.include?(order) }
    order.discounted_price(self)
  end
end


## Replace Magic Number with Symbolic Constant
GRAVITATIONAL_CONSTANT = 9.81

def potential_energy(mass, height)
  mass * GRAVITATIONAL_CONSTANT * height
end


## Encapsulate Collection
class Course
  def initialize(name, advanced)
    @name = name
    @advanced = advanced
  end

  def advanced?
    @advanced
  end
end

class Person
  # ...
  attr_accessor :courses

  def initialize
    @courses = []
  end

  def add_course(course)
    @courses << course
  end

  def remove_course(course)
    @courses.delete(course)
  end

  def number_of_courses
    @courses.size
  end

  def number_of_advanced_courses
    @courses.select { |course| course.advanced? }.size
  end
end

## Replace Record with Data Class (No code)
## Replace Type Code with Polymorphism
module MountainBike
  def initialize(params)
    params.each { |key, value| instance_variable_set "@#{key}", value }
  end
end

class RigidMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price
  end

  def off_road_ability
    @tire_width * TIRE_WIDTH_FACTOR
  end
end

class FrontSuspensionMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price + @front_suspension_price
  end

  def off_road_ability
    @tire_width * TIRE_WIDTH_FACTOR +
      @front_fork_travel * FRONT_SUSPENSION_FACTOR
  end
end

class FullSuspensionMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price +
      @front_suspension_price + @rear_suspension_price
  end

  def off_road_ability
    @tire_width * TIRE_WIDTH_FACTOR +
      @front_fork_travel * FRONT_SUSPENSION_FACTOR +
      @rear_fork_travel * REAR_SUSPENSION_FACTOR
  end
end

bike = RigidMountainBike.new(:tire_width => 2.5)
bike2 = FrontSuspensionMountainBike.new(:tire_width => 2,
                                        :front_fork_travel => 3)

## Replace Type Code with Module Extension
module FrontSuspensionMountainBike
  def price
    (1 + @commission) * @base_price + @front_suspension_price
  end

  def off_road_ability
    @tire_width * MountainBike::TIRE_WIDTH_FACTOR +
      @front_fork_travel * MountainBike::FRONT_SUSPENSION_FACTOR
  end
end

module FullSuspensionMountainBike
  def price
    (1 + @commission) * @base_price + @front_suspension_price +
      @rear_suspension_price
  end

  def off_road_ability
    @tire_width * MountainBike::IRE_WIDTH_FACTOR +
      @front_fork_travel * MountainBike::FRONT_SUSPENSION_FACTOR +
      @rear_fork_travel * MountainBike::REAR_SUSPENSION_FACTOR
  end
end

class MountainBike
  attr_reader :type_code

  def initialize(params)
    @commission = params[:commission]
    # ...
  end

  def type_code=(mod)
    extend(mod)
  end

  def off_road_ability
    @tire_width * TIRE_WIDTH_FACTOR
  end

  def price
    (1 + @commission) * @base_price # :rigid
  end
end

bike = MountainBike.new
bike.type_code = FrontSuspensionMountainBike

## Replace Type Code with State/Strategy
class MountainBike
  extend Forwardable
  def_delegators :@bike_type, :off_road_ability, :price

  attr_reader :type_code

  def type_code=(value)
    @type_code = value
  end

  def initialize(bike_type)
    @bike_type = bike_type
  end

  def add_front_suspension(params)
    @bike_type = FrontSuspensionMountainBike.new(
      @bike_type.upgradable_parameters.merge(params)
    )
  end

  def add_rear_suspension(params)
    unless @bike_type.is_a?(FrontSuspensionMountainBike)
      raise "You can't add rear suspension unless you have front suspension"
    end
    @bike_type = FullSuspensionMountainBike.new(
      @bike_type.upgradable_parameters.merge(params)
    )
  end
end

class RigidMountainBike
  def initialize(params)
    @tire_width = params[:tire_width]
  end

  def off_road_ability
    @tire_width * MountainBike::TIRE_WIDTH_FACTOR
  end

  def price
    (1 + @commission) * @base_price
  end

  def upgradable_parameters
    {
      tire_width: @tire_width,
      base_price: @base_price,
      commission: @commission
    }
  end
end

class FrontSuspensionMountainBike
  def initialize(params)
    @tire_width = params[:tire_width]
    @front_fork_travel = params[:front_fork_travel]
  end

  def off_road_ability
    @tire_width * MountainBike::TIRE_WIDTH_FACTOR +
    @front_fork_travel * MountainBike::FRONT_SUSPENSION_FACTOR
  end

  def price
    (1 + @commission) * @base_price + @front_suspension_price
  end

  def upgradable_parameters
    {
      tire_width: @tire_width,
      front_fork_travel: @front_fork_travel,
      front_suspension_price: @front_suspension_price,
      base_price: @base_price,
      commission: @commission
    }
  end
end

class FullSuspensionMountainBike
  def initialize(params)
    @tire_width = params[:tire_width]
    @front_fork_travel = params[:front_fork_travel]
    @rear_fork_travel = params[:rear_fork_travel]
  end

  def off_road_ability
    @tire_width * MountainBike::TIRE_WIDTH_FACTOR +
    @front_fork_travel * MountainBike::FRONT_SUSPENSION_FACTOR +
    @rear_fork_travel * MountainBike::REAR_SUSPENSION_FACTOR
  end

  def price
    (1 + @commission) * @base_price + @front_suspension_price + @rear_suspension_price
  end

  def upgradable_parameters
    {
      tire_width: @tire_width,
      front_fork_travel: @front_fork_travel,
      rear_fork_travel: @rear_fork_travel,
      front_suspension_price: @front_suspension_price,
      rear_suspension_price: @rear_suspension_price,
      base_price: @base_price,
      commission: @commission
    }
  end
end

bike = MountainBike.new(FrontSuspensionMountainBike.new(
  tire_width: @tire_width,
  front_fork_travel: @front_fork_travel,
  front_suspension_price: @front_suspension_price,
  base_price: @base_price,
  commission: @commission
))

## Replace Subclass with Fields
class Person
  def initialize(female, code)
    @female = female
    @code = code
  end

  def self.create_female
    Person.new(true, 'F')
  end

  def self.create_male
    Person.new(false, 'M')
  end

  def female?
    @female
  end
end

## Lazily Initialized Attribute
class Employee
  def emails
    @email ||= []
  end
end

### Example using ||=
class Employee
  def emails
    @emails ||= []
  end

  def voice_mails
    @voice_mails ||= []
  end
end

### Example Using instance_variable_defined?
class Employee
  # ...
  def assistant
    # インスタンス変数があるかどうか調べる
    # なければ @assistant にアサインする
    unless instance_variable_defined? :@assistant
      @assistant = Employee.find_by_boss_id(self.id)
    end
    @assistant
  end
end

## Eagerly Initialized Attribute
class Employee
  def initialize
    @emails ||= []
  end
end

### Example
class Employee
  attr_reader :emails, :voice_mails

  def initialize(emails, voice_mails)
    @emails = []
    @voice_mails = []
  end
end
