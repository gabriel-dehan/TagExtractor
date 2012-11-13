require_relative '../lib/tag_extractor.rb'

describe TagExtractor do
  describe 'for a String' do
    let(:sharp_tags) { %w(#tag1 #Tag2 #tAg3 #foo-bar #foo #bar #Per) }
    let(:at_tags) { %w(@share) }
    let(:multiwords_tags) { ['#[long tag1]', '#[long tag2]'] }
    let(:bracket_multiwords_tags) { ['#{long tag3}', '#{long tag4}'] }
    let(:source) { "Le petit #{sharp_tags[0]}, #{sharp_tags[1]}, #{sharp_tags[2]} !#1 !## ## #{sharp_tags[3]} #{sharp_tags[4]} #{sharp_tags[5]}, #1we #{at_tags[0]}, #{sharp_tags[6]} #{multiwords_tags[0]} #{multiwords_tags[1]} #{bracket_multiwords_tags[0]}, #{bracket_multiwords_tags[1]}" }

    describe TagExtractor::StringExtractor do
      let(:content) { TagExtractor::StringExtractor.new(source) }
      it 'should have a source of type string' do
        content.source.should be_kind_of String
      end

      describe '#extract_with_separator method' do
        specify 'if no tag separator is set' do
          ->{ content.extract_with_separator }.should raise_error(TagExtractor::TagSeparatorError)
        end

        specify 'if no word container is set' do
          TagExtractor::words_container.should == '[]'
        end

        specify 'if a tag separator is set' do
          content.extract_with_separator(TagExtractor::DEFAULT_SEPARATOR, TagExtractor::words_container, { multiword: false }).first[0].should == '#'
        end

        specify 'if a tag separator is explicitly send' do
          content.extract_with_separator('@', TagExtractor::words_container, { multiword: false }).first[0].should == '@'
        end

        it 'should return all the tags' do
          TagExtractor.tag_separator = '#'
          content.extract_with_separator(TagExtractor::GLOBAL_SEPARATOR, TagExtractor::words_container, { multiword: false }).should == sharp_tags
          content.extract_with_separator('@', TagExtractor::words_container, { multiword: false }).should == at_tags
        end

        describe 'multiwords tag extraction' do
          before do
            require 'set'
            @bracket_multiwords_tags = bracket_multiwords_tags.to_set
            @multiwords_tags = multiwords_tags.to_set
            TagExtractor.words_container = nil
          end
          specify 'with a global separator' do
            TagExtractor.tag_separator = '#'
            TagExtractor.words_container = '{}'
            tags = content.extract_with_separator.to_set
            @bracket_multiwords_tags.should be_subset(tags)
          end

          describe 'with a given separator' do
            specify 'using the default word container' do
              tags = content.extract_with_separator('#').to_set
              @multiwords_tags.should be_subset(tags)
            end

            specify 'using a global word container' do
              TagExtractor.multiwords_container = '{}'
              tags = content.extract_with_separator('#').to_set
              @bracket_multiwords_tags.should be_subset(tags)
            end

            specify 'using a given word container' do
              tags = content.extract_with_separator('#', '{}').to_set
              @bracket_multiwords_tags.should be_subset(tags)
            end
          end
        end

      end # extract_with_separator method

      describe '#extract method' do
        it 'should return all the tags without the separator' do
          TagExtractor.tag_separator = '#'
          content.extract(nil, nil, { multiword: false }).should == sharp_tags.collect { |t| t.slice!(0); t }
          TagExtractor.tag_separator = '@'
          content.extract(nil, nil, { multiword: false }).should == at_tags.collect { |t| t.slice!(0); t }
        end
        it 'should not return bad tags' do
          TagExtractor.tag_separator = '#'
          content.extract.should_not include('1we')
          content.extract.should_not include('##')
          content.extract.should_not include('!#1')
        end

        specify 'multiwords tag extraction' do
          require 'set'
          tags = content.extract('#', '{}').to_set
          bracket_multiwords_tags.remove_tags_container('{}').collect { |t| t.slice!(0); t }.to_set.should be_subset(tags)
        end
      end # extract
    end # StringExtractor

    describe TagExtractor::HTMLExtractor do
      let(:html_extractor) { TagExtractor::HTMLExtractor.new('This is a string with #tag1, #tag2, #3wrongtag') }
      it 'should inherit from StringExtractor' do
        html_extractor.class.superclass.should == TagExtractor::StringExtractor
      end
      describe '#convert_tags_to_html_links method' do
        it 'should wraps tags into html links' do
          linkified = html_extractor.convert_tags_to_html_links('#') { }
          linkified.should == "This is a string with <a href=\"\">#tag1</a>, <a href=\"\">#tag2</a>, #3wrongtag"
        end
        it 'can be passed a css class' do
          linkified = html_extractor.convert_tags_to_html_links('#', '[]', :class => 'my_class') { }
          linkified.should == "This is a string with <a class=\"my_class\" href=\"\">#tag1</a>, <a class=\"my_class\" href=\"\">#tag2</a>, #3wrongtag"
        end

        it 'can handle multiword tags' do
          html_extractor = TagExtractor::HTMLExtractor.new('This is a string with #tag1, #tag2, #3wrongtag, #{long tag1}, #{long tag2}')
          linkified = html_extractor.convert_tags_to_html_links('#', '{}') { }
          linkified.should == "This is a string with <a href=\"\">#tag1</a>, <a href=\"\">#tag2</a>, #3wrongtag, <a href=\"\">#long tag1</a>, <a href=\"\">#long tag2</a>"
        end

        it 'should take a block as an argument, providing the content for the href' do
          TagExtractor.tag_separator = '#'
          linkified = html_extractor.convert_tags_to_html_links() { |name|
            "/tags/#{name}"
          }
          linkified.should == "This is a string with <a href=\"/tags/tag1\">#tag1</a>, <a href=\"/tags/tag2\">#tag2</a>, #3wrongtag"
        end
      end
    end # HTMLExtractor

    describe 'String#extract_tags' do
      it 'should add extractor methods to class String' do
        ->{ "string".extract_tags }.should_not raise_error(NoMethodError)
      end
      it 'should extract tags from the string' do
        tags = sharp_tags + multiwords_tags
        source.extract_tags('#').should == tags.remove_tags_container('[]').collect { |t| t.slice!(0); t }
      end
      it 'should return an empty array if no tags were found' do
        "string".extract_tags.should == []
      end
    end

  end # for a String
end

class Array
  def remove_tags_container(container)
    left_op, right_op  = container.split ''
    self.map do |tag|
      cleaned_str = tag.gsub(left_op, '')
      cleaned_str = cleaned_str.gsub(right_op, '')
      cleaned_str || tag
    end
  end
end
