require 'active_record'
require 'safe_attributes'

class Customer < ActiveRecord::Base
  # This safe attributes line is due to an actvive record error on the Customer
  # table. The table contains a column named `hash` which collides with the
  # ActiveRecord::Base#hash method. For mor info see:
  # https://github.com/rails/rails/issues/18338
  include SafeAttributes::Base
  bad_attribute_names :hash
end

class Subscription < ActiveRecord::Base
end

class Charge < ActiveRecord::Base
end

class Order < ActiveRecord::Base
end
