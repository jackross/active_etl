module ActiveETL
  module ModuleConstMissing

    def const_missing(const_name, nesting = nil)
      # puts "In const_missing for #{const_name}"
      begin
        self.handle_return_val super
      rescue Exception => e
        self.handle_return_val e
      end
    end

    def handle_return_val(return_val)
      # puts "In handle_return_val for #{self} returning #{return_val}"
      case return_val
        when NameError
          self.handle_klass_name return_val.missing_name()
        when Class 
          if (return_val.name.deconstantize == self.name)
            return_val
          else
            self.handle_klass_name return_val.name
          end
        else
          return_val
      end
    end

    def handle_klass_name(klass_name)
      mod_name_to_include = self.name.singularize
      self.create_klass(klass_name.demodulize, self.superklass) do
        include ActiveETL.module_eval(mod_name_to_include)
      end
    end

    def create_klass(klass_name, superklass, &block)
      klass = Class.new superklass, &block
      self.const_set(klass_name, klass).tap{|c| puts "Created #{c.name}"}
    end

    def superklass
      key = self.to_s.downcase.to_sym
      Connections.module_eval("#{Rails.application.config.active_etl[:defaults][key][:connection]}")
    end

  end
end