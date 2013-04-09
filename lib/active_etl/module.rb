class Module
  alias :normal_const_missing :const_missing

  def const_missing(const_name, nesting = nil)
    begin
      puts "Module (#{self.name}) const_missing for const_name: #{const_name} Starting"
      return_val = normal_const_missing(const_name, nesting)
      puts "Module (#{self.name}) const_missing for const_name: #{const_name} Returning #{return_val}"
      return return_val
    rescue => e
      puts "Module (#{self.name}) const_missing for const_name: #{const_name} RESCUING"
      puts e
    end
  end
    
end