#!/usr/bin/env ruby
#
#

require 'pp'

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

flag  = 'ignore'
entry = {}
sections = %w( real dolar taxa )
sections.each{ |s| entry[ s ] =  [] }

# entry = {
#   'real'  => [],
#   'dolar' => [],
#   'taxa'  => []
# }

meses = {
   'janeiro'     => '01' ,
   'fevereiro'   => '02' ,
   'março'       => '03' ,
   'abril'       => '04' ,
   'maio'        => '05' ,
   'junho'       => '06' ,
   'julho'       => '07' ,
   'agosto'      => '08' ,
   'setembro'    => '09' ,
   'outubro'     => '10' ,
   'novembro'    => '11' ,
   'dezembro'    => '12' ,
}


###
### pre-process
###

File.open('1.txt', :encoding => 'iso-8859-1:utf-8').each do |line|

  puts "line 0: [#{flag}] [#{line.chomp}]" if ENV['YNAB_DEBUG']
# puts "line 0: [#{flag}] [#{line.encoding}] [[#{line.chomp}]" #if ENV['YNAB_DEBUG']

  case line

  ###
  ### Sections
  ###
  when /^DESPESAS EM REAL/i
    flag = 'real'
    next
  when /^DESPESAS EM MOEDA ESTRANGEIRA/i
    flag = 'dolar'
    next
  when /^OUTROS LAN/i
    flag = 'taxa'
    next
  when /^Total/i
    flag = 'ignore'
    next


  ###
  ### Entries
  ###
  when /^\d+ \s de \s/ix
    puts "line 1: [#{flag}] [#{line.chomp}]" if ENV['YNAB_DEBUG']

    case flag
    when 'real', 'dolar'
      hash = { 'info' => trim(line), 'descr' => [] }
      entry[ flag ].push hash
    when 'taxa'
      entry[ flag ].push trim(line)
    when 'ignore'
      next
    end # case flag

  when /^\s+ \w*/
    puts "line 2: [#{flag}] [#{line.chomp}]" if ENV['YNAB_DEBUG']

    case flag
    when 'real', 'dolar'
      entry[ flag ][ -1 ]['descr'].push trim(line)  # add to the last 'entry'
    when 'ignore'
      next
    end # case flag

  end # case line

end # file

###
### Parse
###
csv = []
sections.each do |section|

  entry[section].each do |e|

#   puts "entry for [#{section}] [#{e['info']}]"
    ## info
    case section
    when 'real'
      day, mes, payee, val = e['info'].match( /^(\d+) \s de \s (\w+) \s* (\w.*) \s+ ([.]?\d+.*)$/ixu ).captures
      descr = e['descr'].join(' / ')

    when 'dolar'
      day, mes, payee, dolar, val = e['info'].match( /^(\d+) \s de \s (\w+) \s* (\w.*) \s+ ([.]?\d+.*) \s+ ([.]?\d+.*)$/ixu ).captures
      dolar = dolar.gsub(/[.,]/, '').to_f / 100
      descr = e['descr'].join(' / ')

    when 'taxa'
      day, mes, payee, val = e.match( /^(\d+) \s de \s (\w+) \s* (\w.*) \s+ (\d+.*)$/ixu ).captures
      descr = 'outros'

    end

    dt  = sprintf "%02d/%s/2014", day, meses[mes.downcase]
    val = val.gsub(/[.,]/, '').to_f / 100

    csv << "'#{dt}','#{trim(payee)}','categ','#{section.capitalize} - #{noblanks(descr)}','#{val}',''"

  end

end

###
### Result
###

pp entry
pp csv

