class SeedDump
  module DumpMethods
    include Enumeration

    def dump(records, options = {})
      return nil if records.count == 0

      io = open_io(options)

      rval = write_records_to_io(records, io, options)

      if options[:include_has_associations] && records.respond_to?(:reflect_on_all_associations)
        [:has_many, :has_one].each do |a|
          records.reflect_on_all_associations(a).each do |r|
            rval += write_records_to_io(r.klass, io, options.merge({references: true}))
          end
        end
      end

      rval

    ensure
        io.close if io.present?
    end

    private

    def dump_record(record, options)
      attribute_strings = []

      fk_syms = []
      # dump the belongs_to references, handling polymorphic
      if options[:references] && record.class.respond_to?(:reflect_on_all_associations)
        record.class.reflect_on_all_associations(:belongs_to).each do |r|
          assoc_name = r.name
          fk_syms << r.foreign_key.to_sym
          the_id = record.send(r.foreign_key)
          if r.polymorphic?
            fk_syms << r.foreign_type.to_sym
            attribute_strings << dump_belongs_to_reference(assoc_name, record.send(r.foreign_type).underscore, the_id, options)
          else
            attribute_strings << dump_belongs_to_reference(assoc_name, r.name, the_id, options)
          end
        end
      end

      # We select only string attribute names to avoid conflict
      # with the composite_primary_keys gem (it returns composite
      # primary key attribute names as hashes).
      record.attributes.select {|key| key.is_a?(String) || key.is_a?(Symbol) }.each do |attribute, value|
        attribute_strings << dump_attribute_new(attribute, value, options) unless options[:exclude].include?(attribute.to_sym) || fk_syms.include?(attribute.to_sym)
      end
  
      open_character, close_character = options[:import] ? ['[', ']'] : ['{', '}']

      "#{open_character}#{attribute_strings.join(", ")}#{close_character}"
    end

    def dump_belongs_to_reference(assoc_name, foreign_key_name, id, options)
      options[:import] ? "#{foreign_key_name}_#{id}" : "#{assoc_name}: #{foreign_key_name}_#{id}"
    end


    def dump_attribute_new(attribute, value, options)
      options[:import] ? value_to_s(value) : "#{attribute}: #{value_to_s(value)}"
    end

    def value_to_s(value)
      value = case value
              when BigDecimal, IPAddr
                value.to_s
              when Date, Time, DateTime
                value.to_s(:db)
              when Range
                range_to_string(value)
              when ->(v) { v.class.ancestors.map(&:to_s).include?('RGeo::Feature::Instance') }
                value.to_s
              else
                value
              end

      value.inspect
    end

    def range_to_string(object)
      from = object.begin.respond_to?(:infinite?) && object.begin.infinite? ? '' : object.begin
      to   = object.end.respond_to?(:infinite?) && object.end.infinite? ? '' : object.end
      "[#{from},#{to}#{object.exclude_end? ? ')' : ']'}"
    end

    def open_io(options)
      if options[:file].present?
        mode = options[:append] ? 'a+' : 'w+'

        File.open(options[:file], mode)
      else
        StringIO.new('', 'w+')
      end
    end

    def write_records_to_io(records, io, options)
      options[:exclude] ||= [:id, :created_at, :updated_at]


      method = options[:import] ? 'import' : 'create!'

      enumeration_method = if records.is_a?(ActiveRecord::Relation) || records.is_a?(Class)
                             :active_record_enumeration
                           else
                             :enumerable_enumeration
                           end

      if options[:references] && enumeration_method == :active_record_enumeration
        # keep track of the objects. It's just memory, right?
        io.write('(')
        send(enumeration_method, records, io, options.merge(id_only: true)) do |record_ids, last_batch|
          io.write(record_ids.join(", "))
        end
        io.write(') =  ')
      end

      io.write("#{model_for(records)}.#{method}(")

      if options[:import]
        io.write("[#{attribute_names(records, options).map {|name| name.to_sym.inspect}.join(', ')}], ")
      end

      io.write("[\n  ")


      send(enumeration_method, records, io, options) do |record_strings, last_batch|
        io.write(record_strings.join(",\n  "))

        io.write(",\n  ") unless last_batch
      end

      io.write("\n]#{active_record_import_options(options)})\n")

      if options[:file].present?
        nil
      else
        io.rewind
        io.read
      end
    end

    def active_record_import_options(options)
      return unless options[:import] && options[:import].is_a?(Hash)

      ', ' + options[:import].map { |key, value| "#{key}: #{value}" }.join(', ')
    end

    def attribute_names(records, options)
      attribute_names = if records.is_a?(ActiveRecord::Relation) || records.is_a?(Class)
                          records.attribute_names
                        else
                          records[0].attribute_names
                        end

      attribute_names.select {|name| !options[:exclude].include?(name.to_sym)}
    end

    def model_for(records)
      if records.is_a?(Class)
        records
      elsif records.respond_to?(:model)
        records.model
      else
        records[0].class
      end
    end

  end
end
