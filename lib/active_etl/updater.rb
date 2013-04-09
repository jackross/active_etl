require 'tempfile'
require 'csv'

module ActiveETL
  module Updater

    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def attributes_protected_by_default
        []
      end

      def remove!(batch_id, column_name = :account_id)
        self.connection.execute "DELETE FROM #{self.table_name} WHERE EXISTS (SELECT * FROM stage.active_etl_batch_data bd WHERE bd.account_id = #{self.table_name}.#{column_name} AND bd.batch_id = #{batch_id})"
      end

      def load!(records)
        write(records)
      end

      def bulk_update!(batch_id, records)
        write records.map{|record| record.merge(:batch_id => batch_id)}
        cols = records.first.keys.reject{|k| k == :id}.map{|col| "#{col} = u.#{col}"}.join(", ")
        sql = <<-"SQL"
          UPDATE x SET
            #{cols}
          FROM #{self.table_name.gsub('_updater', '')} x
          INNER JOIN #{self.table_name} u ON u.id = x.id
          WHERE u.batch_id = #{batch_id};
        SQL
        self.connection.execute sql
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

