module DamageControl

  class HostVerifier
    def initialize(allowed_client_ips=["127.0.0.1"], allowed_client_hostnames=["localhost"])
      @allowed_client_hostnames = allowed_client_hostnames
      @allowed_client_ips = allowed_client_ips
    end

    def allowed?(client_hostname, client_ip)
      !@allowed_client_hostnames.index(client_hostname).nil? || !@allowed_client_ips.index(client_ip).nil?
    end
  end

  class OpenHostVerifier
    def allowed?(client_hostname, client_ip)
      true
    end
  end
  
end
				      
