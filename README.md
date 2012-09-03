[TagExtractor](https://rubygems.org/gems/tag-extractor)
============
```
tag-extractor -v
# => 0.1.0
```
A minimal ruby library for tag extraction and manipulation.

# Installation
`gem install tag-extractor`

# A tag ?
A tag is composed of a Tag separator, which is usually a character such as `#` or `@` and a string of characters.
The basic regex currently in use is
```ruby
%r{(?:#{tag_separator})[a-zA-Z](?:\w|-)*}
```
Which allows, considering we are using `#` as a separator :
* #tag
* #Tag
* #T123ag
* #tAg
* #foo-bar

And does not allow :
* #@ (or any special character)
* #Tag@1 (or any special character)
* #1
* #1rstTag

# Usage
Tag extractor is fairly simple to use :
## Setting the Tag separator
There are two ways to set the tag separator :
* Using the global setter
  ```ruby
  TagExtractor.tag_separator = '#'
  ```
Which will set a default tag separator to `#` for every call to a TagExtractor method

* Passing the separator as first argument of a method
  ```ruby
  TagExtractor::StringExtractor.new('#tag1').extract('#')
  ```
Which will set a tag separator with a higher precedence than the one set through the global setter.
Please be careful with the fact that if you have not set any tag separator through the global setter, you will need to pass it in every method call.

Here is an example to illustrate the higher precedence principle:
```ruby
TagExtractor.tag_separator = '#'
TagExtractor::StringExtractor.new('#tag1').extract
# Will actually extract #tag1
TagExtractor::StringExtractor.new('@tag1').extract('@')
# Will actually extract @tag1
TagExtractor::StringExtractor.new('@tag1').extract
# Will NOT extract @tag1 as the global tag separator is #
```

You can retrieve the tag_separator using
```ruby
TagExtractor.tag_separator
```

## String Extractor
A string extractor is initialized by passing the content from which to extract (the source) :
```ruby
extractor = TagExtractor::StringExtractor.new('Here is my string with #tag1, #tag2')
```

It provides 2 methods :
* Extract
  ```ruby
  extractor.extract('#')
  # => ['tag1', 'tag2']
  ```
* Extract with separator
  ```ruby
  extractor.extract_with_separator('#')
  # => ['#tag1', '#tag2']
```

## HTMLExtractor
```ruby
html_extractor = TagExtractor::HTMLExtractor.new('This is a string with #tag1, #tag2')
```
Is a subclass of `StringExtractor` and thus inherits all of its methods, adding a new one for tag manipulation :
* Convert tags to html links
  ```ruby
  # It can be passed a separator, as usual, as a first parameter,
  # and an hash with a class attribute for css classes.
  html_extractor.convert_tags_to_html_links('#', :class => 'tag tag-link') { }
  # => 'This is a string with <a class="tag tag-link" href="">#tag1</a>, <a class="tag tag-link" href="">#tag2</a>'
  ```

  Now, how do we specify a link in a dynamic way ? Using a block :
  ```ruby
  html_extractor.convert_tags_to_html_links('#', :class => 'tag tag-link') do |name|
    "/tag/#{name}.downcase"
  end
  # => 'This is a string with <a class="tag tag-link" href="/tag/tag2">#tag1</a>, <a class="tag tag-link" href="/tag/tag2">#tag2</a>'
  ```
  The method passes the extracted tag name (without the separator) to the block, so you can use it to dynamically create links.

*Protip:* This method is aliased `linkify_tags` as `convert_tags_to_html_links` can often be a pain to write.

### HTMLExtractor with rails
Using rails, or most web frameworks, we often encounter HTML escaping. In rails, if you actually add pure HTML into a string, it will only display as regular text (gladly).
To allow you to put html in your converted string just use [html_safe](http://gabriel-dehan.github.com/2012/08/07/render-multiple-tags-in-a-helper/) :
```ruby
  string = html_extractor.convert_tags_to_html_links('#', :class => 'tag tag-link') do |name|
    "/tag/#{name}.downcase"
  end
  string = string.html_safe
```
And you are done.

## With ruby native String objects
As we are usually working with native ruby strings :
* String#_extract_tags_ :
  ```ruby
  '#tag1'.extract_tags('#') # => ['tag1']
  # It can be passed a second parameter which determine if we want to return the tags with separators (default: false)
  '#tag1'.extract_tags('#', true) # => ['#tag1']
  ```
* String#_linkify_tags_ and String#_convert_tags_to_html_links_ :
  ```ruby
  '#tag1'.linkify_tags('#', :class => 'tag') { |name| "/tag/#{name}" }
  # => '<a class="tag" href="/tag/tag1">#tag1</a>'
  ```

# Want to contribute ?
Please, do fork and pull request !
Simply remember that TagExtractor is a module containing all TagExtractor related classes.

## Road map :
* Allow multiple tag separators
* Allow customised regex
* HTMLExtractor :
** #wrap_in_html_tag method
* XMLExtractor
* JSONExtractor

# Misc
'Licensed' under [WTFPL](http://sam.zoy.org/wtfpl/COPYING)