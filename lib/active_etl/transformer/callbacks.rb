module ActiveETL
  module Transformer
    module Callbacks
      extend ActiveSupport::Concern

      included do
        extend ActiveModel::Callbacks
        define_model_callbacks :extract, :transform_row, :transform_rows, :transform_set, :remove, :load
      end

      module ClassMethods
      end
  
    end
  end
end
