## ⚙️ Configurando o Sender25

O Sender25 pode ser configurado de duas maneiras: utilizando um arquivo de configuração baseado em YAML ou por meio de variáveis de ambiente.

Se você optar por usar variáveis de ambiente, **não é necessário fornecer um arquivo de configuração**. Uma lista completa de variáveis disponíveis está no arquivo `environment-variables.md` neste diretório.

Para usar um arquivo de configuração, a variável de ambiente `SENDER25_CONFIG_FILE_PATH` definirá onde o Sender25 deve procurar o arquivo. Um exemplo contendo todas as configurações disponíveis está no arquivo `yaml.yml`, também neste diretório. Lembre-se de incluir a chave `version: 2` no seu arquivo YAML.

---

## 👨‍💻 Desenvolvimento

Durante o desenvolvimento com Sender25, você pode configurar a aplicação colocando um arquivo de configuração em `config/sender25/sender25.yml`. Alternativamente, pode usar variáveis de ambiente em um arquivo `.env` na raiz do projeto.

### 🧪 Execução de testes

Por padrão, os testes utilizarão o arquivo de configuração `config/sender25/sender25.test.yml` e o arquivo de ambiente `.env.test`.

---

## 🐳 Containers

Dentro de um container, o Sender25 procurará pelo arquivo de configuração em `/config/sender25.yml`, a menos que seja sobrescrito pela variável de ambiente `SENDER25_CONFIG_FILE_PATH`.

---

## 🌐 Portas e Endereços de Bind

O servidor web e o servidor SMTP escutam em portas e endereços configuráveis. Os valores padrão podem ser definidos via configuração. Porém, se você for executar múltiplas instâncias no mesmo host, será necessário definir portas diferentes para cada uma.

Você pode utilizar as variáveis de ambiente `PORT` e `BIND_ADDRESS` para fornecer valores específicos por instância.

Adicionalmente, as variáveis `HEALTH_SERVER_PORT` e `HEALTH_SERVER_BIND_ADDRESS` podem ser usadas para configurar a porta/endereço do servidor de verificação de saúde, que pode rodar junto com os outros processos.

---

## 🕹️ Configuração legada

Arquivos de configuração das versões anteriores do Sender25 (v1 e v2) ainda são suportados. No entanto, se você desejar utilizar uma nova opção de configuração que **não esteja disponível no formato legado**, será necessário atualizar o arquivo para a versão 2.

--- 

Se quiser posso te ajudar a adaptar esse conteúdo como parte da documentação oficial ou README do projeto. Deseja isso?
