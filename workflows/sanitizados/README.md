# Workflows sanitizados

Esta pasta contém os exports públicos dos workflows n8n usados no case.

Os arquivos foram adaptados para portfólio e não devem conter:

- credenciais;
- IDs reais de workflows;
- IDs reais de grupos WhatsApp;
- IDs reais de pastas Google Drive;
- URL real do projeto Supabase;
- metadados internos da instância n8n.

## Variáveis de ambiente esperadas

Ao importar os workflows em um ambiente real ou de demonstração, configure:

```text
SUPABASE_URL
SUPABASE_SERVICE_KEY
WHAPI_TOKEN
OPENAI_API_KEY
WHAPI_INTERNAL_GROUP_ID
GOOGLE_DRIVE_COMPROVANTES_FOLDER_ID
```

## Observação sobre subworkflow

O workflow `01-gateway-whapi.sanitizado.json` chama o workflow `02-processar-mensagem.sanitizado.json`.

Após importar no n8n, substitua o placeholder:

```text
REPLACE_WITH_WORKFLOW_02_PROCESSAR_MENSAGEM_ID
```

pelo ID gerado pelo n8n para o workflow 02 importado.
