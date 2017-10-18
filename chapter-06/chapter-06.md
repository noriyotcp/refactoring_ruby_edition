# Chapter 6: Composing Methods

## Extract Method

```ruby
def print_owing(amount)
  print_banner
  puts "name: #{@name}"
  puts "amount: #{amount}"
end
```

```ruby
# Turn the fragment into a method whose name explains the purpose of the method.
def print_owing(amount)
  print_banner
  print_details(amount)
end

def print_details(amount)
  puts "name: #{@name}"
  puts "amount: #{amount}"
end
```

### Example: No Local Variables

```ruby
def print_owing
  outstanding = 0.0

  # print banner
  puts "*************************"
  puts "***** Customer Owes *****"
  puts "*************************"

  # calculate outstanding
  @orders.each do |order|
    outstanding += order.amount
  end

  # print details
  puts "name: #{@name}"
  puts "amount: #{outstanding}"
end
```

-----

```ruby
# print_banner method に切り出す
def print_owing
  outstanding = 0.0

  print_banner # ここ

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
```

### Example: Using Local Variables

```ruby
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
```

-----

details を表示する部分を print_details メソッドへと切り出し、outstanding を渡す

```ruby
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
```

### Example: Reassigning a Local Variables

```ruby
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
```

outstanding を計算する部分を calculate_outstanding メソッドに切り出す

```ruby
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
```

calculate_outstanding に初期値を渡す形

```ruby
def print_owing(previous_amount)
  outstanding = previous_amount * 1.2
  print_banner
  # calculate outstanding
  @orders.each do |order|
    outstanding += order.amount
  end
  print_details(outstanding)
end
```

-----

```ruby
def print_owing(previous_amount)
  outstanding = previous_amount * 1.2
  print_banner
  calculate_outstanding(outstanding)
  print_details(outstanding)
end

def calculate_outstanding(initial_value)
  @orders.inject(initial_value) { |result, order| result + order.amount }
end
```

さらに直接 `previous_amount * 1.2` を渡す  
返ってきた結果を`outstanding` に格納して、`print_details` へと渡す

```ruby
def print_owing(previous_amount)
  print_banner
  outstanding = calculate_outstanding(previous_amount * 1.2)
  print_details(outstanding)
end
```

## Inline Method

```ruby
def get_rating
  more_than_five_late_deliveries ? 2 : 1
end

def more_than_five_late_deliveries
  @number_of_late_deliveries > 5
end
```

-----

メソッドの中身を呼び出し側へと移動する

```ruby
def get_rating
  @number_of_late_deliveries > 5 ? 2 : 1
end
```

## Inline Temp

一時変数への参照を expression で置き換え

```ruby
base_price = an_order.base_price
return (base_price > 100)
```

-----

```ruby
return (an_order.base_price > 100)
```

## Replace Temp with Query

```ruby
base_price = @quantity * @item_price
if base_price > 1000
  base_price * 0.95
else
  base_price * 0.98
end
```

-----

一時変数をクエリメソッドで置きかえ

```ruby
if base_price > 1000
  base_price * 0.95
else
  base_price * 0.98
end

def base_price
  @quantity * @item_price
end
```

### Example

```ruby
def price
  base_price = @quantity * @item_price
  if base_price > 1000
    discount_factor = 0.95
  else
    discount_factor = 0.98
  end
  base_price * discount_factor
end
```

-----

まず右辺をbase_price メソッドへと切り出す
それにより base_price = @quantity * @item_price と、一時変数に格納する行を削除できる

```ruby
def price
  if base_price > 1000
    discount_factor = 0.95
  else
    discount_factor = 0.98
  end
  base_price * discount_factor
end

def base_price
  @quantity * @item_price
end
```

-----

条件分岐の部分をdiscount_factor へと切り出す

```ruby
def price
  base_price * discount_factor
end

def base_price
  @quantity * @item_price
end

def discount_factor
  base_price > 1000 ? 0.95 : 0.98
end
```

## Replace Temp with Chain

チェーンメソッドを使用することにより一時変数を削除することができる

```ruby
mock = Mock.new
expectation = mock.expects(:a_method_name)
expectation.with("arguments")
expectation.returns([1, :array])
```

-----

```ruby
mock = Mock.new
mock.expects(:a_method_name).with("arguments").returns([1, :array])
```

Method Chaining はローカル変数の必要性を減らすことができる
メンテナンス性を改善し、インターフェースの提供により、自然に読むことができるコードを組み立てることができる

一時変数をチェーンで置き換えることは、１つのオブジェクトに対して実行される。メソッド呼び出しをチェーンすることはオブジェクトの流暢さをよくする

### Example

HTML の要素を組み立てるライブラリをデザインする
ドロップダウンのセレクトボタンを作成することができ、それにオプションを追加していくことができる

```ruby
class Select
  def options
    @options ||= []
  end

  def add_option(arg)
    options << arg
  end
end

select = Select.new
select.add_option(1999)
select.add_option(2000)
select.add_option(2001)
select.add_option(2002)
select # => #<Select:0x28708 @options=[1999, 2000, 2001, 2002]>
```

-----

``with_option`` というクラスメソッドを作成する。自身のインスタンスを作成し、オプションを追加する

```ruby
class Select
  def options
    @options ||= []
  end

  def add_option(arg)
    options << arg
  end

  def self.with_option(option)
    select = self.new
    select.options << option
    select
  end
end

select = Select.with_option(1999)
select.add_option(2000)
select.add_option(2001)
select.add_option(2002)
select # => #<Select:0x28708 @options=[1999, 2000, 2001, 2002]>
```

次は``add_option`` にてself を返すようにする。これによりチェーンすることが可能になる

```ruby
class Select
  def options
    @options ||= []
  end

  def add_option(arg)
    options << arg
    self
  end

  def self.with_option(option)
    select = self.new
    select.options << option
    select
  end
end

select = Select.with_option(1999).add_option(2000).add_option(2001).add_option(2002)
select # => #<Select:0x28708 @options=[1999, 2000, 2001, 2002]>
```

最後に ``add_option`` を ``and`` という名前に変えて読みやすくする

```ruby
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
```

## Introduce Explaining Variable

式の結果を変数に格納して置き換える

```ruby
if (platform.upcase.index("MAC") &&
    browser.upcase.index("IE") &&
    initialized? &&
    resize > 0
)
  # do something
end
```

変数名も説明的な名前にする

```ruby
is_mac_os = platform.upcase.index("MAC")
is_ie_browser = browser.upcase.index("IE")
was_resized = resize > 0

if (is_mac_os && is_ie_browser && initialized? && was_resized)
  # do something
end
```

### Example

```ruby
def price
  # price is base price - quantity discount + shipping
  return @quantity * @item_price -
    [0, @quantity - 500].max * @item_price * 0.05 +
    [@quantity * @item_price * 0.1, 100.0].min
end
```

各計算を変数へ格納する

```ruby
def price
  # price is base price - quantity discount + shipping
  base_price = @quantity * @item_price
  quantity_discount = [0, @quantity - 500].max * @item_price * 0.05
  shipping = [base_price * 0.1, 100.0].min
  return base_price - quantity_discount + shipping
end
```

### Example with Extract Method

一時変数を使わず、メソッドへと切り出す

```ruby
def price
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
```

## Split Temporary Variable

１つの一時変数 (temp) だけでなく、複数の変数に切り分ける

### Example

``acc`` という変数を２度使っているが、それぞれ意味が違う

```ruby
def distance_traveled(time)
  acc = @primary_force / @mass # ここと
  primary_time = [time, @delay].min
  result = 0.5 * acc * primary_time * primary_time
  secondary_time = time - @delay
  if(secondary_time > 0)
    primary_vel = acc * @delay
    acc = (@prmary_force + @secondary_force) / @mass # ここ
    result += primary_vel * secondary_time + 5 * acc * secondary_time *
      secondary_time
  end
  result
end
```

``primary_acc``, ``secondary_acc`` の２つに分ける

```ruby
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
```


## Remove Assignments to Parameters

メソッドにfoo というオブジェクトをパラメータとして渡した時、"変数に割り当てる (assigns to a parameter)"とは、別のオブジェクトを参照するためにfoo を変えることを意味する

```ruby
def a_method(foo)
  foo.modify_in_some_way # that's OK
  foo = another_object # trouble and despair will follow you
end
```

Ruby は排他的に値渡しを使うので、参照渡しとの区別をはっきりさせる

### Example

```ruby
def discount(input_val, quantity, year_to_date)
  input_val -= 2 if input_val > 50
  input_val -= 1 if quantity > 100
  input_val -= 4 if year_to_date > 10000
  input_val
end
```

-----

```ruby
def discount(input_val, quantity, year_to_date)
  result = input_val # input_val をresultへコピー、そちらの値を変えていく
  result -= 2 if input_val > 50 # if のinput_val は引数として渡された「元々の」input_val
  result -= 1 if quantity > 100
  result -= 4 if year_to_date > 10000
  result
end
```

## Replace Method with Method Object

メソッドが長すぎる場合はオブジェクトにしろ、的な

1. Create a new class, name it after the method.
2. Give the new class an attribute for the object that hosted the original method (the source object) and an attribute for each temporary variable and each parameter in the method.
3. Give the new class a constructor that takes the source object and each parameter.
4. Give the new class a method named “compute”
5. Copy the body of the original method into compute. Use the source object
instance variable for any invocations of methods on the original object.
6. Test.
7. Replace the old method with one that creates the new object and calls compute

1.新しいクラスを作成し、メソッドの後に名前を付けます  
2.元のメソッド（ソースオブジェクト）を提供していたオブジェクトの属性と、メソッドの各一時変数および各パラメーターの属性を、新しいクラスに与えます  
3.新しいクラスに、ソースオブジェクトと各パラメータを取るコンストラクタを与えます  
4.新しいクラスに "compute"という名前のメソッドを与えます  
5.元のメソッドの本体をcomputeにコピーします   ソースオブジェクトのインスタンス変数を使用して元のオブジェクト上のメソッドを呼び出します  
6.テスト  
7.古いメソッドを、新しいオブジェクトを作成し、compute を呼び出すメソッドに置き換えます

### Example

```ruby
class Account
  def gamma(input_val, quantity, year_to_date)
    inportant_value1 = (input_val * quantity) + delta
    important_value2 = (input_val * year_to_date) + 100
    if (year_to_date - important_value1) > 100
      important_value2 -= 20
    end
    important_value3 = important_value2 * 7
    # and so on.
    important_value3 - 2 * important_value1
  end
end
```

-----

```ruby
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
  # Accountのほうにあったgamma メソッドの属性をこちらへ持ってくる
  # Account のオブジェクト用の属性 (account)も
  attr_reader :account,
              :input_val,
              :quantity,
              :year_to_date,
              :important_value1,
              :important_value2,
              :important_value3

  # 初期化の際にcompute の計算部分で必要な属性をセットする
  def initialize(account, input_val_arg, quantity_arg, year_to_date_arg)
    @account = account
    @input_val = input_val_arg
    @quantity = quantity_arg
    @year_to_date = year_to_date_arg
  end

  def compute
    @important_value1 = (input_val * quantity) + @account.delta # account のインスタンスからdelta にアクセス
    @important_value2 = (input_val * year_to_date) + 100
    important_thing # 条件分岐の部分を別メソッドへ切り出し
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
```

## Substitute Algorithm

代替のアルゴリズムに置き換える

```ruby
def found_friends(people)
  friends = []
  people.each do |person|
    if(person == "Don")
      friends << "Don"
    end
    if(person == "John")
      friends << "John"
    end
    if(person == "Kent")
      friends << "Kent"
    end
  end
  return friends
end
```

-----

```ruby
def found_friends(people)
  people.select { |person| %w(Don John Kent).include?(person) }
end
```

## Replace Loop with Collection Closure Method

ループ内で要素のコレクションを処理している場合、ループをコレクションクロージャメソッドに置き換える

ループを関連するコレクションクロージャメソッドに置き換えると、コードをたどりやすくなる

-----

```ruby
offices = []
employees.each { |e| offices << e.office }
```

```ruby
employees.collect { |e| e.office }
```

-----

```ruby
managerOffices = []
employees.each do |e|
  managerOffices << e.office if e.manager?
end
```

```ruby
managerOffices = employees.select { |e| e.manager? }
                          .collect { |e| e.office }
# managerOffices = employees.select(&:manager?).collect(&:office)
```

-----

```ruby
total = 0
employees.each { |e| total += e.salary }
```

```ruby
p employees.inject(0) { |sum, e| sum + e.salary }
# p employees.reduce(0) { |sum, e| sum + e.salary }
```

## Extract Surrounding Method

重複しているメソッドを切り出す。ブロックを受け取れるようにしてyield で呼び出して実行？

要はユニークなコードがメソッドの先頭か末尾にあるなら単純に切り出せるけど、メソッドの真ん中にあったらどうするのと

これにより、インフラストラクチャコード（例：コレクションを反復するコードや外部サービスに接続するコードなど）を隠して、ビジネスロジックを目立たせることができる

```ruby
def charge(amount, credit_card_number) # ここで引数を２つ受け取っている
  begin
    connection = CreditCardServer.connect(...)
    connection.send(amount, credit_card_number) # ここでも引数を２つ受け取っている
  rescue IOError => e
    Logger.log "Could not submit order #{@order_number} to the server: #{e}"
    return nil
  ensure
    connection.close
  end
end
```

-----

```ruby
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
```

### Example

家系図のモデルを作る

- `number_of_living_descendants` 生きている子供が何人いるかを数え上げる
- `number_of_descendants_named(name)` その名前の子供を数え上げる

重複しているのは、インクリメントするかどうかを判別する部分である

```ruby
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
    children.inject(0) do |count, child|
      count += 1 if child.alive? # ここでインクリメント
      count + child.number_of_living_descendants
    end
  end

  def number_of_descendants_named(name)
    children.inject(0) do |count, child|
      count += 1 if child.name == name # ここでインクリメント
      count + child.number_of_descendants_named(name)
    end
  end

  def alive?
    @date_of_death.nil?
  end
end
```

まず数え上げる部分を別メソッド (`count_descendants_matching(name)`) へ切り出す

```ruby
  def number_of_descendants_named(name)
    count_descendants_matching(name)
  end

  protected
  def count_descendants_matching(name)
    children.inject(0) do |count, child|
      count += 1 if child.name == name
      count + child.count_descendants_matching(name) # 再帰的に count_descendants_matching(name) を実行
    end
  end
```

インクリメントするかどうか判別する部分 ``if child.name == name`` をブロックにする

```ruby
  def number_of_descendants_named(name)
    count_descendants_matching { |descendant| descendant.name == name }
  end

  protected
  def count_descendants_matching(&block) # block を受け取る
    children.inject(0) do |count, child|
      count += 1 if yield child # block にchild を渡す
      count + child.count_descendants_matching(&block) # block を受け取る
    end
  end
```

## Introduce Class Annotation

宣言的な構文でコードの目的が明確につかめる場合に適用すると、コードの意図を明確にできる

Class Annotation を使用する
例えば次のようなイニシャライザに対して・・・

```ruby
class SearchCriteria
  def initialize(hash)
    @author_id = hash[:author_id]
    @publisher_id = hash[:publisher_id]
    @isbn = hash[:isbn]
  end
  # ...
end
```

このようなClass Annotation を作る

``hash_initializer :author_id, :publisher_id, :isbn``

```ruby
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
```

注意点：Class annotation の前にクラスメソッドを宣言する
このことによって渡されるハッシュのキー名がどんなものでも対応できるようにする
けどこれどうなんだろうなあ・・・

#### module に切り出す

```ruby
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
```

```ruby
# ここで全てのクラスに CustomInitializers をインクルード
Class.send(:include, CustomInitializers)
# ここでは Class annotation を宣言するだけで良い
class SearchCriteria
  # ...
  hash_initializer :author_id, :publisher_id, :isbn
end
```

## Introduce Named Parameter

まあこれは引数はハッシュで渡せ、的な  
先ほどの Introduce Class annotation のカスタムイニシャライザを使うと便利

### Example 2: Naming Only the Optional Parameters

```ruby
class Books
  def self.find(selector, conditions="", *joins)
    sql = ["SELECT * FROM books"]
    joins.each do |join_table|
      sql << "LEFT OUTER JOIN #{join_table} ON"
      sql << "books.#{join_table.to_s.chop}_id"
      sql << " = #{join_table}.id"
    end
    sql << "WHERE #{conditions}" unless conditions.empty?
    sql << "LIMIT 1" if selector == :first
    connection.find(sql.join(" "))
  end
end

# 引数の順番を気にしないといけないし、わかりづらい
Books.find(:all)
Books.find(:all, "title like '%Voodoo Economics'")
Books.find(:all, "authors.name = 'Jenny James'", :authors)
Books.find(:first, "authors.name = 'Jenny James'", :authors)
```

-----

```ruby
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
```

conditions, joins はハッシュで渡す。joins の値はシンボルの配列で

#### module for assertion

ハッシュのキー名をあらかじめ把握しておくのは辛い
なんか違うキーが渡されたらエラー出すようにしておきたい

```ruby
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
    # ここで有効なキー名だけを登録し、hash オブジェクト内のキーを精査する
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
```

## Remove Named Parameter

名前付き引数も使いすぎよくない

```ruby
Books.find
Books.find(:selector => :all,
           :conditions => "authors.name = 'Jenny James'",
           :joins => [:authors])
Books.find(:selector => :first,
           :conditions => "authors.name = 'JennyJames'",
           :joins => [:authors])
```

``find`` の実装を見ずにどういう結果が返ってくるかを予測するのが難しい

``:selector`` というパラメータにも問題がある。SQL では意味をなさない

```ruby
sql << "LIMIT 1" if selector == :first
```

これでパラメータが ``:first`` の時は１つだけ返す。その他の場合は全部返す

```ruby
Books.find # => Books.find(:all)
Books.find(:all,
           :conditions => "authors.name = 'Jenny James'",
           :joins => [:authors])
Books.find(:first,
           :conditions => "authors.name = 'JennyJames'",
           :joins => [:authors])
```


## Remove Unused Default Parameter

引数がデフォルト値を持っていて、メソッドが必ずその引数を必要とするならば、デフォルト値は不要

```ruby
def product_count_items(search_criteria=nil)
  criteria = search_criteria | @search_criteria
  ProductCountItem.find_all_by_criteria(search_criteria)
end
```

-----

```ruby
def product_count_items(search_criteria)
  ProductCountItem.find_all_by_criteria(search_criteria)
end
```

## Dynamic Method Definition

動的メソッド定義

```ruby
def failure
  self.state = :failure
end

def error
  self.state = :error
end
```

-----

```ruby
def_each :failure, :error do |method_name|
  self.state = method_name
end
```

わざわざ ``def_each`` というメソッドを定義するらしい・・・

### Example: Using def_each to Define Similar Methods

似たようなメソッドがこのように並んでいる

```ruby
def failure
  self.state = :failure
end

def error
  self.state = :error
end

def success
  self.state = :success
end
```

まずはこのようにして重複をなくす

```ruby
[:failure, :error, :success].each do |method|
  define_method method do
    self.state = method
  end
end
```

そこから以下のように動的定義を導入する

```ruby
class Class
  def def_each(*method_names, &block)
    method_names.each do |method_name|
      define_method method_name do
        instance_exec method_name, &block
      end
    end
  end
end
```

``instance_exec`` 渡されたブロックをレシーバのインスタンスの元で実行する。ブロックの戻り値がメソッドの戻り値になる
インスタンスメソッド内でコードを実行するときと同じことができる

```ruby
# :failure を定義する
define_method method_name do # 1. failure というメソッドを定義
  instance_exec method_name, &block # 2. レシーバ (failure) のインスタンスの元でブロックを実行
end
```

https://ref.xaio.jp/ruby/classes/object/instance_exec

### Example: Defining Instance Methods with a Class Annotation

```ruby
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
```

### Example: Defining Methods By Extending a Dynamically Defined Module

動的に定義されたmoduleを拡張

```ruby
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
```

初期化の際にハッシュを渡し、それをセットしていく場合

```ruby
class Hash
  def to_module
    hash = self
    Module.new do # module 化する
      # Hash を拡張する メソッド名がキー名と同じで値を返す
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
    # ハッシュをモジュール化 self.extend でモジュールの特異メソッドとして使える
    self.extend post_data.to_module
  end
end

post_data = PostData.new(params: 1, session: 'session')
p post_data.params
p post_data.session
```

## Replace Dynamic Receptor with Dynamic Method Definition

``method_missing`` のデバッグは辛い
``NoMethodError`` になるんならいいけど ``SystemStackError`` になるのは最悪

動的に必要なメソッドを定義する

### Example: Dynamic Delegation Without method_missing

```ruby
class Decorator
  def initialize(subject)
    @subject = subject
  end

  def method_missing(sym, *args, &block)
    @subject.send sym, *args, &block
  end
end
```

存在しないメソッドを呼んだとき、``NoMethodError`` が起こるが、メソッドを呼ぶのは ``Decorator`` であるにもかかわらず、エラーが起こるのは ``subject`` である

`Decorator` で`NoMethodError` が起こるようにする

```ruby
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
```

https://ref.xaio.jp/ruby/classes/object/public_methods

https://docs.ruby-lang.org/ja/latest/method/Module/i/class_eval.html

### Example: Using User-Defined Data to Define Methods

```ruby
class Person
  attr_accessor :name, :age
  def method_missing(sym, *args, &block)
    empty?(sym.to_s.sub(/^empty_/,"").chomp("?"))
  end

  def empty?(sym)
    self.send(sym).nil?
  end
end
```

これも先ほどと同じ問題がある

```ruby
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
```

## Isolate Dynamic Receptor

``method_missing`` を新しいクラスに切り出す

```ruby
class Recorder
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

  def play_for(obj)
    messages.inject(obj) do |result, message|
      result.send(message.first, *message.last)
    end
  end

  def to_s
    messages.inject([]) do |result, message|
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

recorder = Recorder.new
recorder.start("LRMMMMRL") # start がmethod_missing でmessages に一旦格納される？
recorder.stop("LRMMMMRL")
recorder.play_for(CommandCenter.new)
```

どこか不具合が出た時に特定しづらい  
未定義のメッセージを集めておく機能を`Recorder`から `MessageCollecter` へと切り出す

```ruby
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
```

Recorder ではrecord メソッド内でMessagesCollector を初期化しておく  
message_collector のmessages を利用する

```ruby
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

# 使用する際にrecord を差し込む
recorder = Recorder.new
recorder.record.start("LRMMMMRL") # start とその引数を記録する、というのがわかりやすい
recorder.record.stop("LRMMMMRL")
recorder.play_for(CommandCenter.new)
```

-----

## Move Eval from Runtime to Parse Time

eval を実行時からパース時へ  
eval の使用をメソッド定義の内側から定義する箇所そのものへと移動する  

eval の実行回数を減らすことができる

```ruby
class Person
  def self.attr_with_default(options)
    options.each_pair do |attribute, default_value|
      define_method attribute do
        eval "@#{attribute} ||= #{default_value}"
      end
    end
  end
  attr_with_default :emails => "[]",
                    :employee_number =>"EmployeeNumberGenerator.next"
end
```

-----

```ruby
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
```
