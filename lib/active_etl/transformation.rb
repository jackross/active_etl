module ActiveETL
  module Transformation

    extend ActiveSupport::Concern
    include ActiveModel::AttributeMethods

    included do
      # attribute_method_suffix  "="  # attr_writers
      # attribute_method_suffix  ""   # attr_readers

      delegate :extractor, :to => "self.class"
      delegate :loader, :to => "self.class"
    end

    module ClassMethods

      attr_reader :extractor, :loader
  
      def set_extractor(extractor)
        @extractor = extractor
      end
  
      def set_loader(loader)
        @loader = loader
      end
    
    end

    attr_reader :attributes
    
    # def id
    #   0
    # end

    def initialize(input_row)
      @attributes = input_row #.attributes
    end

    def include_record?
      true
    end

    def persisted?
      false
    end

    def transformed_attributes
      loader = self.class.loader
      if include_record?
        {}.tap{|h| loader.column_names.map(&:to_sym).each{|c| h[c] = self.send(c) if self.respond_to?(c)}}
      end
    end

    def output_record
      transformed_attributes
    end

    def coerce_boolean(attr)
      ((attr.nil?) || (attr == 0)) ? false : true
    end
    
    def created_at
      Time.now
    end

    def updated_at
      Time.now
    end

    private
    def attribute=(attr, value)
      @attributes[attr] = value
    end

    def attribute(attr)
      @attributes[attr]
    end

  end
end


