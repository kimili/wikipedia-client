module Wikipedia
  class Page
    def initialize(json)
      require 'json'
      @json = json
      @data = JSON::load(json)
    end

    def page
      @data['query']['pages'].values.first if @data['query']['pages']
    end

    def content
      return nil unless page['revisions']
      page['revisions'].first['*']
    end

    def sanitized_content
      self.class.sanitize(content)
    end

    def redirect?
      content && content.match(/\#REDIRECT\s*\[\[(.*?)\]\]/i)
    end

    def redirect_title
      if matches = redirect?
        matches[1]
      end
    end

    def title
      page['title']
    end

    def fullurl
      page['fullurl']
    end

    def editurl
      page['editurl']
    end

    def text
      page['extract']
    end

    def extract
      return nil unless page['extract'] && page['extract'] != ''
      (page['extract'].split("=="))[0].strip
    end

    def sanitized_extract
      self.class.sanitize extract
    end

    def summary
      return nil unless content
      (content.split("=="))[0].strip
    end

    def sanitized_summary
      self.class.sanitize summary
    end

    def categories
      page['categories'].map {|c| c['title'] } if page['categories']
    end

    def links
      page['links'].map {|c| c['title'] } if page['links']
    end

    def extlinks
      page['extlinks'].map {|c| c['*'] } if page['extlinks']
    end

    def images
      page['images'].map {|c| c['title'] } if page['images']
    end

    def image_url
      page['imageinfo'].first['url'] if page['imageinfo']
    end

    def image_thumb_url
      page['imageinfo'].first['thumburl'] if page['imageinfo']
    end

    def image_thumb_dimensions
      return unless page.key?('imageinfo')
      {
        width: page['imageinfo'].first['thumbwidth'],
        height: page['imageinfo'].first['thumbheight']
      }
    end

    def image_descriptionurl
      page['imageinfo'].first['descriptionurl'] if page['imageinfo']
    end

    def image_urls
      image_metadata.map(&:image_url)
    end

    def image_descriptionurls
      image_metadata.map(&:image_descriptionurl)
    end

    def coordinates
      page['coordinates'].first.values if page['coordinates']
    end

    def raw_data
      @data
    end

    def image_metadata
      unless @cached_image_metadata
        if list = images
          filtered = list.select {|i| i =~ /:.+\.(jpg|jpeg|png|gif|svg)$/i && !i.include?("LinkFA-star") }
          @cached_image_metadata = filtered.map {|title| Wikipedia.find_image(title) }
        end
      end
      @cached_image_metadata || []
    end

    def templates
      page['templates'].map {|c| c['title'] } if page['templates']
    end

    def error?
      @data.key?('error')
    end

    def error
      @data['error']
    end

    def warnings?
      @data.key?('warnings')
    end

    def warnings
      @data['warnings']
    end

    def json
      @json
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def self.sanitize(s)
      return unless s

      # Transform language specific blocks
      s.gsub!(/\{\{lang[\-\|]([a-z]+)\|([^\|\{\}]+)(\|[^\{\}]+)?\}\}/i, '<span lang="\1">\2</span>')

      # strip anything inside curly braces!
      s.gsub!(/\{\{[^\{\}]+?\}\}[\;\,]?/, '') while s =~ /\{\{[^\{\}]+?\}\}[\;\,]?/

      # strip info box
      s.sub!(/^\{\|[^\{\}]+?\n\|\}\n/, '')

      # strip images and file links
      s.gsub!(/\[\[Image:[^\[\]]+?\]\]/, '')
      s.gsub!(/\[\[File:[^\[\]]+?\]\]/, '')
      
      # strip internal links
      s.gsub!(/\[\[([^\]\|]+)\|(.*?(?=\]\]))??\]\]/i, '\2')
      s.gsub!(/\[\[([^\]\|]+?)\]\]/, '\1')

      # convert bold/italic to html
      s.gsub!(/'''''(.+?)'''''/, '<b><i>\1</i></b>')
      s.gsub!(/'''(.+?)'''/, '<b>\1</b>')
      s.gsub!(/''(.+?)''/, '<i>\1</i>')

      # misc
      s.gsub!(/(\d)<ref[^<>]*>[\s\S]*?<\/ref>(\d)/, '\1 &ndash; \2')
      s.gsub!(/<ref[^<>]*>[\s\S]*?<\/ref>/, '')
      s.gsub!(/<!--[^>]+?-->/, '')
      s.gsub!(/\(\s+/, '(')
      s.gsub!('  ', ' ')
      s.strip!

      # create paragraphs
      sections = s.split("\n\n")
      s =
        if sections.size > 1
          sections.map { |paragraph| "<p>#{paragraph.strip}</p>" }.join("\n")
        else
          "<p>#{s}</p>"
        end

      s
    end
  end
end
