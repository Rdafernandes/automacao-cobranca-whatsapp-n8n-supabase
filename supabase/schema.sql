-- Supabase/PostgreSQL demo schema for the public portfolio case.
-- This file uses fictitious structures and data contracts based on the n8n automation.

create extension if not exists pgcrypto;

-- Base operational tables used by the automation.

create table if not exists public.cliente (
  id uuid primary key default gen_random_uuid(),
  nome_fantasia text not null,
  razao_social text,
  documento text,
  cnpj text,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.cliente_contato (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.cliente(id) on delete cascade,
  nome text not null,
  email text,
  telefone text,
  whatsapp text,
  whatsapp_norm text not null,
  ativo boolean not null default true,
  created_at timestamptz not null default now(),
  unique (whatsapp_norm)
);

-- Automation tables.

create table if not exists public.n8n_cobranca_cliente (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.cliente(id) on delete cascade,
  cliente_contato_id uuid not null references public.cliente_contato(id) on delete cascade,
  ativo boolean not null default true,
  status_automacao text not null default 'ativo',
  canal_whatsapp boolean not null default true,
  canal_email boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cliente_id, cliente_contato_id)
);

create table if not exists public.n8n_cobranca_pendencia (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.cliente(id) on delete cascade,
  cliente_contato_id uuid not null references public.cliente_contato(id) on delete cascade,
  ordem_servico_id uuid,
  num_os integer,
  valor_original_centavos integer not null check (valor_original_centavos >= 0),
  valor_cobrado_centavos integer not null check (valor_cobrado_centavos >= 0),
  valor_atualizado_centavos integer not null check (valor_atualizado_centavos >= 0),
  vencimento date not null,
  status_cobranca text not null default 'em_aberto',
  ultimo_contato_em timestamptz,
  proximo_contato_em timestamptz,
  tentativas_cobranca integer not null default 0,
  observacoes text,
  dias_atraso_ultimo_envio integer,
  dias_sem_resposta_ultimo_envio integer,
  ultimo_envio_cobranca_em timestamptz,
  promessa_pagamento_data date,
  pausado_ate timestamptz,
  motivo_pausa text,
  ultima_resposta_cliente_em timestamptz,
  sem_resposta_desde_em timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint n8n_cobranca_pendencia_status_check check (
    status_cobranca in (
      'em_aberto',
      'em_cobranca',
      'aguardando_pagamento',
      'negociando',
      'em_analise',
      'validando_comprovante',
      'pago',
      'cancelado'
    )
  )
);

create table if not exists public.n8n_cobranca_interacao (
  id uuid primary key default gen_random_uuid(),
  pendencia_id uuid references public.n8n_cobranca_pendencia(id) on delete set null,
  cliente_id uuid not null references public.cliente(id) on delete cascade,
  cliente_contato_id uuid not null references public.cliente_contato(id) on delete cascade,
  tipo text not null check (tipo in ('entrada', 'saida')),
  categoria text not null default 'outro',
  mensagem text,
  classificacao_ia text,
  acao_automacao text,
  anexo_url text,
  notificacao_equipe boolean not null default false,
  whatsapp_message_id text,
  raw_payload jsonb not null default '{}'::jsonb,
  dias_atraso_no_envio integer,
  dias_sem_resposta_no_envio integer,
  tentativa_no_envio integer,
  tom_cobranca_no_envio text,
  pendencias_snapshot_json jsonb,
  promessa_pagamento_data date,
  pausado_ate timestamptz,
  motivo_pausa text,
  sem_resposta_desde_em timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.n8n_cobranca_comprovante (
  id uuid primary key default gen_random_uuid(),
  pendencia_id uuid references public.n8n_cobranca_pendencia(id) on delete set null,
  cliente_id uuid not null references public.cliente(id) on delete cascade,
  cliente_contato_id uuid not null references public.cliente_contato(id) on delete cascade,
  recebido_em timestamptz not null default now(),
  tipo_arquivo text,
  arquivo_url text,
  drive_file_id text,
  valor_extraido_centavos integer,
  data_extraida date,
  autenticacao text,
  classificacao_ia text,
  status_validacao text not null default 'pendente',
  validado_por text,
  validado_em timestamptz,
  observacoes text,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint n8n_cobranca_comprovante_status_check check (
    status_validacao in ('pendente', 'validado', 'rejeitado', 'inconclusivo')
  )
);

create table if not exists public.n8n_cobranca_config (
  chave text primary key,
  valor text not null,
  ativo boolean not null default true,
  descricao text,
  updated_at timestamptz not null default now()
);

create index if not exists idx_cliente_contato_whatsapp_norm
  on public.cliente_contato (whatsapp_norm);

create index if not exists idx_cobranca_cliente_contato_ativo
  on public.n8n_cobranca_cliente (cliente_id, cliente_contato_id, ativo);

create index if not exists idx_cobranca_pendencia_fila
  on public.n8n_cobranca_pendencia (
    status_cobranca,
    vencimento,
    proximo_contato_em,
    pausado_ate
  );

create index if not exists idx_cobranca_interacao_notificacao
  on public.n8n_cobranca_interacao (notificacao_equipe, tipo, created_at);

create index if not exists idx_cobranca_comprovante_validacao
  on public.n8n_cobranca_comprovante (status_validacao, recebido_em);

-- Helper functions.

create or replace function public.n8n_cobranca_is_send_window(
  p_at timestamptz default now()
) returns boolean
language plpgsql
stable
as $$
declare
  v_local timestamp := p_at at time zone 'America/Sao_Paulo';
  v_dow integer := extract(isodow from v_local);
  v_hour integer := extract(hour from v_local);
begin
  return v_dow between 1 and 5 and v_hour >= 11 and v_hour < 18;
end;
$$;

create or replace function public.n8n_cobranca_next_business_send_at(
  p_base timestamptz default now(),
  p_days_ahead integer default 1
) returns timestamptz
language plpgsql
stable
as $$
declare
  v_date date := ((p_base at time zone 'America/Sao_Paulo')::date + greatest(p_days_ahead, 0));
  v_dow integer;
begin
  loop
    v_dow := extract(isodow from v_date);
    if v_dow between 1 and 5 then
      return (v_date::timestamp + time '11:00') at time zone 'America/Sao_Paulo';
    end if;
    v_date := v_date + 1;
  end loop;
end;
$$;

-- Operational views.

create or replace view public.n8n_cobranca_v_pendencias_cobraveis as
select
  p.id as pendencia_id,
  p.cliente_id,
  c.nome_fantasia as cliente_nome_fantasia,
  c.razao_social as cliente_razao_social,
  c.documento as cliente_documento,
  c.cnpj as cliente_cnpj,
  p.cliente_contato_id,
  cc.nome as contato_nome,
  cc.whatsapp_norm as contato_whatsapp_norm,
  p.num_os,
  p.valor_cobrado_centavos,
  p.valor_atualizado_centavos,
  p.vencimento,
  p.status_cobranca,
  p.tentativas_cobranca,
  p.ultimo_envio_cobranca_em,
  p.proximo_contato_em,
  p.pausado_ate,
  greatest((current_date - p.vencimento), 0) as dias_atraso,
  case
    when greatest((current_date - p.vencimento), 0) >= 30 then 'firme'
    when greatest((current_date - p.vencimento), 0) >= 10 then 'educada'
    when greatest((current_date - p.vencimento), 0) > 0 then 'amigavel'
    else 'sem_atraso'
  end as tom_cobranca,
  case
    when p.sem_resposta_desde_em is null then 0
    else greatest((current_date - (p.sem_resposta_desde_em at time zone 'America/Sao_Paulo')::date), 0)
  end as dias_sem_resposta_atual
from public.n8n_cobranca_pendencia p
join public.cliente c on c.id = p.cliente_id
join public.cliente_contato cc on cc.id = p.cliente_contato_id
join public.n8n_cobranca_cliente nc
  on nc.cliente_id = p.cliente_id
 and nc.cliente_contato_id = p.cliente_contato_id
where coalesce((select valor from public.n8n_cobranca_config where chave = 'ativo_geral'), 'sim') = 'sim'
  and public.n8n_cobranca_is_send_window(now()) = true
  and c.ativo = true
  and cc.ativo = true
  and nc.ativo = true
  and nc.status_automacao = 'ativo'
  and nc.canal_whatsapp = true
  and cc.whatsapp_norm is not null
  and p.status_cobranca in ('em_aberto', 'em_cobranca', 'aguardando_pagamento', 'negociando')
  and p.vencimento < current_date
  and (p.proximo_contato_em is null or p.proximo_contato_em <= now())
  and (p.pausado_ate is null or p.pausado_ate <= now());

create or replace view public.n8n_cobranca_v_resumo_cobranca_contato as
select
  cliente_id,
  cliente_nome_fantasia,
  cliente_razao_social,
  cliente_documento,
  cliente_cnpj,
  cliente_contato_id,
  contato_nome,
  contato_whatsapp_norm,
  count(*)::integer as qtd_pendencias,
  sum(valor_cobrado_centavos)::integer as total_cobrado_centavos,
  sum(valor_atualizado_centavos)::integer as total_atualizado_centavos,
  min(vencimento) as vencimento_mais_antigo,
  max(dias_atraso)::integer as maior_dias_atraso,
  max(tentativas_cobranca)::integer as maior_tentativas_cobranca,
  case
    when max(dias_atraso) >= 30 then 'firme'
    when max(dias_atraso) >= 10 then 'educada'
    else 'amigavel'
  end as tom_cobranca,
  jsonb_agg(
    jsonb_build_object(
      'pendencia_id', pendencia_id,
      'num_os', num_os,
      'valor_atualizado_centavos', valor_atualizado_centavos,
      'vencimento', vencimento,
      'dias_atraso', dias_atraso,
      'status_cobranca', status_cobranca
    )
    order by vencimento asc
  ) as pendencias_json,
  max(dias_sem_resposta_atual)::integer as maior_dias_sem_resposta_atual,
  min(proximo_contato_em) as proximo_contato_mais_proximo,
  max(ultimo_envio_cobranca_em) as ultimo_envio_cobranca_em
from public.n8n_cobranca_v_pendencias_cobraveis
group by
  cliente_id,
  cliente_nome_fantasia,
  cliente_razao_social,
  cliente_documento,
  cliente_cnpj,
  cliente_contato_id,
  contato_nome,
  contato_whatsapp_norm;

create or replace view public.n8n_cobranca_v_diagnostico_fila as
select
  p.id as pendencia_id,
  p.cliente_id,
  c.nome_fantasia as cliente_nome_fantasia,
  p.cliente_contato_id,
  cc.nome as contato_nome,
  cc.whatsapp_norm as contato_whatsapp_norm,
  p.num_os,
  p.valor_atualizado_centavos,
  p.vencimento,
  p.status_cobranca,
  p.proximo_contato_em,
  p.pausado_ate,
  p.tentativas_cobranca,
  coalesce((select valor from public.n8n_cobranca_config where chave = 'ativo_geral'), 'sim') = 'sim' as config_ativa,
  public.n8n_cobranca_is_send_window(now()) as dentro_janela_envio,
  c.ativo as cliente_ativo,
  cc.ativo as contato_ativo,
  coalesce(nc.ativo, false) as automacao_contato_ativa,
  coalesce(nc.status_automacao = 'ativo', false) as status_automacao_ativo,
  coalesce(nc.canal_whatsapp, false) as canal_whatsapp_ativo,
  cc.whatsapp_norm is not null as whatsapp_preenchido,
  p.status_cobranca in ('em_aberto', 'em_cobranca', 'aguardando_pagamento', 'negociando') as status_cobravel,
  p.vencimento < current_date as vencida,
  (p.proximo_contato_em is null or p.proximo_contato_em <= now()) as proximo_contato_liberado,
  (p.pausado_ate is null or p.pausado_ate <= now()) as pausa_liberada,
  (
    coalesce((select valor from public.n8n_cobranca_config where chave = 'ativo_geral'), 'sim') = 'sim'
    and public.n8n_cobranca_is_send_window(now()) = true
    and c.ativo = true
    and cc.ativo = true
    and coalesce(nc.ativo, false) = true
    and coalesce(nc.status_automacao = 'ativo', false) = true
    and coalesce(nc.canal_whatsapp, false) = true
    and cc.whatsapp_norm is not null
    and p.status_cobranca in ('em_aberto', 'em_cobranca', 'aguardando_pagamento', 'negociando')
    and p.vencimento < current_date
    and (p.proximo_contato_em is null or p.proximo_contato_em <= now())
    and (p.pausado_ate is null or p.pausado_ate <= now())
  ) as elegivel_agora
from public.n8n_cobranca_pendencia p
join public.cliente c on c.id = p.cliente_id
join public.cliente_contato cc on cc.id = p.cliente_contato_id
left join public.n8n_cobranca_cliente nc
  on nc.cliente_id = p.cliente_id
 and nc.cliente_contato_id = p.cliente_contato_id
order by p.vencimento asc;

create or replace view public.n8n_cobranca_v_interacoes_pendentes_notificacao as
select
  i.id as interacao_id,
  i.cliente_id,
  c.nome_fantasia as cliente_nome_fantasia,
  i.cliente_contato_id,
  cc.nome as contato_nome,
  cc.whatsapp_norm as contato_whatsapp_norm,
  i.tipo,
  i.categoria,
  i.mensagem,
  i.classificacao_ia,
  i.acao_automacao,
  i.anexo_url,
  i.created_at
from public.n8n_cobranca_interacao i
join public.cliente c on c.id = i.cliente_id
join public.cliente_contato cc on cc.id = i.cliente_contato_id
where i.tipo = 'entrada'
  and i.notificacao_equipe = false
order by i.created_at asc;

create or replace view public.n8n_cobranca_v_comprovantes_pendentes_validacao as
select
  cp.id as comprovante_id,
  cp.pendencia_id,
  cp.cliente_id,
  c.nome_fantasia as cliente_nome_fantasia,
  cp.cliente_contato_id,
  cc.nome as contato_nome,
  p.num_os,
  p.valor_atualizado_centavos,
  cp.valor_extraido_centavos,
  (coalesce(cp.valor_extraido_centavos, 0) - coalesce(p.valor_atualizado_centavos, 0)) as diferenca_centavos,
  cp.arquivo_url,
  cp.data_extraida,
  cp.autenticacao,
  cp.classificacao_ia,
  cp.status_validacao,
  cp.observacoes,
  cp.recebido_em
from public.n8n_cobranca_comprovante cp
join public.cliente c on c.id = cp.cliente_id
join public.cliente_contato cc on cc.id = cp.cliente_contato_id
left join public.n8n_cobranca_pendencia p on p.id = cp.pendencia_id
where cp.status_validacao = 'pendente'
order by cp.recebido_em asc;

-- RPCs called by n8n.

create or replace function public.n8n_cobranca_gateway_resolver_contato(
  p_whatsapp text
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_record record;
begin
  select
    nc.id as cobranca_cliente_id,
    c.id as cliente_id,
    cc.id as cliente_contato_id,
    cc.nome as contato_nome,
    cc.whatsapp_norm
  into v_record
  from public.n8n_cobranca_cliente nc
  join public.cliente c on c.id = nc.cliente_id
  join public.cliente_contato cc on cc.id = nc.cliente_contato_id
  where cc.whatsapp_norm = p_whatsapp
    and c.ativo = true
    and cc.ativo = true
    and nc.ativo = true
    and nc.status_automacao = 'ativo'
    and nc.canal_whatsapp = true
  limit 1;

  if not found then
    return jsonb_build_object(
      'permitido', false,
      'motivo_bloqueio', 'contato_nao_autorizado',
      'modo_teste', false
    );
  end if;

  return jsonb_build_object(
    'permitido', true,
    'motivo_bloqueio', null,
    'modo_teste', coalesce((select valor = 'sim' from public.n8n_cobranca_config where chave = 'modo_teste'), false),
    'whatsapp_norm', v_record.whatsapp_norm,
    'cobranca_cliente_id', v_record.cobranca_cliente_id,
    'cliente_id', v_record.cliente_id,
    'cliente_contato_id', v_record.cliente_contato_id,
    'contato_nome', v_record.contato_nome
  );
end;
$$;

create or replace function public.n8n_cobranca_registrar_resposta_cliente(
  p_whatsapp text default null,
  p_cliente_contato_id uuid default null,
  p_mensagem text default null,
  p_classificacao_ia text default null,
  p_categoria text default null,
  p_status_cobranca text default null,
  p_resumo_observacao text default null,
  p_whatsapp_message_id text default null,
  p_anexo_url text default null,
  p_raw_payload jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_contato record;
  v_pendencia_id uuid;
  v_promessa date;
  v_status text := nullif(p_status_cobranca, 'SEM_ALTERACAO');
  v_pausado_ate timestamptz;
begin
  select cc.id as cliente_contato_id, cc.cliente_id, cc.whatsapp_norm
  into v_contato
  from public.cliente_contato cc
  where (p_cliente_contato_id is not null and cc.id = p_cliente_contato_id)
     or (p_cliente_contato_id is null and p_whatsapp is not null and cc.whatsapp_norm = p_whatsapp)
  limit 1;

  if not found then
    raise exception 'Contato não encontrado para registro de resposta';
  end if;

  select p.id
  into v_pendencia_id
  from public.n8n_cobranca_pendencia p
  where p.cliente_contato_id = v_contato.cliente_contato_id
    and p.status_cobranca not in ('pago', 'cancelado')
  order by p.vencimento asc
  limit 1;

  v_promessa := nullif(p_raw_payload #>> '{ia,promessa_pagamento_data}', '')::date;

  if v_promessa is not null then
    v_status := 'aguardando_pagamento';
    v_pausado_ate := public.n8n_cobranca_next_business_send_at(v_promessa::timestamp at time zone 'America/Sao_Paulo', 1);
  end if;

  insert into public.n8n_cobranca_interacao (
    pendencia_id,
    cliente_id,
    cliente_contato_id,
    tipo,
    categoria,
    mensagem,
    classificacao_ia,
    acao_automacao,
    anexo_url,
    whatsapp_message_id,
    raw_payload,
    promessa_pagamento_data,
    pausado_ate,
    motivo_pausa
  ) values (
    v_pendencia_id,
    v_contato.cliente_id,
    v_contato.cliente_contato_id,
    'entrada',
    coalesce(p_categoria, 'outro'),
    coalesce(p_mensagem, p_resumo_observacao),
    p_classificacao_ia,
    'resposta_cliente_registrada',
    p_anexo_url,
    p_whatsapp_message_id,
    coalesce(p_raw_payload, '{}'::jsonb),
    v_promessa,
    v_pausado_ate,
    case when v_promessa is not null then 'promessa_pagamento' else null end
  );

  if v_pendencia_id is not null and v_status is not null then
    update public.n8n_cobranca_pendencia
    set
      status_cobranca = case
        when status_cobranca = 'validando_comprovante' then status_cobranca
        else v_status
      end,
      promessa_pagamento_data = coalesce(v_promessa, promessa_pagamento_data),
      pausado_ate = coalesce(v_pausado_ate, pausado_ate),
      motivo_pausa = case when v_promessa is not null then 'promessa_pagamento' else motivo_pausa end,
      proximo_contato_em = coalesce(v_pausado_ate, proximo_contato_em),
      ultima_resposta_cliente_em = now(),
      sem_resposta_desde_em = null,
      updated_at = now()
    where id = v_pendencia_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'cliente_id', v_contato.cliente_id,
    'cliente_contato_id', v_contato.cliente_contato_id,
    'pendencia_id', v_pendencia_id,
    'status_aplicado', v_status,
    'promessa_pagamento_data', v_promessa,
    'pausado_ate', v_pausado_ate
  );
end;
$$;

create or replace function public.n8n_cobranca_registrar_comprovante(
  p_cliente_contato_id uuid,
  p_pendencia_id uuid default null,
  p_tipo_arquivo text default null,
  p_arquivo_url text default null,
  p_drive_file_id text default null,
  p_valor_extraido_centavos integer default null,
  p_data_extraida date default null,
  p_autenticacao text default null,
  p_classificacao_ia text default null,
  p_observacoes text default null,
  p_whatsapp_message_id text default null,
  p_raw_payload jsonb default '{}'::jsonb
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_contato record;
  v_pendencia_id uuid := p_pendencia_id;
  v_comprovante_id uuid;
begin
  select cc.id as cliente_contato_id, cc.cliente_id
  into v_contato
  from public.cliente_contato cc
  where cc.id = p_cliente_contato_id;

  if not found then
    raise exception 'Contato não encontrado para registrar comprovante';
  end if;

  if v_pendencia_id is null then
    select p.id
    into v_pendencia_id
    from public.n8n_cobranca_pendencia p
    where p.cliente_contato_id = p_cliente_contato_id
      and p.status_cobranca not in ('pago', 'cancelado')
    order by p.vencimento asc
    limit 1;
  end if;

  insert into public.n8n_cobranca_comprovante (
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
    observacoes,
    raw_payload
  ) values (
    v_pendencia_id,
    v_contato.cliente_id,
    v_contato.cliente_contato_id,
    p_tipo_arquivo,
    p_arquivo_url,
    p_drive_file_id,
    p_valor_extraido_centavos,
    p_data_extraida,
    p_autenticacao,
    coalesce(p_classificacao_ia, 'INCONCLUSIVO'),
    p_observacoes,
    coalesce(p_raw_payload, '{}'::jsonb)
  )
  returning id into v_comprovante_id;

  insert into public.n8n_cobranca_interacao (
    pendencia_id,
    cliente_id,
    cliente_contato_id,
    tipo,
    categoria,
    mensagem,
    classificacao_ia,
    acao_automacao,
    anexo_url,
    whatsapp_message_id,
    raw_payload
  ) values (
    v_pendencia_id,
    v_contato.cliente_id,
    v_contato.cliente_contato_id,
    'entrada',
    'comprovante',
    'Comprovante recebido para validação humana.',
    coalesce(p_classificacao_ia, 'INCONCLUSIVO'),
    'comprovante_recebido',
    p_arquivo_url,
    p_whatsapp_message_id,
    coalesce(p_raw_payload, '{}'::jsonb)
  );

  if v_pendencia_id is not null and coalesce(p_classificacao_ia, 'INCONCLUSIVO') <> 'NAO_COMPROVANTE' then
    update public.n8n_cobranca_pendencia
    set
      status_cobranca = 'validando_comprovante',
      pausado_ate = null,
      motivo_pausa = 'validacao_comprovante',
      ultima_resposta_cliente_em = now(),
      sem_resposta_desde_em = null,
      updated_at = now()
    where id = v_pendencia_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'comprovante_id', v_comprovante_id,
    'pendencia_id', v_pendencia_id,
    'status_validacao', 'pendente'
  );
end;
$$;

create or replace function public.n8n_cobranca_registrar_envio(
  p_cliente_id uuid,
  p_cliente_contato_id uuid,
  p_pendencia_ids uuid[],
  p_mensagem text,
  p_whatsapp_message_id text default null,
  p_raw_payload jsonb default '{}'::jsonb,
  p_proximo_contato_em timestamptz default null
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_proximo timestamptz := coalesce(p_proximo_contato_em, public.n8n_cobranca_next_business_send_at(now(), 1));
  v_snapshot jsonb;
begin
  select jsonb_agg(
    jsonb_build_object(
      'pendencia_id', p.id,
      'num_os', p.num_os,
      'valor_atualizado_centavos', p.valor_atualizado_centavos,
      'vencimento', p.vencimento,
      'tentativas_antes_envio', p.tentativas_cobranca
    )
    order by p.vencimento asc
  )
  into v_snapshot
  from public.n8n_cobranca_pendencia p
  where p.id = any(p_pendencia_ids);

  update public.n8n_cobranca_pendencia p
  set
    status_cobranca = 'em_cobranca',
    ultimo_contato_em = now(),
    ultimo_envio_cobranca_em = now(),
    proximo_contato_em = v_proximo,
    tentativas_cobranca = p.tentativas_cobranca + 1,
    dias_atraso_ultimo_envio = greatest((current_date - p.vencimento), 0),
    dias_sem_resposta_ultimo_envio = case
      when p.sem_resposta_desde_em is null then 0
      else greatest((current_date - (p.sem_resposta_desde_em at time zone 'America/Sao_Paulo')::date), 0)
    end,
    sem_resposta_desde_em = coalesce(p.sem_resposta_desde_em, now()),
    pausado_ate = null,
    motivo_pausa = null,
    updated_at = now()
  where p.id = any(p_pendencia_ids)
    and p.cliente_id = p_cliente_id
    and p.cliente_contato_id = p_cliente_contato_id;

  insert into public.n8n_cobranca_interacao (
    cliente_id,
    cliente_contato_id,
    tipo,
    categoria,
    mensagem,
    classificacao_ia,
    acao_automacao,
    whatsapp_message_id,
    raw_payload,
    dias_atraso_no_envio,
    dias_sem_resposta_no_envio,
    tentativa_no_envio,
    tom_cobranca_no_envio,
    pendencias_snapshot_json,
    sem_resposta_desde_em
  )
  select
    p_cliente_id,
    p_cliente_contato_id,
    'saida',
    'cobranca',
    p_mensagem,
    'AUTO_COBRANCA',
    'mensagem_cobranca_enviada',
    p_whatsapp_message_id,
    coalesce(p_raw_payload, '{}'::jsonb),
    max(greatest((current_date - p.vencimento), 0)),
    max(case
      when p.sem_resposta_desde_em is null then 0
      else greatest((current_date - (p.sem_resposta_desde_em at time zone 'America/Sao_Paulo')::date), 0)
    end),
    max(p.tentativas_cobranca),
    case
      when max(greatest((current_date - p.vencimento), 0)) >= 30 then 'firme'
      when max(greatest((current_date - p.vencimento), 0)) >= 10 then 'educada'
      else 'amigavel'
    end,
    v_snapshot,
    now()
  from public.n8n_cobranca_pendencia p
  where p.id = any(p_pendencia_ids);

  return jsonb_build_object(
    'ok', true,
    'pendencias_atualizadas', coalesce(array_length(p_pendencia_ids, 1), 0),
    'proximo_contato_em', v_proximo
  );
end;
$$;

create or replace function public.n8n_cobranca_marcar_interacoes_notificadas(
  p_interacao_ids uuid[]
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_count integer;
begin
  update public.n8n_cobranca_interacao
  set notificacao_equipe = true
  where id = any(p_interacao_ids);

  get diagnostics v_count = row_count;

  return jsonb_build_object(
    'ok', true,
    'interacoes_marcadas', v_count
  );
end;
$$;

