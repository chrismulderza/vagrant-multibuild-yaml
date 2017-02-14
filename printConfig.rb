#!/usr/bin/env ruby
#
require 'yaml'
cwd    = File.dirname(File.expand_path(__FILE__))
user_opts       = YAML.load_file("#{cwd}/build.yaml")

_opts = Hash[user_opts.select {|hash| hash["option"] == "general"}[0]]
_machines = user_opts.select {|hash| hash["option"] == "machine"}

# Hack to print detail of the build
puts "Build Summary:"
puts "=========================================================="
puts "General Project Configuration"
puts "=========================================================="
puts "TLD => .#{_opts["tld"]}"
puts "Project Domain => #{_opts["domain"]}.#{_opts["tld"]}"
puts "Project Prefix => #{_opts["project"]}"
puts "=========================================================="
puts "Machine Configuration"
puts "=========================================================="
_machines.each do |m|
  puts "Machine Name => #{m["name"]}"
  puts "Description => #{m["description"]}"
  puts "Enabled => #{m["enabled"]}"
  puts "Primary => #{m["primary"]}"
  puts "Box Type => #{m["box"]}"
  puts "Box URL => #{m["box_url"]}"
  puts "Linked Clone => #{m["box_url"]}"
  puts "Hostname => #{m["hostname"]}"
  puts "FQDN => #{m["hostname"]}.#{_opts["domain"]}.#{_opts["tld"]}"
  puts "CPUs => #{m["cpus"]}"
  puts "Memory => #{m["memory"]}"
  puts "Enable GUI => #{m["gui"]}"
  puts "Customizations"
  m["vm_mods"].each do |_copts|
    puts "    | #{_copts["option"]} => #{_copts["value"]}"
  end
  puts "Private IP => #{m["private_ip"]}"
  if m["provision"]
  puts "Provisioning Options"
    puts "    | Playbook => #{m["playbook"]}"
  end
  puts "----------------------------------------------------------"
end
puts "\n"
