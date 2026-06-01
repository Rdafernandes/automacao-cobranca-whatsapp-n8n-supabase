-- Consultas de validação para o case demonstrativo.

-- 1. Verificar se a automação está habilitada.
select *
from public.n8n_cobranca_config
order by chave;

-- 2. Inspecionar a fila atual de cobrança.
select *
from public.n8n_cobranca_v_resumo_cobranca_contato
order by maior_dias_atraso desc;

-- 3. Diagnosticar a fila mesmo fora da janela operacional de envio.
select *
from public.n8n_cobranca_v_diagnostico_fila
order by vencimento asc;

-- 4. Inspecionar pendências cobráveis individualmente.
select *
from public.n8n_cobranca_v_pendencias_cobraveis
order by vencimento asc;

-- 5. Verificar notificações internas pendentes.
select *
from public.n8n_cobranca_v_interacoes_pendentes_notificacao
order by created_at asc;

-- 6. Verificar comprovantes pendentes de validação humana.
select *
from public.n8n_cobranca_v_comprovantes_pendentes_validacao
order by recebido_em asc;

-- 7. Auditar cobranças enviadas recentemente.
select
  id,
  created_at,
  cliente_id,
  cliente_contato_id,
  whatsapp_message_id,
  dias_atraso_no_envio,
  dias_sem_resposta_no_envio,
  tentativa_no_envio,
  tom_cobranca_no_envio,
  pendencias_snapshot_json
from public.n8n_cobranca_interacao
where tipo = 'saida'
  and categoria = 'cobranca'
order by created_at desc;

-- 8. Auditar promessas de pagamento.
select
  id,
  num_os,
  status_cobranca,
  promessa_pagamento_data,
  pausado_ate,
  motivo_pausa,
  proximo_contato_em,
  ultima_resposta_cliente_em
from public.n8n_cobranca_pendencia
where promessa_pagamento_data is not null
order by updated_at desc;

-- 9. Simular resolução de contato no gateway.
select public.n8n_cobranca_gateway_resolver_contato('5511999990001') as contato_autorizado;

-- 10. Simular contato não autorizado.
select public.n8n_cobranca_gateway_resolver_contato('5511888880000') as contato_bloqueado;
