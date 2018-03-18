#!/usr/bin/env ruby -W0
#
# Name:         agm (Automate Gateway Max)
# Version:      0.0.5
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

# Some defaults

default_address = "192.168.1.254"
test_address    = "google.com"
$verbose        = 0
$mask_values    = 0

# Get command line options

options = "bcdhlmorsvwg:u:p:t:"

# Code to install a gem

def install_gem(load_name,install_name)
  puts "Information:\tInstalling #{install_name}"
  %x[gem install #{install_name}]
  Gem.clear_paths
  require "#{load_name}"
end

# Load / install additional gems

begin
  require 'getopt/long'
rescue LoadError
  install_gem("getopt/long","getopt")
end

begin
  require 'highline/import'
rescue LoadError
  install_gem("highline/import","highline")
end

begin
  require 'net/ping'
rescue LoadError
  install_gem("net/ping","net-ping")
end

[ "rubygems", "selenium-webdriver", "nokogiri", "fileutils", "terminal-table" ].each do |gem_name|
  begin
    require gem_name 
  rescue LoadError
    install_gem(gem_name,gem_name)
  end
end

include Net

# Print the version of the script

def print_version()
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  puts name+" v. "+version+" "+packager
end

# Print script usage information

def print_help()
  switches     = []
  long_switch  = ""
  short_switch = ""
  help_info    = ""
  puts
  puts "Usage: #{$script}"
  puts
  file_array  = IO.readlines $0
  option_list = file_array.grep(/\[ "--/)
  option_list.each do |line|
    if !line.match(/file_array/)
      help_info    = line.split(/# /)[1]
      switches     = line.split(/,/)
      long_switch  = switches[0].gsub(/\[/,"").gsub(/\s+/,"")
      short_switch = switches[1].gsub(/\s+/,"")
      if short_switch.match(/REQ|BOOL/)
        short_switch = ""
      end
      if long_switch.gsub(/\s+/,"").length < 7
        puts "#{long_switch},\t\t\t#{short_switch}\t#{help_info}"
      else
        if long_switch.gsub(/\s+/,"").length < 15
          puts "#{long_switch},\t\t#{short_switch}\t#{help_info}"
        else
          puts "#{long_switch},\t#{short_switch}\t#{help_info}"
        end
      end
    end
  end
  puts
  return
end

# If a ~/,agmpasswd doesn't exist ask for details

def get_gwm_details()
  gwm_passwd_file = Dir.home+"/.agmpasswd"
  if !File.exist?(gwm_passwd_file)
    gwm_username = ask("Enter Gateway Username: ") { |q| }
    gwm_password = ask("Enter Gateway Password: ") { |q| q.echo = false }
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
  return
end

# Get Gateway Max URL

def get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  opt = Selenium::WebDriver::Chrome::Options.new
  opt.add_argument('--headless')
	cap = Selenium::WebDriver::Remote::Capabilities.chrome('chrome.page.settings.userAgent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.39.41 (KHTML, like Gecko) Version/8.0 Safari/538.39.41')
  doc = Selenium::WebDriver.for :chrome, :options => opt, :desired_capabilities => cap
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
  opt = Selenium::WebDriver::Chrome::Options.new
  opt.add_argument('--headless')
  cap = Selenium::WebDriver::Remote::Capabilities.chrome('chrome.page.settings.userAgent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10) AppleWebKit/538.39.41 (KHTML, like Gecko) Version/8.0 Safari/538.39.41')
  doc = Selenium::WebDriver.for :chrome, :options => opt, :desired_capabilities => cap
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
  gwm_url  = "http://"+gwm_address+"/HngEventLog.asp"
  gwm_page = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  if gwm_page.length < 100
    gwm_url  = "http://"+gwm_address+"/HngRgSystemLogs.asp"
    gwm_page = get_gwm_url(gwm_address,gwm_url,gwm_username,gwm_password)
  end
  if gwm_url.match(/System/)
    table = Terminal::Table.new :title => "System Logs", :headings => [ 'Description', 'Count', 'Last Occurence', 'Target', 'Source' ]
    doc   =  Nokogiri::HTML(gwm_page)
    doc.css("tr").each do |node|
      test = node.text.gsub(/\s+/,"")
      if !test.match(/^Description/)
        line = node.to_s
        if line.match(/[0-9]/)
          puts line
          (info,count,last,target,source) = line.split("</td>")
          info   = info.split(/>/)[-1].gsub(/\n/,"")
          count  = count.split(/>/)[-1].gsub(/\n/,"")
          count  = count.gsub(/^\W/,"")
          last   = last.split(/>/)[-1] .gsub(/\n/,"")
          last   = last.gsub(/^\W/,"")
          target = target.split(/>/)[-1].gsub(/\n/,"")
          target = target.gsub(/^\W/,"")
          source = source.split(/>/)[-1].gsub(/\n/,"")
          source = source.gsub(/^\W/,"")
          data   = info+"\n"+count+"\n"+last+"\n"+target+"\n"+source
          gwm_logs.push(data)
        end
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
  else
    table = Terminal::Table.new :title => "Event Logs", :headings => [ 'Time', 'Priority', 'Count', 'Description', 'CM-MAC', 'CMTS-MAC', 'CM-QOS', 'CM-VER' ]
    doc   =  Nokogiri::HTML(gwm_page)
    doc.css("tr").each do |node|
      test = node.text.gsub(/\s+/,"")
      if !test.match(/^Description/)
        line     = node.to_s.gsub(/\n/,"")
        count    = "1"
        cm_mac   = "N/A"
        cmts_mac = "N/A"
        cm_qos   = "N/A"
        cm_ver   = "N/A"
        if line.match(/[0-9]/)
          (time,priority,description) = line.split("</td>")
          time        = time.split(/\<td\>/)[1]
          time        = time.split()[1..-1].join(" ")
          priority    = priority.split(/\<td\>/)[1]
          if priority.match(/\(/)
            (priority,count) = priority.split(/\(/)
            count       = count.gsub(/\)/,"")
            priority    = priority.gsub(/\W/,"")
            description = description.split(/\<td\>/)[1]
            if description
              description = description.split()[1..-1].join(" ")
            else
              description = "N/A"
            end
            if description.match(/CM-MAC/)
              (description,cm_mac,cmts_mac,cm_qos,cm_ver,tail) = description.split(";")
              cm_mac   = cm_mac.split("=")[1]
              cmts_mac = cmts_mac.split("=")[1]
              cm_qos   = cm_qos.split("=")[1]
              cm_ver   = cm_ver.split("=")[1]
            end
          else
            priority    = priority.gsub(/^\W/,"")
            description = priority
            priority    = "Warning"
          end
          data = time+"\n"+priority+"\n"+count+"\n"+description+"\n"+cm_mac+"\n"+cmts_mac+"\n"+cm_qos+"\n"+cm_ver
          gwm_logs.push(data)
        end
      end
    end
    length = gwm_logs.length
    row    = []
    item   = ""
    gwm_logs.each_with_index do |line,index|
      (time,priority,count,description,cm_mac,cmts_mac,cm_qos,cm_ver) = line.split("\n")
      cm_mac   = mask_value(item,cm_mac)
      cmts_mac = mask_value(item,cmts_mac)
      row      = [ time, priority, count, description, cm_mac, cmts_mac, cm_qos, cm_ver ]
      table.add_row(row)
      if index < length-1
        table.add_separator
      end
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

# Check Gateway Max Connectivity

def check_gwm(test_address,gwm_address,gwm_username,gwm_password)
  Ping::TCP.service_check = true
  test = Net::Ping::TCP.new(test_address)
  if !test.ping?
    if $verbose == 1
      puts "Test address "+test_address+" is not responding, rebooting "+gwm_address
    end
    reboot_gwm(gwm_address,gwm_username,gwm_password)
  else
    if $verbose == 1
      puts "Test address "+test_address+" is responding"
    end
  end
  return
end

# Get command line arguments

# Print help if specified none

if !ARGV[0]
  print_help()
end

# Try to make sure we have valid long switches

ARGV[0..-1].each do |switch|
  if switch.match(/^-[a-z,A-Z][a-z,A-Z]/)
    handle_output("Invalid command line option: #{switch}")
    exit
  end
end

# Handle command line options

include Getopt

begin
  option = Long.getopts(
     [ "--verbose",   BOOLEAN ],  # Verbose mode
     [ "--version",   BOOLEAN ],  # Print version
     [ "--help",      BOOLEAN ],  # Print help / usage
     [ "--mask",      BOOLEAN ],  # Mask MAC addresses and IPs
     [ "--status",    BOOLEAN ],  # Get status of Gateway Max
     [ "--reboot",    BOOLEAN ],  # Reboot Gateway Max
     [ "--check",     BOOLEAN ],  # Check network connectivity and reboot Gateway Max if down
     [ "--text",      BOOLEAN ],  # Test address
     [ "--dhcp",      BOOLEAN ],  # Get DHCP client information from Gateway Max
     [ "--wireless",  BOOLEAN ],  # Get wireless information from Gateway Max
     [ "--broadband", BOOLEAN ],  # Get broadband information from Gateway Max
     [ "--logs",      BOOLEAN ],  # Get system log information from Gateway Max
     [ "--overview",  BOOLEAN ],  # Get overview information from Gateway Max
     [ "--ip",        REQUIRED ], # IP or hostname of Gateway Max
     [ "--username",  REQUIRED ], # Username for Gateway Max
     [ "--password",  REQUIRED ]  # Password for Gateway Max
  )
rescue
  print_help()
  exit
end

# Handle options

if option["verbose"]
	$verbose = 1
end

if option["mask"]
  $mask_values = 1
end

if option["help"]
  print_help()
  exit
end

if option["version"]
  print_version()
  exit
end

if option["username"]
	gwm_username = option["username"]
end

if option["password"]
	gwm_password = option["password"]
end

if option["ip"]
	gwm_address = option["ip"]
else
	gwm_address = default_address
end

if !option["username"] or !option["password"]
  gwm_passwd_file = Dir.home+"/.agmpasswd"
  if !File.exist?(gwm_passwd_file)
    (gwm_username,gwm_password) = get_gwm_details()
    create_gwm_passwd_file(gwm_username,gwm_password)
  else
    (gwm_username,gwm_password) = get_gwm_details()
  end
end

if option["status"]
	get_gwm_status(gwm_address,gwm_username,gwm_password)
  exit
end

if option["reboot"]
  reboot_gwm(gwm_address,gwm_username,gwm_password)
  exit
end

if option["dhcp"]
  get_gwm_dhcp(gwm_address,gwm_username,gwm_password)
  exit
end

if option["wireless"]
  get_gwm_wireless(gwm_address,gwm_username,gwm_password)
  exit
end

if option["broadband"]
  get_gwm_broadband(gwm_address,gwm_username,gwm_password)
  exit
end

if option["logs"]
  get_gwm_logs(gwm_address,gwm_username,gwm_password)
  exit
end

if option["overview"]
  get_gwm_view(gwm_address,gwm_username,gwm_password)
  exit
end

if option["test"]
  test_address = option["test"]
end

if option["check"]
  check_gwm(test_address,gwm_address,gwm_username,gwm_password)
  exit
end
