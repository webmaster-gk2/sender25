FROM ruby:3.1-slim

# Instalar dependências do sistema necessárias para compilar gems nativas e rodar o app
RUN apt-get update && apt-get install -y \
  build-essential \
  libmariadb-dev \
  nodejs \
  yarn \
  default-mysql-client \
  git \
  && rm -rf /var/lib/apt/lists/*


# Definir diretório de trabalho
WORKDIR /workspace

# Instalar bundler globalmente
RUN gem install bundler

# Expor a porta do servidor Rails (ajuste se necessário)
EXPOSE 3000

# Comando padrão: iniciar o servidor Rails
CMD ["sh", "-c", "(bundle check || bundle install) && ./sender25 web-server"]