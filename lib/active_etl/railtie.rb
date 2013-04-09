module ActiveETL
  class Railtie < ::Rails::Railtie
    initializer "active_etl.configure_etl" do
      config.active_etl = ActiveETL::ConfigLoader.config
    end
    
    # config.autoload_paths += %W(#{config.root}/app/etl/transformers/)
    # config.autoload_paths += %W(#{config.root}/app/etl/transformers/**/)
  end
end