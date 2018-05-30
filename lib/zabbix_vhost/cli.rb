require 'thor'
require 'json'
require_relative './config'
module ZabbixVhost
  class CLI < Thor


    desc "autodiscover PATH", "Autodiscover Vhost in absolute path"
    def autodiscover(path)


      configurations = ZabbixVhost::Config.dir_reader(path)


      data = configurations.collect do |c|
        {
          "{#DOMAIN}" => c.server_name
        }
      end

      print JSON.generate({data: data})


    end


    desc "get_domain_data PATH DOMAIN FUNCTION", "Get a information from the Vhost configuration find in the PATH"

    def get_domain_data(path,domain,function)

      c = ZabbixVhost::Config.find_in_dir(path, domain)

      print c.send(function)
    end

  end
end