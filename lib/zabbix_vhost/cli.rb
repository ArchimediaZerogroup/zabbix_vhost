require 'thor'
require 'json'
require_relative './config'
module ZabbixVhost
  class CLI < Thor


    desc "autodiscover PATH", "Autodiscover Vhost in absolute path"

    def autodiscover(path)


      configurations = ZabbixVhost::Config.dir_reader(path)


      data = configurations.collect do |c|

        unless c.server_name.nil?
          {
            "{#DOMAIN}" => c.server_name,
            "{#CONFIG_FILE}" => c.file_path
          }
        end
      end.compact

      print JSON.generate({data: data})


    end


    desc "get_domain_data CONFIG_FILE FUNCTION", "Get a information from the Vhost configuration of CONFIG_FILE"

    def get_domain_data(config_file, function)

      c = ZabbixVhost::Config.new(config_file)

      print c.send(function)
    end

    desc "version", "Get version"

    def version
      puts ZabbixVhost::VERSION
    end

  end
end