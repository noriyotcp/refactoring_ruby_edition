# Chapter 11: Dealing with Generalization

## Pull Up Method
class Customer
  # method ってかattributeにする？
  def last_bill_date
  end

  def add_bill(date, amount)
    # ...
  end

  def charge_for(start_date, end_date)
    # This should be overridden in Subclass
  end

  def create_bill(date)
    charge_amount = charge_for(last_bill_date, date)
    add_bill(date, charge_amount)
  end
end

class RegularCustomer < Customer
  def charge_for(start_date, end_date)
    # ...
  end
end

class PreferredCustomer < Customer
  def charge_for(start_date, end_date)
    # ...
  end
end

## Push Down Method
class Employee
end

class Salesman < Employee
  def quota
    # ...
  end
end

class Engineer < Employee

end

## Extract Module
class Bid
  # ...
  include AccountNumberCapture
end

module AccountNumberCapture
  def self.included(klass)
    klass.class_eval do
      before_save :capture_account_number
    end
  end

  def capture_account_number
    self.account_number = buyer.preferred_account_number
  end
end

### Example
class Bid
  # ...
  include AccountNumberCapture
end

class Sale
  # ...
  include AccountNumberCapture
end

module AccountNumberCapture
  def self.included(klass)
    klass.class_eval do
      before_save :capture_account_number
    end
  end

  def capture_account_number
    self.account_number = buyer.preferred_account_number
  end
end

## Inline Module
# No code

## Extract Subclass
class JobItem
  attr_reader :quantity, :unit_price

  def initialize(unit_price, quantity)
    @unit_price = unit_price
    @quantity = quantity
  end

  def total_price
    unit_price * @quantity
  end

  protected

  def labor?
    false
  end
end

class Employee
  # ...
  attr_reader :rate

  def initialize(rate)
    @rate = rate
  end
end

class LaborItem < JobItem
  attr_reader :employee

  def initialize(quantity, employee)
    super(0, quantity)
    @employee = employee
  end

  def unit_price
    @employee.rate
  end

  protected

  def labor?
    true
  end
end

## Introduce Inheritance
class MountainBike
  TIRE_WIDTH_FACTOR = 6

  attr_accessor :tire_diameter

  def wheel_circumference
    Math::PI * (@wheel_diameter + @tire_diameter)
  end

  def off_road_ability
    @tire_diameter * TIRE_WIDTH_FACTOR
  end
end

class FrontSuspensionMountainBike < MountainBike
  FRONT_SUSPENSION_FACTOR = 8

  attr_accessor :front_fork_travel

  def off_road_ability
    super + @front_fork_travel * FRONT_SUSPENSION_FACTOR
  end
end

## Collapse Heirarchy
# No code

## Form Template Method

### Example 1: Template Method Using Inheritance
class Customer
  def statement
    TextStatement.value(self)
  end

  def html_statement
    HtmlStatement.value(self)
  end
end

class Statement
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      result << each_rental_string(rental)
    end
    result << footer_string(customer)
  end
end

class TextStatement < Statement
  def header_string(customer)
    "Rental Record for #{customer.name}\n"
  end

  def each_rental_string(rental)
    "\t#{rental.movie.title}\t#{rental.charge}\n"
  end

  def footer_string(customer)
    <<-EOS
      Amount owed is #{customer.total_charge}
      You earned #{customer.total_frequent_renter_points} frequent renter points
    EOS
  end
end

class HtmlStatement < Statement
  def header_string(customer)
    "<H1>Rentals for <EM>#{customer.name}</EM></H1><P>\n"
  end

  def each_rental_string(rental)
    "#{rental.movie.title}: \t#{rental.charge}<BR/>\n"
  end

  def footer_string(customer)
    <<-EOS
      <P>You owe <EM>#{customer.total_charge}</EM></P>
      On this rental you earned <EM>#{customer.total_frequent_renter_points}</EM> frequent renter points</P>
    EOS
  end
end

### Example 2: Template Method Using Extension of Modules
class Customer
  def statement
    Statement.new.extend(TextStatement).value(self)
  end

  def html_statement
    Statement.new.extend(HtmlStatement).value(self)
  end
end

class Statement
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      # show figures for this rental
      result << each_rental_string(rental)
    end
    # add footer lines
    result << footer_string(customer)
  end
end

module TextStatement
  def header_string(customer)
    "Rental Record for #{customer.name}\n"
  end

  def each_rental_string(rental)
    "\t#{rental.movie.title}\t#{rental.charge}\n"
  end

  def footer_string(customer)
    <<-EOS
      Amount owed is #{customer.total_charge}
      You earned #{customer.total_frequent_renter_points} frequent renter points
    EOS
  end
end

module HtmlStatement
  def header_string(customer)
    "<H1>Rentals for <EM>#{customer.name}</EM></H1><P>\n"
  end

  def each_rental_string(rental)
    "#{rental.movie.title}: \t#{rental.charge}<BR/>\n"
  end

  def footer_string(customer)
    <<-EOS
      <P>You owe <EM>#{customer.total_charge}</EM></P>
      On this rental you earned <EM>#{customer.total_frequent_renter_points}</EM> frequent renter points</P>
    EOS
  end
end

## Replace Inheritance with Delegation
require 'forwardable'

class Policy
  attr_reader :name

  extend Forwardable

  def_delegators :@rules, :size, :empty?, :[]

  def initialize(name)
    @name = name
    @rules = {}
  end

  def <<(rule)
    key = rule.attribute.to_sym
    @rules[key] ||= []
    @rules[key] << rule
  end

  def apply(account)
    @rules.each do |attribute, rules|
      rules.each { |rule| rule.apply(account) }
    end
  end
end

class Rule
  # ...
  attr_reader :attribute, :default_value

  def initialize(attribute, default_value)
    @attribute, @default_value = attribute, default_value
  end

  def apply(account)
    #...
  end
end

## Replace Delegation with Hierarchy
### Example
class Employee
  include Person

  def initialize
    @person = self
  end

  def to_s
   "Emp: #{last_name}"
  end
end

module Person
  attr_accessor :name

  def last_name
    @name.split(' ').last
  end
end

## Replace Abstract Superclass with Module
### Example
class LeftOuterJoin
  include Join

  def join_type
    "LEFT OUTER"
  end
end

class InnerJoin
  include Join

  def join_type
    "INNER"
  end
end

# They can be used like so:
InnerJoin.new(
  :equipment_listings,
  :on => "equipment_listings.listing_id =listings.id"
).to_sql

# And we have a class method for returning all joins for a given table:
InnerJoin.joins_for_table(:books)

# Super class
module Join
  # ...
  def self.included(klass)
    klass.class_eval do
      def self.joins_for_table(table_name)
        table_name.to_s
      end
    end
  end

  def initialize(table, options)
    @table = table
    @on = options[:on]
  end

  def to_sql
    "#{join_type} JOIN #{@table} ON #{@on}"
  end
end
