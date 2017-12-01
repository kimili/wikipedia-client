module Wikipedia
  class Wikidata
    def initialize(json)
      require 'json'
      @json = json
      @data = JSON::load(json)
    end

    def entities
      @data['entities'].values.first if @data['entities'] && @data['entities'].values
    end

    def labels
      entities['labels'] if entities['labels']
    end

    def label( lang = Configuration[:default_language] )
      labels[lang]['value'] if labels && labels[lang]
    end

    def descriptions
      entities['descriptions'] if entities['descriptions']
    end

    def description( lang = Configuration[:default_language] )
      labels[lang]['description'] if descriptions && labels[lang]
    end

    def sitelinks
      entities['sitelinks'] if entities['sitelinks']
    end

    def sitelink( lang = Configuration[:default_language] )
      return nil unless sitelinks
      sitelinks["#{lang}wiki"]['title'] if sitelinks["#{lang}wiki"].present?
    end

    def error?
      @data.has_key?('error')
    end

    def error
      @data['error'] if @data['error']
    end

    def raw_data
      @data
    end
  end
end
