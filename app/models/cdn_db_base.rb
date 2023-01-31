class CdnDbBase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :cdn
end