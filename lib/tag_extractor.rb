module TagExtractor
  @@separator = nil

  def self.tag_separator=(s)
    @@separator = s
  end

  def self.tag_separator
    @@separator || raise(TagSeparatorError)
  end

  class StringExtractor
    attr_reader :source

    def initialize(source)
      @source = source
    end

    def extract_with_separator(separator = nil)
      @source.scan(get_regex(separator))
    end

    def extract(separator = nil)
      extract_with_separator(separator).collect { |t| t.slice!(0); t }
    end

    private
      def get_regex(separator = nil)
        tag_separator = separator || TagExtractor::tag_separator
        %r{(?:#{tag_separator})[a-zA-Z](?:\w|-)*}
      end
  end # StringExtractor

  class HTMLExtractor < StringExtractor
      def convert_tags_to_html_links(separator = nil, options = { class: nil }, &block)
        @source.gsub!(get_regex(separator)) { |name|
          link = block.call(name.slice(1..-1)) || ''
          '<a ' + (options[:class].nil? ? '' : 'class="' + options[:class] + '" ') + 'href="' + link  + '">' + name + '</a>'
        }
      end
      alias :linkify_tags :convert_tags_to_html_links
    end

  class TagSeparatorError < StandardError
    def initialize
      super "Could not find any tag separator"
    end
  end
end

class String
  def extract_tags(separator = nil)
    TagExtractor::StringExtractor.new(self).extract(separator)
  end

  def convert_tags_to_html_links(separator = nil, &block)
    TagExtractor::HTMLExtractor.new(self).convert_tags_to_html_links(separator, &block)
  end
  alias :linkify_tags :convert_tags_to_html_links
end
