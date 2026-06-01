# Simulação

O repositório público usa dados fictícios para demonstrar o comportamento da automação sem expor dados reais.

## Objetivo

Permitir que uma pessoa avaliadora entenda o fluxo ponta a ponta mesmo sem acesso ao ambiente real de produção.

Os exemplos simulam entradas, classificações, comprovantes, envios e registros de auditoria, mantendo a mesma lógica da automação original.

## Itens simulados

- Clientes fictícios.
- Contatos fictícios.
- Pendências financeiras fictícias.
- Payloads WHAPI anonimizados.
- Respostas de clientes.
- Promessas de pagamento.
- Comprovantes demonstrativos.
- Registros de auditoria.
- Notificações internas.

## Estrutura dos samples

```text
samples/
|-- entrada-whatsapp/
|-- processamento/
|-- cobranca-enviada/
`-- comprovantes/
```

## Cenários incluídos

### Cenário 1 - Cobrança enviada

Um cliente possui duas pendências vencidas. A view de resumo agrupa as pendências por contato e o workflow 04 envia uma única mensagem de cobrança.

Arquivos esperados:

```text
samples/cobranca-enviada/mensagem-cobranca.md
samples/cobranca-enviada/registro-envio.json
```

### Cenário 2 - Promessa de pagamento

O cliente responde que pagará em uma data futura. A IA classifica a resposta como promessa de pagamento e a RPC pausa a cobrança até a data calculada.

Arquivos esperados:

```text
samples/entrada-whatsapp/texto-promessa-pagamento.json
samples/processamento/classificacao-promessa.json
```

### Cenário 3 - Comprovante recebido

O cliente envia imagem ou PDF de comprovante. O workflow processa o arquivo, extrai informações relevantes e gera pendência para validação humana.

Arquivos esperados:

```text
samples/entrada-whatsapp/arquivo-comprovante.json
samples/comprovantes/analise-comprovante.json
```

### Cenário 4 - Contestação

O cliente questiona valor ou serviço. A IA classifica como contestação e a pendência segue para análise da equipe.

Arquivos esperados:

```text
samples/entrada-whatsapp/texto-contestacao.json
samples/processamento/classificacao-contestacao.json
```

## Dados demonstrativos

Os dados fictícios usam placeholders para evitar nomes de pessoas ou empresas:

```text
{{cliente}}
{{cliente_2}}
{{contato}}
{{usuario_financeiro}}
```

Telefones devem ser claramente fictícios:

```text
5511999990001
5511999990002
```

IDs devem ser UUIDs de exemplo, não IDs reais de produção.
