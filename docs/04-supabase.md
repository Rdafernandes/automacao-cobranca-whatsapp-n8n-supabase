# Supabase

O Supabase atua como banco operacional da automação. Ele centraliza estado, histórico e regras de fila.

Os arquivos demonstrativos ficam em [`../supabase/`](../supabase/):

- `README.md`
- `schema.sql`
- `seed_demo.sql`
- `queries_validacao.sql`

## Tabelas Principais

### `cliente`

Tabela base de clientes.

Uso na automação:

- identificar cliente;
- validar cliente ativo;
- associar pendências, contatos e histórico.

### `cliente_contato`

Tabela base de contatos.

Uso na automação:

- identificar WhatsApp autorizado;
- resolver respostas recebidas;
- associar interações ao contato correto.

Campo crítico:

```text
whatsapp_norm
```

Formato esperado:

```text
55 + DDD + número
```

### `n8n_cobranca_cliente`

Autoriza um contato a participar da automação.

Campos relevantes:

```text
cliente_id
cliente_contato_id
ativo
status_automacao
canal_whatsapp
```

### `n8n_cobranca_pendencia`

Tabela principal de pendências financeiras cobráveis.

Responsabilidades:

- guardar valor, vencimento e status;
- controlar tentativas;
- armazenar próximo contato;
- pausar cobrança;
- registrar promessa de pagamento.

Status operacionais:

```text
em_aberto
em_cobranca
aguardando_pagamento
negociando
em_analise
validando_comprovante
pago
cancelado
```

### `n8n_cobranca_interacao`

Histórico de entradas e saídas relevantes.

Exemplos:

- resposta do cliente;
- cobrança enviada;
- promessa de pagamento;
- comprovante recebido;
- classificação de IA;
- snapshot das pendências no momento do envio.

### `n8n_cobranca_comprovante`

Registros de comprovantes recebidos.

Contém:

- arquivo;
- dados extraídos;
- classificação da IA;
- status da validação humana;
- payload bruto sanitizado.

Status de validação:

```text
pendente
validado
rejeitado
inconclusivo
```

### `n8n_cobranca_config`

Configurações globais da automação.

Exemplos:

```text
ativo_geral
modo_teste
```

## Views Principais

### `n8n_cobranca_v_pendencias_cobraveis`

Lista pendências individuais que podem ser cobradas naquele momento.

Filtros principais:

- automação ativa;
- cliente e contato ativos;
- contato autorizado;
- WhatsApp preenchido;
- status cobrável;
- vencimento anterior à data atual;
- sem pausa ativa;
- dentro da janela de envio.

### `n8n_cobranca_v_resumo_cobranca_contato`

Agrupa pendências por contato.

Usada pelo workflow 04 para enviar uma cobrança consolidada por cliente/contato.

### `n8n_cobranca_v_interacoes_pendentes_notificacao`

Lista interações que ainda precisam ser notificadas para a equipe.

Usada pelo workflow 03.

### `n8n_cobranca_v_diagnostico_fila`

Mostra por que cada pendência está ou não elegível para cobrança.

Essa view é útil para demonstração, porque a fila real respeita a janela de envio. Fora do horário permitido, a view operacional pode retornar vazia mesmo com dados fictícios carregados.

### `n8n_cobranca_v_comprovantes_pendentes_validacao`

Lista comprovantes que precisam de validação humana.

## RPCs Principais

### `n8n_cobranca_gateway_resolver_contato`

Recebe um WhatsApp normalizado e retorna se existe contato autorizado para a automação.

### `n8n_cobranca_registrar_resposta_cliente`

Registra resposta do cliente e atualiza o estado da pendência quando aplicável.

Exemplos:

- promessa de pagamento;
- negociação;
- contestação;
- dúvida.

### `n8n_cobranca_registrar_comprovante`

Registra comprovante recebido, cria histórico e coloca a pendência em validação quando aplicável.

### `n8n_cobranca_registrar_envio`

Registra cobrança enviada, incrementa tentativas e agenda o próximo contato.

### `n8n_cobranca_marcar_interacoes_notificadas`

Marca interações como notificadas após o workflow 03 enviar alerta interno.

## Funções Auxiliares

### `n8n_cobranca_next_business_send_at`

Calcula o próximo envio em dia útil, no horário operacional configurado.

### `n8n_cobranca_is_send_window`

Define se o horário atual está dentro da janela permitida de envio.

## Máquina De Estados

```text
em_aberto
  -> em_cobranca
  -> aguardando_pagamento
  -> validando_comprovante
  -> pago
```

Estados alternativos:

```text
negociando
em_analise
cancelado
```

## Observabilidade

As queries de validação devem responder perguntas como:

- quantos contatos estão na fila de cobrança;
- quantas interações aguardam notificação;
- quantos comprovantes aguardam validação;
- quais cobranças foram enviadas recentemente;
- quais pendências estão pausadas por promessa.

