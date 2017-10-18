# Chapter 1: Refactoring, a First Example
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

class ChildrensPrice
  include DefaultPrice

  def charge(days_rented)
    result = 1.5
    result += (days_rented - 3) * 1.5 if days_rented > 3
    result
  end
end


class Movie
  REGULAR = 0
  NEW_RELEASE = 1
  CHILDRENS = 2

  attr_reader :title
  attr_writer :price

  def initialize(title, price_code)
    @title, @price = title, price_code
  end

  def charge(days_rented)
    @price.charge(days_rented)
  end

  def frequent_renter_points(days_rented)
    @price.frequent_renter_points(days_rented)
  end
end

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

class Rental
  attr_reader :movie, :days_rented

  def initialize(movie, days_rented)
    @movie, @days_rented = movie, days_rented
  end

  def charge
    movie.charge(days_rented)
  end

  def frequent_renter_points
    movie.frequent_renter_points(days_rented)
  end
end

class Customer
  attr_reader :name

  def initialize(name)
    @name = name
    @rentals = []
  end

  def add_rental(arg)
    @rentals << arg
  end

  def statement
    result = "Rental Record for #{@name}\n"
    @rentals.each do |element|
      # show figures for this rental
      result += "\t" + element.movie.title + "\t" + element.charge.to_s + "\n"
    end
    # add footer lines
    result += "Amount owed is #{total_charge}\n"
    result += "You earned #{total_frequent_renter_points} frequent renter points"
    result
  end

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

  def amount_for(rental)
    rental.charge
  end

  private

  def total_charge
    @rentals.inject(0) { |sum, rental| sum + rental.charge }
    # @rentals.reduce(0) { |sum, rental| sum + rental.charge }
  end

  def total_frequent_renter_points
    @rentals.inject(0) { |sum, rental| sum + rental.frequent_renter_points }
    # @rentals.reduce(0) { |sum, rental| sum + rental.frequent_renter_points }
  end
end
