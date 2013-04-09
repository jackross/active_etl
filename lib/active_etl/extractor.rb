module ActiveETL
  module Extractor

    extend ActiveSupport::Concern
    # include DataUtilities::TableColumnAnalyzer

    included do
    end

    module ClassMethods
      
      def extract(batch_id, column_name = :account_id)
        joins("INNER JOIN data.active_etl_batch_data bd ON bd.account_id = #{self.table_name}.#{column_name} AND bd.batch_id = #{batch_id}")
      end
      
      def extract_all
        self
      end

      # def extract(ids, column_name = :account_id)
      #   self.connection.select_all where(column_name => ids)
      # end
      
    end
    
  end
end
