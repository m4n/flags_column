# encoding: utf-8

require "flags_column"
require "rails"

module FlagsColumn
  # @private
  class Railtie < Rails::Railtie
    initializer "flags_column.initialize" do
      ActiveSupport.on_load :active_record do
        include FlagsColumn::ActiveRecord
      end
    end
  end
end

