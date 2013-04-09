require 'tempfile'
require 'csv'

module ActiveETL
  module Loader

    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def attributes_protected_by_default
        []
      end

      def extract(batch_id, column_name = :account_id)
        joins("INNER JOIN stage.active_etl_batch_data bd ON bd.account_id = #{self.table_name}.#{column_name} AND bd.batch_id = #{batch_id}")
      end

      def remove!(batch_id, column_name = :account_id)
        # delete(where(column_name => ids))
        self.connection.execute "DELETE FROM #{self.table_name} WHERE EXISTS (SELECT * FROM stage.active_etl_batch_data bd WHERE bd.account_id = #{self.table_name}.#{column_name} AND bd.batch_id = #{batch_id})"
      end

      def truncate!
        self.connection.execute "TRUNCATE TABLE #{self.table_name}"
      end

      def bulk_update!(batch_id, records)
        Updaters.class_eval(self.name.demodulize).bulk_update! batch_id, records
      end

      def load_sql(records)
        sql = "INSERT INTO #{self.table_name} (#{records.first.keys.map(&:to_s).join(', ')}) VALUES "
        sql += records.map do |record|
          "(" +
          record.each.map do |attr, val|
            column = self.columns_hash[attr.to_s]
            self.connection.quote(column.type_cast(val), column)
          end.join(", ") +
          ")"
        end.join(", ")
        sql
      end

      def load!(records)
        write(records)
        # records.each_slice(100).each{|batch| self.connection.execute self.load_sql(batch)}
        # self.transaction do
          # create records
        # end
      end

      def load(records)
        self.transaction do
          create records
        end
        "loaded"
      end
      
      def write(records)
        base_name = self.table_name
        data_file_name = "#{base_name}.txt"
        format_file_path = Rails.root.join('tmp', "#{base_name}.fmt")
        create_format_file(format_file_path, records.first.keys) unless File.exists?(format_file_path)
        loader_table_name = "#{self.connection.instance_variable_get(:@connection_options)[:database]}.#{base_name}"
        this = self
        # File.open(Rails.root.join('tmp', data_file_name), "w+") do |data_file|
        Tempfile.open([base_name, '.txt']) do |data_file|
          csv = CSV.new(data_file, :col_sep => "<~>")
          records.each do |record|
            # ap record
            csv << record.each.map do |attr, val|
              column = this.columns_hash[attr.to_s]
              case val
              when Date, Time
                this.connection.quote(column.sql_type == "date" ? val.to_date : val)[1..-2]
              when true, false
                column.sql_type == "bit" ? (val ? 1 : 0) : column.type_cast(val)
              else column.type_cast(val)
              end
            end
          end
          # ap csv
          data_file.flush
          system "freebcp #{loader_table_name} in #{data_file.path} -f #{format_file_path} -U StageSchemaUser -P usgasecret -S 192.168.23.50:49406"
        end
      end
      
      def create_format_file(format_file_path, attrs)
        this = self
        File.open(format_file_path, "w+") do |f|
          f.puts("8.0", attrs.size)
          attrs.map(&:to_s).each.with_index do |attr, i|
            column = this.columns_hash[attr]
            ordinal_position = column.instance_variable_get(:@sqlserver_options)[:ordinal_position]
            collation = [:string, :text].include?(column.type) ? "SQL_Latin1_General_CP1_CI_AS" : '""'
            col_sep = i == attrs.size - 1 ? '"\n"' : '"<~>"'
            line = [i+1, 'SYBCHAR', 0, 1, col_sep, ordinal_position, attr, collation].join(" ")
            f.puts line
          end
        end
      end
    end

  end
end

