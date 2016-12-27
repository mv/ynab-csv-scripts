#!/usr/bin/env ruby

require 'date'

###
### file name
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path/to/edited/file.txt

  USAGE
  exit 1
end

usage if ARGV.empty?

file_name  = ARGV[0]
base_name = File.basename(file_name, '.*')
dir_name  = File.dirname( File.absolute_path( file_name ) )
csv_name  = base_name + '.ynab.csv'


if ENV['YNAB_DEBUG']
  puts "Processing: [#{file_name}]"
  puts "base: #{base_name}"
  puts "dir:  #{dir_name}"
  puts "csv:  #{csv_name}"
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

def fix_spaces( memo )
  memo = trim( memo )
  memo = noblanks( memo )
end

def fix_val( val, oper = '' )
  val = val.gsub( ".", ""  )
  val = val.gsub( ",", "." )
  val = "#{oper}#{val}"   # negative sign
end

flag = 'start'
csv  = []
payee, memo, val = ''
dt, day, mes = ''
year = '----'

###
### Parse
###

# parse txt
File.open( file_name, :encoding => 'utf-8').each do |line|

  puts "line: [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line

    # get current year
    when /^Vencimento \s+ (\d\d\d\d)/xi

      year = $1
      puts "line: [year=#{year}]" if ENV['YNAB_DEBUG']

      next


    # entries
    #
    when /^ (\d\d*)[\/](\d\d*) \s+ (\w .*) \s+ ([-]?\d*[.]?\d+[,]\d\d) /x

      day, mes, memo, val = $1, $2, $3, $4

      dt    = "#{year}/#{mes}/#{day}"
      memo  = fix_spaces(memo)
      val   = fix_val(val)

      # parcelas
      if parc = memo.match( /PARC \s+ (\d\d) /x )
         parc = parc.captures[0].to_i

         # add months
         parc_dt = Date.strptime( dt, "%Y/%m/%d" )
         parc_dt = parc_dt >> ( parc - 1 )

         # fix year overflow
         if parc >= mes.to_i or       # parc number greater than entry month
            parc_dt.year > year.to_i  # year in the future
            parc_dt = parc_dt << 12   # go back 12 months
         end

         dt = parc_dt.strftime( "%Y/%m/%d" )
         puts "parc: parc=#{parc} dt=#{dt}"
      end

      # fix payee
      payee = memo.split.map(&:capitalize).join(' ') # Capitalize
      payee.gsub!( /\s* PARC \s+ \d\d[\/]\d\d/ix , '')

      # date,payee,category,memo,outflow,inflow
      res = "#{dt},#{payee},,#{memo},#{val},"
      puts "res : [#{res}]" if ENV['YNAB_DEBUG']
      csv << res

  end # case line

end # file

###
### Result
###
File.open(csv_name, 'w') do |f|
  f.puts("Date,Payee,Category,Memo,Outflow,Inflow")
  csv.each { |c| f.puts(c) }
end

puts "Created: [#{csv_name}]"

