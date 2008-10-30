require 'flags_column'

ActiveRecord::Base.send :include, FlagsColumn
