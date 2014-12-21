#!/usr/bin/env ruby
#
# Name:         agm (Automate Gateway Max)
# Version:      0.0.1
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: OS X
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Script to automate Telstra Gateway Max functions

# Required modules

require 'rubygems'
require 'nokogiri'
require 'getopt/std'
require 'selenium-webdriver'
require 'phantomjs'
require 'fileutils'
require 'terminal-table'

# Some defaults

default_address = "192.168.1.254"
$verbose        = 0
$mask_values    = 0

# Get command line options

options = "bdhlmorsvwg:u:p:"

# Print the version of the script

def print_version()
  puts
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  puts name+" v. "+version+" "+packager
  puts
end

# Print options

def print_usage(options)
	puts
	puts "Usage: "+$0+" -["+options+"]"
	puts
  puts "-V:\tDisplay version information"
  puts "-h:\tDisplay usage information"
	puts "-g:\tSpecify Gateway IP or hostname"
	puts "-u:\tSpecify Gateway username"
	puts "-p:\tSpecify Gateway password"
	puts "-s:\tDisplay Status"
  puts "-d:\tDisplay DHCP Leases"
  puts "-w:\tDisplay Wireless Information"
  puts "-b:\tDisplay Broadband Status"
  puts "-l:\tDisplay System Logs"
  puts "-o:\tDisplay Overview"
  puts "-r:\tReboot Gateway"
  puts "-m:\tMask values"
	puts "-v:\tVerbose mode"
	puts
	return
end

# If a ~/,agmpasswd doesn't exist ask for details

def get_gwm_details()
  gwm_passwd_file = Dir.home+"/.agmpasswd"
  if !File.exist?(gwm_passwd_file)
    puts "Enter Gateway Username:"
    STDOUT.flush
    gwm_username = gets.chomp
    puts "Enter Gateway Password:"
    STDOUT.flush
    gwm_password = gets.chomp
    create_gwm_passwd_file(gwm_username,gwm_password)
  else
    gwm_data = File.readlines(gwm_passwd_file)
    gwm_data.each do |line|
      line.chomp
      if line.match(/http-user/)
        gwm_username = line.split(/\=/)[1].chomp
      end
      if line.match(/http-password/)
        gwm_password = line.split(/\=/)[1].chomp
      end
    end
  end
  return gwm_username,gwm_password
end

# If gateway password file doesn't exist create it and give it appropriate permissions

def create_gwm_passwd_file(gwm_username,gwm_password)
  gwm_passwd_file = Dir.home+"/.agmpasswd"
  FileUtils.touch(gwm_passwd_file)
  File.chmod(0600,gwm_passwd_file)
  output_text = "http-user="+gwm_username+"\n"
  File.open(gwm_passwd_file, 'a') { |file| file.write(output_text) }
  output_text = "http-password="+gwm_password+"\n"
  File.open(gwm_passwd_file, 'a') { |file| file.write(output_text) }
  output_text = "check-certificate=off\n"
  File.open(gwm_passwd_file, 'a') { |file| file.write(output_text) }
  File.close(gwm_passwd_file)
  return
end

# Get Gateway Max URL

def get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
	cap = Selenium::WebDriver::Remote::Capabilities.phantomjs('phantomjs.page.settings.userAgent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.39.41 (KHTML, like Gecko) Version/8.0 Safari/538.39.41')
  doc = Selenium::WebDriver.for :phantomjs, :desired_capabilities => cap
  top = "http://"+gwm_address
  doc.get(top)
  doc.find_element(:id => "login").send_keys(gwm_username)
  doc.find_element(:id => "password").send_keys(gwm_password)
  doc.find_element(:id => "loginbtn").click
  doc.get(gwm_url)
  output_page = doc.page_source
  return(output_page)
end

# Reboot Gateway Max

def reboot_gwm(gwm_address,gwm_username,gwm_password)
  cap = Selenium::WebDriver::Remote::Capabilities.phantomjs('phantomjs.page.settings.userAgent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.39.41 (KHTML, like Gecko) Version/8.0 Safari/538.39.41')
  doc = Selenium::WebDriver.for :phantomjs, :desired_capabilities => cap
  top = "http://"+gwm_address
  url = "http://"+gwm_address+"/HngDiagnostics.asp"
  doc.get(top)
  doc.find_element(:id => "login").send_keys(gwm_username)
  doc.find_element(:id => "password").send_keys(gwm_password)
  doc.find_element(:id => "loginbtn").click
  doc.get(url)
  doc.find_element(:id => "RebootRouterBtn").click
  return
end

# get DHCP information

def get_gwm_dhcp(gwm_address,gwm_username,gwm_password)
  gwm_dhcp = []
  gwm_url  = "http://"+gwm_address+"/Hnglan_ip.asp"
  gwm_page = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  table = Terminal::Table.new :title => "DHCP Information", :headings => [ 'MAC', 'IP', 'Expires' ]
  doc   =  Nokogiri::HTML(gwm_page)
  doc.css("tr").each do |node|
    if node.to_s.match(/HngDhcpClientList/)
      line = node.text
      line = line.gsub(/^\s+/,"")
      line = line.chomp
      gwm_dhcp.push(line)
    end
  end
  length = gwm_dhcp.length
  row    = []
  item   = ""
  gwm_dhcp.each_with_index do |line,index|
    (mac,ip,expire) = line.split("\n")
    mac = mask_value(item,mac)
    ip  = mask_value(item,ip)
    row = [ mac, ip, expire ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
  return
end

# Get Gateway Max Wireless information

def get_gwm_wireless(gwm_address,gwm_username,gwm_password)
  gwm_wlan = []
  gwm_url  = "http://"+gwm_address+"/Hngwireless_card_access_list.asp"
  gwm_page = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  table = Terminal::Table.new :title => "Wireless Devices", :headings => [ 'IP', 'MAC', 'Interface' ]
  doc   =  Nokogiri::HTML(gwm_page)
  doc.css("table#tbl_wirelessCardAccessList_connrcted_devices tbody tr").each do |node|
    info = []
    node.css("td").each do |line|
      line = line.text
      line = line.gsub(/^\s+/,"")
      line = line.chomp
      info.push(line)
    end
    gwm_wlan.push(info.join("\n"))
  end
  length = gwm_wlan.length
  row    = []
  item   = ""
  gwm_wlan.each_with_index do |line,index|
    (ip,mac,interface) = line.split("\n")
    mac = mask_value(item,mac)
    ip  = mask_value(item,ip)
    row = [ ip, mac, interface ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
  return
end

# Get Gateway Max System Logs

def get_gwm_logs(gwm_address,gwm_username,gwm_password)
  gwm_logs = []
  gwm_url  = "http://"+gwm_address+"/HngRgSystemLogs.asp"
  gwm_page = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  table = Terminal::Table.new :title => "System Logs", :headings => [ 'Description', 'Count', 'Last Occurence', 'Target', 'Source' ]
  doc   =  Nokogiri::HTML(gwm_page)
  doc.css("tr").each do |node|
    test = node.text.gsub(/\s+/,"")
    if !test.match(/^Description/)
      line = node.to_s
      (info,count,last,target,source) = line.split("</td>")
      info   = info.split(/>/)[-1].gsub(/\n/,"")
      count  = count.split(/>/)[-1].gsub(/\n/,"")
      last   = last.split(/>/)[-1] .gsub(/\n/,"")
      target = target.split(/>/)[-1].gsub(/\n/,"")
      source = source.split(/>/)[-1].gsub(/\n/,"")
      data   = info+"\n"+count+"\n"+last+"\n"+target+"\n"+source
      gwm_logs.push(data)
    end
  end
  length = gwm_logs.length
  row    = []
  item   = ""
  gwm_logs.each_with_index do |line,index|
    (description,count,last,target,source) = line.split("\n")
    target = mask_value(item,target)
    source = mask_value(item,source)
    row = [ description, count, last, target, source ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
  return
end

# Get Gateway Max status

def get_gwm_status(gwm_address,gwm_username,gwm_password)
  gwm_status = []
	gwm_url    = "http://"+gwm_address+"/HngIndex.asp"
 	gwm_page   = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  table = Terminal::Table.new :title => "Status Information", :headings => [ 'Item', 'Value' ]
 	doc   =  Nokogiri::HTML(gwm_page)
 	doc.css("tr").each do |node|
 		line = node.text
 		line = line.gsub(/^\s+/,"")
    line = line.chomp
    gwm_status.push(line)
 	end
  length = gwm_status.length
  row    = []
  gwm_status.each_with_index do |line,index|
    (item,value) = line.split("\n")
    value = mask_value(item,value)
    row   = [ item, value ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
	return
end

# Get Gateway Max Overview

def get_gwm_view(gwm_address,gwm_username,gwm_password)
  gwm_status = []
  gwm_url    = "http://"+gwm_address+"/HngBasicViewIndex.asp"
  gwm_page   = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  table = Terminal::Table.new :title => "Wireless Devices", :headings => [ 'LAN IP', 'Device Name', 'Link Speed' ]
  doc   =  Nokogiri::HTML(gwm_page)
  doc.css("div#wifiDev").each do |node|
    line = node.text
    line = line.gsub(/^\s+/,"")
    line = line.chomp
    gwm_status.push(line)
  end
  item   = ""
  length = gwm_status.length
  row    = []
  gwm_status.each_with_index do |line,index|
    (ip,name,speed) = line.split("\n")
    ip    = ip.split(": ")[1]
    name  = name.split(": ")[1]
    speed = speed.split(": ")[1]
    ip    = mask_value(item,ip)
    name  = mask_value(item,name)
    row   = [ ip, name, speed ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
  gwm_status = []
  table = Terminal::Table.new :title => "LAN Devices", :headings => [ 'LAN IP', 'Device Name', 'Link Speed' ]
  doc   =  Nokogiri::HTML(gwm_page)
  doc.css("div#lanDev").each do |node|
    line = node.text
    line = line.gsub(/^\s+/,"")
    line = line.chomp
    gwm_status.push(line)
  end
  item   = ""
  length = gwm_status.length
  row    = []
  gwm_status.each_with_index do |line,index|
    (ip,name,speed) = line.split("\n")
    ip    = ip.split(": ")[1]
    name  = name.split(": ")[1]
    speed = speed.split(": ")[1]
    ip    = mask_value(item,ip)
    name  = mask_value(item,name)
    row   = [ ip, name, speed ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
  return
end

# Get Gateway Max Broadband status 

def get_gwm_broadband(gwm_address,gwm_username,gwm_password)
  gwm_status = []
  gwm_url    = "http://"+gwm_address+"/HngBroadbandBasicSettings.asp"
  gwm_page   = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  table = Terminal::Table.new :title => "Broadband Information", :headings => [ 'Item', 'Value' ]
  doc   =  Nokogiri::HTML(gwm_page)
  doc.css("tr").each do |node|
    line = node.text
    line = line.gsub(/^\s+/,"")
    line = line.chomp
    gwm_status.push(line)
  end
  length = gwm_status.length
  row    = []
  gwm_status.each_with_index do |line,index|
    (item,value) = line.split("\n")
    value = mask_value(item,value)
    row   = [ item, value ]
    table.add_row(row)
    if index < length-1
      table.add_separator
    end
  end
  puts table
  return
end

# Mask information

def mask_value(item,value)
  if $mask_values == 1
    if item.match(/Serial|Hardware|Software|Specification/)
      value = value.gsub(/[0-9,A-Z]/,"X")
    else
      if !value.match(/[A-Z]/)
        value = value.gsub(/[0-9,a-f]/,"X")
      end
    end
  end
  return value
end

# Handle command line options

begin
  opt  = Getopt::Std.getopts(options)
  used = 0
  options.gsub(/:/,"").each_char do |option|
    if opt[option]
      used = 1
    end
  end
  if used == 0
    print_usage
  end
rescue
  print_usage(options)
  exit
end

if opt["v"]
	$verbose = 1
end

if opt["m"]
  $mask_values = 1
end

if opt["h"]
  print_usage(options)
  exit
end

if opt["V"]
  print_version()
  exit
end

if opt["u"]
	gwm_username = opt["u"]
end

if opt["p"]
	gwm_password = opt["p"]
end

if opt["g"]
	gwm_address = opt["g"]
else
	gwm_address = default_address
end

if !opt["u"] or !opt["p"]
  gwm_passwd_file = Dir.home+"/.agmpasswd"
  if !File.exist?(gwm_passwd_file)
    (gwm_username,gwm_password) = get_gwm_details()
    create_gwm_passwd_file(gwm_username,gwm_password)
  else
    (gwm_username,gwm_password) = get_gwm_details()
  end
end

if opt["s"]
	get_gwm_status(gwm_address,gwm_username,gwm_password)
  exit
end

if opt["r"]
  reboot_gwm(gwm_address,gwm_username,gwm_password)
  exit
end

if opt["d"]
  get_gwm_dhcp(gwm_address,gwm_username,gwm_password)
  exit
end

if opt["w"]
  get_gwm_wireless(gwm_address,gwm_username,gwm_password)
  exit
end

if opt["b"]
  get_gwm_broadband(gwm_address,gwm_username,gwm_password)
  exit
end

if opt["l"]
  get_gwm_logs(gwm_address,gwm_username,gwm_password)
  exit
end

if opt["o"]
  get_gwm_view(gwm_address,gwm_username,gwm_password)
  exit
end