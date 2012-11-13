# Public: TagExtractor module contains various classes to handle tag extraction and manipulation.
# The class uses the principles of separator and containers as a way to separate tags from the
# rest of the string.
#
# Examples
#
#   "#social, economy, #physics, #[web development]"
#   # Here we have 3 tags : social, physics, web development.
#   # '#' is the tag separator and [] are the containers,
#   # needed only when tags are composed of multiple words.
#
# author        - Gabriel Dehan (https://github.com/gabriel-dehan)
# documentation - https://github.com/gabriel-dehan/TagExtractor
# version       - 1.0.0
#
#   ______________
#  < Tag Extractor >
#   --------------
#          \ ^__^
#           \(00)\_______
#            (__)\  RUBY )\/\
#             ## ||----w |
#                ||     ||
#
# A minimal ruby library for tag extraction and manipulation.

module TagExtractor
  # Public: Constant to be passed to TagExtractor subclasses methods,
  # allowing you to default to the Global Separator you have set through tag_separator=(separator)
  GLOBAL_SEPARATOR    = nil

  @@separator         = GLOBAL_SEPARATOR

  # Public : Constant set with a default separator, namely a sharp symbol (#)
  DEFAULT_SEPARATOR = '#'

  # Public : Constant set with the default container, namely square brackets ([])
  @@default_container = DEFAULT_CONTAINER = '[]'

  @@container         = @@default_container

  class << self
    # Public: Sets the String tag separator.
    def tag_separator=(s)
      @@separator = s
    end

    # Public: Returns the String tag separator.
    def tag_separator
      @@separator || raise(TagSeparatorError)
    end

    # Public: Sets the String multi-words tag container.
    def words_container=(c)
      @@container = c
    end
    alias :multiwords_container= :words_container=

    # Public: Returns the String multi-words tag container.
    def words_container
      @@container || @@default_container
    end
    alias :multiwords_container :words_container
  end

  # Public: TagExtractor::StringExtractor class, allows tag extraction from a String.
  class StringExtractor
    # Public: Returns the original String.
    attr_reader :source

    # Public: Initialize a StringExtractor.
    #
    # source - A String from which to extract the tags.
    def initialize(source)
      @source = source
    end

    # Public: Extract tags, along with their separators, from the source.
    #
    # separator - a separator to use for tag extraction.
    #             If none specified, it will default to the global separator.
    # container - a container to use for tag extraction.
    #             If none specified, it will default to the default container.
    # opts      - A hash with options for the extraction (default: { multiword => true } ).
    #             :multiword - A boolean to indicate if multiple words tags are to extracted.
    #
    # Returns an Array of tags with separators : ["#tag1", "#[long tag]", "#tag2"]
    def extract_with_separator(separator = nil, container = nil, opts = { multiword: true })
      @source.scan(get_regex(separator, container, opts[:multiword]))
    end

    # Public: Extract tags, removing their separators.
    #
    # separator - A String separator to use for tag extraction.
    #             If none specified, it will default to the global separator.
    # container - A String container to use for tag extraction.
    #             If none specified, it will default to the default container.
    # opts      - A Hash with options for the extraction (default: { multiword => true } ).
    #             :multiword - A Boolean to indicate if multiple words tags are to be extracted.
    #
    # Returns an Array of tags without separators : ["tag1", "long tag", "tag2"]
    def extract(separator = nil, container = nil, opts = { multiword: true })
      tags = extract_with_separator(separator, container, opts)
      remove_separators_in(tags, container: container)
    end

    private
      # Private: provides the regexp used for scanning a tagful string.
      #
      # separator - The String separator used for tag extraction.
      # container - The String container used for tag extraction.
      # multiword - A Boolean to indicate if multiple words tags are to be extracted.
      #
      # Returns a Regexp.
      def get_regex(separator, container, multiword)
        # We get the default separator & containers if none were specified
        tag_separator = separator || TagExtractor::tag_separator
        tag_container = container || TagExtractor::words_container

        # Transforms the container string into an array like ['[', ']'].
        left, right = container_array(tag_container)

        # Word matching regex for simple and multiple words.
        mono_word   = '(?:[a-zA-Z](?:\w|-)*)'
        multi_words = '(?:[a-zA-Z](?:\w|-|\s)*)'

        # Escapes everything.
        left, right, tag_separator = [left, right, tag_separator].map { |s| Regexp::escape(s) }

        if multiword
          %r(#{tag_separator}(?:#{mono_word}|(?:#{left}{1}#{multi_words}#{right}{1})))
        else
          %r(#{tag_separator}(?:#{mono_word}))
        end
      end

      # Private: Remove tags separators and containers from a list of tags.
      #
      # tags - An Array of tags.
      # opts - A Hash of options (default: { container => nil }).
      #        :container - A String to specify the container from which to extract multiple words tags.
      #                     If none specified, it will default to the Default or Global words container.
      #
      # Returns an Array of cleaned tags.
      def remove_separators_in tags, opts = { container: nil }
        tag_container = opts[:container] || TagExtractor::words_container
        tags.collect { |t| t.slice!(0); remove_tags_container(t, tag_container) }
      end

      # Private: Remove tags container from a tag.
      #
      # t - The tag, as a String.
      # c - the container, as a String.
      #
      # Returns the cleaned tag.
      def remove_tags_container(t, c)
        l, r = container_array(c)
        t.gsub!(l, '')
        t.gsub!(r, '')
        t
      end

      # Private: Transforms the container string into an array.
      #
      # c - the container's String.
      #
      # Examples
      #
      #   container_array '[]' # => ['[',']']
      #
      # Returns an Array of two strings.
      def container_array(c)
        c = c || TagExtractor::words_container
        c = c.split ''
      end
  end # StringExtractor

  # Public: A class holding methods to handle tags extraction and manipulation from HTML Strings.
  # Inherits from StringExtractor.
  class HTMLExtractor < StringExtractor
    # Public: Add links around all tags in an HTML String.
    #
    # separator - A specific separator, as a String. If none specified, it defaults to the global separator.
    # container - A specific container, as a String. If none specified, it defaults to the default or global container.
    # options   - An Hash of options for the link extraction (default: { class => nil }).
    #             :class     - A String css class to add to the <a> link tag.
    #             :multiword - A Boolean to indicate if multiple words tags are to be extracted.
    # block     - A Block used to specify a link dynamicaly. It is passed the cleaned tag string and it should return a String to be injected in the href attribute.
    #
    # Examples
    #
    #   # Considering the following string has been used for instanciation :
    #   # 'This is a string with #tag1, #tag2'
    #   html_extractor.convert_tags_to_html_links('#', :class => 'tag tag-link') do |tag_string|
    #     "/tag/#{tag_string}.downcase"
    #   end
    #   # => 'This is a string with <a class="tag tag-link" href="/tag/tag2">#tag1</a>, <a class="tag tag-link" href="/tag/tag2">#tag2</a>'
    #
    # Returns an HTML String.
    def convert_tags_to_html_links(separator = nil, container = nil, options = { class: nil }, &block)
        multi = options[:multiword] || true
        @source.gsub!(get_regex(separator, container, multi)) { |name|
          name = remove_tags_container(name, container)
          link = block.call(name.slice(1..-1)) || ''
          '<a ' + (options[:class].nil? ? '' : 'class="' + options[:class] + '" ') + 'href="' + link  + '">' + name + '</a>'
        }
      end
      alias :linkify_tags :convert_tags_to_html_links
    end

  # Private : TagExtractor  specific Error and Exceptions.
  class TagSeparatorError < StandardError
    def initialize
      super "Could not find any tag separator"
    end
  end
end

class String
  # Public: Native String helper for TagExtractor::StringExtractor#extract_tags.
  #
  # separator      - a separator to use for tag extraction.
  #                  If none specified, it will default to the global separator.
  # container      - a container to use for tag extraction.
  #                  If none specified, it will default to the default container.
  # opts           - A hash with options for the extraction (default: { multiword => true } ).
  #                  :multiword - A boolean to indicate if multiple words tags are to extracted.
  # with_separator - A Boolean specifying if the tags are to be return with or without separators (default: false).
  #
  # Returns an Array of tags : ["#tag1", "#[long tag]", "#tag2"] or ["tag1", "long tag", "tag2"].
  def extract_tags(separator = nil, container = nil, opts = { multiword:  true }, with_separator = false)
    if with_separator
      TagExtractor::StringExtractor.new(self).extract_with_separator(separator, container, opts)
    else
      TagExtractor::StringExtractor.new(self).extract(separator, container, opts)
    end
  end

  # Public: Native String helper for TagExtractor::HTMLExtractor#convert_tags_to_html_links.
  # See API for TagExtractor::HTMLExtractor#convert_tags_to_html_links
  #
  # Returns an HTML String.
  def convert_tags_to_html_links(separator = nil, container = nil, opts = { multiword: true }, &block)
    TagExtractor::HTMLExtractor.new(self).convert_tags_to_html_links(separator, container, opts, &block)
  end
  alias :linkify_tags :convert_tags_to_html_links
end
