class ProductController
  attr_reader :base_price, :imported

  def initialize(base_price, imported=false)
    @base_price = base_price
    @imported = imported
  end

  def create
    # ...
    @product = Product.create(base_price, imported)
    #...
  end
end

class Product
  def initialize(base_price)
    @base_price = base_price
  end

  def total_price
    @base_price
  end

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

class LuxuryProduct < Product
  def total_price
    super + 0.1 * super
  end
end

class ImportedProduct < Product
  def total_price
    super + 0.25 * super
  end
end

p ProductController.new(1000, true).create
# #<ImportedProduct:0x007fd4cc874fa8 @base_price=1000>

p ProductController.new(10000, false).create
# #<LuxuryProduct:0x007fa711890930 @base_price=10000>

p ProductController.new(1000, false).create
# #<Product:0x007ff4c8048318 @base_price=1000>



