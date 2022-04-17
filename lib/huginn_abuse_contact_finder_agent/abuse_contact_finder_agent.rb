module Agents
  class AbuseContactFinderAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule "never"

    description do
      <<-MD
      The Abuse Contact Finder agent fetches email address from the RIPE Database and creates an event.

      `debug` is used for verbose mode.

      `ip` for the ip wanted.

      `host` for the targeted hostname.

      `type` for the ban type.

      `logs` is not mandatory, just available if an email agent is after this one for completing for example an abuse report.

       If `emit_events` is set to `true`, the server response will be emitted as an Event. No data processing
       will be attempted by this Agent, so the Event's "body" value will always be raw text.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
              "messages": [
          
              ],
              "see_also": [
          
              ],
              "version": "2.0",
              "data_call_name": "abuse-contact-finder",
              "data_call_status": "supported",
              "cached": false,
              "data": {
                "abuse_contacts": [
                  "XXXXXXX@XXXXXXXXXXXXXXXX"
                ],
                "authoritative_rir": "lacnic",
                "latest_time": "2022-04-17T15:10:00",
                "earliest_time": "2022-04-17T15:10:00",
                "parameters": {
                  "resource": "XXXXXXXXXXXXXX"
                }
              },
              "query_id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
              "process_time": 3854,
              "server_id": "app145",
              "build_version": "live.2022.4.11.91",
              "status": "ok",
              "status_code": 200,
              "time": "2022-04-17T15:10:36.978754",
              "logs": ".....",
              "ip": "XXXXXXXXXXXXXX",
              "host": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
              "type": "XXX"
          }
    MD

    def default_options
      {
        'ip' => '',
        'host' => '',
        'type' => '',
        'debug' => 'false',
        'expected_receive_period_in_days' => '2',
        'logs' => '',
        'emit_events' => 'true'
      }
    end

    form_configurable :debug, type: :boolean
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :ip, type: :string
    form_configurable :host, type: :string
    form_configurable :type, type: :string
    form_configurable :logs, type: :string
    form_configurable :emit_events, type: :boolean

    def validate_options

      unless options['ip'].present?
        errors.add(:base, "ip is a required field")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          fetch
        end
      end
    end

    def check
      fetch
    end

    private

    def fetch

      uri = URI.parse("https://stat.ripe.net/data/abuse-contact-finder/data.json?resource=#{interpolated['ip']}")
      response = Net::HTTP.get_response(uri)

      log "request  status : #{response.code}"

      payload = JSON.parse(response.body)
  
      if interpolated['debug'] == 'true'
        log "response body : #{payload}"
      end

      payload[:logs] = "#{interpolated['logs']}"
      payload[:ip] = "#{interpolated['ip']}"
      payload[:host] = "#{interpolated['host']}"
      payload[:type] = "#{interpolated['type']}"
  
      if interpolated['emit_events'] == 'true'
        create_event :payload => payload
      end
    end
  end
end
