# Chapter 8: Organizing Data

## Self Encapsulate Field

getter, setter を作成して、フィールドへのアクセスにはそれらを使用する

```ruby
def total
  @base_price * (1 + @tax_rate)
end

# using attr_reader
attr_reader :base_price, :tax_rate

def total
  base_price * (1 + tax_rate)
end
```

### Example

```ruby
class Item
  def initialize(base_price, tax_rate)
    @base_price = base_price
    @tax_rate = tax_rate
  end

  def raise_base_price_by(percent)
    @base_price = @base_price * (1 + percent / 100.0)
  end

  def total
    @base_price * (1 + @tax_rate)
  end
end
```

-----

```ruby
class Item
  attr_reader :base_price, :tax_rate

  def raise_base_price_by(percent)
    base_price = base_price * (1 + percent / 100.0)
  end

  def total
    base_price * (1 + tax_rate)
  end
end
```

setter をコンストラクタ内で使用する際には注意を払わなくてはいけない

オブジェクトが生成された後にsetter を使用すると、初期化の際とは違う、意図しない振る舞いをする恐れがある

```ruby
class Item
  # 初期化の部分をsetup メソッドに切り出す
  def initialize(base_price, tax_rate)
    setup(base_price, tax_rate)
  end

  def setup(base_price, tax_rate)
    @base_price = base_price
    @tax_rate = tax_rate
  end
  # ...
```

```ruby
class ImportedItem < Item
  attr_reader :import_duty

  def initialize(base_price, tax_rate, import_duty)
    super(base_price, tax_rate) # super を呼んで初期化
    @import_duty = import_duty
  end

  def tax_rate
    super + import_duty # 継承元のtax_rateを上書き
  end
end
```

## Replace Data Value with Object

data item をオブジェクトにする

```ruby
class Order
  # ...
  attr_accessor :customer
  def initialize(customer)
    @customer = customer
  end
end

# Some client code that uses this looks like:
# これは別のクライアントからの使用例？かな
private
  def self.number_of_orders_for(orders, customer)
    # order.customer にアクセスしている
    orders.select { |order| order.customer == customer }.size
  end
```

-----

```ruby
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

# Customer class を作成し、name という属性を持たせる
class Customer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end
```

## Change Value to Reference

オブジェクトを参照用にする

```ruby
class Customer
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

# It is used by an Order class:
class Order
  # ...
  def initialize(customer_name)
    @customer = Customer.new(customer_name)
  end

  def customer=(customer_name)
    @customer = Customer.new(customer_name)
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
```

Customer はvalue object である。これを１つの概念的なcustomer に対して複数のオーダーを持たせるようにしたい

それらのオーダーは１つのcustomer object を共有する

コンストラクタをファクトリメソッドで置き換える

```ruby
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
```


## Change Reference to Value

```ruby
class Currency
  attr_reader :code

  def initialize(code)
    @code = code
  end
end
```

-----

```ruby
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
```

## Replace Array with Object

```ruby
row = []
row[0] = "Liverpool"
row[1] = "15"

row = Performance.new
row.name = "Liverpool"
row.wins = "15"
```

-----

```ruby
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
```

## Replace Hash with Object

ライブラリとか作ってる際に古いメソッドをすぐには削除せず、廃止予定ということにしておきたい

その古いメソッドが呼ばれたら、将来のリリースで廃止予定ですよ、というメッセージを出したい

Module classにdeprecate というメソッドを作っておく

```ruby
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
```

```sh
Warning: calling deprecated method
  Foo.foo. This method will be removed in a future release.
in the foo method
```

## Change Unidirectional Association to Bidirectional

pointer は一方通行のリンクなので二方向の参照をしたいのであれば、``back pointer`` というのを使う

```ruby
class Order
  attr_accessor :customer
end
```

```ruby
# Customer にフィールドを追加する
# customer は複数のオーダーを持つことができる、フィールドをコレクションにする

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
```


## Change Bidirectional Association to Unidirectional

不必要な連携をなくす

双方向の連携は便利だが、高くつく。ゾンビを作り出してしまう

参照が不明瞭なために死ぬべきオブジェクトが宙ぶらりんの状態になる

```ruby
class Order
  attr_reader :customer

  def customer=(value)
    # friend_orders で返ってくるのはSet なのでsubtract method が使える
    customer.friend_orders.subtract(self) unless customer.nil?
    @customer = value
    customer.friend_orders.add(self) unless customer.nil?
  end

  # ...
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
  # ...
end
```

-----

```ruby
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
```

## Replace Magic Number with Symbolic Constant

マジックナンバーを定数に置き換える

```ruby
def potential_energy(mass, height)
  mass * 9.81 * height
end
```

-----

```ruby
GRAVITATIONAL_CONSTANT = 9.81

def potential_energy(mass, height)
  mass * GRAVITATIONAL_CONSTANT * height
end
```

## Encapsulate Collection

collection を返すメソッドと、add/remove メソッドを定義する

Person が複数のコースを持っている

```ruby
class Course
  def initialize(name, advanced)
    @name = name
    @advanced = advanced
  end
end

class Person
  attr_accessor :courses
end
```

-----

```ruby
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

kent = Person.new
kent.add_course(Course.new("Smalltalk Programming", false))
p kent.number_of_courses
p kent.number_of_advanced_courses
```

なんか色々あるけどよくわからん

## Replace Record with Data Class

コード例はない

## Replace Type Code with Polymorphism

```ruby
class MountainBike
  def initialize(params)
    params.each { |key, value| instance_variable_set "@#{key}", value }
  end

  def off_road_ability
    result = @tire_width * TIRE_WIDTH_FACTOR

    if @type_code == :front_suspension || @type_code == :full_suspension
      result += @front_fork_travel * FRONT_SUSPENSION_FACTOR
    end

    if @type_code == :full_suspension
      result += @rear_fork_travel * REAR_SUSPENSION_FACTOR
    end

    result
  end

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

bike = MountainBike.new(:type_code => :rigid, :tire_width => 2.5)
bike2 = MountainBike.new(:type_code => :front_suspension, :tire_width => 2,
:front_fork_travel => 3)
```

``@type_code`` を判別する部分が煩雑になってしまっている

それぞれのタイプのクラスを作成し、MountainBike はモジュールにする

```ruby
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

呼び出し側ではそれらのクラスを作成する形にする

```ruby
bike = RigidMountainBike.new(:type_code => :rigid, :tire_width => 2.5)
bike2 = FrontSuspensionMountainBike.new(:type_code => :front_suspension, :tire_width => 2,
:front_fork_travel => 3)
```

各クラスでprice メソッドをオーバーライドしていく

```ruby
class RigidMountainBike
  include MountainBike

  def price
    (1 + @commission) * @base_price
  end
end
```

MountainBike のほうでは、case の中でraise しておく

```ruby
module MountainBike
  # ...
  def price
    case @type_code
    when :rigid
      raise "shouldn't get here"
    when :front_suspension
      (1 + @commission) * @base_price + @front_suspension_price
    when :full_suspension
      (1 + @commission) * @base_price + @front_suspension_price + @rear_suspension_price
    end
  end
end
```

そして各クラスで price のオーバーライドが完了したら、MountainBike 側のprice は削除する

同様に off_road_ability についてもオーバーライドしていく

```ruby
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

# 初期化の際にtype_code を指定しなくても良い
bike = RigidMountainBike.new(:tire_width => 2.5)
bike2 = FrontSuspensionMountainBike.new(:tire_width => 2,
:front_fork_travel => 3)
```

## Replace Type Code with Module Extension

```ruby
bike = MountainBike.new(:type_code => :rigid)
bike.type_code = :front_suspension

class MountainBike
  attr_writer :type_code

  def initialize(params)
    @type_code = params[:type_code]
    @commission = params[:commission]
    # ...
  end

  def off_road_ability
    result = @tire_width * TIRE_WIDTH_FACTOR

    if @type_code == :front_suspension || @type_code == :full_suspension
      result += @front_fork_travel * FRONT_SUSPENSION_FACTOR
    end

    if @type_code == :full_suspension
      result += @rear_fork_travel * REAR_SUSPENSION_FACTOR
    end

    result
  end

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
```

自己カプセル化フィールドを使用する

```ruby
class MountainBike
  attr_reader :type_code

  def initialize(params)
    @type_code = params[:type_code]
    @commission = params[:commission]
    # ...
  end

  def type_code=(value)
    @type_code = value
  end
  # ...
end

# @type_code -> type_code に置き換える
```

type_code のセッタを最適なモジュールに拡張するために書き換える

```ruby
  def type_code=(value)
    @type_code = value
    case type_code
    when :front_suspension
      extend(FrontSuspensionMountainBike)
    when :full_suspension
      extend(FullSuspensionMountainBike)
    end
  end
```

conditonal な部分をポリモーフィズムで置き換える
モジュール内でprice メソッドをオーバーライド

```ruby
module FrontSuspensionMountainBike
  def price
    (1 + @commission) * @base_price + @front_suspension_price
  end
end

module FullSuspensionMountainBike
  def price
    (1 + @commission) * @base_price + @front_suspension_price +
        @rear_suspension_price
  end
end

# price から条件分岐を取り除ける
class MountainBike
  def price
    (1 + @commission) * @base_price # :rigid
  end
end
```

off_road_ability についても同様に。MountainBike の定数を参照する

```ruby
module FrontSuspensionMountainBike
  # ...
  def off_road_ability
    @tire_width * MountainBike::TIRE_WIDTH_FACTOR +
    @front_fork_travel * MountainBike::FRONT_SUSPENSION_FACTOR
  end
end

module FullSuspensionMountainBike
  # ...
  def off_road_ability
    @tire_width * MountainBike::IRE_WIDTH_FACTOR +
    @front_fork_travel * MountainBike::FRONT_SUSPENSION_FACTOR +
    @rear_fork_travel * MountainBike::REAR_SUSPENSION_FACTOR
  end
end

class MountainBike
  # ...
  def off_road_ability
    @tire_width * TIRE_WIDTH_FACTOR
  end
  # ...
end
```

```ruby
# before
bike = MountainBike.new(:type_code => :rigid)
bike.type_code = :front_suspension

# after
# type_code のセッタはモジュールを受け取ってextendする
class MountainBike
  # initialize から @type_code = params[:type_code] を削除する

  def type_code=(mod)
    extend(mod)
  end
  # ...
end

# 呼び出す際に適切なモジュールをセットする
bike = MountainBike.new
bike.type_code = FrontSuspensionMountainBike
```

## Replace Type Code with State/Strategy

```ruby
class MountainBike
  def initialize(params)
    set_state_from_hash(params)
  end

  def add_front_suspension(params)
    @type_code = :front_suspension
    set_state_from_hash(params)
  end

  def add_rear_suspension(params)
    unless @type_code == :front_suspension
      raise "You can't add rear suspension unless you have front suspension"
    end
    @type_code = :full_suspension
    set_state_from_hash(params)
  end

  def off_road_ability
    result = @tire_width * TIRE_WIDTH_FACTOR
    if @type_code == :front_suspension || @type_code == :full_suspension
      result += @front_fork_travel * FRONT_SUSPENSION_FACTOR
    end
    if @type_code == :full_suspension
      result += @rear_fork_travel * REAR_SUSPENSION_FACTOR
    end
    result
  end

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

  private

  def set_state_from_hash(hash)
    @base_price = hash[:base_price] if hash.has_key?(:base_price)

    if hash.has_key?(:front_suspension_price)
      @front_suspension_price = hash[:front_suspension_price]
    end

    if hash.has_key?(:rear_suspension_price)
      @rear_suspension_price = hash[:rear_suspension_price]
    end

    if hash.has_key?(:commission)
      @commission = hash[:commission]
    end

    if hash.has_key?(:tire_width)
      @tire_width = hash[:tire_width]
    end

    if hash.has_key?(:front_fork_travel)
      @front_fork_travel = hash[:front_fork_travel]
    end

    if hash.has_key?(:rear_fork_travel)
      @rear_fork_travel = hash[:rear_fork_travel]
    end

    @type_code = hash[:type_code] if hash.has_key?(:type_code)
  end
end
```

- まず自己カプセル化フィールドから。attr_reader, custom attribute writer を追加する
- 次に``type_code`` に応じた空のクラスを作成
- type を表すインスタンス変数を作成。新たに作成したクラスのインスタンスをそこにアサインしていく
- ポリモーフィズムで条件分岐を置き換える。インスタンス変数をstate object に渡す
- Forwardable を使用してメソッドを移譲する
- add_front_suspension, add_rear_suspension methods をクラスのインスタンスにtype object をセットするようにする
- price method も同様に
- price method が移動させるべき最後のメソッド。type_code を削除することから始める
- MountainBike の呼び出し側を変える。initialize method からcase 節を取り除く
- 大半のインスタンスのデータをtype object へ直接セットすることにより、MountainBike のインスタンス変数をすべて取り除く
- アップグレードする際にtype object に到達するのでなく、Extract Method を使用してアップグレード可能なパラメータをカプセル化することができる
- Extract Module を使用して、クラス内の重複を取り除く

```ruby
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
```

## Replace Subclass with Fields

サブクラスのメソッドをスーパークラスのフィールドにする

サブクラスのメソッドはハードコードの値しか返してないので

```ruby
class Person
end

class Female < Person
  def female?
    true
  end

  def code
    'F'
  end
end

class Male < Person
  def female?
    false
  end

  def code
    'M'
  end
end
```

- まずファクトリメソッドでコンストラクタを置き換える
- スーパークラスに initialize method を追加し、それぞれのインスタンス変数へアサインする
- サブクラス内でsuper を呼ぶ
- スーパークラスにアクセサを用意し、サブクラスのメソッドを削除
- サブクラスが空になったので、Inline Method を使用してスーパークラス内にサブクラスのコンストラクタを作成

```ruby
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
```

## Lazily Initialized Attribute

コンストラクタではなく、アクセスする際に属性を初期化したい

```ruby
class Employee
  def initialize
    @emails = []
  end
end
```

```ruby
class Employee
  def emails
    @email ||= []
  end
end
```

### Example using ||=

```ruby
class Employee
  attr_reader :emails, :voice_mails

  def initialize
    @emails = []
    @voice_mails = []
  end
end
```

初期化のロジックをゲッタに移して、最初のアクセス時に初期化する

```ruby
class Employee
  def emails
    @emails ||= []
  end

  def voice_mails
    @voice_mails ||= []
  end
end
```

### Example Using instance_variable_defined?

``||=`` はnil or false が返り値として有効な場合は機能しない

```ruby
class Employee
  def initialize
    @assistant = Employee.find_by_boss_id(self.id)
  end
end
```

-----

```ruby
class Employee
  # ...
  def assistant
    # インスタンス変数があるかどうか調べる
    # なければ @assistant にアサインする
    unless instance_variable_defined? :@assistant
      @assistant = Employee.find_by_boss_id(self.id)
    end
    @assistant # 返すのを忘れずに
  end
end
```

## Eagerly Initialized Attribute

今度は逆に、最初のアクセス時ではなく、コンストラクタ内で初期化する

```ruby
class Employee
  def emails
    @emails ||= []
  end
end
```

-----

```ruby
class Employee
  def initialize
    @emails ||= []
  end
end
```

Lazy initialized attributes ではデバッグする際に問題が生じる  
なぜならアクセスの際に値が変わってしまうから

```ruby
class Employee
  def emails
    @emails ||= []
  end

  def voice_mails
    @voice_mails ||= []
  end
end
```

-----

```ruby
class Employee
  attr_reader :emails, :voice_mails

  def initialize(emails, voice_mails)
    @emails = []
    @voice_mails = []
  end
end
```
