# All code in this file was pulled from prototype-rails which was a dependency
# added for the sole purpose of creating tests.

class JavaScriptGenerator #:nodoc:
  def initialize(context, &block) #:nodoc:
    @context, @lines = context, []
    
    @context.with_output_buffer(@lines) do
      @context.instance_exec(self, &block)
    end
  end

  def to_s #:nodoc:
    (@lines * $/)
  end

  def literal(code)
    ::ActiveSupport::JSON::Variable.new(code.to_s)
  end

  def insert_html(position, id, *options_for_render)
    content = javascript_object_for(render(*options_for_render))
    record "Element.insert(\"#{id}\", { #{position.to_s.downcase}: #{content} });"
  end

  def replace(id, *options_for_render)
    call 'Element.replace', id, render(*options_for_render)
  end

  def alert(message)
    call 'alert', message
  end

  def redirect_to(location)
    record "window.location.href = #{@context.url_for(location).inspect}"
  end

  def call(function, *arguments)
    record "#{function}(#{arguments_for_call(arguments)})"
  end

  def <<(javascript)
    @lines << javascript
  end

  private

  def record(line)
    line = "#{line.to_s.chomp.gsub(/\;\z/, '')};"
    self << line
    line
  end

  def render(*options)
    with_formats(:html) do
      case option = options.first
      when Hash
        @context.render(*options)
      else
        option.to_s
      end
    end
  end

  def with_formats(*args)
    return yield unless @context
    
    lookup = @context.lookup_context
    begin
      old_formats, lookup.formats = lookup.formats, args
      yield
    ensure
      lookup.formats = old_formats
    end
  end

  def javascript_object_for(object)
    ::ActiveSupport::JSON.encode(object)
  end

  def arguments_for_call(arguments)
    arguments.map { |argument| javascript_object_for(argument) }.join ', '
  end
end

require 'action_controller/metal/renderers'

module ActionController
  module Renderers
    add :update do |proc, options|
      generator = ::JavaScriptGenerator.new(self.view_context, &proc)
      self.content_type  = Mime::JS
      self.response_body = generator.to_s
    end
  end
end

require 'active_support/core_ext/module/aliasing'
require 'rails/dom/testing/assertions'
require 'action_dispatch/testing/assertions'
require 'action_dispatch/testing/assertions/selector'

#--
# Copyright (c) 2006 Assaf Arkin (http://labnotes.org)
# Under MIT and/or CC By license.
#++

Rails::Dom::Testing::Assertions::SelectorAssertions.module_eval do
  def assert_select_rjs(*args, &block)
    rjs_type = args.first.is_a?(Symbol) ? args.shift : nil
    id       = args.first.is_a?(String) ? args.shift : nil

    # If the first argument is a symbol, it's the type of RJS statement we're looking
    # for (update, replace, insertion, etc). Otherwise, we're looking for just about
    # any RJS statement.
    if rjs_type
      if rjs_type == :insert
        position  = args.shift
        id = args.shift
        insertion = "insert_#{position}".to_sym
        raise ArgumentError, "Unknown RJS insertion type #{position}" unless RJS_STATEMENTS[insertion]
        statement = "(#{RJS_STATEMENTS[insertion]})"
      else
        raise ArgumentError, "Unknown RJS statement type #{rjs_type}" unless RJS_STATEMENTS[rjs_type]
        statement = "(#{RJS_STATEMENTS[rjs_type]})"
      end
    else
      statement = "#{RJS_STATEMENTS[:any]}"
    end

    # Next argument we're looking for is the element identifier. If missing, we pick
    # any element, otherwise we replace it in the statement.
    pattern = Regexp.new(
      id ? statement.gsub(RJS_ANY_ID, "\"#{id}\"") : statement
    )

    # Duplicate the body since the next step involves destroying it.
    matches = nil
    case rjs_type
      when :remove, :show, :hide, :toggle
        matches = @response.body.match(pattern)
      else
        @response.body.gsub(pattern) do |match|
          html = unescape_rjs(match)
          matches ||= []
          matches.concat HTML::Document.new(html).root.children.select { |n| n.tag? }
          ""
        end
    end

    if matches
      assert true, '' # to count the assertion
      matches = Nokogiri::HTML::DocumentFragment.new(Nokogiri::HTML::Document.new, matches.join(''))
      if block_given? && !([:remove, :show, :hide, :toggle].include? rjs_type)
        begin
          @selected ||= nil
          in_scope, @selected = @selected, matches
          yield matches
        ensure
          @selected = in_scope
        end
      end
      matches
    else
      # RJS statement not found.
      case rjs_type
        when :remove, :show, :hide, :toggle
          flunk_message = "No RJS statement that #{rjs_type.to_s}s '#{id}' was rendered."
        else
          flunk_message = "No RJS statement that replaces or inserts HTML content."
      end
      flunk args.shift || flunk_message
    end
  end
  
  protected

  RJS_PATTERN_HTML  = "\"((\\\\\"|[^\"])*)\""
  RJS_ANY_ID        = "\"([^\"])*\""
  RJS_STATEMENTS    = {
    :chained_replace      => "\\$\\(#{RJS_ANY_ID}\\)\\.replace\\(#{RJS_PATTERN_HTML}\\)",
    :chained_replace_html => "\\$\\(#{RJS_ANY_ID}\\)\\.update\\(#{RJS_PATTERN_HTML}\\)",
    :replace_html         => "Element\\.update\\(#{RJS_ANY_ID}, #{RJS_PATTERN_HTML}\\)",
    :replace              => "Element\\.replace\\(#{RJS_ANY_ID}, #{RJS_PATTERN_HTML}\\)",
    :redirect             => "window.location.href = #{RJS_ANY_ID}"
  }
  [:remove, :show, :hide, :toggle].each do |action|
    RJS_STATEMENTS[action] = "Element\\.#{action}\\(#{RJS_ANY_ID}\\)"
  end
  RJS_INSERTIONS = ["top", "bottom", "before", "after"]
  RJS_INSERTIONS.each do |insertion|
    RJS_STATEMENTS["insert_#{insertion}".to_sym] = "Element.insert\\(#{RJS_ANY_ID}, \\{ #{insertion}: #{RJS_PATTERN_HTML} \\}\\)"
  end
  RJS_STATEMENTS[:insert_html] = "Element.insert\\(#{RJS_ANY_ID}, \\{ (#{RJS_INSERTIONS.join('|')}): #{RJS_PATTERN_HTML} \\}\\)"
  RJS_STATEMENTS[:any] = Regexp.new("(#{RJS_STATEMENTS.values.join('|')})")
  RJS_PATTERN_UNICODE_ESCAPED_CHAR = /\\u([0-9a-zA-Z]{4})/

  # +assert_select+ and +css_select+ call this to obtain the content in the HTML
  # page, or from all the RJS statements, depending on the type of response.
  def response_from_page_with_rjs
    content_type = @response.content_type

    if content_type && Mime::JS =~ content_type
      body = @response.body.dup
      root = HTML::Node.new(nil)

      while true
        next if body.sub!(RJS_STATEMENTS[:any]) do |match|
          html = unescape_rjs(match)
          matches = HTML::Document.new(html).root.children.select { |n| n.tag? }
          root.children.concat matches
          ""
        end
        break
      end

      root
    else
      response_from_page_without_rjs
    end
  end

  def response_from_page
    HTML::Document.new(@html).root
  end
  alias_method_chain :response_from_page, :rjs

  # Unescapes a RJS string.
  def unescape_rjs(rjs_string)
    # RJS encodes double quotes and line breaks.
    unescaped= rjs_string.gsub('\"', '"')
    unescaped.gsub!(/\\\//, '/')
    unescaped.gsub!('\n', "\n")
    unescaped.gsub!('\076', '>')
    unescaped.gsub!('\074', '<')
    # RJS encodes non-ascii characters.
    unescaped.gsub!(RJS_PATTERN_UNICODE_ESCAPED_CHAR) {|u| [$1.hex].pack('U*')}
    unescaped
  end
end
