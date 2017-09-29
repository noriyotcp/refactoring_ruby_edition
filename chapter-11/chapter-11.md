# Chapter 11: Dealing with Generalization

## Pull Up Method

サブクラスに同じ結果を返すメソッドがあるなら、スーパークラスへと押し上げる

### Example

```ruby
class Customer
  def last_bill_date
  end

  def add_bill(date, amount)
  end
end

class RegularCustomer < Customer
  def create_bill(date)
    charge_amount = charge_for(last_bill_date, date)
    add_bill(date, charge_amount)
  end

  def charge_for(start_date, end_date)
  end
end

class PreferredCustomer < Customer
  def create_bill(date)
    charge_amount = charge_for(last_bill_date, date)
    add_bill(date, charge_amount)
  end

  def charge_for(start_date, end_date)
  end
end
```

サブクラスのどちらか一方から、`create_bill` を親クラスへとコピーしてくる  
そしてサブクラスから削除してテスト。その後もう一方からも削除

```ruby
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
```

## Push Down Method

スーパークラスでの振る舞いがサブクラスのうちのどれかにおいてのみ、関連している  
その振る舞いをそれらのサブクラスに移動する（押し下げる）

```ruby
class Employee
  def quota
    # ...
  end
end

class Salesman < Employee

end

class Engineer < Employee

end
```

`quota` は`Salesman` class にだけ関連していて、`Engineer` class とは関係ない

```ruby
class Employee
end

class Salesman < Employee
  def quota
    # ...
  end
end

class Engineer < Employee

end
```

`Salesman` class へと押し下げる

## Extract Module

２つ以上のクラスに関して振る舞いが重複している

モジュールを作成し、関連する振る舞いをモジュールへと移動させ、クラスでinclude する

```ruby
class Bid
  # ...
  before_save :capture_account_number

  def capture_account_number
    self.account_number = buyer.preferred_account_number
  end
end
```

```ruby
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
```

### Example

```ruby
class Bid
  # ...
  before_save :capture_account_number

  def capture_account_number
    self.account_number = buyer.preferred_account_number
  end
end

class Sale
  # ...
  before_save :capture_account_number

  def capture_account_number
    self.account_number = buyer.preferred_account_number
  end
end
```

`Bid`, `Sale` が`before_save` に対応してくれることを望む


`AccountNumberCapture` module を作成する

```ruby
module AccountNumberCapture
end
```

`Bid`, `Sale` でそれをinclude する

```ruby
class Bid
  # ...
  include AccountNumberCapture
end

class Sale
  # ...
  include AccountNumberCapture
end
```

Move Method を用いて、インスタンスメソッドをモジュールへと移動する

`included` 内で`class_eval` を使用し、include された先のクラスで、`before_save` を定義する

```ruby
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
```

## Inline Module

モジュールは間接的なレベルを作り出す。振る舞いを見つけるにはまずクラスの定義を見て、インクルードされているモジュールを見て、そのモジュールの定義を見にいく

そのような間接的な構造は重複を取り除くには便利だが、重複を減らすに値しない場合、モジュールをクラスにマージしたほうが良い

1. Push Down Method を用いて、モジュール内の振る舞いをクラスへと移動する  
2. テストしていく  
3. 空のモジュールを削除する  
4. テスト


## Extract Subclass

```ruby
class JobItem
  attr_reader :quantity, :employee

  def initialize(unit_price, quantity, is_labor, employee)
    @unit_price = unit_price
    @quantity = quantity
    @is_labor = is_labor
    @employee = employee
  end

  def total_price
    unit_price * @quantity
  end

  def unit_price
    labor? ? @employee.rate : @unit_price
  end

  def labor?
    @is_labor
  end
end

class Employee
  # ...
  attr_reader :rate

  def initialize(rate)
    @rate = rate
  end
end
```

`JobItem` から`LaborItem` というサブクラスに切り出す。

まずコンストラクタを作る。JobItem のそれは引数を取るので、LaborItem もそのようにする

それでもテストは通るのだが、引数の中には LaborItem では不要なものもある

LaborItem からインスタンスを作成する方法を確認する

コンストラクタの引数のリストを整理する。 is_labor, employee にデフォルト値を設定する

サブクラス(LaborItem)のコンストラクタから不要なパラメータを取り除く

Push Down Method を用いて、employee をサブクラスへと押し下げる

コンストラクタをさらに整理できる。employee はサブクラスでのみ必要

@is_labor を取り除く。フィールドのカプセル化を行う

labor? というメソッドを用意して、JobItem ではfalse, LaborItem ではtrue を返す

そのことによって、unit_price method から条件分岐を取り除くことができる

```ruby
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
```

## Introduce Inheritance

似たような機能を持った２つのクラスがある

スーパークラスを作成し、共通の機能をスーパークラスへと移動する

```ruby
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

class FrontSuspensionMountainBike
  TIRE_WIDTH_FACTOR = 6
  FRONT_SUSPENSION_FACTOR = 8
  attr_accessor :tire_diameter, :front_fork_travel

  def wheel_circumference
     Math::PI * (@wheel_diameter + @tire_diameter)
  end

  def off_road_ability
    @tire_diameter * TIRE_WIDTH_FACTOR + @front_fork_travel *
    FRONT_SUSPENSION_FACTOR
  end
end
```

-----

```ruby
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
```

## Collapse Heirarchy

スーパークラスとサブクラスがそんなに違わないのであれば、一緒にしてしまう

## Form Template Method

Ruby では、Form Template Method はモジュールの拡張を使用することによって実現されうる

### Example 1: Template Method Using Inheritance

Customer class があり、２つの表示に関するメソッドを持っている

`statement` method は ASCII で表示する

`html_statement` method は HTML で表示する

```ruby
class Customer
  def statement
    result = "Rental Record for #{name}\n"
    @rentals.each do |rental|
      # show figures for this rental
      result << "\t#{rental.movie.title}\t#{rental.charge}\n"
    end
    # add footer lines
    result << "Amount owed is #{total_charge}\n"
    result << "You earned #{total_frequent_renter_points} frequent renter\
    points"
    result
  end

  def html_statement
    result = "<H1>Rentals for <EM>#{name}</EM></H1><P>\n"
    @rentals.each do |rental|
      # show figures for this rental
      result << "#{rental.movie.title}: \t#{rental.charge}<BR/>\n"
    end
    # add footer lines
    result << "<P>You owe <EM>#{total_charge}</EM></P>\n"
    result << "On this rental you earned <EM>#{total_frequent_renter_points}</\
  EM> frequent renter points</P>"
  end
end
```

-----

Form Template Method を使用する前に、スーパークラスとサブクラスを作る

```ruby
class Statement

end

class TextStatement < Statement

end

class HtmlStatement < Statement

end
```

-----

Move Method を用いて、サブクラスを利用したメソッドを作成

```ruby
class Customer
  def statement
    TextStatement.value(self)
  end

  def html_statement
    HtmlStatement.value(self)
  end
end

class TextStatement < Statement
  def value(customer)
    result = "Rental Record for #{customer.name}\n"
    customer.rentals.each do |rental|
      # show figures for this rental
      result << "\t#{rental.movie.title}\t#{rental.charge}\n"
    end
    # add footer lines
    result << "Amount owed is #{customer.total_charge}\n"
    result << "You earned #{customer.total_frequent_renter_points} frequent renter\
              points"
    result
  end
end

class HtmlStatement < Statement
  def value(customer)
    result = "<H1>Rentals for <EM>#{customer.name}</EM></H1><P>\n"
    customer.rentals.each do |rental|
      # show figures for this rental
      result << "#{rental.movie.title}: \t#{rental.charge}<BR/>\n"
    end
    # add footer lines
    result << "<P>You owe <EM>#{customer.total_charge}</EM></P>\n"
    result << "On this rental you earned <EM>#{customer.total_frequent_renter_points}</\
    EM> frequent renter points</P>"
  end
end
```

----

各サブクラスで、ヘッダーの文を構築するメソッド `header_string` を追加する

他の文章を構築するメソッドも追加していく

```ruby
class TextStatement < Statement
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      # show figures for this rental
      result << each_rental_string(rental)
    end
    # add footer lines
    result << footer_string(customer)
  end

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
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      # show figures for this rental
      result << each_rental_string(rental)
    end
    # add footer lines
    result << footer_string(customer)
  end

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
```

-----

`value` method はそれぞれ似通っているので、Pull Up Mehtod を用いて Statement class へと押し上げる

```ruby
class Statement
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      result << each_rental_string(rental)
    end
    result << footer_string(customer)
  end
end
```

２つのサブクラスにある`value` メソッドは削除できる

最終的には以下のようになる

```ruby
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
```

### Example 2: Template Method Using Extension of Modules

```ruby
class Customer
  def statement
    result = "Rental Record for #{name}\n"
    @rentals.each do |rental|
      # show figures for this rental
      result << "\t#{rental.movie.title}\t#{rental.charge}\n"
    end
    # add footer lines
    result << "Amount owed is #{total_charge}\n"
    result << "You earned #{total_frequent_renter_points} frequent renter\
    points"
    result
  end

  def html_statement
    result = "<H1>Rentals for <EM>#{name}</EM></H1><P>\n"
    @rentals.each do |rental|
      # show figures for this rental
      result << "#{rental.movie.title}: \t#{rental.charge}<BR/>\n"
    end
    # add footer lines
    result << "<P>You owe <EM>#{total_charge}</EM></P>\n"
    result << "On this rental you earned <EM>#{total_frequent_renter_points}</\
  EM> frequent renter points</P>"
  end
end
```

`Statement` class を作り、あとの２つはモジュールで作成する

```ruby
class Statement
end

module TextStatement
end

module HtmlStatement
end
```

Move Method によって、モジュールを利用した`statement`, `html_statement` を作成する

```ruby
class Customer
  def statement
    Statement.new.extend(TextStatement).value(self)
  end

  def html_statement
    Statement.new.extend(HtmlStatement).value(self)
  end
end

class Statement
end

module TextStatement
  def value(customer)
    result = "Rental Record for #{customer.name}\n"
    customer.rentals.each do |rental|
      # show figures for this rental
      result << "\t#{rental.movie.title}\t#{rental.charge}\n"
    end
    # add footer lines
    result << "Amount owed is #{customer.total_charge}\n"
    result << "You earned #{customer.total_frequent_renter_points} frequent renter\
    points"
    result
  end
end

module HtmlStatement
  def value(customer)
    result = "<H1>Rentals for <EM>#{customer.name}</EM></H1><P>\n"
    customer.rentals.each do |rental|
      # show figures for this rental
      result << "#{rental.movie.title}: \t#{rental.charge}<BR/>\n"
    end
    # add footer lines
    result << "<P>You owe <EM>#{customer.total_charge}</EM></P>\n"
    result << "On this rental you earned <EM>#{customer.total_frequent_renter_points}</\
  EM> frequent renter points</P>"
  end
end
```

------

Extract Method を用いて、ユニークな振る舞いを切り出す

```ruby
module TextStatement
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      # show figures for this rental
      result << each_rental_string(rental)
    end
    # add footer lines
    result << footer_string(customer)
  end

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
  def value(customer)
    result = header_string(customer)
    customer.rentals.each do |rental|
      # show figures for this rental
      result << each_rental_string(rental)
    end
    # add footer lines
    result << footer_string(customer)
  end

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
```

-----

最後に `value` method を押し上げる

```ruby
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
```

## Replace Inheritance with Delegation

サブクラスがスーパークラスの一部のインターフェースしか使用しておらず、データも継承しない

スーパークラスのフィールドを作り、メソッドをスーパークラスへ移譲するように調整し、サブクラスから削除する

-----

`Policy` class はHash を継承している。Hash の要素は`Rules` の配列であり、`Policy` はHash に対して、 `<<` operator というArray のようなインターフェースを提供している

```ruby
class Policy < Hash
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def <<(rule)
    key = rule.attribute
    self[key] ||= []
    self[key] << rule
  end

  def apply(account)
    self.each do |attribute, rules|
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
```

`Policy` は　`<<`, `apply`, `[]`, `size`, `empty?` の５つを持っている。そのうち最後３つはHash から継承しているものである  

移譲されたHashのためにフィールドを作ることから移譲を始める

```ruby
class Policy < Hash
  attr_reader :name

  def initialize(name)
    @name = name
    @rules = self
  end
#...
end
```

-----

移譲を使用してメソッドを置き換えていく

```ruby
class Policy < Hash
  attr_reader :name

  def initialize(name)
    @name = name
    @rules = self
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
```

サブクラスはこれで終わり。スーパークラス(Hash)を継承するのをやめる

```ruby
class Policy
  # ...
end
```

-----

`Forwardable` をextendしてスーパークラスのシンプルなdelegating methods を追加する

```ruby
require 'forwardable'

class Policy
  attr_reader :name

  extend Forwardable

  def_delegators :@rules, :size, :empty?, :[]

  def initialize(name)
    @name = name
    @rules = {}
  end
# ...
end
```

``@rules = {}`` Hash object に対して、`:size` などのメソッドを移譲する  
継承だとHash の機能を全て継承してしまうが、移譲を使えば一部の機能だけを利用することができ、親子関係も生まれないので何かと捗る

## Replace Delegation with Hierarchy

モジュールを移譲して、移譲元のクラスへinclude する

### Example

`Person`に移譲している `Employee` がある

```ruby
class Employee
  extend Forwardable

  def_delegators :@person, :name, :name=

  def initialize
    @person = Person.new
  end

  def to_s
   "Emp: #{@person.last_name}"
  end
end

class Person
  attr_accessor :name
  
  def last_name
    @name.split(' ').last
  end
end
```

-----

最初のステップは `Person` module を作成し、`Employee` へとインクルードすること

```ruby
module Person
  attr_accessor :name

  def last_name
    @name.split(' ').last
  end
end

class Employee
  include Person
  # ...
end
```

-----

次は移譲用のフィールドを作成し、self を参照する。`name`, `name=` などの移譲用メソッドは削除しなければいけない  
それを忘れると、無限に再帰が起こりスタックオーバーフローになる  
`def_delegators` も削除

```ruby
class Employee
  include Person

  def initialize
    @person = self
  end

  def to_s
   "Emp: #{@person.last_name}"
  end
end
```

-----

最後に移譲を使用しているメソッドを変更する。暗黙のself に変更

```ruby
class Employee
  include Person

  def initialize
    @person = self
  end

  def to_s
   "Emp: #{last_name}"
  end
end
```

## Replace Abstract Superclass with Module

継承の階層があるが、スーパークラスのインスタンスを明示的にインスタンス化するつもりはない  
スーパークラスをモジュールに置き換えて、意図したやりとりができるようにする

1. スーパークラスのクラスメソッドがサブクラスを使用して呼び出したいものであった場合、`inherited` hook を定義して、それによりクラスメソッドをサブクラスへと移動させる  
2. Test  
3. クラスをモジュールにして、各基底クラスにおいて継承の定義を `include`　する  
4. `inherited` hook を `include` hook にする  
5. Test

### Example

SQL joins を構築するサブクラスがある

```ruby
class LeftOuterJoin < Join
  def join_type
    "LEFT OUTER"
  end
end

class InnerJoin < Join
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
class Join
  # ...
  def initialize(table, options)
    @table = table
    @on = options[:on]
  end

  def self.joins_for_table(table_name)
    # ...some code for querying the database for the given table’s joins of
    # the base class’s join type
  end

  def to_sql
    "#{join_type} JOIN #{@table} ON #{@on}"
  end
end
```

`joins_for_table` method を両方のサブクラスへと追加する  
重複を避けるために、`inherited` hook を使用する  

`Join` class に`inherited` hook を定義して、その定義の中で継承を行うクラスを開いて、`joins_for_table` method を追加する

```ruby
module Join
  # ...
  def self.inherited(klass)
    klass.class_eval do
      def self.joins_for_table(table_name)
        table_name.to_s
      end
    end
  end
# ...
end
```

サブクラスでinclude する。`Join` を継承する必要がなくなった

-----

```ruby
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
```

-----

最後に、`inherited` hook はもう実行されない（継承ではなくinclude した）ので、`included` hook を使用する

```ruby
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
```
