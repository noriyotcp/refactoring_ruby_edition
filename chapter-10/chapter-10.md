# Chapter 10: Making Method Calls Simpler

## Rename Method

コードは第一に人間のためのものであって、コンピューターはその次

分かりやすい名前大事

電話番号を返すメソッドがある

```ruby
def telephone_number
  "(#{@officeAreaCode}) #{@officeNumber}"
end
```

-----

まず新しいメソッドを作り、古いメソッドの内容をコピーする  
古いメソッドから新しいメソッドを呼び出す

```ruby
class Person
  def telephone_number
    office_telephone_number
  end

  def office_telephone_number
    "(#{@officeAreaCode}) #{@officeNumber}"
  end
end
```

## Add Parameter

オブジェクトをパラメータとして、その情報を渡す

## Remove Parameter

今度は逆に、メソッドの中で使われないパラメータを削除する

## Separate Query from Modifier

値を返しつつ、オブジェクトの状態を変更するメソッドがある  
２つのメソッドを作る。１つはクエリ用、もう１つは変更用

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
  ""
end

def check_security(people)
  found = found_miscreant(people)
  some_later_code(found)
end
```

-----

```ruby
# 変更する側と同じ値を返す最適なクエリを作成する（副作用なし）
def found_person(people)
  people.each do |person|
    return "Don" if person == "Don"
    return "John" if person == "John"
  end
  ""
end

# found_miscreant から名前を変更
# 人物が見つからなければアラートを送る
def send_alert_if_miscreant_in(people)
  send_alert unless found_person(people).empty?
end

def check_security(people)
  send_alert_if_miscreant_in(people)
  found = found_person(people)
  some_later_code(found)
end
```

## Parameterize Method

似たようなことを行うメソッドが複数ある。しかしそれぞれが持っている値は違う

異なる値をパラメータとして使用する１つのメソッドを作成

```ruby
class Employee
  def ten_percent_raise
    @salary *= 1.1
  end

  def five_percent_raise
    @salary *= 1.05
  end
end
```

-----

```ruby
def raise(factor)
  @salary *= (1 + factor)
end
```

もう１つのケース

```ruby
def base_charge
  result = [last_usage, 100].min * 0.03

  if last_usage > 100
    result += ([last_usage, 200].min - 100) * 0.05
  end

  if last_usage > 200
    result += (last_usage - 200) * 0.07
  end

  Dollar.new(result)
end

def last_usage
  # ...
end
```

``last_usage`` の値によって条件分岐して異なるresult を返している

---

```ruby
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
```

> https://docs.ruby-lang.org/ja/latest/method/Range/i/begin.html  
> begin -> object  
> first -> object  
> 始端の要素を返します。範囲オブジェクトが始端を含むかどうかは関係ありません。

> p (1..5).begin # => 1  
> p (1..0).begin # => 1  

> https://docs.ruby-lang.org/ja/latest/method/Range/i/end.html  
> end -> object  
> last -> object  
> 終端の要素を返します。範囲オブジェクトが終端を含むかどうかは関係ありません。

> (10..20).last      # => 20  
> (10...20).last     # => 20  


## Replace Parameter with Explicit Methods

列挙されたパラメータの値によって違うコードが走るメソッドがある

```ruby
def set_value(name, value)
  if name == "height"
    @height = value
  elsif name == "width"
    @width = value
  else
    raise "Should never reach here"
  end
end
```

それぞれのパラメータの値のための分離されたメソッドを作る

-----

```ruby
def height=(value)
  @height = value
end

def name=(value)
  @width = value
end
```

### Example

```ruby
ENGINEER = 0
SALESPERSON = 1
MANAGER = 2

def self.create(type)
  case type
  when ENGINEER
    Engineer.new
  when SALESPERSON
    Salesperson.new
  when MANAGER
   Manager.new
  else
    raise ArgumentError, "Incorrect type code value"
  end
end
```

渡されたパラメータを元にしたEmployeeのサブクラスを作りたい。  
ファクトリメソッドでコンストラクタを置き換えた結果になりうる

```ruby
def self.create_engineer
  Engineer.new
end

def self.create_salesperson
  Salesperson.new
end

def self.create_manager
  Manager.new
end
```

呼び出し側ではこのようにすれば良い

```ruby
kent = Employee.create(Employee::ENGINEER)

kent = Employee.create_engineer
```

## Preserve Whole Object

オブジェクトからいくつかの値を取得し、それらをパラメータとしてメソッド呼び出しへ渡す

```ruby
low = days_temperature_range.low
high = days_temperature_range.high
plan.within_range?(low, high)
```

代わりにオブジェクト全体を渡す

```ruby
plan.within_range?(days_temperature_range)
```

### Example

日中の最高気温と最低気温を記録する Room オブジェクトがあるとする。  
前もって予想した気温の範囲内に収まっているかどうか比較する

```ruby
class Room
  # ...
  def within_plan?(plan)
    low = days_temperature_range.low
    high = days_temperature_range.high
    plan.within_range?(low, high)
  end
end

class HeatingPlan
  # ...
  def within_range?(low, high)
    (low >= @range.low) && (high <= @range.high)
  end
end
```

渡した際に範囲についての情報を開封するよりも、範囲についてのオブジェクトを丸ごと渡してしまう  
この場合ではワンステップでできる。パラメータが必要になればなるほど、より少ないステップで実行できる  
まずパラメータのリストにオブジェクトを丸ごと追加する

```ruby
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
```

## Replace Parameter with Method

オブジェクトがメソッドを実行し、その結果をパラメータとしてメソッドへ渡す  

```ruby
base_price = @quantity * @item_price
level_of_discount = discount_level
final_price = discounted_price(base_price, level_of_discount)
```

パラメータを削除し、レシーバにメソッドを実行させる

```ruby
base_price = @quantity * @item_price
final_price = discounted_price(base_price)
```

### Example

```ruby
def price
  base_price = @quantity * @item_price
  level_of_discount = 1
  level_of_discount = 2 if @quantity > 100
  discounted_price(base_price, level_of_discount)
end

def discounted_price(base_price, level_of_discount)
  return base_price * 0.1 if level_of_discount == 2
  base_price * 0.05
end
```

- discount level の計算部分を切り出す
- discounted_price メソッド内でlevel_of_discount への参照部分をdiscount_level に置き換え
- Parameterを削除する
- 一時変数の削除
- 他のパラメータ、一時変数の削除
- price は単に discounted_price にbase_price を渡すだけになった
  - よって、discounted_price の中身をprice に移す

```ruby
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
```

## Introduce Parameter Object

パラメータのグループが一緒になっている。それらをオブジェクトに置き換える

```ruby
class Account
  def add_charge(base_price, tax_rate, imported)
    total = base_price + base_price * tax_rate
    total += base_price * 0.1 if imported
    @charges << total
  end
  
  def total_charge
    @charges.inject(0) { |total, charge| total + charge }
  end
end

# client code
account.add_charge(5, 0.1, true)
account.add_charge(12, 0.125, false)
# ...
total = account.total_charge
```

- base_price, tax_rate, imported が一緒になっているので、それらをCharge オブジェクトとしてグルーピングする
- Charge class はimmutable である。charge する値はコンストラクタでセットされ、値を更新するメソッドは他にはない
- add_charge のパラメータのリストにcharge を追加する
- パラメータを１つ削除してみる。代わりにオブジェクトを使用する
- 残りのパラメータも削除していく
- add_charge 内のtotal を計算する部分をCharge 側に移す



## Remove Setting Method

フィールドが作成時にセットされ他のものにはならない

フィールド用のセッティングメソッドを削除する

オブジェクトが作成されるときに一度だけフィールドをしたら以降は変えたくない、というのであれば、セッティングメソッドを提供すべきでない

```ruby
class Account
  def initialize(id)
    self.id = id
  end

  # you may have an attr_writer instead of this method - it
  # should be removed also
  def id=(value)
    @id = value
  end
end
```

変更が複雑か分離したメソッドを呼びたいのであれば、メソッドを作成する

```ruby
class Account
  def initialize(id)
    initialize_id(id)
  end

  def initialize_id(value)
    @id = "ZZ#{value}"
  end
end
```

## Hide Method

メソッドが他のクラスで使用されないのであれば、private にする


## Replace Constructor with Factory Method

オブジェクト作成時にシンプルなコンストラクションよりもより多くのことをしたいのであれば、コンストラクタをファクトリメソッドで置き換える

```ruby
class ProductController
  def create
    # ...
    @product = if imported
      ImportedProduct.new(base_price)
    else
      if base_price > 1000
        LuxuryProduct.new(base_price)
      else
        Product.new(base_price)
      end
    end
#...
  end
end
```

-----

```ruby
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
```

Replace Constructor with Factory Method は作成すべきオブジェクトの種類を決定する分岐的なロジックがあるときに主に用いられる

１箇所よりも多くの箇所で条件分岐が必要なら、Factory Method の出番だ

```ruby
class ProductController
  def create
    # ...
    @product = if imported
      ImportedProduct.new(base_price)
    else
      if base_price > 1000
        LuxuryProduct.new(base_price)
      else
        Product.new(base_price)
      end
    end
    #...
  end
end
```

このコードでは、作成するプロダクトの種類は、base_price とどこの国から輸入されている (imported) かによる

- コンストラクションのロジックを切り出す
- Product class にメソッドを移す。そちらがより適した場所なので

## Replace Error Code with Exception

エラーを表す特別なコードを返すメソッドがある

代わりに例外をraise する

```ruby
def withdraw(amount)
  return -1 if amount > @balance
  @balance -= amount
end
```

```ruby
def withdraw(amount)
  raise BalanceError.new if amount > @balance
  @balance -= amount
end
```

### Example
```ruby
class Account
  def withdraw(amount)
    return -1 if amount > @balance
    @balance -= amount
    return 0
  end
end
```

### Example: Caller Checks Condition Before Calling

呼び出し側

```ruby
if account.withdraw(amount) == -1
  handle_overdrawn
else
  do_the_usual_thing
end
```

-----

以下のように変更

```ruby
if !account.can_withdraw?
  handle_overdrawn
else
  do_the_usual_thing
end
```

error code を取り除いて例外を発生させる。なぜならその振る舞いは例外的であり、ガードクルーズを使用してチェックを入れないといけない

```ruby
class Account
  def withdraw(amount)
    raise ArgumentError.new if amount > @balance
    @balance -= amount
  end
end
```

モジュールを作ってassertion を使用する

```ruby
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
```

### Example: Caller Catches Exception

呼び出し側で例外をキャッチする。まず適切な例外を作成する

```ruby
class BalanceError < StandardError ; end
```

呼び出し側をこのように整える

```ruby
begin
  account.withdraw(amount)
  do_the_usual_thing
rescue BalanceError
  handle_overdrawn
end
```

``withdraw`` method で例外を使用する

```ruby
def withdraw(amount)
  raise BalanceError.new if amount > @balance
  @balance -= amount
end
```

### 呼び出し側が数多くあった場合・・・一時的な中間のメソッドを使用する

```ruby
if account.withdraw(amount) == -1
  handle_overdrawn
else
  do_the_usual_thing
end

class Account
  def withdraw(amount)
    return -1 if amount > @balance
    @balance -= amount
    return 0
  end
end
```

- まず例外を使用する新しいwithdraw メソッド (new_withdraw) を作成する
- 現在のwithdraw メソッドにて新しいメソッドを使用するように調整
- 各呼び出し側で新しいメソッドを呼ぶように置き換える
- そして古いメソッドを削除、新しいほうをリネーム

```ruby
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
```

## Replace Exception with Test

呼び出し側が初めにチェックする条件にて例外を発生させる

```ruby
def execute(command)
  command.prepare rescue nil
  command.execute
end
```

-----

呼び出し側でまずテストするように変更

```ruby
def execute(command)
  command.prepare if command.respond_to? :prepare
  command.execute
end
```

## Introduce Gateway

外部システムの複雑なAPIやリソースとシンプルな方法でやりとりしたい  
ゲートウェイを導入する

Rails はActiveRecord をゲートウェイとして、リレーショナルデータベースとやりとりする  
複数のWebサービスとの接続にYAML ファイルを使用したりする

### Example

```ruby
class Person
  attr_accessor :first_name, :last_name, :ssn

  def save
    url = URI.parse('http://www.example.com/person')
    request = Net::HTTP::Post.new(url.path)
    request.set_form_data(
      "first_name" => first_name,
      "last_name" => last_name,
      "ssn" => ssn
    )
    Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
  end
end

class Company
  attr_accessor :name, :tax_id

  def save
    url = URI.parse('http://www.example.com/companies')
    request = Net::HTTP::Get.new(url.path + "?name=#{name}&tax_id=#{tax_id}")
    Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
  end
end

class Laptop
  attr_accessor :assigned_to, :serial_number

  def save
    url = URI.parse('http://www.example.com/issued_laptop')
    request = Net::HTTP::Post.new(url.path)
    request.basic_auth 'username', 'password'
    request.set_form_data(
      "assigned_to" => assigned_to,
      "serial_number" => serial_number
    )
    Net::HTTP.new(url.host, url.port).start {|http| http.request(request) }
  end
end
```

`save` メソッドにおいてRuby の標準ライブラリである `net/http` を使用してはいるんだけど、Webサービスではそれぞれ利用方法が違うということ？

解決策としてはゲートウェイを作り、APIをシンプルにして負担を減らす、そして裏ではシンプルに `net/http` を移譲している

まずはゲートウェイを作成して、`Person` class で必要とされるメソッドを与えるだけ

```ruby
class Gateway
  attr_accessor :subject, :attributes, :to

  def self.save
    gateway = self.new
    yield gateway
    gateway.execute
  end

  def execute
    request = Net::HTTP::Post.new(url.path)
    attribute_hash = attributes.inject({}) do |result, attribute|
      result[attribute.to_s] = subject.send attribute
      result
    end
    request.set_form_data(attribute_hash)
    Net::HTTP.new(url.host, url,port).start { |http| http.request(request) }
  end

  def url
    URI.parse(to)
  end
end
```

`Person` class ではゲートウェイを利用する

```ruby
class Person
  attr_accessor :first_name, :last_name, :ssn

  def save
    Gateway.save do |persist|
      persist.subject = self
      persist.attributes = [:first_name, :last_name, :ssn]
      persist.to = 'http://www.example.com/person'
    end
  end
end
```

`Company` class をサポートできるようにする。`Company` class は`get`, `post` の両方をサポートする必要がある。  
そのためには`PostGateway`, `GetGateway` を導入する

```ruby
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
```

```ruby
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
```

`Person` class では`PostGateway` を使用する

```ruby
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
```

authentication を`Laptop` class でサポートする

```ruby
class Gateway
  # :authenticateを追加
  attr_accessor :subject, :attributes, :to, :authenticate

  def self.save
    gateway = self.new
    yield gateway
    gateway.execute
  end

  def execute
    # build_requestにurl を渡してリクエストを組み上げておいて・・・
    request = build_request(url)
    # authenticate があれば、basic_auth にユーザーネームとパスワードを渡す
    request.basic_auth 'username', 'password' if authenticate
    Net::HTTP.new(url.host, url,port).start do |http|
      http.request(request)
    end
  end

  def url
    URI.parse(to)
  end
end
```

```ruby
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
```

## Introduce Expression Builder

先ほど作成したゲートウェイを使用するが、それはもっと滑らか(fluent) にできる

```ruby
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
```

`http` というprivate method で `GatewayExpressionBuilder` のインスタンスを作成

```ruby
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
  end

  # 元々Person#save でやっていたことをこちらに移動
  def to(address)
    PostGateway.save do |persist|
      persist.subject = @subject
      persist.attributes = @attributes
      persist.to = address
    end
  end
end
```

今度は`Company` class を修正していくが、`Person` class では`http` というprivate method を用意していたが、それを`DomainObject` class に移動しているようだ

`http` method は共通のメソッドとして、ベースクラスへと切り出したほうが良い、という判断かな？

```ruby
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
```

そうなると今度は `Company` class では`PostGateway`, `GetGateway` の両方を使用できるように、`GatewayExpressionBuilder` が対応できるようにしたい

gateway というインスタンスを作成するようにする

```ruby
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

  def to(address)
    @gateway.save do |persist|
      persist.subject = @subject
      persist.attributes = @attributes
      persist.to = address
    end
  end
end
```

Laptop class では認証に関する処理をしなきゃいけない  
with_authentication というメソッドでそれを行う

```ruby
class Laptop < DomainObject
  attr_accessor :assigned_to, :serial_number

  def save
    http.post(:assigned_to, :serial_number).with_authentication.to(
      'http://www.example.com/issued_laptop'
    )
  end
end
```

GatewayExpressionBuilder に with_authentication method を追加する

```ruby
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

  # ここでインスタンスにセットしておいて・・・
  def with_authentication
    @with_authentication = true
  end

  def to(address)
    @gateway.save do |persist|
      persist.subject = @subject
      persist.attributes = @attributes
      # Gateway.save のyield で渡されるgateway(persist) のauthenticate にセットする
      persist.authenticate = @with_authentication
      persist.to = address
    end
  end
end
```
