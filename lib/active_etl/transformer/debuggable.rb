module ActiveETL
  module Transformer
    module Callbacks
      module Debuggable
        extend ActiveSupport::Concern

        included do
          before_extract lambda { puts "#{@model}: Before Extract For id: #{@id} at #{Time.now}" }
          after_extract lambda { puts "#{@model}: After Extract For id: #{@id} at #{Time.now}" }
          around_extract :do_around_extract

          before_transform_set lambda { puts "#{@model}: Before Transform Set For id: #{@id}" }
          after_transform_set lambda { puts "#{@model}: After Transform Set For id: #{@id}" }
          around_transform_set :do_around_transform_set

          before_transform_row lambda { puts "#{@model}: Before Transform Row For id: #{@id}" }
          after_transform_row lambda { puts "#{@model}: After Transform Row For id: #{@id}" }
          around_transform_row :do_around_transform_row

          before_remove lambda { puts "#{@model}: Before Remove For id: #{@id}" }
          after_remove lambda { puts "#{@model}: After Remove For id: #{@id}" }
          around_remove :do_around_remove

          before_load lambda { puts "#{@model}: Before Load For id: #{@id}" }
          after_load lambda { puts "#{@model}: After Load For id: #{@id}" }
          around_load :do_around_load
        end

        module ClassMethods
    
        end
  
        def do_around_extract; puts "#{@model}: Before Around Extract For id: #{@id}"; yield; puts "#{@model}: After Around Extract For id: #{@id}"; end
        def do_around_transform_set; puts "#{@model}: Before Around Transform Set For id: #{@id}"; yield; puts "#{@model}: After Around Transform Set For id: #{@id}"; end
        def do_around_transform_row; puts "#{@model}: Before Around Transform Row For id: #{@id}"; yield; puts "#{@model}: After Around Transform Row For id: #{@id}"; end
        def do_around_remove; puts "#{@model}: Before Around Remove For id: #{@id}"; yield; puts "#{@model}: After Around Remove For id: #{@id}"; end
        def do_around_load; puts "#{@model}: Before Around Load For id: #{@id}"; yield; puts "#{@model}: After Around Load For id: #{@id}"; end
      end
    end
  end
end
