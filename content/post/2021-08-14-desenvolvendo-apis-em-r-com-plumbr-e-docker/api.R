
library(DBI)
library(uuid)
library(dplyr)
library(purrr)
library(tibble)
library(plumber)
library(randomNames)

# Criando um DB temporário na memória RAM.
con <- DBI::dbConnect(
  RSQLite::SQLite(), 
  ":memory:")

# Tabela dummy com nossos dados
tbl <- tibble::tibble(
  names = randomNames::randomNames(
    n = 10, 
    name.order = "first.last", 
    name.sep = " "),
  id = uuid::UUIDgenerate(n = 10),
  balance = purrr::rdunif(10, 1, 1000)) %>%
  dplyr::bind_rows(
    tibble::tibble(names = "Maria",
                   id = "123456789t",
                   balance = 420.69))

DBI::dbWriteTable(con, "accounts", tbl)


#---------------

#* Consulta o Banco
#*
#* @param name nome do usuario
#* @param id id do usuario
#*
#* @get /balance
function(name, id) {

  con %>% 
    DBI::dbSendQuery(
      glue::glue("SELECT * 
                 FROM accounts 
                 WHERE id = '{id}' 
                 AND names = '{name}'")) %>%
    DBI::dbFetch() %>%
    dplyr::pull(balance)
}
