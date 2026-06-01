# Workflow 02 - Processar Mensagem

![Workflow 02 - Processar Mensagem](../assets/screenshots/workflow-02-processar-mensagem.png)

## Visão geral

Este workflow é o núcleo de processamento das mensagens autorizadas pelo Gateway WHAPI.

Ele recebe um payload já normalizado, identifica o tipo operacional da entrada e direciona a execução para uma das rotas principais: texto, áudio ou comprovante.

O objetivo não é apenas responder a mensagens, mas transformar interações recebidas pelo WhatsApp em dados estruturados, auditáveis e acionáveis no Supabase.

## Objetivo

O objetivo do workflow 02 é interpretar a mensagem do cliente e registrar corretamente o impacto operacional daquela interação.

Dependendo do conteúdo recebido, ele pode:

- classificar uma resposta textual;
- transcrever e classificar um áudio;
- analisar um arquivo enviado como possível comprovante;
- registrar a interação no Supabase;
- atualizar status de cobrança;
- gerar pendência de validação humana;
- preservar o histórico para auditoria.

## Papel na arquitetura

Este workflow fica entre a camada de entrada e as rotinas de acompanhamento.

Ele concentra a inteligência de leitura das respostas dos clientes, mas mantém uma regra importante: a IA não confirma pagamento de forma definitiva. Ela apenas classifica, extrai sinais e organiza evidências para decisão humana quando necessário.

Essa separação reduz risco operacional e deixa claro o limite entre automação e validação financeira.

## O que o workflow faz

### 1. Classifica o tipo operacional

O node `Classificar tipo operacional` avalia o payload recebido e define se a mensagem deve seguir como:

- `Texto`;
- `Audio`;
- `Comprovante`.

Essa decisão alimenta o node `Switch | Tipo mensagem`, que abre as branches específicas do fluxo.

### 2. Processa mensagens de texto

Na branch de texto, o workflow envia a mensagem para classificação com IA.

O prompt orienta a IA a retornar apenas JSON válido, classificando a intenção da resposta e sugerindo impacto operacional.

Exemplos de classificação:

```text
PAGAMENTO_PROMETIDO
NEGOCIACAO
CONTESTACAO
DUVIDA
AGRESSIVO
OUTRO
```

Depois disso, o node `Normalizar JSON IA` padroniza a saída e o node `HTTP RPC | Registrar resposta cliente` grava a interação no Supabase.

### 3. Processa mensagens de áudio

Na branch de áudio, o workflow baixa a mídia pela WHAPI e envia o arquivo para transcrição.

Após a transcrição, o texto resultante passa por uma lógica semelhante à branch textual: classificação com IA, normalização do JSON e registro da resposta.

Esse desenho permite tratar áudio como uma entrada operacional equivalente ao texto, mantendo rastreabilidade sobre a origem da informação.

### 4. Processa comprovantes

Na branch de comprovante, o workflow baixa a mídia enviada pelo cliente e prepara o arquivo para análise auxiliar com IA.

A IA avalia se o arquivo parece ser um comprovante e tenta extrair sinais como:

- tipo do documento;
- valor;
- data;
- autenticação;
- favorecido;
- pagador;
- nível de confiança;
- observações úteis para conferência.

O arquivo é salvo no Google Drive e o Supabase registra o comprovante como pendente de validação humana.

### 5. Remove arquivo temporário

Após a análise, o arquivo temporário enviado para a OpenAI é removido.

Esse cuidado reduz acúmulo desnecessário de arquivos externos e demonstra atenção ao ciclo de vida dos dados processados.

## Decisão importante

A automação não marca uma pendência como paga apenas porque recebeu um comprovante.

O comprovante fica registrado para análise e a validação final permanece humana. Essa decisão preserva controle financeiro e evita baixa indevida por erro de leitura, comprovante parcial ou arquivo inconclusivo.

## Integrações utilizadas

- **OpenAI:** classificação de texto, transcrição de áudio e análise auxiliar de comprovantes.
- **WHAPI:** download de mídias recebidas pelo WhatsApp.
- **Google Drive:** armazenamento público demonstrativo dos comprovantes.
- **Supabase:** registro transacional de respostas, comprovantes, status e auditoria.

## Valor técnico demonstrado

Este workflow evidencia:

- roteamento por tipo de entrada;
- uso de IA com contrato JSON estruturado;
- tratamento de texto, áudio e arquivos em um mesmo processo;
- persistência transacional via RPC;
- desenho com validação humana para casos financeiros sensíveis;
- separação entre interpretação automatizada e decisão final.

## Resultado esperado

Ao final da execução, a mensagem recebida deixa de ser apenas um evento do WhatsApp e passa a existir como registro estruturado no Supabase.

Esse registro alimenta notificações internas, histórico do cliente, regras de pausa, acompanhamento de promessa de pagamento e validação de comprovantes.

## Export público

```text
workflows/sanitizados/02-processar-mensagem.sanitizado.json
```
