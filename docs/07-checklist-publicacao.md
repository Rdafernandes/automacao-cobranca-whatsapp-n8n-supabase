# Checklist de publicação

Use este checklist antes de criar ou preencher o repositório público no GitHub.

## Estrutura

- [ ] `README.md` revisado.
- [ ] `docs/` completo.
- [ ] `workflows/sanitizados/` com os 4 workflows.
- [ ] `supabase/` com schema, seeds e queries demonstrativas.
- [ ] `samples/` com payloads fictícios.
- [ ] `assets/diagramas/` com diagrama público.
- [ ] `assets/screenshots/` com prints sanitizados.
- [ ] `.gitignore` revisado.

## Workflows

- [ ] Workflows originais fora do material público.
- [ ] Workflows sanitizados com `active: false`.
- [ ] Credenciais removidas.
- [ ] IDs internos removidos.
- [ ] `versionId`, `meta`, `tags` e `errorWorkflow` removidos.
- [ ] URL real do Supabase removida.
- [ ] ID real de grupo WhatsApp removido.
- [ ] ID real de pasta Google Drive removido.
- [ ] Placeholder do subworkflow documentado.

## Supabase

- [ ] Schema demonstrativo sem dados reais.
- [ ] Seeds apenas com dados fictícios.
- [ ] Views e RPCs documentadas.
- [ ] Queries de validação incluídas.
- [ ] Nenhuma service key real no repositório.

## Samples

- [ ] Payloads WHAPI fictícios.
- [ ] Telefones fictícios.
- [ ] Documentos fiscais fictícios ou mascarados.
- [ ] Mensagens sem nomes reais.
- [ ] IDs demonstrativos.
- [ ] Comprovantes fictícios.

## Screenshots

- [ ] Sem nomes de clientes reais.
- [ ] Sem números reais.
- [ ] Sem URLs privadas.
- [ ] Sem tokens ou credenciais.
- [ ] Sem conteúdo de conversas reais.

## Busca final

- [ ] Buscar por `apikey`.
- [ ] Buscar por `Authorization`.
- [ ] Buscar por `Bearer`.
- [ ] Buscar por `service_role`.
- [ ] Buscar por `supabase.co`.
- [ ] Buscar por IDs reais conhecidos.
- [ ] Buscar por telefones reais.
- [ ] Buscar por nomes reais.
- [ ] Buscar por documentos reais.

## Publicação

- [ ] Criar repositório no GitHub somente depois da revisão final.
- [ ] Subir apenas arquivos públicos.
- [ ] Se fizer upload manual pelo navegador, não arrastar a pasta inteira.
- [ ] Selecionar manualmente apenas `README.md`, `.gitignore`, `assets/`, `docs/`, `samples/`, `supabase/` e `workflows/sanitizados/`.
- [ ] Conferir o repositório online após upload.
- [ ] Abrir README no GitHub e revisar links.
- [ ] Confirmar que os JSONs sanitizados aparecem corretamente.
