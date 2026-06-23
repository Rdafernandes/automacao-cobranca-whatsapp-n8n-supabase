# Workflows n8n

Os workflows foram separados por responsabilidade para reduzir acoplamento, facilitar manutenção e tornar a auditoria mais clara.

Os exports públicos ficam em [`../workflows/sanitizados/`](../workflows/sanitizados/).

## Documentação Individual Com Prints

- [Workflow 01 - Gateway WHAPI](08-workflow-01-gateway-whapi.md)
- [Workflow 02 - Processar Mensagem](09-workflow-02-processar-mensagem.md)
- [Workflow 03 - Notificar Equipe Entradas](10-workflow-03-notificar-equipe-entradas.md)
- [Workflow 04 - Enviar Cobrança Clientes](11-workflow-04-enviar-cobranca-clientes.md)

## 01 - Gateway WHAPI

Arquivo:

```text
workflows/sanitizados/01-gateway-whapi.sanitizado.json
```

Responsabilidades:

- receber webhook da WHAPI;
- normalizar payload de WhatsApp;
- bloquear mensagens inválidas;
- resolver se o contato está autorizado;
- chamar o workflow 02 como subworkflow.

Bloqueios esperados:

- mensagem enviada pelo próprio número;
- mensagem de grupo;
- evento que não é DM privada;
- PDF identificado como ordem de serviço;
- contato não autorizado no Supabase.

Saída principal para o workflow 02:

```json
{
  "source": "whapi_cobranca_gateway",
  "gateway": {
    "permitido": true,
    "modo_teste": false,
    "motivo_bloqueio": null
  },
  "contato": {
    "cliente_id": "uuid",
    "cliente_contato_id": "uuid",
    "contato_nome": "{{contato}}",
    "whatsapp_norm": "{{whatsapp_norm}}"
  },
  "whapi": {
    "message_id": "msg_demo_001",
    "type": "text",
    "text_body": "Vou pagar amanhã",
    "raw_payload": {}
  }
}
```

## 02 - Processar Mensagem

Arquivo:

```text
workflows/sanitizados/02-processar-mensagem.sanitizado.json
```

Responsabilidades:

- classificar a entrada como texto, áudio ou arquivo;
- processar respostas em texto;
- baixar e transcrever áudio;
- baixar e analisar comprovantes;
- salvar comprovantes no Drive;
- registrar interações e atualizações no Supabase.

Branches:

```text
Texto
Áudio
Comprovante
```

### Texto

Fluxo resumido:

```text
Classificar tipo operacional
-> IA classifica resposta
-> Normalizar JSON IA
-> RPC registrar resposta cliente
```

Classificações esperadas:

```text
PAGAMENTO_CONFIRMADO
PAGAMENTO_PROMETIDO
NEGOCIACAO
DIFICULDADE
CONTESTACAO
DUVIDA
SPAM
AGRESSIVO
OUTRO
```

### Áudio

Fluxo resumido:

```text
Baixar áudio
-> Transcrever
-> Classificar texto transcrito
-> Registrar resposta
```

O histórico preserva que a mensagem veio de áudio transcrito.

### Comprovante

Fluxo resumido:

```text
Baixar arquivo
-> Preparar mídia
-> Upload temporário para análise
-> IA analisa comprovante
-> Upload do arquivo para Drive
-> RPC registra comprovante
-> Apagar arquivo temporário da OpenAI
```

A IA pode retornar:

```text
COMPROVANTE_PROVAVEL
NAO_COMPROVANTE
INCONCLUSIVO
```

## 03 - Notificar Equipe Entradas

Arquivo:

```text
workflows/sanitizados/03-notificar-equipe-entradas.sanitizado.json
```

Responsabilidades:

- buscar interações pendentes de notificação;
- consolidar mensagem para a equipe;
- enviar alerta interno via WhatsApp;
- marcar as interações como notificadas.

Schedule público:

```text
*/5 9-18 * * 1-5
```

## 04 - Enviar Cobrança Clientes

Arquivo:

```text
workflows/sanitizados/04-enviar-cobranca-clientes.sanitizado.json
```

Responsabilidades:

- buscar contatos cobráveis pela view do Supabase;
- montar mensagem de cobrança por template;
- enviar a mensagem via WHAPI;
- registrar envio por RPC;
- notificar internamente que a cobrança foi enviada.

Schedule público:

```text
*/30 11-17 * * 1-5
```
## Estratégia de orquestração

Os workflows se comunicam por persistência e eventos intermediários.

Princípios adotados:

- desacoplamento entre entrada e execução;
- reprocessamento independente;
- separação entre captura e decisão;
- rastreabilidade por banco;
- recuperação de falhas sem reprocessamento completo.

## Variáveis De Ambiente Esperadas

```text
SUPABASE_URL
SUPABASE_SERVICE_KEY
WHAPI_TOKEN
OPENAI_API_KEY
WHAPI_INTERNAL_GROUP_ID
GOOGLE_DRIVE_COMPROVANTES_FOLDER_ID
```

## Observação Sobre Importação

O workflow 01 chama o workflow 02 como subworkflow. Depois de importar os workflows no n8n, substitua o placeholder:

```text
REPLACE_WITH_WORKFLOW_02_PROCESSAR_MENSAGEM_ID
```

pelo ID gerado no seu ambiente para o workflow 02.

