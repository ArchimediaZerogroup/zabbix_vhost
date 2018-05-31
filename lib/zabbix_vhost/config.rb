module ZabbixVhost
  class Config

    attr_accessor :file_path

    attr_reader :server_alias, :server_name

    def initialize(f)

      @file_path = f
      @server_alias = []
      @server_name = nil
      @ssl_active = nil
      parse

    end

    def parse
      @config_content = File.read(@file_path)
      ## Controlliamo se siamo in apache
      if_apache do
        @server_name = @config_content.match(/^\s*ServerName (?<server_name>.*)/)[:server_name]

        if @config_content.match(/^\s*ServerAlias/)
          @server_alias = @config_content.match(/^\s*ServerAlias (?<names>.*)/)[:names].split(" ")
        end

        @ssl_active = !@config_content.match(/443/).nil?
      end

      if @ssl_active
        @ssl_data = read_ssl_data
      end
    end


    def self.dir_reader(path)
      configuration_files = Dir.glob("#{path}/*")

      configurations = []

      configuration_files.each do |f|

        if File.file?(f)
          cfg = self.new(f)
          configurations << cfg
        end

      end

      configurations
    end

    ##
    # Cerca il dominio all'interno della cartella
    def self.find_in_dir(path, domain)
      dir_reader(path).select {|c| c.server_name == domain}.first
    end




    def ssl_active
      @ssl_active ? 1 : 0
    end

    def ssl_until_days
      return 0 unless @ssl_data
      @ssl_data[:days_until]
    end

    def ssl_issuer
      return nil unless @ssl_data
      @ssl_data[:issuer]
    end


    private

    def if_apache
      if @config_content.match(/^\s*ServerName/)
        yield
      end
    end

    def read_ssl_data

      if @ssl_active
        begin
          require "socket"
          require "openssl"

          host = @server_name

          # Il codice commentato si occupa di verificare veramente il certificato. non ci interessa in questo momento
          # ssl_context = OpenSSL::SSL::SSLContext.new
          # ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
          #
          # cert_store = OpenSSL::X509::Store.new
          # cert_store.set_default_paths
          # ssl_context.cert_store = cert_store

          tcp_client = TCPSocket.new(host, 443)
          # ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, ssl_context)
          ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)


          ssl_client.hostname = host
          ssl_client.connect
          cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
          ssl_client.sysclose
          tcp_client.close

          certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
          issuer = certprops.select {|name, data, type| name == "O"}.first[1]
          {
            valid_on: cert.not_before,
            valid_until: cert.not_after,
            days_until: (cert.not_after - Time.now).to_i / 86400,
            issuer: issuer
            # valid: (ssl_client.verify_result == 0)
          }
        rescue Exception => e
          puts "PROBLEMI ELABORAZIONE #{@server_name} SSL #{e.message} - "
        end
      end

    end

  end
end