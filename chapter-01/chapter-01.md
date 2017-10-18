# Chapter 1: Refactoring, a First Example

## The Starting Point
## The First Step in Refactoring

## Decomposing and Redistributing the Statement Method

```ruby
class Customer
  # ...
  def statement
    total_amount, frequent_renter_points = 0, 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # this_amount = element.charge # ここを削除して
      # ...
      # ここのthis_amount をelement.charge に置き換える
      # result += "\t" + element.movie.title + "\t" + this_amount.to_s + "\n"
      # total_amount += this_amount
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      total_amount += element.charge
    end
    # ...
  end
  # ...
end
```

一時変数はあんまりやりすぎも良くない

### Extracting Frequent Renter Points

以下の部分をRental クラス内のメソッドへと切り出す

```ruby
class Customer
# ...
      # add frequent renter points
      frequent_renter_points += 1
      # add bonus for a two day new release rental
      if element.movie.price_code == Movie.NEW_RELEASE && element.days_rented > 1
        frequent_renter_points += 1
      end
      # ...
end
```
-----

```ruby
class Rental
# ...
  def frequent_renter_points
    movie.price_code == Movie.NEW_RELEASE && days_rented > 1 ? 2 : 1
  end
# ...
end
```

そして置き換える

```ruby
class Customer
# ...
    @rentals.each do |element|
      frequent_renter_points += element.frequent_renter_points # ここ！
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      total_amount += element.charge
    end
    # ...
end
```

### Removing Temps

一時変数は問題を起こしうるので、クエリメソッドで置きかえよう

Customer classの ``total_amount``, ``frequent_renter_points`` を置き換え

```ruby
  def statement
    total_amount, frequent_renter_points = 0, 0
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      frequent_renter_points += element.frequent_renter_points
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      total_amount += element.charge
    end
    # add footer lines
    result += "Amount owed is #{total_amount}\n"
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end
```

-----

total_amount の計算を、total_charge というプライベートメソッドに切り出す

```ruby
  def statement
    frequent_renter_points = 0 # total_amount を削除
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      frequent_renter_points += element.frequent_renter_points
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      # ここの行も削除
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n" # total_charge に置き換え
    result += "You earned #{frequent_renter_points} frequent renter points"
    result
  end

  def amount_for(rental)
    rental.charge
  end

  private

  def total_charge
    @rentals.inject(0) { |sum, rental| sum + rental.charge }
    # @rentals.reduce(0) { |sum, rental| sum + rental.charge }
  end
```

frequent_renter_points も、total_frequent_renter_points というプライベートメソッドに置き換え

```ruby
  def statement
    # frequent_renter_points を削除
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # ここ削除
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
      # ここの行も削除
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n" # total_charge に置き換え
    result += "You earned #{total_frequent_renter_points} frequent renter points" # ここ
    result
  end

  def amount_for(rental)
    rental.charge
  end

  private

  # ...

  def total_frequent_renter_points
    @rentals.inject(0) { |sum, rental| sum + rental.frequent_renter_points }
    # @rentals.reduce(0) { |sum, rental| sum + rental.frequent_renter_points }
  end
```

``html_statement`` method なんかp タグがおかしいんだけどまあいいか

```ruby
  def html_statement
    result = "<h1>Rental Record for <em>#{@name}</em></h1><p>\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "<br>\n"
    end
    # add footer lines
    result += "<p>You owed <em>#{total_charge}</em></p>\n"
    result += "On this rental you earned " +
              "<em>#{total_frequent_renter_points}</em> " +
              "frequent renter points</p>" +
    result
  end
```

## Replacing the Conditional Logic on Price Code with Polymorphism

case がイケてない。その中でMovie を参照しているので、Movie に移したほうがいいのでは

```ruby
class Movie
  # ...
  def charge(days_rented)
    result = 0
    case price_code
    when REGULAR
      result += 2
      result += (days_rented - 2) * 1.5 if days_rented > 2
    when NEW_RELEASE
      result += days_rented * 3
    when CHILDRENS
      result += 1.5
      result += (days_rented - 3) * 1.5 if days_rented > 3
    end
    result
  end
  # ...
end

class Rental
  # ...
  def charge
    movie.charge(days_rented)
  end
  # ...
end
```

-----

Movie#charge に貸出期間(days_rented) を渡さないといけなくなったが、case...when 内でMovie の種類を判別しようとするよりはマシ

同様にMovie#frequent_renter_points を作成
Rental の同名のメソッドでは、Movie のfrequent_renter_points を呼んで、day_rented を渡す


```ruby
class Movie
  # ...
  def frequent_renter_points(days_rented)
    (price_code == NEW_RELEASE && days_rented > 1) ? 2 : 1
  end
  # ...
end

class Rental
  # ...
  def frequent_renter_points
    movie.frequent_renter_points(days_rented)
  end
  # ...
end
```

### At Last...Inheritance

とうとう継承を使うのだが、Replace Type Code with State/Strategy を使用する  
Self Encapsulate Field セッターメソッドを作成し、ゲッターとセッターを使用する

```ruby
class Movie
  # ...
  attr_reader :price_code

  def price_code=(value)
    @price_code = value
  end

  def initialize(title, the_price_code)
    @title, self.price_code = title, the_price_code
  end
  # ...
end
```

``price_code`` というセッターメソッドを作って、それを初期化の際に呼ぶ

値段に関する空のクラスを作成しておいて、セッターメソッド内で判別し、``@price`` に格納

```ruby
class RegularPrice
end
class NewReleasePrice
end
class ChildrensPrice
end

class Movie
  # ...
  def price_code=(value)
    @price_code = value
    @price = case price_code
      when REGULAR
        RegularPrice.new
      when NEW_RELEASE
        NewReleasePrice.new
      when CHILDRENS
        ChildrensPrice.new
    end
  end
  # ...
end
```

今度は ``charge`` メソッドに目をつける

```ruby
  def charge(days_rented)
    result = 0
    case price_code
    when REGULAR
      result += 2
      result += (days_rented - 2) * 1.5 if days_rented > 2
    when NEW_RELEASE
      result += days_rented * 3
    when CHILDRENS
      result += 1.5
      result += (days_rented - 3) * 1.5 if days_rented > 3
    end
    result
  end
```

-----

この中でもcase...when による条件分岐をしている。それを他クラスに移す

```ruby
class RegularPrice
  def charge(days_rented)
    result = 2
    result += (days_rented - 2) * 1.5 if days_rented > 2
    result
  end
end

class NewReleasePrice
  def charge(days_rented)
    days_rented * 3
  end
end

class ChildrensPrice
  def charge(days_rented)
    result = 1.5
    result += (days_rented - 3) * 1.5 if days_rented > 3
    result
  end
end
```

そしてMovie#charge ではシンプルに ``@price`` のcharge メソッドを呼び出す

```ruby
class Movie
  # ...
  def charge(days_rented)
    @price.charge(days_rented)
  end
  # ...
end
```

今度は frequent_renter_points について

```ruby
  def frequent_renter_points(days_rented)
    (price_code == NEW_RELEASE && days_rented > 1) ? 2 : 1
  end
```

ChildrensPrice, RegularPrice に関しては同じでいいのだが、 NewReleasePrice についてはちょっとちがう

1 だけを返すDefaultPrice というモジュールを作成し、 RegularPrice, ChildrensPrice でそれをインクルードする。 NewReleasePrice では別途 frequent_renter_points を作成すれば良い

```ruby
module DefaultPrice
  def frequent_renter_points(days_rented)
    1
  end
end

class RegularPrice
  include DefaultPrice

  def charge(days_rented)
    result = 2
    result += (days_rented - 2) * 1.5 if days_rented > 2
    result
  end
end

class NewReleasePrice
  def charge(days_rented)
    days_rented * 3
  end

  def frequent_renter_points(days_rented)
    days_rented > 1 ? 2 : 1
  end
end
```

Movie でdelegator を作成

```ruby
class Movie
  # ...
  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
end
```

price_code による判別を ``price_code`` というセッターの中で行い、``@price`` というインスタンスを作成しておけば、あとはそこにメッセージを送るだけで良い


```ruby
class Movie
  # ...
  def price_code=(value)
    @price_code = value
    @price = case price_code
      when REGULAR
        RegularPrice.new
      when NEW_RELEASE
        NewReleasePrice.new
      when CHILDRENS
        ChildrensPrice.new
    end
  end
  # ...
end
```

-----

初期化と後から``price_code`` を変更するのは、現在こうなっている

```ruby
# ここで第２引数に定数を与えてインスタンス作成
movie = Movie.new("The Watchmen", Movie::NEW_REALEASE)
# 後からprice_code を変更する
movie.price_code = Movie::REGULAR
```

``price`` をアクセサとして用意する。そして ``price_code=(value)`` を削除（条件分岐とともに）

```ruby
class Movie
  REGULAR = 0
  NEW_RELEASE = 1
  CHILDRENS = 2

  attr_reader :title
  attr_writer :price

  # 初期化する際はインスタンスを渡すので price_code という名前だが...
  def initialize(title, price_code)
    # charge, frequent_renter_points が返すのは数値なので``@price`` というインスタンス変数に格納
    @title, @price = title, price_code
  end

  def charge(days_rented)
    @price.charge(days_rented)
  end

  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
end
```

```ruby
p movie = Movie.new("The Watchmen", NewReleasePrice.new)
p movie.charge(2)
p movie.frequent_renter_points(2)
p movie.price = RegularPrice.new
p movie.charge(2)
p movie.frequent_renter_points(2)
p movie.price = ChildrensPrice.new
p movie.charge(2)
p movie.frequent_renter_points(2)
# #<Movie:0x007fc55994ce08 @title="The Watchmen", @price=#<NewReleasePrice:0x007fc55994ce58>>
# 6
# 2
# #<RegularPrice:0x007fc55994c660>
# 2
# 1
# #<ChildrensPrice:0x007fc55994c200>
# 1.5
# 1
```
