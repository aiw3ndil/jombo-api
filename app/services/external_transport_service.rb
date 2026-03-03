require 'net/http'
require 'json'

class ExternalTransportService
  DIGITRANSIT_ROUTING_URL = URI("https://api.digitransit.fi/routing/v2/finland/gtfs/v1")
  DIGITRANSIT_GEOCODING_URL = URI("https://api.digitransit.fi/geocoding/v1/search")

  def self.search(from, to)
    new.search(from, to)
  end

  def search(from, to)
    puts "DEBUG: ExternalTransportService.search(#{from}, #{to})"
    from_coords = geocode(from)
    to_coords = geocode(to)

    return [] unless from_coords && to_coords

    itineraries = fetch_itineraries(from_coords, to_coords)
    puts "DEBUG: Found #{itineraries.count} itineraries"
    format_itineraries(itineraries)
  end

  private

  def geocode(location_name)
    uri = DIGITRANSIT_GEOCODING_URL.dup
    uri.query = URI.encode_www_form({ text: location_name, size: 1 })
    
    response = get_request(uri)
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Geocoding failed: #{response.code} #{response.body}"
      return nil
    end

    data = JSON.parse(response.body)
    feature = data["features"]&.first
    return nil unless feature

    coords = feature["geometry"]["coordinates"]
    { lat: coords[1], lon: coords[0] }
  rescue => e
    Rails.logger.error "Geocoding error: #{e.message}"
    nil
  end

  def fetch_itineraries(from, to)
    query = <<~GRAPHQL
      {
        plan(
          from: {lat: #{from[:lat]}, lon: #{from[:lon]}}
          to: {lat: #{to[:lat]}, lon: #{to[:lon]}}
          numItineraries: 5
        ) {
          itineraries {
            startTime
            endTime
            duration
            legs {
              mode
              startTime
              endTime
              from { name }
              to { name }
              route {
                shortName
              }
            }
          }
        }
      }
    GRAPHQL

    response = post_request(DIGITRANSIT_ROUTING_URL, { query: query })
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "Routing failed: #{response.code} #{response.body}"
      return []
    end

    data = JSON.parse(response.body)
    data.dig("data", "plan", "itineraries") || []
  rescue => e
    Rails.logger.error "Routing error: #{e.message}"
    []
  end

  def format_itineraries(itineraries)
    itineraries.map do |itin|
      {
        type: "external_transport",
        start_time: Time.at(itin["startTime"] / 1000).utc,
        end_time: Time.at(itin["endTime"] / 1000).utc,
        duration: itin["duration"],
        legs: itin["legs"].map do |leg|
          {
            mode: leg["mode"],
            start_time: Time.at(leg["startTime"] / 1000).utc,
            end_time: Time.at(leg["endTime"] / 1000).utc,
            from: leg.dig("from", "name"),
            to: leg.dig("to", "name"),
            route: leg.dig("route", "shortName")
          }
        end
      }
    end
  end

  def get_request(uri)
    req = Net::HTTP::Get.new(uri)
    send_request(uri, req)
  end

  def post_request(uri, body)
    req = Net::HTTP::Post.new(uri)
    req.body = body.to_json
    req.content_type = 'application/json'
    send_request(uri, req)
  end

  def send_request(uri, req)
    # Use API key if present in environment
    if ENV['DIGITRANSIT_API_KEY'].present?
      req['digitransit-subscription-key'] = ENV['DIGITRANSIT_API_KEY']
    end

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end
  rescue => e
    Rails.logger.error "HTTP request failed: #{e.message}"
    nil
  end
end
