# Ruby Dev Test - Filesystem Model

## Objetivo

Implementar a camada de modelos de um sistema de arquivos persistido em banco de dados SQL, permitindo a criação de diretórios e arquivos com suporte a hierarquia.

O foco da solução está na modelagem do domínio, consistência estrutural e persistência de conteúdo.

---

## Pre-requisitos:

Docker
Docker-compose

## Visão Geral

A solução foi construída utilizando:

- Ruby on Rails
- PostgreSQL
- Active Storage
- Docker

Foram modeladas duas entidades principais:

- `Directory`
- `FileEntry`

A estrutura de diretórios é representada no banco de dados, enquanto o conteúdo dos arquivos é persistido via Active Storage.

---

## Quick Start

```bash
git clone git@github.com:flaviolpgjr/ruby-dev-test-1.git
cd ruby-dev-test-1

docker compose up --build

docker compose run --rm web rails db:create db:migrate

docker compose run --rm web rspec
```

---

## Execução completa

```bash
docker compose up --build

docker compose run --rm web rails db:create
docker compose run --rm web rails db:migrate

docker compose run --rm web rspec

docker compose run --rm web rails filesystem:demo
```

---

## Uso via Rails Console

```bash
docker compose run --rm web rails console
```

### Criando diretórios

```ruby
root = Directory.create!(name: "root")
docs = Directory.create!(name: "docs", parent: root)
invoices = Directory.create!(name: "invoices", parent: docs)

invoices.path
# => "/root/docs/invoices"
```

### Criando arquivos

```ruby
file = FileEntry.create!(name: "report.txt", directory: docs)

file.path
# => "/root/docs/report.txt"
```

### Anexando conteúdo

```ruby
file.content.attach(
  io: StringIO.new("Conteúdo de exemplo"),
  filename: "report.txt",
  content_type: "text/plain"
)
```

### Lendo conteúdo

```ruby
file.content.download.force_encoding("UTF-8")
```

---

## Modelagem de Diretórios

Os diretórios foram modelados utilizando um relacionamento auto-referenciado (`parent_id`), formando uma árvore.

### Regras

- nome obrigatório
- nome único dentro do mesmo diretório pai
- não pode ser pai de si mesmo
- não pode criar ciclos

### Justificativa

Essa abordagem permite modelar hierarquia de forma simples e eficiente, sem necessidade de estruturas mais complexas como nested sets.

---

## Modelagem de Arquivos

Arquivos pertencem obrigatoriamente a um diretório.

### Regras

- nome obrigatório
- nome único dentro do diretório
- diretório obrigatório

### Justificativa

Evita inconsistências e simplifica o domínio. Assume-se um diretório raiz implícito.

---

## Construção de Caminho (Path)

Os caminhos são gerados dinamicamente com base na hierarquia:

```
/root/docs/report.txt
```

### Justificativa

Evita redundância de dados e mantém consistência.

---

## Validação de Ciclo

Foi implementada validação para impedir loops na árvore:

```
A -> B -> C -> A
```

### Justificativa

Mantém integridade estrutural da árvore e evita comportamentos inválidos.

---

## Armazenamento de Arquivos (Active Storage)

O conteúdo dos arquivos é armazenado utilizando Active Storage com backend local.

### Separação de responsabilidades

- Banco → estrutura lógica (Directory / FileEntry)
- Storage → conteúdo físico

### Por que não usar o caminho físico no model?

O caminho físico:

- depende do backend
- pode mudar (S3, disco, etc)
- não faz parte do domínio

Por isso o model expõe apenas o **path lógico**.

---

## Por que não criar diretórios físicos com mkdir

Não foi implementada criação de diretórios físicos como:

```
/root/docs
```

### Justificativa

- foge do escopo do problema
- duplica responsabilidade do Active Storage
- acopla o domínio ao sistema operacional
- aumenta complexidade sem necessidade

O objetivo do teste foi tratado como **modelagem de domínio**, não como implementação de um filesystem real.

---

## Escopo da Solução

O projeto foi mantido dentro do escopo proposto:

✔ Modelagem de diretórios e arquivos  
✔ Hierarquia  
✔ Regras de consistência  
✔ Persistência de conteúdo  

Não foram implementados:

- permissões de usuário
- versionamento
- movimentação de arquivos
- sincronização com filesystem físico

### Justificativa

Esses itens extrapolam o escopo do teste e aumentariam complexidade desnecessária.

---

## Testes

Os testes cobrem:

### Directory

- presença
- unicidade
- hierarquia
- self-parent
- ciclo
- path

### FileEntry

- presença
- diretório obrigatório
- unicidade
- path
- attachment
- persistência de conteúdo

### Active Storage

- attachment funcional
- download correto
- persistência após reload

---

## Task de Demonstração

```bash
docker compose run --rm web rails filesystem:demo
```

Demonstra:

- criação de estrutura
- criação de arquivos
- attachment real
- validações
- persistência

---

## Limpeza de arquivos

O diretório `storage/` está no `.gitignore`.

### Justificativa

- arquivos gerados em runtime
- não devem ser versionados
- recriados automaticamente

Mesmo assim, limpeza em testes/demo pode ser utilizada para evitar acúmulo local.

---

## Internacionalização (I18n)

Mensagens configuradas em `pt-BR`.

### Justificativa

- melhor legibilidade
- alinhamento com boas práticas
- suporte a expansão futura

---

## Docker

O projeto foi containerizado para:

- facilitar execução
- eliminar dependências locais
- garantir ambiente consistente

---

## Banco de Dados

Foi utilizado PostgreSQL.

### Credenciais no docker-compose


### Por que isso foi feito?

- ambiente local de teste
- não exposto publicamente
- reduz fricção para avaliação

### Em produção

Seria obrigatório:

- uso de variáveis de ambiente
- secret management

---

## Considerações Finais

A solução prioriza:

- clareza de domínio
- separação entre domínio e infraestrutura
- consistência de dados
- simplicidade controlada

A estrutura de diretórios foi tratada como modelo lógico, enquanto a persistência física foi delegada ao Active Storage.

Essa separação mantém o sistema mais flexível, previsível e alinhado com práticas modernas.

