module ActiveETL
  module Transformer
    class Dimension
      include ActiveETL::Transformer::Callbacks
      # include ActiveETL::Transformer::Callbacks::Debuggable

      delegate :extractor, :to => "self.class"
      delegate :loader, :to => "self.class"
      delegate :transformation, :to => "self.class"

      attr_reader :source_data

      class << self
        attr_reader :extractor, :loader, :transformation
    
        def set_extractor(extractor)
          @extractor = extractor
        end
    
        def set_loader(loader)
          @loader = loader
        end
    
        def set_transformation(transformation)
          @transformation = transformation
        end
    
        def inherited(sub_klass)
          transformation_klass = sub_klass.set_transformation klass_for(:transformation, sub_klass)
          extractor_klass = sub_klass.set_transformation klass_for(:extractor, sub_klass)
          loader_klass = sub_klass.set_transformation klass_for(:loader, sub_klass)
          
          sub_klass.set_transformation transformation_klass
          sub_klass.set_extractor extractor_klass
          sub_klass.set_loader loader_klass

          transformation_klass.set_extractor extractor_klass
          transformation_klass.set_loader loader_klass
        end
        
        def run
          self.new.run
        end

      end
      
      def initialize
        @source_data = []
        @transformed_data = []
        @model = self.class.name.demodulize.gsub('Transformer', '')
      end

      def run
        truncate!
        unless extract == 0
          @source_data.each_slice(1000).each do |rows|
            transform rows
            load!
          end
        end
      end

      def extract
        run_callbacks :extract do
          @source_data = self.class.extractor.extract_all.map(&:attributes)
          # puts "#{@source_data.size} records extracted at #{Time.now}"
        end
        @source_data.size
      end
      
      def transform(rows)
        transform_set rows
      end

      def transform_set(rows)
        run_callbacks :transform_set do
          run_callbacks :transform_rows do
            self.class.loader.transaction do
              @transformed_data = rows.map do |row|
                transform_row row
              end.compact
            end
          end
        end
      end

      def transform_row(row)
        run_callbacks :transform_row do
          puts "source: #{row['source']}"
          self.class.transformation.new(row).transformed_attributes
        end
      end

      def truncate!
        run_callbacks :remove do
          self.class.loader.truncate!
        end
      end

      def load!
        run_callbacks :load do
          self.class.loader.load @transformed_data
        end
      end
            
      private
      def self.klass_for(type, klass)
        model = klass.name.demodulize.gsub('Transformer', '')
        case type
          when :extractor
            class_eval("Extractors::#{model}")
          when :loader
            class_eval("Loaders::#{model}")
          when :transformation
            class_eval("Transformations::#{model}")
        end
      end

    end
  end
end
