module ActiveETL
  class ChainRunner

    class << self
      def queue
        :etl_chain_runner
      end

      def perform(model_chain, batch_id)
        model_chain.each do |model|
          # start_time = Time.now
          class_eval("#{model}Transformer").run batch_id
          # finish_time = Time.now
          # puts "Finished transforming model: #{model} for id: #{id} at #{finish_time} in #{finish_time - start_time} seconds"
        end
      end
    end

  end
end