#!/usr/bin/env ruby

require 'date'

###
### TODO: improve command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-santander-cc-copy-paste

  USAGE
  exit 1
end

usage if ARGV.empty?

file_name = ARGV[0]

###
### Main
###

csv = []
due_date = ''

# force encoding: avoid pt-br issues
File.open( file_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line  [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line

    # ignore most lines...
    when /^\s*$/
      next

    # ... except an entry with a full date and details.
    when /^ \d{2} [\/] \d{2} [\/] \d{4} \s+ \w+/ix

      # remove number separator and decimal (so I can use a simpler regex)
      line.gsub!( /(\d)[.](\d)/, '\1\2' )
      line.gsub!( /(\d)[,](\d)/, '\1\2' )
      puts "entry [#{line.chomp}]" if ENV['YNAB_DEBUG']
      # regex: simpler
      dt, payee, val, dolar = line.match( /^ (\d{2}[\/]\d{2}[\/]\d{4}) \s+ (\w.+) \s+ ([-]?\d+) \s+ ([-]?\d+) $/ixu ).captures

      # 'parse time' -> 'format time'
      dt   = Date.strptime( dt, "%d/%m/%Y" ).strftime( "%Y/%m/%d" )

      # string back to number
      val  = sprintf("%.2f", val.to_f / 100)

    # due date: for taxes
    when /^ \d{2} [\/] \d{2} [\/] \d{4}$/x

      due_date = line.match( /^ (\d{2}[\/]\d{2}[\/]\d{4}) $/x ).captures[0]
      puts "due   [#{due_date}]" if ENV['YNAB_DEBUG']
      next

    # capture taxes
    when /^Multa por atraso/i , /^Juros de mora/i , /^[(][+][)]Encargos/i

      payee, val = line.match( /(\w.+)[:] \s+ (.+) $/xu ).captures

      dt  = Date.strptime( due_date, "%d/%m/%Y" ).strftime( "%Y/%m/01" )
      val = sprintf("%.2f", val.gsub( /[.,]/, '' ).to_f / 100)

      puts "tax   [#{dt} - #{payee} : #{val}]" if ENV['YNAB_DEBUG']

      next if val == '0.00' # no tax: ignore

    # ignore everything else
    else
      next

  end # case line

  ###
  ### build entry result
  ###

  memo = payee

  # date,payee,category,memo,outflow,inflow
  res = "#{dt},#{payee},,#{memo},#{val},"
  puts "res   [#{res}]" if ENV['YNAB_DEBUG']

  csv << res

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

