require 'json'

module Nudge
  class Notification
    attr_reader :payload

    def initialize(payload)
      @payload = payload
    end

    def to_json
      @payload.to_json
    end

    def self.alert(alert,
                   badge: nil,
                   sound: nil,
                   content_available: nil,
                   category: nil,
                   custom: nil)
      build({ alert: alert,
              badge: badge,
              sound: sound,
              content_available: content_available,
              category: category }, custom)
    end

    def self.silent(custom: nil)
      build({ content_available: 1 }, custom)
    end

    private

    def self.build(aps_args, custom_args)
      aps_args = underscore_to_dash(aps_args)
      payload = { aps: aps_args }.merge(custom_args || {})
      payload[:aps].delete_if { |k, v| v.nil? }
      payload.delete_if { |k, v| v.nil? }
      Notification.new(payload)
    end

    def self.underscore_to_dash(hash)
      Hash[hash.map { |k, v| [k.to_s.gsub('_', '-').to_sym, v] }]
    end
  end
end
