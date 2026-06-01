# Supabase demo

Esta pasta contém a simulação pública da camada Supabase usada pela automação.

## Arquivos

- `schema.sql` - tabelas, índices, views, funções auxiliares e RPCs demonstrativas.
- `seed_demo.sql` - dados fictícios para popular o ambiente demo.
- `queries_validacao.sql` - consultas para verificar filas, interações e comprovantes.

## Ordem sugerida

Em um projeto Supabase vazio de demonstração:

```sql
\i supabase/schema.sql
\i supabase/seed_demo.sql
\i supabase/queries_validacao.sql
```

Também é possível copiar o conteúdo dos arquivos para o SQL Editor do Supabase, respeitando a mesma ordem.

## Observações

Este schema é demonstrativo. Ele foi criado para explicar a arquitetura pública do case, não para substituir uma migração de produção.

A view operacional de cobrança respeita a janela de envio configurada. Se você executar a demo fora do horário permitido, use `n8n_cobranca_v_diagnostico_fila` para entender quais pendências existem e quais critérios impedem ou liberam o envio.

Antes de usar em produção, revise:

- políticas de RLS;
- permissões por papel;
- auditoria de ações humanas;
- validação transacional de comprovantes;
- calendário de feriados;
- estratégia de logs e retenção.
