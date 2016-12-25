#!/usr/bin/env ruby

require 'csv'
require 'date'

###
### simple(st) command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-cef-txt

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
    when /^date,title/ # CSV header
      next

    else

      # massage csv format
      line.gsub!( /["']/, '' )

      CSV.parse( line ) do |row|
        puts "row: |#{row}|" if ENV['YNAB_DEBUG']

        # 'parse time' -> 'format time'
        dt    = row[0] # Date.strptime( row[0], "%Y-%m-%d" ).strftime( "%d/%m/%Y" )
        payee = row[1]
        memo  = row[1]
        val   = row[2]

        # date,payee,category,memo,outflow,inflow
        res = "#{dt},#{payee},,#{memo},#{val}"
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
