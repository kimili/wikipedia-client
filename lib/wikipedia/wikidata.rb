module Wikipedia
  class Wikidata
    def initialize(json)
      require 'json'
      @json = json
      @data = JSON::load(json)
    end

    def entities
      return error if error?
      @data['entities'].values.first
    end

    def labels
      return error if error?
      entities['labels']
    end

    def label( lang = Configuration[:default_language] )
      return error if error?
      labels[lang]['value']
    end

    def error?
      @data.has_key?('error')
    end

    def error
      return nil unless error?
      @data['error']
    end

    def raw_data
      @data
    end
  end
end