#!/usr/bin/env ruby

require 'optparse'
require 'rexml/document'
include REXML

def type(xmlfile,attribute)
  attr_types = []
  XPath.each(xmlfile, "//Context[@document='#{attribute}']") do |item|
    attr_types << item.attribute("search").value
  end
  puts attr_types.uniq.sort
end

def attributes(xmlfile)
  nodes_list = nodes(xmlfile)
  nodes_unique = nodes_list.uniq
  nodes_unique.each do |item|
    puts "#{item}: "
    puts nodes_list.select {|a| a === "#{item}"}.count
  end
end

def nodes(xmlfile)
  node_list = []
  XPath.each(xmlfile, "//Context") do |item|
    node_list << item.attribute("document").value
  end
  return node_list
end

def domainName(xmlfile)
  XPath.each(xmlfile, "//Context[@search='Network/DNS']/ancestor::IndicatorItem") do |item|
    value = item.attribute("id").value
    puts XPath.match(xmlfile, "//IndicatorItem[@id='#{value}']/Content[@type='string']").map { |element| element.text }
  end
end

def remoteIP(xmlfile)
  XPath.each(xmlfile, "//Context[@search='PortItem/remoteIP']/ancestor::IndicatorItem") do |item|
    value = item.attribute("id").value
    puts XPath.match(xmlfile, "//IndicatorItem[@id='#{value}']/Content[@type='IP']").map { |element| element.text }
  end
end

options = {}

optparse = OptionParser.new do |opts|

  opts.banner = "Usage: ioccmd -f IOC_FILE [...]\n" \
                "Example: ioccmd -f myindicator.xml -e IP,DOMAIN\n" \
                "List of Objects:\n" \
                "IP      - extract remote IPs\n" \
                "DOMAIN  - extract remote Domains\n" \
                "ATTRS   - extract list of Attributes\n"
  opts.on('-h', '--help', 'Display this menu') do
    puts opts
    exit
  end
  opts.on('-f', '--f FILE', 'IOC XML File') do |f|
    options[:file] = f
  end
  options[:extract] = []
  opts.on('-e', '--extract [OBJECT,...]',Array, 'Extract OBJECT in plain text') do |f|
    options[:extract] = f
  end
  opts.on('-t', '--type [ATTRIBUTE,...]', Array, 'Extract TYPE for each ATTRIBUTE') do |f|
    options[:type] = f
  end
end

optparse.parse!

if options[:extract].nil?
  puts "[-] Missing argument try `ioccmd -h`" 
  exit
end

puts "[+] Opening #{options[:file]}"
iocfile = File.new("#{options[:file]}")
xmlioc = Document.new(iocfile)

options[:extract].each do |argument|
  if argument === "IP"
    puts "[+] List of Remote IPs:"
    remoteIP(xmlioc)
    puts "[+] ==== \n\n"
  end
  if argument === "DOMAIN"
    puts "[+] List of Remote Domains:"
    domainName(xmlioc)
    puts "[+] ==== \n\n"
  end
  if argument === "ATTRS"
    puts "[+] List of Attributes:"
    attributes(xmlioc)
    puts "[+] ==== \n\n"
  end
end

if !options[:type].nil?
  options[:type].each do |argument|
    type(xmlioc,argument)
  end
end