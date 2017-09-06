# Chapter 7: Moving Features Between Objects
## Move Method

```ruby
class Account
  # ...
  def overdraft_charge
    if @account_type.premium?
      result = 10
      result += (@days_overdrawn - 7) * 0.85 if @days_overdrawn > 7
      result
    else
      @days_overdrawn * 1.75
    end
  end

  def bank_charge
    result = 4.5
    result += overdraft_charge if @days_overdrawn > 0
    result
  end
  # ...
end
```

``overdraft_charge`` method を ``AccountType`` クラスへと移す

```ruby
class Account
  # ...
  def overdraft_charge
    # ロジックは AccountType のほうへ移したので、そちらのoverdraft_charge を呼ぶ
    # 引数に自身のオブジェクトを渡す
    @account_type.overdraft_charge(self)
  end

  def bank_charge
    result = 4.5
    if @days_overdrawn > 0
      result += @account_type.overdraft_charge(self)
    end
    result
  end
  # ...
end

class AccountType
  def overdraft_charge(account) # account オブジェクトをそのまま渡す
    if premium?
      result = 10
      if account.days_overdrawn > 7 # account.days_overdrawn を参照
        result += (account.days_overdrawn - 7) * 0.85
      end
      result
    else
      account.days_overdrawn * 1.75
    end
  end
end
```

## Move Field

状態と振る舞いをクラス間で移動させるのはリファクタリングの本質である

```ruby
class Account
  # ...
  def interest_for_amount_days(amount, days)
    @interest_rate * amount * days / 365
  end
end
```

``@interest_rate`` をAccountType へ移す

```ruby
class AccountType
  attr_accessor :interest_rate
end

class Account
  # ...
  def interest_for_amount_days(amount, days)
    @account_type.interest_rate * amount * days / 365
  end
end
```

### Example: Using Self-Encapsulation

``interest_rate`` 変数を使用するメソッドが多いなら、自己カプセル化する

```ruby
class Account
  # ...
  def interest_for_amount_days(amount, days)
    interest_rate * amount * days / 365
  end

  def interest_rate
    @account_type.interest_rate
  end
end
```

#### extend Forwardable

```ruby
class Account
  extend Forwardable

  def_delegator :@account_type, :interest_rate, :interest_rate=
  # ...
  def interest_for_amount_days(amount, days)
    interest_rate * amount * days / 365
  end
end
```

``def_delegator(accessor, method, ali = method) -> ()``

> [PARAM] accessor:
> 委譲先のオブジェクト
> [PARAM] method:
> 委譲先のメソッド
> [PARAM] ali:
> 委譲元のメソッド
> 委譲元のオブジェクトで ali が呼び出された場合に、 委譲先のオブジェクトの methodへ処理が委譲されるようになります。
>
> 委譲元と委譲先のメソッド名が同じ場合は, ali を省略することが可能です。
>
> def_delegator は def_instance_delegator の別名になります。

https://docs.ruby-lang.org/ja/latest/class/Forwardable.html#I_DEF_DELEGATOR

## Extract Class

そのクラスが抱えているデータやメソッドが多すぎる場合、クラスを切り分ける

### Example

```ruby
class Person
  # ...
  attr_reader :name
  attr_accessor :office_area_code
  attr_accessor :office_number
  def telephone_number
    '(' + @office_area_code + ') ' + @office_number
  end
end
```

電話番号の振る舞いを別のクラスへと隔離する

```ruby
class TelephoneNumber
  # area_code, number はこちらでもつ
  attr_accessor :area_code, :number

  def telephone_number
    '(' + area_code + ') ' + number
  end
end

class Person
  # ...
  attr_reader :name

  def initialize
    @office_telephone = TelephoneNumber.new
  end

  def office_area_code
    @office_telephone.area_code
  end

  def office_area_code=(arg)
    @office_telephone.area_code(arg)
  end
end
```

## Inline Class

Inline Class はExtract Class の逆である

```ruby
class Person
  attr_reader :name
  def initialize
    @office_telephone = TelephoneNumber.new
  end
  def telephone_number
    @office_telephone.telephone_number
  end
  def office_telephone
    @office_telephone
  end
end

# 電話番号の機能をこのクラスに切り出したけど
# そんなに重くもない。Person クラスにもたせてもいいのでは
class TelephoneNumber
  attr_accessor :area_code, :number
  def telephone_number
    '(' + area_code + ') ' + number
  end
end
```

-----

あくまで TelephoneNumber はarea_code, number を持ったまま
Person 側でそれらの属性へのゲッタとセッタを用意する

```ruby
class Person
  attr_reader :name

  def initialize
    @office_telephone = TelephoneNumber.new
  end

  def area_code
    @office_telephone.area_code
  end

  def area_code=(arg)
    @office_telephone.area_code = arg
  end

  def number
    @office_telephone.number
  end

  def number=(arg)
    @office_telephone.number = arg
  end

  def telephone_number
    @office_telephone.telephone_number
  end

  def office_telephone
    @office_telephone
  end
end

class TelephoneNumber
  attr_accessor :area_code, :number
  def telephone_number
    '(' + area_code + ') ' + number
  end
end
```

## Hide Delegate

カプセル化はオブジェクトが他のパーツをなるべく知らなくてもいいようにする

```ruby
class Person
  attr_accessor :department
end

class Department
  attr_reader :manager
  def initialize(manager)
    @manager = manager
  end
end
```

もしクライアント がperson のマネージャーを知りたい場合、``manager = john.department.manager``
としなければならない

クライアントが部署のことを知らなければならないので、クライアントから部署クラスを隠す

```ruby
class Person
  attr_accessor :department

  # この人のマネージャーを知るためのメソッド
  def manager
    @department.manager
  end
end

# extend Forwardable
class Person
  extend Forwardable

  def_delegator :@department, :manager

  attr_accessor :department

  def manager
    @department.manager
  end
end

manager = john.manager
```

## Remove Middle Man

Hide Delegate の例だと ``manager = john.manager`` と一見シンプルになっていいように見えるが、そのぶん移譲を使ったメソッドが増える

```ruby
class Person
  #...
  attr_reader :department
  # manager メソッドは削除
end
```

delegate のためのシンプルなアクセサを用意する

そして ``manager = john.department.manager``
デメテルの法則には違反してるかもだけど、こっちの方がシンプル

