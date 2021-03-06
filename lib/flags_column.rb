module FlagsColumn
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def flags_column(attribute, flags, options = {})
      column = attribute.to_sym

      unless respond_to?(:flagged_columns)
        write_inheritable_attribute :flagged_columns, {}
        class_inheritable_reader :flagged_columns

        class_eval <<-EOV
          include FlagsColumn::InstanceMethods

          def self.flagged_column_names
            read_inheritable_attribute(:flagged_columns).keys
          end
        EOV

        alias_method_chain :method_missing, :flags
      end

      unless instance_methods.include?('after_initialize')
        class_eval <<-EOV
          def after_initialize
          end
        EOV
      end

      options_attribute = "#{column}_flags".to_sym
      write_inheritable_attribute(options_attribute, [])
      class_inheritable_reader options_attribute

      bit_flags_attribute = "#{column}_bit_flags".to_sym
      write_inheritable_attribute(bit_flags_attribute, {})
      class_inheritable_reader bit_flags_attribute

      bit_flags_inverted_attribute = "#{column}_bit_flags_inverted".to_sym
      write_inheritable_attribute(bit_flags_inverted_attribute, {})
      class_inheritable_reader bit_flags_inverted_attribute

      default_mask_attribute = "#{column}_default_mask".to_sym
      write_inheritable_attribute(default_mask_attribute, 0)
      class_inheritable_reader default_mask_attribute

      class_eval <<-EOV
        def self.mask_#{column}(*flags)
          bit_flags = #{bit_flags_attribute}

          flags.flatten.inject(0) do |n, name|
            n += bit_flags[name.to_sym]
          end
        end

        def self.unmask_#{column}(mask)
          bit_flags_inverted = #{bit_flags_inverted_attribute}

          bit_flags_inverted.inject([]) do |n, b|
            (mask & b.first) == b.first ? n.push(b.last) : n
          end
        end
      EOV

      initial_flags = options[:initial] && Array(options[:initial]).map(&:to_sym)
      accessible = !!options[:accessible]
      read_inheritable_attribute(:flagged_columns)[column] = { :flags => flags, :initial => initial_flags, :accessible => accessible }

      flags.symbolize_keys!.each do |name, position|
        mask = (1 << position)
        read_inheritable_attribute(options_attribute) << name
        read_inheritable_attribute(bit_flags_attribute)[name] = mask
        read_inheritable_attribute(bit_flags_inverted_attribute)[mask] = name

        if initial_flags && initial_flags.include?(name)
          write_inheritable_attribute(default_mask_attribute, read_inheritable_attribute(default_mask_attribute) + mask)
        end

        define_method("#{column}_#{name}?".to_sym) do
          flagged_value = self[column] || 0
          flagged_value[position].eql? 1
        end

        define_method("#{column}_#{name}".to_sym) do
          flagged_value = self[column] || 0
          flagged_value[position].eql? 1
        end

        define_method("#{column}_#{name}=".to_sym) do |v|
          flagged_value = self[column] || 0
          flag = ['true', '1', 'yes', 'ok'].include?(v.to_s.downcase)
          self[column] = flag ? flagged_value |= mask : flagged_value &= ~mask
        end

        attr_accessible "#{column}_#{name}".to_sym if accessible
      end

      ["#{column}_none", "#{column}_none?"].each do |method|
        define_method(method.to_sym) do
          flagged_value = self[column] || 0
          flagged_value == 0
        end
      end

      ["#{column}_all", "#{column}_all?"].each do |method|
        define_method(method.to_sym) do
          flagged_value = self[column] || 0
          flagged_value == self.class.send("mask_#{column}", *self.class.send("#{column}_flags".to_sym))
        end
      end

      define_method("#{column}_flags".to_sym) do
        self.class.send("unmask_#{column}".to_sym, self[column] || 0)
      end

      define_method("initialize_#{column}".to_sym) do
        if @new_record && self[column].nil? && !self.class.flagged_columns[column][:initial].nil?
          self[column] = self.class.send("#{column}_default_mask".to_sym)
        end
      end

      define_method("after_initialize_with_#{column}".to_sym) do
        send("after_initialize_without_#{column}".to_sym)
        send("initialize_#{column}".to_sym)
      end

      alias_method_chain :after_initialize, column
    end
  end

  module InstanceMethods
    def respond_to?(method, include_priv = false) #:nodoc:
      if method.to_s =~ /^(#{self.class.flagged_column_names.map(&:to_s).join('|')})_[^_]+_and_[^_]+/
        true
      else
        super(method, include_priv)
      end
    end

    protected

      def method_missing_with_flags(method, *args, &block) #:nodoc:
        unless column = self.class.flagged_column_names.find { |name| method.to_s =~ /^#{name}_[^_]+_and_[^_]+/ }
          return method_missing_without_flags(method, *args, &block)
        end

        options = self.class.flagged_columns[column]

        if method.to_s =~ /^#{column}_([a-z0-9_]+)(\?|\=)?$/
          anded_flags, suffix = $1, $2
          flags = anded_flags.split('_and_').map(&:to_sym)

          method_missing_without_flags(method, *args, &block) unless (flags - options[:flags].keys).empty?

          flagged_value = self[column] || 0
          mask = self.class.send("mask_#{column}".to_sym, *flags)

          if suffix == '='
            flag = ['true', '1', 'yes', 'ok'].include?(args.first.to_s.downcase)
            self[column] = flag ? flagged_value |= mask : flagged_value &= ~mask
          else
            (flagged_value & mask) == mask
          end
        else
          method_missing_without_flags(method, *args, &block)
        end
      end

  end
end

