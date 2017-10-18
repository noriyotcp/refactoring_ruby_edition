# Chapter 7: Moving Features Between Objects
## Move Method
class Account
  # ...
  def overdraft_charge
    @account_type.overdraft_charge(@days_overdrawn)
  end

  def bank_charge
    result = 4.5
    if @days_overdrawn > 0
      result += @account_type.overdraft_charge(@days_overdrawn)
    end
    result
  end
  # ...
end

class AccountType
  def overdraft_charge(account)
    if premium?
      result = 10
      if account.days_overdrawn > 7
        result += (account.days_overdrawn - 7) * 0.85
      end
      result
    else
      account.days_overdrawn * 1.75
    end
  end
end

## Move Field
class Account
  # ...
  def interest_for_amount_days(amount, days)
    @account_type.interest_rate * amount * days / 365
  end
end

class AccountType
  attr_accessor :interest_rate
end

### Example: Using Self-Encapsulation
class Account
  # ...
  def interest_for_amount_days(amount, days)
    interest_rate * amount * days / 365
  end

  def interest_rate
    @account_type.interest_rate
  end
end

#### extend Forwardable
class Account
  extend Forwardable

  def_delegator :@account_type, :interest_rate, :interest_rate=
  # ...
  def interest_for_amount_days(amount, days)
    interest_rate * amount * days / 365
  end
end

## Extract Class
### Example
class TelephoneNumber
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

## Inline Class
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

class TelephoneNumber
  attr_accessor :area_code, :number
  def telephone_number
    '(' + area_code + ') ' + number
  end
end

## Hide Delegate
### #manager method
class Person
  attr_accessor :department

  def manager
    @department.manager
  end
end

class Department
  attr_reader :manager
  def initialize(manager)
    @manager = manager
  end
end

### using extend Forwardable
class Person
  extend Forwardable
  def_delegator :@department, :manager

  attr_accessor :department
end

class Department
  # same as above
end

manager = john.manager

## Remove Middle Man
class Person
  #...
  attr_reader :department
  # manager メソッドは削除
end

manager = john.department.manager

