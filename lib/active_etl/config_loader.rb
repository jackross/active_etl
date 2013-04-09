module ActiveETL
  class ConfigLoader
    attr_accessor :base_config

    def initialize
      @base_config = self.class.load_config
    end

    def fact_sorter
      @fact_sorter ||= ActiveETL::Transformer::Sorter.new(facts)
    end

    def dimension_sorter
      @dimension_sorter ||= ActiveETL::Transformer::Sorter.new(dimensions)
    end

    def facts
      @facts ||= @base_config[:facts]
    end

    def fact_chains
      @fact_chains ||= fact_sorter.chains
    end

    def tsorted_facts
      @tsorted_facts ||= fact_sorter.tsorted_nodes
    end

    def dimensions
      @dimensions ||= @base_config[:dimensions]
    end

    def dimension_chains
      @dimension_chains ||= dimension_sorter.chains
    end

    def tsorted_dimensions
      @tsorted_dimensions ||= dimension_sorter.tsorted_nodes
    end

    def config
      @config ||= @base_config.merge(:fact_chains => fact_chains, :tsorted_facts => tsorted_facts, :dimension_chains => dimension_chains, :tsorted_dimensions => tsorted_dimensions)
    end

    class << self
      def load_config
        YAML.load_file(File.join(Rails.root, "config", "etl.yml"))[Rails.env].with_indifferent_access
      end
      
      def config
        self.new.config
      end
    end
  end
end