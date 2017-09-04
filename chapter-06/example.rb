x = 5
def triple(arg)
  arg = arg * 3
  puts "arg in triple: #{arg}"
end
triple x
puts "x after triple #{x}"
# arg in triple: 15
# x after triple 5

class Ledger
  attr_reader :balance
  def initialize(balance)
    @balance = balance
  end
  def add(arg)
    @balance += arg
  end
end

class Product
  def self.add_price_by_updating(ledger, price)
    ledger.add(price) # 渡されたledger のadd メッセージを使ってbalance を更新
    puts "ledger in add_price_by_updating: #{ledger.balance}"
  end

  def self.add_price_by_replacing(ledger, price)
    # ここで新たに Ledger のインスタンスを作成する
    # 引数で渡されたledger とは別
    ledger = Ledger.new(ledger.balance + price)
    puts "ledger in add_price_by_replacing: #{ledger.balance}"
  end
end

l1 = Ledger.new(0)
Product.add_price_by_updating(l1, 5)
puts "l1 after add_price_by_updating: #{l1.balance}"
# ledger in add_price_by_updating: 5
# l1 after add_price_by_updating: 5

l2 = Ledger.new(0)
Product.add_price_by_replacing(l2, 5) # l2 は渡された先でコピーされるので balance は変わらない
puts "l2 after add_price_by_replacing: #{l2.balance}"
# ledger in add_price_by_replacing: 5
# l2 after add_price_by_replacing: 0


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

require 'pp'
## Replace Loop with Collection Closure Method
class Employee
  attr_reader :manager
  attr_accessor :office
  attr_reader :salary

  def initialize(is_manager=false, office="Default Office")
    @manager = is_manager
    @office = office
    @salary = (100000..1000000).to_a.sample
  end

  def manager?
    manager
  end
end

employees = []
5.times { employees.push(Employee.new(false)) }
5.times { employees.push(Employee.new(true)) }
p employees.select { |e| e.manager? }
# [#<Employee:0x005602b9558f40 @manager=true>, #<Employee:0x005602b9558f18 @manager=true>, #<Employee:0x005602b9558ec8 @manager=true>, #<Employee:0x005602b9558ea0 @manager=true>, #<Employee:0x005602b9558e78 @manager=true>]

# offices = []
# employees.each { |e| offices << e.office }
employees.each { |e| e.office = "Office " + ("A".."Z").to_a.sample }
pp employees.collect { |e| e.office }
# ["Office O",
#  "Office H",
#  "Office M",
#  "Office C",
#  "Office X",
#  "Office U",
#  "Office P",
#  "Office P",
#  "Office J",
#  "Office W"]

pp employees.select(&:manager?).collect(&:office)
p employees.inject(0) { |sum, e| sum + e.salary }
# p employees.reduce(0) { |sum, e| sum + e.salary }

## Extract Surrounding Method
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
  def self.hash_initializer(*attribute_names)
    define_method(:initialize) do |*args|
      data = args.first || {}
      attribute_names.each do |attribute_name|
        instance_variable_set "@#{attribute_name}", data[attribute_name]
      end
    end
  end

  hash_initializer :author_id, :publisher_id, :isbn
end

p search_criteria = SearchCriteria.new(publisher_id: 2, author_id: 1)

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

Class.send(:include, CustomInitializers)

class SearchCriteria
  hash_initializer :author_id, :publisher_id, :isbn
end

puts "Include CustomInitializers"
p search_criteria = SearchCriteria.new(publisher_id: 2, author_id: 1)

## Dynamic Method Definition
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

p post = Post.new
p post.failure
p post.error
p post.success
# #<Post:0x007fe69c0479e8>
# :failure
# :error
# :success

# p post.done # => undefined method `done

# 後から追加
p Post.states(:done)
p post.done
# [:done]
# :done

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
p post_data.params
p post_data.session


class People
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

p people = People.new
p people.empty_name?
p people.empty_age?
