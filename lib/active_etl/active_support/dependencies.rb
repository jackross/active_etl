module ActiveSupport
  module Dependencies
    alias :normal_load_missing_constant :load_missing_constant

    def load_missing_constant(from_mod, const_name)
      # puts "load_missing_constant from_mod: #{from_mod}, const_name: #{const_name} Starting"
      begin
        return_val = normal_load_missing_constant(from_mod, const_name)
        # puts "load_missing_constant from_mod: #{from_mod}, const_name: #{const_name} Returning #{return_val}"
        return return_val
      rescue Exception => e
        # unless local_const_defined?(from_mod, const_name)        
          # puts "load_missing_constant from_mod: #{from_mod}, const_name: #{const_name} RESCUING"
          ap e
        # else
          # puts "Local const defined"
        # end
      end
      
    end
  end
end
