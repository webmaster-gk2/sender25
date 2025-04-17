# Setup de Desenvolvimento – Sender25

Este documento descreve o processo de configuração do ambiente de desenvolvimento local para o Sender25 (baseado no Sender25 3.3.4) utilizando DevContainer (VS Code + Docker) e Docker Compose. Siga os passos abaixo para que todos os membros da equipe possam configurar o ambiente de forma idêntica e padronizada.

---

## Pré-requisitos

- **Docker** e **Docker Compose** instalados no sistema.  
    [Docker Desktop para Linux](https://docs.docker.com/engine/install/fedora/) ou as instruções específicas para Fedora.
- **Git** para clonar o repositório.
- Visual Studio Code e extensões.

### Instalação Manual (opcional)

- **Bundler:**  
    Se precisar instalar o Bundler globalmente no seu sistema (fora do container), execute:
    
    ```bash
    gem install bundler
    ```
    
- **Yarn:**  
    Para instalar o Yarn, se necessário, siga:
    
    ```bash
    npm install --global yarn
    ```
    

> Geralmente, ao usar o DevContainer, essas dependências já estarão incluídas na imagem. A instalação manual é opcional para uso fora do container.

---

## Estrutura do Projeto

- **.devcontainer/**
    
    - **devcontainer.json:** Configura o VS Code para abrir o projeto dentro do container, definindo extensões, configurações e comandos pós-criação (como `bundle install && yarn install`).
        
    - **Dockerfile:** Define a imagem base (Ruby, Node.js, etc.) e instala as dependências necessárias para o Sender25.
        
- **docker-compose.yml**  
    Arquivo na raiz que orquestra os containers:
    
    - **app:** Container que roda a aplicação Sender25 (Rails).
        
    - **mariadb:** Serviço de banco de dados MariaDB.
        
    - **rabbitmq:** Serviço de filas RabbitMQ (se necessário).
        
- **config/database.yml**  
    As configurações de conexão com o banco são carregadas via variáveis definidas no `config/sender25.yml`.
    
- **config/sender25.yml**  
    Arquivo com as configurações do Sender25, que inclui os dados de conexão do banco de dados.  
    **Atenção:** Esse arquivo deve estar no `.gitignore` para proteger informações sensíveis.  
    Exemplo mínimo para desenvolvimento:
    
    ```yaml
    main_db:
      host: mariadb
      username: root
      password:
      database: sender25_development
      encoding: utf8mb4
      pool_size: 5
      port: 3306
    
    message_db:
      host: mariadb
      username: root
      password:
      database: sender25_development
      encoding: utf8mb4
      pool_size: 5
      port: 3306
    
    web:
      host: localhost
      protocol: http
    
    smtp:
      host: 127.0.0.1
      port: 25
    
    rails:
      environment: development
    ```
    

---

## Passo a Passo para Configuração

### 1. Clonar o Repositório

Abra o terminal e clone o repositório:

```bash
git clone https://github.com/webmaster-gk2/sender25.git
cd sender25
```

### 2. Configurar o DevContainer

A estrutura do DevContainer já está criada na pasta `.devcontainer/` e contém:

- **devcontainer.json:** Define o serviço (app), a referência ao `docker-compose.yml` e lista as extensões recomendadas.
    
- **Dockerfile:** Define o ambiente (Ruby, Node.js, Yarn, etc.) e instala as dependências necessárias.
    

### 3. Abrir o Projeto no VS Code

1. Abra o VS Code na raiz do projeto Sender25.
    
2. Utilize o Command Palette (Ctrl+Shift+P) e selecione **Remote-Containers: Reopen in Container**.
    
3. O VS Code construirá a imagem definida e iniciará o container conforme as configurações do `docker-compose.yml`.

---

### 4. Instalar as Dependências

Após a abertura do container, o comando definido no `postCreateCommand` (no `devcontainer.json`) executará:

- `bundle install` para instalar as gems Ruby.
    
- `yarn install` para instalar as dependências Node.js.
    

Após essa etapa, **você deve rodar os seguintes comandos no terminal dentro do container**:

```bash
bin/sender25 initialize
bin/sender25 update
bin/sender25 web-server
```

#### O que cada comando faz:

- `bin/sender25 initialize`: Cria os bancos de dados e aplica as configurações iniciais.
    
- `bin/sender25 update`: Aplica atualizações de schema (caso existam).
    
- `bin/sender25 web-server`: Inicia o servidor da aplicação web usando o `puma` conforme configurado.
    

> Esses comandos garantem que o Sender25 estará com o banco configurado e a aplicação rodando corretamente no modo desenvolvimento, dentro do DevContainer.

---
## Instalação de Extensões no VS Code

Para garantir que o ambiente de desenvolvimento funcione corretamente e oferecer uma boa experiência com Ruby, Rails, testes e Docker, instale (ou confirme que já estão instaladas) as seguintes extensões no Visual Studio Code:

### 🔧 Extensões Recomendadas

| Extensão                   | Descrição                                                                         |
| -------------------------- | --------------------------------------------------------------------------------- |
| **Dev Containers**         | Permite abrir pastas e projetos dentro de containers Docker.                      |
| **Ruby**                   | Suporte a sintaxe, navegação e funcionalidades básicas de Ruby.                   |
| **Solargraph**             | Autocompletar, linting e inteligência para projetos Ruby. (_castwide.solargraph_) |
| **VSCode Ruby Debugger**   | Suporte para depuração (debug) de código Ruby/Rails.                              |
| **YAML**                   | Suporte avançado para arquivos `.yml`, como `sender25.yml`.                         |
| **Prettier**               | Formatador de código para arquivos JavaScript, JSON, YAML etc.                    |
| **Ruby on Rails Snippets** | Trechos de código prontos para acelerar o desenvolvimento com Rails.              |
| **RSpec Snippets**         | Snippets para testes automatizados com RSpec.                                     |
| **Rubocop**                | Linter e formatter para seguir o estilo de código Ruby.                           |
| **Docker**                 | Suporte a visualização e controle de containers, imagens e volumes.               |
| **Haml**                   | Suporte à sintaxe e realce de código para arquivos `.haml`.                       |
| **GitLens**                | Ferramentas avançadas de Git integradas no VS Code.                               |

### ⚙️ Configuração adicional para Solargraph

Adicione a seguinte configuração ao seu `settings.json` no VS Code:

```json
{
  "solargraph.useBundler": true,
  "solargraph.commandPath": "bundle"
}
```

Essa configuração garante que o Solargraph utilize as gems corretamente via Bundler dentro do ambiente DevContainer.

---

> **Dica:** Algumas dessas extensões já podem ser listadas no `devcontainer.json` para instalação automática quando o container é criado. Se não, instrua a equipe para instalar as extensões manualmente pelo Marketplace do VS Code.

---

## Versionamento e Documentação

- **Versione** os arquivos de configuração do DevContainer (`.devcontainer/`) e o `docker-compose.yml` no repositório.
    
- **Mantenha** o `config/sender25.yml` fora do versionamento (adicione-o ao `.gitignore`)
    
- Atualize este documento conforme houver alterações no setup para manter toda a equipe informada.
    

---

## Considerações Finais

Com esse setup, o ambiente de desenvolvimento do Sender25 ficará padronizado para toda a equipe. Qualquer membro poderá clonar o repositório, abrir o projeto no VS Code via DevContainer e iniciar o desenvolvimento sem depender de configurações individuais do sistema.

---