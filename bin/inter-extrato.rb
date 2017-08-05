#!/usr/bin/env ruby

require 'csv'
require 'date'

###
### simple(st) command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path/to/nu/file.csv

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

def fix_val( val=nil, oper='' )
  return 0 if val.nil?
  val = val.gsub( ".", ""  )
  val = val.gsub( ",", "." )
  val = "#{oper}#{val}"   # negative sign
  val.to_f
end

###
### Main
###

csv = []

# force encoding: avoid pt-br issues
File.open( file_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line [#{line.chomp}]" if ENV['YNAB_DEBUG']
  line = line.encode('iso-8859-1').encode('utf-8')
  puts "line![#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line

    # ignore (just in case)
    when /^\s*$/ # blank lines
      next
    when /^\s*#/ # my comments
      next
    when /^dat/i # CSV header
      next
    when /^[ ]?Extrato | ^Conta | ^Per | ^Saldo/xi # Intermedium
      next

    else

      # massage csv format
      line = '"' + line.chomp + '"'
      line.gsub!( /[;]/, '","' )
      puts line
#     next

      CSV.parse( line ) do |row|
        puts "row: |#{row}|" if ENV['YNAB_DEBUG']

        # 'parse time' -> 'format time'
        dt    = row[0] # Date.strptime( row[0], "%Y-%m-%d" ).strftime( "%d/%m/%Y" )
        dt    = Date.strptime( row[0], "%d/%m/%Y" ).strftime( "%Y-%m-%d" )
        payee = fix_spaces( row[1] )
        memo  = payee
        val   = fix_val( row[2] )

        # date,payee,category,memo,outflow,inflow
        # res = "#{dt},#{payee},,#{memo},#{val}"
        res = "#{dt},#{memo},,#{memo},#{val},"
        puts "res: [#{res}]" if ENV['YNAB_DEBUG']

        csv << res
      end

  end # case line

end # file

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


