module ActiveETL
  module Transformer
    class Base
      include ActiveETL::Transformer::Callbacks
      # include ActiveETL::Transformer::Callbacks::Debuggable

      delegate :extractor, :to => "self.class"
      delegate :loader, :to => "self.class"
      delegate :transformation, :to => "self.class"

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
        
        def run(batch_id)
          self.new(batch_id).run
        end

      end
      
      def initialize(batch_id)
        @batch_id = batch_id
        @source_data = []
        @transformed_data = []
        @model = self.class.name.demodulize.gsub('Transformer', '')
      end

      def run
        unless extract == 0
          transform
          remove! if @model == 'Account'
          load!
        end
      end

      def extract
        run_callbacks :extract do
          @source_data = self.class.extractor.extract(@batch_id).map(&:attributes)
          # puts "#{@source_data.size} records extracted at #{Time.now}"
        end
        @source_data.size
      end
      
      def transform
        transform_set
      end

      def transform_set
        run_callbacks :transform_set do
          run_callbacks :transform_rows do
            self.class.loader.transaction do
              @transformed_data = @source_data.map do |row|
                transform_row row
              end.compact
            end
          end
        end
      end

      def transform_row(row)
        run_callbacks :transform_row do
          self.class.transformation.new(row).transformed_attributes
        end
      end

      def remove!
        run_callbacks :remove do
          self.class.loader.remove! @batch_id
        end
      end

      def load!
        run_callbacks :load do
          self.class.loader.load! @transformed_data
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
