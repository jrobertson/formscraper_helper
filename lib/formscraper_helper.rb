#!/usr/bin/env ruby

# file: formscraper_helper.rb

require 'ferrum'
require 'nokorexi'


class FormScraperHelper

  attr_reader :browser

  def initialize(url, headless: false, debug: false)

    @url, @debug = url, debug
    @browser = Ferrum::Browser.new  headless: headless
    @browser.goto(url)
    sleep 2
    scrape()

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
h = YAML.load(File.read(filepath))
EOF

    @h.each do |key, h|

      puts 'key: ' + key.inspect if @debug

      s += "r = browser.at_xpath('#{h[:xpath]}')\n"

      if h[:type] == 'text' or h[:type] == 'password' then

        var1 = if h[:title].length > 1 then
          h[:title].downcase.gsub(/ +/,'_')
        else 
          key.downcase
        end
        s += var1 + " = h['#{var1}']\n"
        s += "r.focus.type #{var1}\n\n"

      elsif h[:type] == 'select'

        var1 = if h[:title].length > 1 then
          h[:title].downcase.gsub(/ +/,'_').gsub(/\W/,'')
        else 
          key.downcase
        end

        s += "# options: #{h[:options].join(', ')}\n"
        s += "#{var1} = h['#{var1}']\n"
        s += 'r = titles.grep /#{' + var1 + '}/i' + "\n"
        s += "n = titles.index(r.first) + 1\n"
        s += "r.focus\n"
        s += "n.times { r.type(:down); sleep 1}\n"
        s += "r.click\n\n"

      elsif h[:type] == 'checkbox'
        s += "r.focus.click\n\n"
      end

    end

    return s

  end

  # creates a YAML document for the inputs
  #
  def to_yaml()

    s = '---' + "\n"

    @h.each do |key, h|

      puts 'key: ' + key.inspect if @debug

      if h[:type] == 'text' or h[:type] == 'password' then

        var1 = if h[:title].length > 1 then
          h[:title].downcase.gsub(/ +/,'_')
        else 
          key.downcase
        end
        s += var1 + ": xxx\n"

      elsif h[:type] == 'select'

        var1 = if h[:title].length > 1 then
          h[:title].downcase.gsub(/ +/,'_').gsub(/\W/,'')
        else 
          key.downcase
        end

        s += "#{var1}: xxx\n"

      elsif h[:type] == 'checkbox'

      end

    end

    return s

  end

  private

  def scrape()  

    doc = Nokorexi.new(@browser.body).to_doc

    #a = doc.root.xpath('//input|//select')
    a = doc.root.xpath('//*').select do |x|
      x.name == 'input' or x.name == 'select'
    end
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


end
