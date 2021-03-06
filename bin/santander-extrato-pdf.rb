#!/usr/bin/env ruby

###
### file name
###
def usage()
  puts <<-"USAGE"

  Usage: #{$0} santander-extrato-pdf.rb

  USAGE
  exit 1
end

usage if ARGV.empty?

pdf_name  = ARGV[0]
base_name = File.basename(pdf_name, '.*')
dir_name  = File.dirname( File.absolute_path( pdf_name ) )
csv_name  = base_name + '.ynab.csv'
txt_name  = base_name + '.pdf.txt'

if ENV['YNAB_DEBUG']
  puts "Processing: [#{pdf_name}]"
  puts "base: #{base_name}"
  puts "dir:  #{dir_name}"
  puts "csv:  #{csv_name}"
  puts "txt:  #{txt_name}"
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

flag = 'start'
csv  = []
payee, memo, val = ''
dt, day, mes = ''
year = '----'

###
### pre-process
###

# simplify: pdf -> txt
system("pdftotext #{pdf_name} -layout #{txt_name}")

# parse txt
File.open( txt_name, :encoding => 'iso-8859-1:utf-8').each do |line|

  puts "line 0: [#{flag}] [#{line.chomp[0..120]}]" if ENV['YNAB_DEBUG']
# next

  case line

    ###
    ### Sections
    ###

    when / \s+ Movimentação \s* $/xu
      flag = 'contacorrente'
      next
    when /^ \s+ Saldos \s por \s Per/x
      flag = 'ignore'
      next

    next if flag == 'ignore'

    ###
    ### Specifics
    ###
    when /SALDO EM \d\d[\/]\d\d/
      # begin of section
      next if dt == ''

      # end of section
      flag = 'ignore' if dt != ''
      next

    # pdf page break
    when /Data \s+ Descr/x
      next

    ###
    ### Entries
    ###


    # get current year
    when /^Extrato_PF_Inteligente - \d\d*[\/]\d\d*[\/](\d\d\d\d)/

      next unless year == '----'

      year = $1
      puts "line z: [year=#{year}]" if ENV['YNAB_DEBUG']

      next


    # contacorrente: entry 1: begin with date
    #     dd/mm   doc   memo   val[oper]  [saldo]
    #
    when /^ \s+ (\d+)[\/](\d+) \s+ (\w+ .*) \s+ (\d+|[-]) \s+ (\d*[.]?\d+[,]\d\d)([-])? /x

      next unless flag == 'contacorrente'

      puts "line 1: [#{flag}]+[#{line.chomp}]","" if ENV['YNAB_DEBUG']

      oper = ''
      day, mes, memo, doc, val, oper = $1, $2, $3, $4, $5, $6

      dt    = "#{year}/#{mes}/#{day}"
      memo  = fix_spaces(memo)
      payee = memo.split.map(&:capitalize).join(' ') # Capitalize

      memo  = "#{memo} - #{doc}" unless doc == "-"
      val   = fix_val(val,oper)

      puts   "line 1" if ENV['YNAB_DEBUG']
      printf "line 1: [%s]+[ dt=[%s] doc=[%s] val=[%s] oper=[%s] memo=[%s] ]\n",flag,dt,doc,val,oper,memo if ENV['YNAB_DEBUG']

      # date,payee,category,memo,outflow,inflow
      res = "#{dt},#{payee},,#{memo},,#{val}"
      puts "line 1: res: [#{res}]" if ENV['YNAB_DEBUG']
      puts "line 1","" if ENV['YNAB_DEBUG']
      csv << res


    # contacorrente: entry 2: full entry with no date: keep the same day
    #     memo  doc  val[oper]  [saldo]
    when /^ \s+ (\w+ .*) \s+ (\d+|[-]) \s+ (\d*[.]?\d+[,]\d\d)([-])? /x

      next unless flag == 'contacorrente'

      puts "line 2: [#{flag}]+[#{line.chomp}]","" if ENV['YNAB_DEBUG']

      oper = ''
      memo, doc, val, oper = $1, $2, $3, $4

      memo  = fix_spaces(memo)
      payee = memo.split.map(&:capitalize).join(' ')

      memo  = "#{memo} - #{doc}" unless doc == "-"
      val   = fix_val(val,oper)

      puts   "line 2" if ENV['YNAB_DEBUG']
      printf "line 2: [%s]+[ dt=[%s] doc=[%s] val=[%s] oper=[%s] memo=[%s] ]\n",flag,dt,doc,val,oper,memo if ENV['YNAB_DEBUG']

      # date,payee,category,memo,outflow,inflow
      res = "#{dt},#{payee},,#{memo},,#{val}"
      puts "line 2: res: [#{res}]" if ENV['YNAB_DEBUG']
      puts "line 2","" if ENV['YNAB_DEBUG']
      csv << res

    # contacorrente: entry 3: a previous date + description only: payee
    #     dd/mm   payee
    #
#   when /^ \s+ (\d+[\/]\d+) \s{1} (?:\d\d[:]\d\d)? \s{1} (\w+ .*) /x
    when /^ \s+ (\d+[\/]\d+) \s{1} (\w+ .*) /x

      next unless flag == 'contacorrente'

      puts "line 3: [#{flag}]+[#{line.chomp}]","" if ENV['YNAB_DEBUG']

      dt_at, payee = $1, $2
      payee = fix_spaces(payee)

      # some entries have 'HH:mm'
      payee.gsub!( /\d\d[:]\d\d \s/x, '' )
      payee = payee.split.map(&:capitalize).join(' ')

      # redo last entry
      memo = "#{dt_at} | #{payee} - #{memo}"
      sink = csv.pop  # ignore

      puts   "line 3" if ENV['YNAB_DEBUG']
      printf "line 3: [%s]+[ dt=[%s] doc=[%s] val=[%s] oper=[%s] memo=[%s] ]\n",flag,dt,doc,val,oper,memo if ENV['YNAB_DEBUG']

      # date,payee,category,memo,outflow,inflow
      res = "#{dt},#{payee},,#{memo},,#{val}"
      puts "line 3: res: [#{res}]" if ENV['YNAB_DEBUG']
      puts "line 3","" if ENV['YNAB_DEBUG']
      csv << res

    # contacorrente: entry 4: description only: payee
    #     payee
    #
    when /^ \s+ (\w+ .*) /x

      next unless flag == 'contacorrente'
      next if     dt   == ''  # only if previous entry was parsed

      puts "line 4: [#{flag}]+[#{line.chomp}]","" if ENV['YNAB_DEBUG']

      payee = $1
      payee = fix_spaces(payee)
      payee = payee.split.map(&:capitalize).join(' ')

      # redo last entry
      sink = csv.pop  # ignore

      puts   "line 4" if ENV['YNAB_DEBUG']
      printf "line 4: [%s]+[ dt=[%s] doc=[%s] val=[%s] oper=[%s] payee=[%s] ]\n",flag,dt,doc,val,oper,payee if ENV['YNAB_DEBUG']

      # date,payee,category,memo,outflow,inflow
      res = "#{dt},#{payee},,#{memo},,#{val}"
      puts "line 4: res: [#{res}]" if ENV['YNAB_DEBUG']
      puts "line 4","" if ENV['YNAB_DEBUG']
      csv << res

  end # case line

end # file

###
### Result
###
File.open(csv_name, 'w') do |f|
  f.puts("Date,Payee,Category,Memo,Outflow,Inflow")
  csv.each do |c|

    case c # memo

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

###
### Cleanup
###
File.unlink(txt_name) unless ENV['YNAB_DEBUG']

