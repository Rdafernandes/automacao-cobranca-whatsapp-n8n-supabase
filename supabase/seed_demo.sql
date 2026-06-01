-- Dados fictícios para o case público de portfólio.
-- Seguro para publicação: nomes, IDs, telefones e valores são demonstrativos.

insert into public.n8n_cobranca_config (chave, valor, ativo, descricao)
values
  ('ativo_geral', 'sim', true, 'Liga ou desliga a automação demonstrativa.'),
  ('modo_teste', 'sim', true, 'Indica que este ambiente usa dados fictícios.')
on conflict (chave) do update
set valor = excluded.valor,
    ativo = excluded.ativo,
    descricao = excluded.descricao,
    updated_at = now();

insert into public.cliente (id, nome_fantasia, razao_social, documento, cnpj, ativo)
values
  ('11111111-1111-1111-1111-111111111111', '{{cliente}}', '{{cliente_razao_social}}', '00.000.000/0001-01', '00000000000101', true),
  ('22222222-2222-2222-2222-222222222222', '{{cliente_2}}', '{{cliente_razao_social}}', '00.000.000/0001-02', '00000000000102', true),
  ('33333333-3333-3333-3333-333333333333', '{{cliente_pausado}}', '{{cliente_razao_social}}', '00.000.000/0001-03', '00000000000103', true)
on conflict (id) do update
set nome_fantasia = excluded.nome_fantasia,
    razao_social = excluded.razao_social,
    documento = excluded.documento,
    cnpj = excluded.cnpj,
    ativo = excluded.ativo;

insert into public.cliente_contato (id, cliente_id, nome, email, telefone, whatsapp, whatsapp_norm, ativo)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', '11111111-1111-1111-1111-111111111111', '{{contato}}', '{{email_contato}}', '(11) 99999-0001', '(11) 99999-0001', '5511999990001', true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', '22222222-2222-2222-2222-222222222222', '{{contato}}', '{{email_contato}}', '(11) 99999-0002', '(11) 99999-0002', '5511999990002', true),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', '33333333-3333-3333-3333-333333333333', '{{contato}}', '{{email_contato}}', '(11) 99999-0003', '(11) 99999-0003', '5511999990003', true)
on conflict (whatsapp_norm) do update
set nome = excluded.nome,
    email = excluded.email,
    telefone = excluded.telefone,
    whatsapp = excluded.whatsapp,
    ativo = excluded.ativo;

insert into public.n8n_cobranca_cliente (id, cliente_id, cliente_contato_id, ativo, status_automacao, canal_whatsapp, canal_email)
values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb01', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1', true, 'ativo', true, false),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb02', '22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2', true, 'ativo', true, false),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbb03', '33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3', true, 'ativo', true, false)
on conflict (cliente_id, cliente_contato_id) do update
set ativo = excluded.ativo,
    status_automacao = excluded.status_automacao,
    canal_whatsapp = excluded.canal_whatsapp,
    canal_email = excluded.canal_email,
    updated_at = now();

insert into public.n8n_cobranca_pendencia (
  id,
  cliente_id,
  cliente_contato_id,
  ordem_servico_id,
  num_os,
  valor_original_centavos,
  valor_cobrado_centavos,
  valor_atualizado_centavos,
  vencimento,
  status_cobranca,
  proximo_contato_em,
  tentativas_cobranca,
  observacoes
) values
  (
    'cccccccc-cccc-cccc-cccc-cccccccccc01',
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    'dddddddd-dddd-dddd-dddd-dddddddddd01',
    1001,
    45000,
    45000,
    45000,
    current_date - 12,
    'em_aberto',
    null,
    0,
    'Pendência fictícia para demonstração de cobrança agrupada.'
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccc02',
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    'dddddddd-dddd-dddd-dddd-dddddddddd02',
    1002,
    78000,
    78000,
    78000,
    current_date - 31,
    'em_aberto',
    null,
    1,
    'Segunda pendência fictícia do mesmo contato.'
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccc03',
    '22222222-2222-2222-2222-222222222222',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    'dddddddd-dddd-dddd-dddd-dddddddddd03',
    2001,
    129900,
    129900,
    129900,
    current_date - 7,
    'em_cobranca',
    now() - interval '1 hour',
    2,
    'Pendência fictícia pronta para nova tentativa.'
  ),
  (
    'cccccccc-cccc-cccc-cccc-cccccccccc04',
    '33333333-3333-3333-3333-333333333333',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa3',
    'dddddddd-dddd-dddd-dddd-dddddddddd04',
    3001,
    88000,
    88000,
    88000,
    current_date - 20,
    'aguardando_pagamento',
    now() + interval '2 days',
    1,
    'Pendência fictícia pausada por promessa de pagamento.'
  )
on conflict (id) do update
set valor_original_centavos = excluded.valor_original_centavos,
    valor_cobrado_centavos = excluded.valor_cobrado_centavos,
    valor_atualizado_centavos = excluded.valor_atualizado_centavos,
    vencimento = excluded.vencimento,
    status_cobranca = excluded.status_cobranca,
    proximo_contato_em = excluded.proximo_contato_em,
    tentativas_cobranca = excluded.tentativas_cobranca,
    observacoes = excluded.observacoes,
    updated_at = now();

insert into public.n8n_cobranca_interacao (
  id,
  pendencia_id,
  cliente_id,
  cliente_contato_id,
  tipo,
  categoria,
  mensagem,
  classificacao_ia,
  acao_automacao,
  notificacao_equipe,
  whatsapp_message_id,
  raw_payload,
  created_at
) values
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeee01',
    'cccccccc-cccc-cccc-cccc-cccccccccc03',
    '22222222-2222-2222-2222-222222222222',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2',
    'entrada',
    'validacao',
    'Recebi, consigo pagar amanhã.',
    'PAGAMENTO_PROMETIDO',
    'resposta_cliente_registrada',
    false,
    'wamid.demo.promessa.001',
    '{"demo": true, "origem": "seed_demo"}'::jsonb,
    now() - interval '20 minutes'
  )
on conflict (id) do nothing;

insert into public.n8n_cobranca_comprovante (
  id,
  pendencia_id,
  cliente_id,
  cliente_contato_id,
  tipo_arquivo,
  arquivo_url,
  drive_file_id,
  valor_extraido_centavos,
  data_extraida,
  autenticacao,
  classificacao_ia,
  status_validacao,
  observacoes,
  raw_payload
) values
  (
    'ffffffff-ffff-ffff-ffff-ffffffffff01',
    'cccccccc-cccc-cccc-cccc-cccccccccc02',
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1',
    'application/pdf',
    'https://example.com/demo/comprovante-ficticio.pdf',
    'drive_demo_file_id',
    78000,
    current_date,
    'AUTH-DEMO-123',
    'COMPROVANTE_PROVAVEL',
    'pendente',
    'Comprovante fictício para demonstração de validação humana.',
    '{"demo": true, "origem": "seed_demo"}'::jsonb
  )
on conflict (id) do nothing;


