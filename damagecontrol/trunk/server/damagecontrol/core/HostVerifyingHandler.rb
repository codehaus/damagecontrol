require 'webrick/httpstatus'

module DamageControl

  class HostVerifyingHandler
    attr_reader :host_verifier

    def initialize(host_verifier)
      @host_verifier = host_verifier
    end

    def error_message(client_hostname, client_ip)
      "This DamageControl server doesn't allow connections from #{client_hostname} / #{client_ip}"
    end

    def call(req, res)
      client_hostname = req.peeraddr[2]
      client_ip = req.peeraddr[3]
      raise WEBrick::HTTPStatus::Unauthorized, error_message(client_hostname, client_ip) unless host_verifier.allowed?(client_hostname, client_ip)
    end
  end

end
