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
File.open( txt_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  puts "line 0: [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line
    when /^\s*$/
      next

    when /^[#] \s* Venc \s+/ix
      year = line.match( /^[#] \s* Venc \s+ \d\d[\/]\w+[\/](\d{4})$/ixu ).captures[0]
      puts "Year: #{year}"       if ENV['YNAB_DEBUG']

    when /^\d+/ # \s \w+ \s/

      # number massage
      line.gsub!( /(\d)[.,](\d)/, '\1\2' )

      day, mes, payee, val = line.match( /(\d+) \s+ (\w+) \s+ (\w.+) \s+ ([-]?\d+)$/ixu ).captures
      puts "line 1: [#{day}] [#{mes}] [#{payee}] [#{val}]" if ENV['YNAB_DEBUG']

      dt  = sprintf "%s/%s/%s", year, meses[mes.downcase], day
      val = val.to_f / 100

      csv << "#{dt},#{payee},,,#{val},"

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

