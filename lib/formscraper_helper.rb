#!/usr/bin/env ruby

# file: formscraper_helper.rb

require 'ferrumwizard'
require 'nokorexi'
require 'clipboard'


class FormScraperHelper

  attr_reader :browser

  # note: fd corresponds to FakeDataGenerator22 which is optional
  #
  def initialize(url=nil, browser: nil, headless: false, clipb: true,
                 fd: nil, debug: false)

    @url, @clipb, @fd, @debug = url, clipb, fd, debug

    @browser = browser ? browser : FerrumWizard.new(url,  headless: headless)

  end

  def scrape(body=@browser.body)
    puts 'body: '  + body.inspect if @debug
    doc = Nokorexi.new(body).to_doc

    #a = doc.root.xpath('//input|//select')
    a = doc.root.xpath('//*').select {|x| x.name == 'input' or x.name == 'select'}
    a.reject! do |x|
      x.attributes[:type] == 'hidden' or x.attributes[:style] =~ /display:none/
    end

    @h = a.map do |x|

      key = x.attributes[:name]
      type = x.name

      h = {}
      h[:type] = x.attributes[:type] || type
      h[:xpath] = "//%s[@name=\"%s\"]" % [type, key]
      h[:title] = x.attributes[:title]

      if type == 'select' then
        h[:options] = x.xpath('option').map {|x| x.text.to_s}
      end

      [key, h]

    end.to_h

  end

  def to_h()
    @h
  end

  def to_code()

s=<<EOF
require 'yaml'
require 'ferrum'
require 'nokorexi'

browser = Ferrum::Browser.new  headless: false
url = '#{@url}'
browser.goto(url)
sleep 2

doc = Nokorexi.new(browser.body).to_doc

# load the YAML document containing the inputs
#filepath = ''
filepath = '/tmp/tmp.yaml'
h = YAML.load(File.read(filepath))
EOF

    @h.each do |key, h|

      puts 'key: ' + key.inspect if @debug

      s += "r = browser.at_xpath('#{h[:xpath]}')\n"

      if h[:type] == 'text' or h[:type] == 'password' then

        var1, s2 = format_var1(h[:title], key)
        s += s2
        s += var1 + " = h['#{var1}']\n"
        s += "r.focus.type #{var1}\n"
        s += "sleep 0.5\n\n"

      elsif h[:type] == 'select'

        var1, s2 = format_var1(h[:title], key)
        s += s2

        s += "# options: #{h[:options].join(', ')}\n"
        s += "#{var1} = h['#{var1}']\n"
        s += 'titles = %w(' + h[:options].join(' ') + ')' + "\n"
        s += 'found = titles.grep /#{' + var1 + '}/i' + "\n"
        s += "n = titles.index(found.first) + 1\n"
        s += "r.focus\n"
        s += "n.times { r.type(:down); sleep 1}\n"
        s += "r.click\n"
        s += "sleep 0.5\n\n"

      elsif h[:type] == 'checkbox'
        s += "r.focus.click\n\n"
      end

    end

    Clipboard.copy s if @clipb
    puts 'generated code copied to clipboard'

    return s

  end

  # creates a YAML document for the inputs
  #
  def to_yaml()

    s = '---' + "\n"

    @h.each do |key, h|

      puts 'key: ' + key.inspect if @debug

      if h[:type] == 'text' or h[:type] == 'password' then

        var1, s2 = format_var1(h[:title], key)

        s += s2

        if h[:type] == 'password' then
          @pwd ||= @fd ? @fd.password : 'xxx'
          s += var1 + ": #{@pwd}\n"
        elsif @fd

          found = @fd.lookup var1
          val = found.is_a?(String) ? found : 'xxx'
          s += var1 + ": '#{val}'\n"
        else
          s += var1 + ": xxx\n"
        end

      elsif h[:type] == 'select'

        var1, s2 = format_var1(h[:title], key)

        s += s2
        s += "# options: #{h[:options].join(', ')}\n"
        val = h[:options][1..-1].sample
        s += "#{var1}: '#{val}'\n"

      elsif h[:type] == 'checkbox'

      end

    end

    Clipboard.copy s if @clipb
    puts 'generated YAML copied to clipboard'

    return s

  end

  private

  # returns var1 using arguments rawtitle or key
  #
  def format_var1(rawtitle, key)

    var1 = if rawtitle.length > 1 then

      s = "\n# " + rawtitle + "\n"
      title = rawtitle.scan(/[A-Z][^A-Z]+/).join(' ').gsub(/[^\w ]/,'')
      words = title.downcase.scan(/\w+/)

      if words.count > 2 then
        words.take(5).map {|x| x[0]}.join
      else
        title.downcase.gsub(/ +/,'_')
      end

    else
      newtitle = key.scan(/[A-Z][^A-Z]+/).join(' ')
      s = "\n# " + newtitle + "\n"
      newtitle.gsub(/[^\w ]/,'').downcase\
          .gsub(/ +/,'_')
    end

    [var1, s]

  end

end

