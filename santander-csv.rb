#!/usr/bin/env ruby

require 'csv'
require 'date'

###
### TODO: improve command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-santander-csv

  USAGE
  exit 1
end

usage if ARGV.empty?

file_name = ARGV[0]

###
### Main
###

csv = []

# force encoding: avoid pt-br issues
File.open( file_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line

    # ignore (just in case)
    when /^\s*$/ # blank lines
      next
    when /^\s*#/ # my comments
      next

    # ignore Santander stuff
    when /^Data,/i
      next
    when /SALDO ANTERIOR,/i
      next

    else
      CSV.parse( line ) do |row|
        puts "row: [#{row}]" if ENV['YNAB_DEBUG']

        # 'parse time' -> 'format time'
        dt    = Date.strptime( row[0], "%d/%m/%Y" ).strftime( "%Y/%m/%d" )
        payee = row[2]
        memo  = row[2]
        memo  = memo + " - NroDoc: " + sprintf("%06d", row[3]) if row[3] != "0" # add if present
        val   = row[4].gsub( /,/, '.')

        # date,payee,category,memo,outflow,inflow
        res = "#{dt},#{payee},,#{memo},,#{val}"
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
  puts csv.sort.join("\n")
else
  base_name = File.basename(file_name, '.*')
  dir_name  = File.dirname( File.absolute_path( file_name ) )
  csv_name  = base_name + '.ynab.csv'

  if ENV['YNAB_DEBUG']
    puts "Processing: [#{file_name}]"
    puts "base: #{base_name}"
    puts "dir: #{dir_name}"
    puts "csv: #{csv_name}"
  end

  file = File.open(csv_name, 'w')
  file.write("Date,Payee,Category,Memo,Outflow,Inflow\n")
  file.write(csv.sort.join("\n")) # sort order for same date
  file.write("\n")
  file.close
  puts "Created: [#{csv_name}]"
end

