module ActiveRecord
  module ConnectionAdapters
    module Sqlserver
      module SchemaStatements
        def native_database_types
          @native_database_types ||= initialize_native_database_types.merge(:primary_key  => "int NOT NULL IDENTITY(1, 1) PRIMARY KEY NONCLUSTERED").freeze
        end
      end
    end
  end
end