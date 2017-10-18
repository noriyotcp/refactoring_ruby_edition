# Chapter 6: Composing Methods

## Extract Method
def print_owing(amount)
  print_banner
  print_details(amount)
end

def print_details(amount)
  puts "name: #{@name}"
  puts "amount: #{amount}"
end

### Example: No Local Variables
def print_owing
  outstanding = 0.0

  print_banner

  # calculate outstanding
  @orders.each do |order|
    outstanding += order.amount
  end

  # print details
  puts "name: #{@name}"
  puts "amount: #{outstanding}"
end

def print_banner
  # print banner
  puts "*************************"
  puts "***** Customer Owes *****"
  puts "*************************"
end

### Example: Using Local Variables
def print_owing
  outstanding = 0.0

  print_banner

  # calculate outstanding
  @orders.each do |order|
    outstanding += order.amount
  end

  # print details
  print_details(outstanding)
end

def print_banner
  # print banner
  puts "*************************"
  puts "***** Customer Owes *****"
  puts "*************************"
end

def print_details(outstanding)
  puts "name: #{@name}"
  puts "amount: #{outstanding}"
end

### Example: Reassigning a Local Variables
def print_owing
  print_banner

  outstanding = calculate_outstanding
  # print details
  print_details(outstanding)
end

def print_banner
  # print banner
  puts "*************************"
  puts "***** Customer Owes *****"
  puts "*************************"
end

def print_details(outstanding)
  puts "name: #{@name}"
  puts "amount: #{outstanding}"
end

def calculate_outstanding
  outstanding = 0.0
  @orders.each do |order|
    outstanding += order.amount
  end
  outstanding

  # Alternative ways
  # @orders.inject(0.0) { |result, order| result + order.amount }
  # @orders.reduce(0.0) { |result, order| result + order.amount }
end

#### The case of passing an initial value to calculate_outstanding
def print_owing(previous_amount)
  print_banner
  outstanding = calculate_outstanding(previous_amount * 1.2)
  print_details(outstanding)
end

def calculate_outstanding(initial_value)
  @orders.inject(initial_value) { |result, order| result + order.amount }
end

## Inline Method
def get_rating
  @number_of_late_deliveries > 5 ? 2 : 1
end


## Inline Temp
return (an_order.base_price > 100)

## Replace Temp with Query
if base_price > 1000
  base_price * 0.95
else
  base_price * 0.98
end

def base_price
  @quantity * @item_price
end

### Example
def price
  base_price * discount_factor
end

def base_price
  @quantity * @item_price
end

def discount_factor
  base_price > 1000 ? 0.95 : 0.98
end

## Replace Temp with Chain
mock = Mock.new
mock.expects(:a_method_name).with("arguments").returns([1, :array])

### Example
class Select
  def self.with_option(option)
    select = self.new
    select.options << option
    select
  end

  def options
    @options ||= []
  end

  def and(arg)
    options << arg
    self
  end
end

select = Select.with_option(1999).and(2000).and(2001).and(2002)
select # => #<Select:0x28708 @options=[1999, 2000, 2001, 2002]>

## Introduce Explaining Variable
is_mac_os = platform.upcase.index("MAC")
is_ie_browser = browser.upcase.index("IE")
was_resized = resize > 0

if (is_mac_os && is_ie_browser && initialized? && was_resized)
  # do something
end

### Example
def price
  # price is base price - quantity discount + shipping
  base_price = @quantity * @item_price
  quantity_discount = [0, @quantity - 500].max * @item_price * 0.05
  shipping = [base_price * 0.1, 100.0].min
  return base_price - quantity_discount + shipping
end

### Example with Extract Method
def price
  # price is base price - quantity discount + shipping
  base_price - quantity_discount + shipping
end

def base_price
  @quantity * @item_price
end

def quantity_discount
  [0, @quantity - 500].max * @item_price * 0.05
end

def shipping
  [base_price * 0.1, 100.0].min
end

## Split Temporary Variable
### Example
def distance_traveled(time)
  primary_acc = @primary_force / @mass
  primary_time = [time, @delay].min
  result = 0.5 * primary_acc * primary_time * primary_time
  secondary_time = time - @delay
  if(secondary_time > 0)
    primary_vel = primary_acc * @delay
    secondary_acc = (@prmary_force + @secondary_force) / @mass
    result += primary_vel * secondary_time + 5 * secondary_acc * secondary_time *
      secondary_time
  end
  result
end

## Remove Assignments to Parameters
### Example
def discount(input_val, quantity, year_to_date)
  result = input_val # input_val をresultへコピー、そちらの値を変えていく
  result -= 2 if input_val > 50 # if のinput_val は引数として渡された「元々の」input_val
  result -= 1 if quantity > 100
  result -= 4 if year_to_date > 10000
  result
end

## Replace Method with Method Object
### Example
class Account
  attr_reader :delta

  def initialize(delta=1)
    @delta = delta
  end

  def gamma(input_val, quantity, year_to_date)
    Gamma.new(self, input_val, quantity, year_to_date).compute
  end
end

class Gamma
  attr_reader :account,
              :input_val,
              :quantity,
              :year_to_date,
              :important_value1,
              :important_value2,
              :important_value3

  def initialize(account, input_val_arg, quantity_arg, year_to_date_arg)
    @account = account
    @input_val = input_val_arg
    @quantity = quantity_arg
    @year_to_date = year_to_date_arg
  end

  def compute
    @important_value1 = (input_val * quantity) + @account.delta
    @important_value2 = (input_val * year_to_date) + 100
    important_thing
    @important_value3 = important_value2 * 7
    # and so on.
    important_value3 - 2 * important_value1
  end

  def important_thing
    if (year_to_date - important_value1) > 100
      @important_value2 -= 20
    end
  end
end

p Account.new.gamma(1, 2, 3)
p Account.new(100).gamma(1, 2, 3)


## Substitute Algorithm
def found_friends(people)
  people.select { |person| %w(Don John Kent).include?(person) }
end

## Replace Loop with Collection Closure Method
employees.select { |e| e.manager? }

employees.collect { |e| e.office }

p employees.inject(0) { |sum, e| sum + e.salary }
# p employees.reduce(0) { |sum, e| sum + e.salary }

## Extract Surrounding Method
def charge(amount, credit_card_number)
  # connect メソッド内のyield にブロックを渡す
  # yield からのconnection を受け取る
  connect do |connection|
    connection.send(amount, credit_card_number)
  end
end

def connect
  begin
    connection = CreditCardServer.connect("something...")
    # 与えられたブロックに対し、connection を渡して実行
    yield connection
  rescue IOError => e
    Logger.log "Could not submit order #{@order_number} to the server: #{e}"
    return nil
  ensure
    connection.close
  end
end

### Example
class Person
  attr_reader :mother, :children, :name
  def initialize(name, date_of_birth, date_of_death=nil, mother=nil)
    @name, @mother = name, mother
    @date_of_birth, @date_of_death = date_of_birth, date_of_death
    @children = []
    @mother.add_child(self) if @mother
  end

  def add_child(child)
    @children << child
  end

  def number_of_living_descendants
    count_descendants_matching { |descendant| descendant.alive? }
  end

  def number_of_descendants_named(name)
    count_descendants_matching { |descendant| descendant.name == name }
  end

  def alive?
    @date_of_death.nil?
  end

  protected
  def count_descendants_matching(&block)
    children.inject(0) do |count, child|
      count += 1 if yield child
      count + child.count_descendants_matching(&block)
    end
  end
end

## Introduce Class Annotation
class SearchCriteria
  def self.hash_initializer(*attribute_names) # :author_id, :publisher_id, :isbn
    define_method(:initialize) do |*args|
      data = args.first || {}
      attribute_names.each do |attribute_name|
        # ここでシンボルを文字列に展開させ、インスタンス変数をセット
        instance_variable_set "@#{attribute_name}", data[attribute_name]
      end
    end
  end

  hash_initializer :author_id, :publisher_id, :isbn
end

### Extract initializer to a module
# module に切り出す
module CustomInitializers
  def hash_initializer(*attribute_names)
    define_method(:initialize) do |*args|
      data = args.first || {}
      attribute_names.each do |attribute_name|
        instance_variable_set "@#{attribute_name}", data[attribute_name]
      end
    end
  end
end
# ここで全てのクラスに CustomInitializers をインクルード
Class.send(:include, CustomInitializers)
# ここでは Class annotation を宣言するだけで良い
class SearchCriteria

  hash_initializer :author_id, :publisher_id, :isbn
end


## Introduce Named Parameter
### Example 2: Naming Only the Optional Parameters

class Books
  def self.find(selector, hash={})
    hash[:joins] ||= []
    hash[:conditions] ||= ""

    sql = ["SELECT * FROM books"]
    hash[:joins].each do |join_table|
      sql << "LEFT OUTER JOIN #{join_table} ON"
      sql << "books.#{join_table.to_s.chop}_id"
      sql << " = #{join_table}.id"
    end
    sql << "WHERE #{hash[:conditions]}" unless hash[:conditions].empty?
    sql << "LIMIT 1" if selector == :first
    connection.find(sql.join(" "))
  end
end

Books.find(:all)
Books.find(:all, conditions: "title like '%Voodoo Economics'")
Books.find(:all, conditions: "authors.name = 'Jenny James'", joins: [:authors])
Books.find(:first, conditions: "authors.name = 'Jenny James'", joins: [:authors])

#### module for assertion
module AssertValidKeys
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys].flatten # keys はなんぞ？ Hash にインクルードする前提だからいいのか
    if unknown_keys.any?
      raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}")
    end
  end
end
# Hash にインクルードする
Hash.send(:include, AssertValidKeys)

class Books
  def self.find(selector, hash={})
    hash.assert_valid_keys(:conditions, :joins)

    hash[:joins] ||= []
    hash[:conditions] ||= ""

    sql = ["SELECT * FROM books"]
    hash[:joins].each do |join_table|
      sql << "LEFT OUTER JOIN #{join_table} ON"
      sql << "books.#{join_table.to_s.chop}_id"
      sql << " = #{join_table}.id"
    end
    sql << "WHERE #{hash[:conditions]}" unless hash[:conditions].empty?
    sql << "LIMIT 1" if selector == :first
    connection.find(sql.join(" "))
  end
end

## Remove Named Parameter
Books.find # => Books.find(:all)
Books.find(:all,
           :conditions => "authors.name = 'Jenny James'",
           :joins => [:authors])
Books.find(:first,
           :conditions => "authors.name = 'JennyJames'",
           :joins => [:authors])

## Remove Unused Default Parameter

def product_count_items(search_criteria)
  ProductCountItem.find_all_by_criteria(search_criteria)
end

## Dynamic Method Definition

def_each :failure, :error, :success do |method_name|
  self.state = method_name
end

class Class
  def def_each(*method_names, &block)
    method_names.each do |method_name|
      define_method method_name do
        instance_exec method_name, &block
      end
    end
  end
end

### Example: Defining Instance Methods with a Class Annotation

class Post
  attr_writer :state

  def self.states(*args)
    args.each do |arg|
      define_method arg do
        self.state = arg
      end
    end
  end

  states :failure, :error, :success
end

### Example: Defining Methods By Extending a Dynamically Defined Module
class PostData
  def initialize(post_data)
    @post_data = post_data
  end

  def params
    @post_data[:params]
  end

  def session
    @post_data[:session]
  end
end

### Example: Defining Methods By Extending a Dynamically Defined Module
class Hash
  def to_module
    hash = self
    Module.new do
      hash.each_pair do |key, value| # each_pair is an alias for each
        define_method key do
          value
        end
      end
    end
  end
end

class PostData
  def initialize(post_data)
    self.extend post_data.to_module
  end
end

post_data = PostData.new(params: 1, session: 'session')
p post_data.params # => 1
p post_data.session # => 'session'

## Replace Dynamic Receptor with Dynamic Method Definition
### Example: Dynamic Delegation Without method_missing
class Decorator
  def initialize(subject)
    # public_methods(false) sujectのクラスのメソッドのみを返す
    subject.public_methods(false).each do |meth|
      # class_eval ブロックを評価してその結果を返す
      # Decorator class 自身にメソッドを定義
      (class << self; self; end).class_eval do
        define_method meth do |*args|
          subject.send(meth, *args)
        end
      end
    end
  end
end

### Example: Using User-Defined Data to Define Methods
class Person
  def self.attrs_with_empty_predicate(*args)
    attr_accessor(*args)

    args.each do |attribute|
      define_method "empty_#{attribute}?" do
        self.send(attribute).nil?
      end
    end
  end

  attrs_with_empty_predicate :name, :age
end

# p people = People.new
# p people.empty_name? # => true
# p people.empty_age? # => true

## Isolate Dynamic Receptor
class Recorder
  def play_for(obj)
    @message_collector.messages.inject(obj) do |result, message|
      result.send(message.first, *message.last)
    end
  end

  def record
    @message_collector ||= MessageCollecter.new
  end

  def to_s
    @messages_collector.messages.inject([]) do |result, message|
      result << "#{message.first}(arg: #{message.last.inspect})"
    end
  end
end

class CommandCenter
  def start(command_string)
    # ...
    self
  end

  def stop(command_string)
    # ...
    self
  end
end

class MessageCollecter
  instance_methods.each do |meth|
    undef_method meth unless meth =~ /^(__|inspect)/
  end

  def messages
    @messages ||= []
  end

  def method_missing(sym, *args)
    messages << [sym, args] # ex.) [:start, "LRMMMMRL"]
    self
  end
end

recorder = Recorder.new
recorder.record.start("LRMMMMRL") # start がmethod_missing でmessages に一旦格納される？
recorder.record.stop("LRMMMMRL")
recorder.play_for(CommandCenter.new)

## Move Eval from Runtime to Parse Time

class Person
  def self.attr_with_default(options)
    options.each_pair do |attribute, default_value|
      eval "define_method #{attribute} do
        @#{attribute} ||= #{default_value}
      end"
    end
  end
  attr_with_default :emails => "[]",
                    :employee_number =>"EmployeeNumberGenerator.next"
end
