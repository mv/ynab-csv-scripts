#!/usr/bin/env ruby

###
### file name
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-nubank-txt

  USAGE
  exit 1
end

usage if ARGV.empty?

txt_name  = ARGV[0]
base_name = File.basename(txt_name, '.*')
dir_name  = File.dirname( File.absolute_path( txt_name ) )
csv_name  = base_name + '.csv'

if ENV['YNAB_DEBUG']
  puts "Processing: [#{txt_name}]"
  puts "base: #{base_name}"
  puts "dir: #{dir_name}"
  puts "csv: #{csv_name}"
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


###
### simple process
###

csv = []
File.open( txt_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line 0: [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line
    when /^\s*$/
      next

    when /^Saldo/i
      next

    when /^[#]/
      next

    when /^\d+[\/]\d+[\/]\d+/

      # number massage
      line.gsub!( /(\d)[.,](\d)/, '\1\2' )

      # just in case
      line = trim(line)

      # take it...
      day, mon, year, payee, val, dolar = line.match( /^(\d+)[\/](\d+)[\/](\d+) \s+ (\w.+) \s+ ([-]?\d+) \s+ ([-]?\d+)$/ixu ).captures
      puts "line 1: [#{day}] [#{mon}] [#{year}] [#{payee}] [#{val}] [#{dolar}] " if ENV['YNAB_DEBUG']

      dt    = sprintf "%s/%s/%s", year, mon, day
      val   = val.to_f / 100
      dolar = dolar.to_f / 100

      payee = noblanks(trim(payee.split.each{ |w| w.capitalize!}.join(' ')))
      memo  = payee
      memo  = "#{payee} (dolar: US$ #{dolar})" unless dolar == 0
      csv << "#{dt},#{payee},,#{memo},#{val},"

  end # case line

end # file

###
### Result
###
file = File.open(csv_name, 'w')
file.write("Date,Payee,Category,Memo,Outflow,Inflow\n")
file.write(csv.sort.join("\n"))
file.write("\n")
file.close

puts "Created: [#{csv_name}]"

# pp entry
# pp csv
# puts "year: #{year}"

