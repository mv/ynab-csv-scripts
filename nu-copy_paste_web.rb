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

year  = ''
meses = {
   'jan' => '01' ,
   'fev' => '02' ,
   'mar' => '03' ,
   'abr' => '04' ,
   'mai' => '05' ,
   'jun' => '06' ,
   'jul' => '07' ,
   'ago' => '08' ,
   'set' => '09' ,
   'out' => '10' ,
   'nov' => '11' ,
   'dez' => '12' ,
}


###
### simple process
###

csv = []
File.open( file_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line:  [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line
    when /^\s*$/
      next

    when /^[#] \s* Venc \s+/ix
      year = line.match( /^[#] \s* Venc \s+ \d\d[\/]\w+[\/](\d{4})/ixu ).captures[0]
      puts "Year: #{year}"       if ENV['YNAB_DEBUG']

    when /^\d+/ # \s \w+ \s/

      # number massage
      line.gsub!( /(\d)[.,](\d)/, '\1\2' )

      day, mes, payee, val = line.match( /(\d+) \s+ (\w+) \s+ (\w.+) \s+ ([-]?\d+)$/ixu ).captures
      puts "match: [#{day}] [#{mes}] [#{payee}] [#{val}]" if ENV['YNAB_DEBUG']

      dt  = sprintf "%s/%s/%s", year, meses[mes.downcase], day
      val = val.to_f / 100

      payee = noblanks(trim(payee.split.each{ |w| w.capitalize!}.join(' ')))
      csv << "#{dt},#{payee},,#{payee},#{val},"

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

