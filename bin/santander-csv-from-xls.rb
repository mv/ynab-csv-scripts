#!/usr/bin/env ruby

require 'csv'
require 'date'

###
### TODO: improve command line parameters
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} path-to-santander-csv

  USAGE
  exit 1
end

usage if ARGV.empty?

file_name = ARGV[0]
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

def fix_val( val, oper )
  val = val.gsub( ".", ""  )
  val = val.gsub( ",", "." )
  val = "#{oper}#{val}"   # negative sign
end

def fix_payee( line, new_payee )
  a = line.split( "," )
  memo  = a[1] + " " + a[3]
  a[1]  = new_payee
  a[3]  = memo
  a.join(",")
end

###
### Main
###

csv = []

# force encoding: avoid pt-br issues
File.open( file_name, :encoding => 'iso-8859-1:utf-8' ).each do |line|

  line.chomp!
# line = line + ";"
  puts "line [#{line.chomp}]" if ENV['YNAB_DEBUG']

  case line

    # ignore (just in case)
    when /^\s*$/ # blank lines
      next
    when /^\s*#/ # my comments
      next

    # ignore Santander stuff
    when /^['"]?Data/i
      next
    when /SALDO ANTERIOR/i
      next
    when /^['"]?Total/i
      next
    when /^;['"]?SubTotal/i
      next

    else
      # xls to CSV fixes
      line.gsub!( /[ ][;]/ , ';' )   # [30/04/2017 ;SALDO ANTERIOR ; ; ; ;"2.666,95 "]
      line.gsub!( /[ ]["]/ , '"' )
      line.gsub!( /\s+/ , ' ')  # reduce multiple spaces

      puts "line [#{line}]" if ENV['YNAB_DEBUG']

      CSV.parse( line, options = { :col_sep => ';' } ) do |row|
        puts "row: [#{row}]" if ENV['YNAB_DEBUG']

        # 'parse time' -> 'format time'
        dt    = Date.strptime( row[0], "%d/%m/%Y" ).strftime( "%Y/%m/%d" )
        payee = row[1].gsub( /[ ]+/, " " )
        memo  = payee
        memo  = payee + " - NroDoc: " + row[2] if row[2] != "000000" # add if present
        inflow  = row[3]
        outflow = row[4]

        # date,payee,category,memo,outflow,inflow
        res = "#{dt},#{payee},,#{memo},#{outflow},#{inflow}"
        puts "res: [#{res}]" if ENV['YNAB_DEBUG']

        csv << res
      end

  end # case line

end # file

###
### Result
###
File.open(csv_name, 'w') do |f|
  f.puts("Date,Payee,Category,Memo,Outflow,Inflow")
  csv.each do |c|

    case c # csv string

    ###
    ### Transferencia entre contas
    ###
    when /TRANSFERENCIA ENTRE CONTAS/
      c = fix_payee( c, 'Transferencia entre Contas' )

    when /TRANSF VALOR/
      c = fix_payee( c, 'Transferencia entre Contas' )

    ###
    ### IOF do Periodo
    ###
    when /Periodo[:].*IOF/
      c = fix_payee( c, 'IOF do Periodo' )

    ###
    ### TED/DOC
    ###
    when /TED RECEB/
      c = fix_payee( c, 'TED Receb' )

    when /TED DIFERENTE TITULAR/
      c = fix_payee( c, 'TED Diferente titularidade' )

    when /DOC \w RECEB/
      c = fix_payee( c, 'DOC Recebido' )

    when /EMISSAO DE DOC/
      c = fix_payee( c, 'Emissao de DOC')

    ###
    ### Credito de Salario
    ###
    when /CREDITO DE SALARIO/
      c = fix_payee( c, 'Credito de Salario' )

    ###
    ### DARF
    ###
    when /PAGAMENTO DARF/
      a = c.split( "," )
      a[1] = "Pagamento DARF"
      c = a.join( "," )


    end

    f.puts(c)
  end
end

puts "Created: [#{csv_name}]"

