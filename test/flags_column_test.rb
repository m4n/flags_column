require 'test_helper'
require 'active_record'
require 'mocha'
require File.join(File.dirname(__FILE__), '../init')

# http://muness.blogspot.com/2006/12/unit-testing-rails-activerecord-classes.html
class Test::Unit::TestCase
  class ActiveRecordUnitTestHelper
    attr_accessor :klass

    def initialize(klass)
      self.klass = klass
      self
    end

    def where(attributes)
      klass.stubs(:columns).returns(columns(attributes))
      instance = klass.new(attributes)
      instance.id = attributes[:id] if attributes[:id] #the id attributes works differently on active record classes
      instance
    end

    protected

      def columns(attributes)
        attributes.keys.collect { |attribute| column attribute.to_s, attributes[attribute] }
      end

      def column(column_name, value)
        ActiveRecord::ConnectionAdapters::Column.new(column_name, nil, ActiveRecordUnitTestHelper.active_record_type(value.class), false)
      end

      def self.active_record_type(klass)
        return case klass.name
          when "Fixnum"         then "integer"
          when "Float"          then "float"
          when "Time"           then "time"
          when "Date"           then "date"
          when "String"         then "string"
          when "Object"         then "boolean"
        end
      end
  end

  def disconnected(klass)
    ActiveRecordUnitTestHelper.new(klass)
  end

  def assert_same_array_elements(left, right, msg = nil)
    assert (left - right).empty? && (right - left).empty?, msg
  end

  def choose(n, k)
    return [[]] if n.nil? || n.empty? && k == 0
    return [] if n.nil? || n.empty? && k > 0
    return [[]] if n.size > 0 && k == 0
    c2 = n.clone
    c2.pop
    new_element = n.clone.pop
    choose(c2, k) + append_all(choose(c2, k-1), new_element)
  end

  def append_all(lists, element)
    lists.map { |l| l << element }
  end

end

# our test model
class Model < ActiveRecord::Base
  flags_column :visible_to,
               { :admins => 0, :members => 1, :friends => 2 },
               :initial => [:members, :friends]

  flags_column :notify_when,
               { :created => 2, :updated => 4, :deleted => 7, :purged => 13 }
end

class FlagsColumnTest < Test::Unit::TestCase # ActiveSupport::TestCase
  def test_class_should_respond_to_flagged_columns
    assert Model.respond_to?(:flagged_columns)
  end

  def test_class_should_respond_to_flagged_column_names
    assert Model.respond_to?(:flagged_column_names)
  end

  def test_flagged_columns_should_have_the_expected_keys
    assert_same_array_elements [:visible_to, :notify_when], Model.flagged_columns.keys
  end

  def test_flagged_columns_keys_should_equal_flagged_column_names
    assert_same_array_elements Model.flagged_columns.keys, Model.flagged_column_names
  end

  def test_flagged_column_flags_should_have_expected_flags
    expected = { :visible_to => [:admins, :members, :friends], :notify_when => [:created, :updated, :deleted, :purged] }

    Model.flagged_columns.each { |name, options| assert_same_array_elements(options[:flags].keys, expected[name]) }
  end

  def test_flagged_column_flags_should_have_expected_initials
    expected = { :visible_to => [:members, :friends], :notify_when => [] }

    Model.flagged_columns.each { |name, options| assert_same_array_elements(options[:initial], expected[name]) }
  end

  def test_class_should_respond_to_flags_column_name_plus_flags
    assert Model.flagged_column_names.all? { |name| Model.respond_to?("#{name}_flags".to_sym) }
  end

  def test_class_should_respond_to_flags_column_name_plus_bit_flags
    assert Model.flagged_column_names.all? { |name| Model.respond_to?("#{name}_bit_flags".to_sym) }
  end

  def test_class_should_respond_to_flags_column_name_plus_default_mask
    assert Model.flagged_column_names.all? { |name| Model.respond_to?("#{name}_default_mask".to_sym) }
  end

  def test_class_should_respond_to_mask_plus_flags_column_name
    assert Model.flagged_column_names.all? { |name| Model.respond_to?("mask_#{name}".to_sym) }
  end

  def test_class_should_respond_to_unmask_plus_flags_column_name
    assert Model.flagged_column_names.all? { |name| Model.respond_to?("unmask_#{name}".to_sym) }
  end

  def test_instance_should_respond_to_flags_column_name_plus_flags
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)
    assert model.class.flagged_column_names.all? { |name| model.respond_to?("#{name}_flags".to_sym) }
  end

  def test_instance_should_respond_to_flags_column_name_plus_all
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)
    assert model.class.flagged_column_names.all? { |name| model.respond_to?("#{name}_all".to_sym) && model.respond_to?("#{name}_all?".to_sym) }
  end

  def test_instance_should_respond_to_flags_column_name_plus_none
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)
    assert model.class.flagged_column_names.all? { |name| model.respond_to?("#{name}_none".to_sym) && model.respond_to?("#{name}_none?".to_sym) }
  end

  def test_instance_should_respond_to_flags_column_name_plus_flag_getters_and_setters
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)
    assert model.class.flagged_columns.all? { |name, options| options[:flags].keys.all? { |flag| model.respond_to?("#{name}_#{flag}".to_sym) && model.respond_to?("#{name}_#{flag}?".to_sym) && model.respond_to?("#{name}_#{flag}=".to_sym) } }
  end

  def test_instance_should_respond_to_flags_column_name_plus_anded_flags_getters_and_setters
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    assert model.class.flagged_columns.all? { |name, options|
      anded_flags = options[:flags].keys.map(&:to_s).join('_and_')
      model.respond_to?("#{name}_#{anded_flags}".to_sym) && model.respond_to?("#{name}_#{anded_flags}?".to_sym) && model.respond_to?("#{name}_#{anded_flags}=".to_sym)
    }
  end

  def test_new_instance_should_have_the_right_initial_flags_set
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)
    model.class.flagged_columns.each { |name, options| assert_same_array_elements(model.class.flagged_columns[name][:initial], model.send("#{name}_flags".to_sym)) }
  end

  def test_all_flags_set_to_false_should_all_getter_return_false
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      options[:flags].keys.each do |flag|
        model.send("#{name}_#{flag}=", false)
      end

      assert !model.send("#{name}_all?")
    end
  end

  def test_all_flags_set_to_false_should_none_getter_return_true
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      options[:flags].keys.each do |flag|
        model.send("#{name}_#{flag}=", false)
      end

      assert model.send("#{name}_none?")
    end
  end

  def test_all_flags_set_to_true_should_all_getter_return_true
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      options[:flags].keys.each do |flag|
        model.send("#{name}_#{flag}=", true)
      end

      assert model.send("#{name}_all?")
    end
  end

  def test_all_flags_set_to_true_should_none_getter_return_false
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      options[:flags].keys.each do |flag|
        model.send("#{name}_#{flag}=", true)
      end

      assert !model.send("#{name}_none?")
    end
  end

  def test_only_one_flag_set_to_true_should_all_getter_return_false
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      options[:flags].keys.each do |flag|
        model.send("#{name}_#{flag}=", false)
      end

      model.send("#{name}_#{options[:flags].keys.first}=", true)

      assert !model.send("#{name}_all?")
    end
  end

  def test_only_one_flag_set_to_true_should_none_getter_return_false
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      options[:flags].keys.each do |flag|
        model.send("#{name}_#{flag}=", false)
      end

      model.send("#{name}_#{options[:flags].keys.first}=", true)

      assert !model.send("#{name}_none?")
    end
  end

  def test_assigned_flags_should_equal_expected_flags
    model = disconnected(Model).where(:visible_to => nil, :notify_when => nil)

    model.class.flagged_columns.each do |name, options|
      flags = options[:flags].keys

      (1..flags.size).to_a.each do |k|
        combinations = choose(flags, k)

        combinations.each do |combination|
          reset_all_flags_to_false(model)

          combination.each do |flag|
            model.send("#{name}_#{flag}=", true)
          end

          assert_same_array_elements combination, model.send("#{name}_flags".to_sym), combination.inspect + ' ' + model.send("#{name}_flags".to_sym).inspect
          assert model.send("#{name}_#{combination.map(&:to_s).join('_and_')}?".to_sym)
        end
      end
    end
  end

  private

    def reset_all_flags_to_false(model)
      model.class.flagged_columns.each do |name, options|
        options[:flags].keys.each do |flag|
          model.send("#{name}_#{flag}=", false)
        end
      end
    end
end

