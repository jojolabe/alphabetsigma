---
title: Github Actions com para Data Science
author: 'João Pedro Oliveira'
date: '2021-07-16'
slug: []
categories: []
tags: []
Description: ''
Tags: []
Categories: []
DisableComments: no
comment: no
toc: no
autoCollapseToc: no
postMetaInFooter: no
hiddenFromHomePage: no
contentCopyright: no
reward: no
mathjax: yes
mathjaxEnableSingleDollar: yes
mathjaxEnableAutoNumber: no
hideHeaderAndFooter: no
---


# Github Actions em Dados

*Por:*  @João Pedro Santos 

O *Github Actions* (GA) é uma ferramenta que é utilizada extensamente pela Comadre - lugar onde trabalho -, e o time de dados não é uma exceção. A ferramenta nos permite automatizar a execução de rotinas - cada rotina no GA é chamada de *Workflow* - de testes e verificações de cobertura de código. Isso faz com que tenhamos uma menor quantidade de erros em produção, pois eles são identificados ainda durante o desenvolvimento das aplicações. O Actions é uma funcionalidade *event-based*, isto é, sua execução ocorre quando algo - geralmente um *commit* - acontece em determinado repositório.

Todavia, o serviço não é um serviço gratuito. A Comadre possui contratada uma *quota* mensal de minutos de execução, e é importante que configuremos o serviço para que ele seja o mais ágil e eficiente possível. O uso de minutos varia conforme as especificações de determinado `workflow` — [dica: instâncias em MacOS consomem 10 vezes mais da sua quota, evite-as](https://docs.github.com/pt/billing/managing-billing-for-github-actions/about-billing-for-github-actions). Portanto, nesse breve tutorial aprenderemos a configurar o Actions para as aplicações de dados em `R` e `Python`.

### Actions Basics

Para criar uma *Action*, devemos estar em um repositório GitHub hospedado remotamente, e estando dentro dele criar um diretório chamado `.github`, e dentro dele criar o diretório `Workflows`, dentro deste último é o local onde colocaremos nossos *Workflows*, que dirão ao serviço quais tarefas desejamos realizar, e quando queremos realizá-las. Temos agora a seguinte estrutura de pastas no nosso repositório:

```bash
.
 └── .github
     └── workflows
```

Todo Workflow é um arquivo `YAML`, e por conta disso segue uma sintaxe especifica, porém bem simples. Cada *Workflow* é composto por *jobs*, e cada *job* é composto por uma sequencia de etapas (*steps*), e que quando executados em determinada ordem, devem executar a nossa tarefa. 

*Recapitulando:*

1. Um *step* é a unidade básica de uma Action, e diz qual ação deve ser realizada.
2. Um *job* é a unidade intermediária, e é o conjunto de *steps,* realizando uma tarefa maior. Ele controla a ordem das tarefas, executando-as sequencialmente.
3. Workflow é o conjunto de jobs e todas as outras instruções adicionais, como qual tipo de evento serve como gatilho para a execução do serviço.

Segue abaixo uma estrutura básica com a explicação do que faz cada uma das possíveis instruções:

```yaml
on: # <- Quais eventos devem executar o workflow
  pull_request: # <- Quando alguém abrir um pull request direcionado a branch abaixo
    branches:
      - main

name: Unit Testing Routine # <- Nome do Workflow

jobs: # <- Indica que a partir de agora listaremos os trabalhos a serem executados
  testando: # <- Nome para o job.
    runs-on: ubuntu-latest # <- Sistema Operacional da Execuçao (Prefira Linux)
    steps: # <- Quais passos devem ser executados
      - name: Printa "ECO" no shell # <- Nome para o *step*
	run: | 
          echo "ECO" 
```

A Action acima será executada em todo *commit* feito em um repositório que ter como alvo a *`main` branch.* A tarefa executada consiste em iniciar uma instância de uma máquina rodando a versão mais recente da distribuição GNU/Linux Ubuntu, iniciar uma instância do Terminal, e dentro dele executar o comando `echo "ECO"`.

[Veja AQUI a documentaçao do Github Actions caso tenha dúvidas adicionais.](https://docs.github.com/pt/actions)

---

### Utilizando o Github Actions em um projeto escrito em R.

Como o *chapter* de dados possui as Práticas e Convenções - Dados, que sao um conjunto de boas práticas do nosso time. Seguindo elas torna-se extremamente simples desenhar um *Workflow* rápido e funcional. O que nos objetivamos é executar os testes automatizados da biblioteca hospedada no repositório, para isso devemos executar a função `testthat::test_local()`, que é suficiente para executar a tarefa. 

- *Package Version Control* adiciona agilidade.

Todavia, isso só é possível caso estejamos fazendo o uso da `renv`, para controle de versão de bibliotecas e armazenamento delas em um cache. O que ocorre é que toda vez que instalamos uma biblioteca por meio da `{renv}`, esta armazena o pacote em um *cache* global. O que este *cache* faz é guardar aquela versão da biblioteca, que é recuperada ela caso seja demandada futuramente. Isso propicia uma instalação dezenas de vezes mais rápida do que ocorreria caso fosse necessário realizar o download e a compilação do *package*.

Os passos a serem seguidos pelo nosso *job* são os seguintes:

1. Iniciar uma instância com Ubuntu Linux
2. Fazer o *setup* de um ambiente de programação com o R.
3. Instalar o [cURL](https://pt.wikipedia.org/wiki/CURL)
4. Restaurar o cache de bibliotecas da `{renv}` - acontece somente caso o cache exista.
5. Se o cache não existir, fazer o download e instalação de todas bibliotecas necessárias - essa etapa pode demorar alguns minutos.
6. Executar os testes com a `{testthat}`.
7. **(?)** Salvar o cache de bibliotecas para agilizar execução futura - acontece somente se a execução for um sucesso.

```yaml
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

name: Unit Testing Routine

jobs:
  Testthat-run_tests_r:
    runs-on: ubuntu-latest # <- [1]
    steps:
      - uses: actions/checkout@v2

      - uses: r-lib/actions/setup-r@v1 # <- [2]

      - name: Install Curl # <- [3]
        run: |
          sudo apt-get update
          sudo apt-get install libcurl4-openssl-dev

      - name: Restore R package cache # <- [4-5-7**(?)**]
        uses: actions/cache@v2
        with:
          path: ~/.local/share/renv
          key: ${{ runner.os }}-renv-${{ hashFiles('**/renv.lock') }}
          restore-keys: |
            ${{ runner.os }}-renv-
      
      - name: Run tests # <- [6]
        run: |
          testthat::test_local()
        shell: Rscript {0}
```

### Utilizando o Github Actions em um projeto escrito em Python.

Quando usando Python, trabalhamos usando a suíte de testes do `pytest` e o linter do `flake8`, este último que garante que o código esteja de acordo com as [PEPs](https://www.python.org/dev/peps/). Como toque final, nós utilizamos a biblioteca `coverage-badge`, que adiciona na nossa `README.md` uma badge de cobertura de código, esta indica quantos $%$%'s das funções do nosso repositório estão testadas. A estrutura básica do *Workflow* é a mesma, com poucas diferenças, como podemos ver abaixo:

```yaml
name: Testes Automatizados
on:
    push:
      branches: [ main ]
    pull_request:
      branches: [ main ]
      
jobs:
  tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8]

    steps:
      - uses: actions/checkout@v2
      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v2
        with:
          python-version: ${{ matrix.python-version }}
          
      - name: Get pip cache
        id: pip-cache
        run: |
          echo "::set-output name=dir::$(pip cache dir)"
      
      - name: pip cache
        uses: actions/cache@v2
        with:
          path: ${{ steps.pip-cache.outputs.dir }}
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
          restore-keys: |
            ${{ runner.os }}-pip-
          
      - name: Instalar das Dependencias
        run: |
          python -m pip install --upgrade pip
          pip install flake8 pytest coverage-badge
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          
      - name: Lint com o flake8
        run: |
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
          flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
          
      - name: Executa os Testes e Code Cov
        run: |
          coverage run -m pytest tests/
          coverage-badge -f -o coverage.svg
      - uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: Badge de Coverage
```

As únicas novidades do *Workflow* são as linhas:

```yaml
    strategy:
      matrix:
        python-version: [3.8]
```

O que elas fazem é indicar as versões do software em que o *Workflow* deve ser executado. Esse valor é recuperado por `${{ matrix.python-version }}` que indica para outras etapas. Caso `python-version` contenha mais de um valor, como por exemplo `[3.7, 3.8]`, o Workflow será executado duas vezes, uma vez em cada uma das versões de Python.

Também podemos notar a novidade que é:

```yaml
      - name: Executa os Testes e Code Cov
        run: |
          coverage run -m pytest tests/
          coverage-badge -f -o coverage.svg
      - uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: Badge de Coverage
```

O que elas fazem é executar os testes usando o pytest, e usar o resultado da execuçao para gerar uma badge com a cobertura de testes - sem que voce precise utilizar serviços como o Coveralls -, mais informaçoes sobre essa badge e como fazer com que ela seja exibida na sua [`README.md`](http://readme.md) podem ser encontradas [aqui](https://pypi.org/project/coverage-badge/). Além de gerar a badge, essas linhas enviam a badge atualizada para o seu repositório - [documentaçao aqui](https://github.com/stefanzweifel/git-auto-commit-action).

**Lembre-se sempre de manter sua requirements.txt atualizada, é ela que o Github Actions usa como base para instalar as bibliotecas necessárias para seu projeto.**

É isso ai, abraços.
