require 'tire/http/clients/faraday'

Tire.configure do
  url    AppConfig.elasticsearch_url
  logger Rails.root.join("log/tire_#{Rails.env}.log")

  Tire::HTTP::Client::Faraday.faraday_middleware = ->(fd) { fd.adapter :net_http_persistent }
  client Tire::HTTP::Client::Faraday

end

TireSettings = Hdo::Search::Settings
