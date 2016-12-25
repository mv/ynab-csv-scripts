#!/usr/bin/env ruby

require 'pp'

###
### file name
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-modalmais-pdf

  USAGE
  exit 1
end

usage if ARGV.empty?

pdf_name  = ARGV[0]
file_name = pdf_name
base_name = File.basename(pdf_name, '.*')
dir_name  = File.dirname( File.absolute_path( pdf_name ) )
csv_name  = base_name + '.csv'
txt_name  = base_name + '.txt'

if ENV['YNAB_DEBUG']
  puts "Processing: [#{pdf_name}]"
  puts "base: #{base_name}"
  puts "dir: #{dir_name}"
  puts "csv: #{csv_name}"
  puts "txt: #{txt_name}"
end

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

csv   = []

###
### pre-process
###

# simplify: pdf -> txt
system("pdftotext #{pdf_name} -layout #{txt_name}")

# parse txt
File.open( txt_name, :encoding => 'iso-8859-1:utf-8').each do |line|

  line.chomp!
  puts "line: [#{line}]" if ENV['YNAB_DEBUG']

  case line

    when /^\s* #/m
      next

    when /SALDO/
      next

    when /^\s*\d\d[\/]\d\d[\/]\d\d\d\d/x

      puts "line: [#{line}]" if ENV['YNAB_DEBUG']

      day, mes, year, payee, val = line.match( /^\s* (\d\d)[\/](\d\d)[\/](\d\d\d\d) \s+ (\w+ .*) \s+ ([+-] \s R[$] \s [-]?\d?[.]?\d+[,]\d+) /ix ).captures

      dt    = "#{year}/#{mes}/#{day}"
      payee = trim(payee)
      payee = noblanks(payee)
      memo  = payee
      val.gsub!(    ".", ""  )
      val.gsub!(    ",", "." )
      val.gsub!( " R$ ", ""  )  # modal specific

      # date,payee,category,memo,outflow,inflow
      res = "#{dt},#{payee},,#{memo},,#{val}"
      puts "res: [#{res}]" if ENV['YNAB_DEBUG']

      csv << res

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

