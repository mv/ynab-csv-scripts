YNAB: CSV scripts
-----------------

Simple/dirty scripts that genetares CSV files for YNAB 4.

## Usage

To run any script:

    bin/script-name   path/to/file.ext


A new file named _**script-name.ynab.csv**_ will be created, ready to be imported into YNAB.


### Debug

For some debug information try to use:

    export YNAB_DEBUG=1

in the command line before running a script.

To show the results without saving to a new file try:

    export YNAB_STDOUT=1


## Get the information

1. [Amex Brasil](https://www.americanexpress.com/br/)

    Type: PDF
        Extrato de Conta -> Consulta por Periodo -> [Download PDF]

2. [Banco do Brasil](https://conta.nubank.com.br)

    Type: OFX
        Conta Corrente -> Extrato -> Aba: mes/ano
        -> Clique Icone Download -> OFX


3. [CEF](https://internetbanking.caixa.gov.br/)

    Type: TXT
        Servicos -> Extrato -> 90 dias
        -> Imprimir Extrato

4. [Modal Mais](https://www.modalmais.com.br)

    Type: PDF
        Servicos -> Extrato -> 90 dias
        -> Imprimir Extrato

5. [Nubank Brasil](https://conta.nubank.com.br)

    Type: CSV
        Faturas -> [Periodo Desejado] -> Exportar para CSV


6. [Rico](https://www.rico.com.vc/)

    Type: PDF
        Minha Conta: Extrato
        -> Periodo de: dd/mm/yyyy
        -> até:        dd/mm/yyyy
        -> IMPRIMIR

7. [Satander](https://www.santander.com.br/)

    Type: CSV


8. [Sofisa Direto](https://www.sofisadireto.com.br)

    Type: PDF
        Extrato
        -> De:  dd/mm/yyyy
        -> até: dd/mm/yyyy
        -> Gerar PDF

9. [XP Investimentos](https://conta.nubank.com.br)

    Type: PDF
        Investimentos -> Conta Corrente -> Extrato
        -> Data:  mm/ano
        -> Ordem: Movimento


## References

1. [YNAB CSV Importing](http://www.youneedabudget.com/support/article/csv-file-importing)


