#!/usr/bin/env ruby

require 'csv'
require 'date'

###
### TODO: improve command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-orignal-csv

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
#File.open( file_name, :encoding => 'utf-8' ).each do |line|
File.open( file_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line

    # ignore (just in case)
    when /^\s*$/ # blank lines
      next
    when /^\s*#/ # my comments
      next

    # ignore Original stuff
    when /^"DATA"/i
      next

    else
      # fix CSV
#     line.encode(Encoding::ISO_8859_1)
      line.gsub!( ';', '","' )
      line = '"' + line + '"'

      CSV.parse( line ) do |row|

        puts "row: [#{row}]" if ENV['YNAB_DEBUG']

        # 'parse time' -> 'format time'
        dt    = Date.strptime( row[0], "%d/%m/%Y" ).strftime( "%Y/%m/%d" )
#       payee = row[1].match( / \w+ \s [-] \s (.*) /x ).captures[0]
        payee = row[1]
        memo  = row[1]
        val   = row[3].gsub( / \s? R[$] \s? /x, "" )
        val   = val.gsub( ".", "" )
        val   = val.gsub( ",", ".")

        if row[2].match( /Compra/i )
          # date,payee,category,memo,outflow,inflow
          res = "#{dt},#{payee},,#{memo},#{val},"
        else
          # date,payee,category,memo,outflow,inflow
          res = "#{dt},#{payee},,#{memo},,#{val}"
        end

#       # date,payee,category,memo,outflow,inflow
#       res = "#{dt},#{payee},,#{memo},,#{val}"
        puts "res: [#{res}]" if ENV['YNAB_DEBUG']

        csv << res
      end

  end # case line

end # file

###
### Results
###

# sort order for some same date entries
csv = csv.sort.join("\n")

if ENV['YNAB_STDOUT']
  puts "Date,Payee,Category,Memo,Outflow,Inflow"
  puts csv
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
  file.write(csv)
  file.write("\n")
  file.close
  puts "Created: [#{csv_name}]"
end

