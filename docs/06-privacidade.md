# Privacidade

Este repositório deve conter apenas material público e sanitizado.

## O que remover ou anonimizar

- Credenciais.
- Tokens.
- URLs reais de projetos.
- IDs reais de grupos WhatsApp.
- IDs reais de pastas Google Drive.
- IDs internos de workflows n8n.
- IDs de credenciais n8n.
- Nomes de clientes reais.
- Telefones reais.
- Documentos fiscais reais.
- Payloads reais de produção.
- Arquivos de comprovantes reais.
- Prints com dados sensíveis.

## Estratégia aplicada aos workflows

Nos exports sanitizados:

- `active` foi definido como `false`;
- credenciais foram removidas;
- metadados internos foram removidos;
- URL do Supabase foi substituída por `SUPABASE_URL`;
- grupo interno foi substituído por `WHAPI_INTERNAL_GROUP_ID`;
- pasta de Drive foi substituída por `GOOGLE_DRIVE_COMPROVANTES_FOLDER_ID`;
- workflow dependente foi substituído por placeholder.

## Variáveis permitidas no repositório

É aceitável documentar nomes de variáveis de ambiente, desde que os valores reais não apareçam:

```text
SUPABASE_URL
SUPABASE_SERVICE_KEY
WHAPI_TOKEN
OPENAI_API_KEY
WHAPI_INTERNAL_GROUP_ID
GOOGLE_DRIVE_COMPROVANTES_FOLDER_ID
```

## Arquivos que não devem ir para o GitHub

```text
MANUAL_AUTOMACAO_COBRANCA_WHATSAPP_*_TECNICO.md
[COBRANCA] 01_GATEWAY_WHAPI.json
[COBRANCA] 02_PROCESSAR_MENSAGEM.json
[COBRANCA] 03_NOTIFICAR_EQUIPE_ENTRADAS.json
[COBRANCA] 04_ENVIAR_COBRANCA_CLIENTES.json
```

Esses arquivos são fontes locais/originais e ainda podem conter referências reais de ambiente.

## Arquivos públicos esperados

```text
README.md
docs/
assets/
samples/
supabase/
workflows/sanitizados/
.gitignore
```

Arquivos auxiliares locais de publicação ou variáveis de ambiente não são necessários no repositório público.

## Busca final recomendada

Antes da publicação, rodar varreduras por padrões como:

```text
token
apikey
Authorization
Bearer
service_role
supabase.co
whapi
openai
google
@g.us
telefone
documento
cnpj
```

O objetivo não é remover toda menção a tecnologias, mas identificar valores reais ou privados que tenham escapado.
