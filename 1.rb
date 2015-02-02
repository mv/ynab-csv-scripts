#!/usr/bin/env ruby
#
#

require 'pp'

def trim( line )
  line.gsub(/^\s+|\s+$/,'')
# line.gsub(/\s{2,}/,'')
end


file = File.open('1.txt', :encoding => 'windows-1251:utf-8')

flag  = 'ignore'
entry = {
  'real'  => [],
  'dolar' => [],
  'taxa'  => []
}

file.each do |line|

  puts "line 0: [#{flag}] [#{line.chomp}]" if ENV['YNAB_DEBUG']

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

pp entry

# when /^\d \s de \s/ix
#
#   puts "line 1: [#{line.chomp}]"
#
#   day, mes, descr, val = line.match( /^(\d+) \s de \s (\w+) \s* (\w.*) \s+ (\d+.*)$/ixu ).captures
#
#   dt  = sprintf "2014-%s-%02d", mes.downcase, day
#   val = val.gsub(/[.,]/, '').to_f / 100
#   descr.gsub!(/\s+$/,'')
#
#   printf "line 1. [%-14s] [%9.2f] [%s]\n\n", dt, val, descr
# end

# when /^(\d+) \s de \s (\w+) \s* (\w.*) \s+ (\d+.*)$/ixu
#
#   puts "line 1: [#{line.chomp}]"
#
#   day, mes, descr, val = $1, $2, $3, $4
#
#   dt  = sprintf "2014-%s-%02d", mes.downcase, day
#   val = val.gsub(/[.,]/, '').to_f / 100
#   descr.gsub!(/\s+$/,'')
#
#   printf "line 1. [%-14s] [%9.2f] [%s]\n\n", dt, val, descr
# end

