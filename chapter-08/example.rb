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

p Currency.send(:new, "USD") == Currency.new("USD") # returns true
p Currency.send(:new, "USD").eql?(Currency.new("USD")) # returns true

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

# Refactor with Deprecation
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
