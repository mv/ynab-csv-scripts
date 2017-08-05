#!/usr/bin/env ruby

require 'ofx'
require 'date'

###
### simple(st) command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path/to/file.ofx

  USAGE
  exit 1
end

usage if ARGV.empty?

file_name = ARGV[0]

###
### definitions
###

def trim( string )
  return '' unless string
  string.gsub(/^\s+|\s+$/,'')
end

def noblanks( string )
  return '' unless string
  string.gsub(/\s{2,}/,' ')
end

def fix_spaces( memo )
  memo = trim( memo )
  memo = noblanks( memo )
end

###
### Main
###

csv = []
ofx = OFX( file_name )

ofx.account.transactions.each do |t|

  # format time
  dt    = t.posted_at.strftime( "%Y-%m-%d" )
# printf "%10s %10s %10.2f %12s {%s}: [%s]\n", t.type, t.amount_in_pennies, t.amount, t.fit_id, t.posted_at, t.memo if ENV['YNAB_DEBUG']

  payee = fix_spaces( t.memo )
  memo  = payee
  val   = t.amount_in_pennies / 100.00

  # date,payee,category,memo,outflow,inflow
  res = "#{dt},#{memo},,#{memo},,#{val}"
  puts "res: [#{res}]" if ENV['YNAB_DEBUG']

  csv << res
end

###
### Results
###

if ENV['YNAB_STDOUT']
  puts "Date,Payee,Category,Memo,Outflow,Inflow"
  puts csv
  exit
end

base_name = File.basename(file_name, '.*')
dir_name  = File.dirname( File.absolute_path( file_name ) )
csv_name  = base_name + '.ynab.csv'

if ENV['YNAB_DEBUG']
  puts "Processing: [#{file_name}]"
  puts "base: #{base_name}"
  puts "dir: #{dir_name}"
  puts "csv: #{csv_name}"
end

File.open(csv_name, 'w') do |f|
  f.puts("Date,Payee,Category,Memo,Outflow,Inflow")
  csv.each { |c| f.puts(c) }
end


