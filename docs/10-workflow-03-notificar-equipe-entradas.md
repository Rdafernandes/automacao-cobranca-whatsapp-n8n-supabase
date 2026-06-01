# Workflow 03 - Notificar Equipe Entradas

![Workflow 03 - Notificar Equipe Entradas](../assets/screenshots/workflow-03-notificar-equipe-entradas.png)

## Visão geral

Este workflow monitora interações recebidas dos clientes e envia alertas internos para a equipe financeira.

Ele garante que respostas, promessas, contestações e comprovantes não fiquem escondidos apenas no histórico do banco.

## Objetivo

O objetivo do workflow 03 é transformar entradas relevantes em notificações operacionais rápidas.

Depois que o workflow 02 registra uma interação no Supabase, este fluxo consulta o que ainda não foi notificado, monta uma mensagem legível e envia para o canal interno definido.

## Papel na arquitetura

Este workflow atua como camada de acompanhamento.

Ele não interpreta a mensagem do cliente e não altera a decisão principal da cobrança. Sua função é dar visibilidade para a equipe sobre eventos que exigem atenção humana ou acompanhamento operacional.

Isso separa processamento de comunicação interna e evita que a equipe precise consultar o banco manualmente para descobrir novas interações.

## O que o workflow faz

### 1. Executa em agenda recorrente

O node `Schedule Trigger` executa o fluxo em intervalos definidos.

Schedule demonstrativo:

```text
*/5 9-18 * * 1-5
```

Essa configuração representa uma rotina a cada 5 minutos, em horário comercial, de segunda a sexta-feira.

### 2. Busca interações pendentes

O node `HTTP GET | Buscar interações pendentes` consulta uma view pública demonstrativa do Supabase.

View utilizada:

```text
public.n8n_cobranca_v_interacoes_pendentes_notificacao
```

A view retorna apenas interações que ainda não foram notificadas internamente.

### 3. Monta a mensagem para a equipe

O node `Montar mensagem equipe` transforma os dados estruturados em uma mensagem operacional.

Dependendo da entrada, a mensagem pode destacar:

- cliente;
- contato;
- tipo de interação;
- resumo da mensagem;
- pendências abertas;
- comprovante recebido;
- diferença entre valor pendente e valor extraído;
- arquivo associado.

### 4. Envia o alerta interno

O node `HTTP | Enviar WhatsApp equipe` envia a notificação para o grupo interno configurado.

No repositório público, o ID do grupo é representado apenas pelo placeholder:

```text
WHAPI_INTERNAL_GROUP_ID
```

### 5. Marca interações como notificadas

Depois do envio, o node `HTTP RPC | Marcar interações notificadas` registra no Supabase que aquelas interações já foram avisadas.

RPC utilizada:

```text
public.n8n_cobranca_marcar_interacoes_notificadas
```

Essa etapa evita duplicidade de alertas nas próximas execuções.

## Valor técnico demonstrado

Este workflow evidencia:

- uso de polling agendado em n8n;
- consulta a view operacional do Supabase;
- montagem de mensagem interna a partir de dados estruturados;
- controle de idempotência para evitar alertas repetidos;
- separação entre processamento de entrada e notificação para equipe.

## Resultado esperado

A equipe financeira recebe alertas rápidos sobre interações relevantes, enquanto o Supabase mantém controle sobre o que já foi notificado.

O resultado é um fluxo mais rastreável, com menos dependência de conferência manual e menor risco de respostas importantes passarem despercebidas.

## Export público

```text
workflows/sanitizados/03-notificar-equipe-entradas.sanitizado.json
```
