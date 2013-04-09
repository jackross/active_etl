module ActiveETL
  class Runner

    class << self
      def queue
        :etl_runner
      end

      def run(*ids)
        self.new(Rails.application.config.active_etl, false, [ids].flatten).run
      end

      def run_async(*ids)
        self.new(Rails.application.config.active_etl, true, [ids].flatten).run
      end

      def perform(ids, async = false)
        unless async
          self.run(ids)
        else
          self.run_async(ids)
        end
      end
    end

    def initialize(etl_config, async, *ids)
      @etl_config = etl_config
      @ids = [ids].flatten
      @etl_base_model = etl_config[:defaults][:base_model]
      @etl_facts_chains = etl_config[:fact_chains]
      @etl_facts = etl_config[:tsorted_facts]
      @etl_dimensions = etl_config[:tsorted_dimensions]
      @async = async
      @batch_id, @batch_size = setup_batch
    end
  
    def run
      unless @async
        start_time = Time.now
        transform_facts
        finish_time = Time.now
        duration = finish_time - start_time
        puts "Finished transforming Batch: #{@batch_id} (#{@batch_size} ids) at #{finish_time} in #{duration} seconds (#{@batch_size / duration} ids per second)"
      else
        async_transform_facts
      end
    end

    def transform_dimensions
      @etl_dimensions.each do |fact|
        class_eval("#{dimension}Transformer").run
      end
    end
  
    def transform_facts
      class_eval("#{@etl_base_model}Transformer").run @batch_id
      @etl_facts.each do |fact|
        class_eval("#{fact}Transformer").run @batch_id
      end
    end
  
    def async_transform_facts
      class_eval("#{@etl_base_model}Transformer").run @batch_id
      @etl_fact_chains.each do |fact_chain|
        Resque.enqueue(ActiveETL::ChainRunner, fact_chain, @batch_id)
      end
    end
    
    def setup_batch
      batch_id = Loaders::Batch.create.id
      # insert all the @ids into Extractors::BatchData and Loaders::BatchData
      Extractors::BatchData.load batch_id, @ids
      Loaders::BatchData.load batch_id, @ids
      return batch_id, @ids.size
    end

  end
end