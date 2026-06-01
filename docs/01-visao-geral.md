# Visão Geral

Este projeto demonstra uma automação de cobrança por WhatsApp estruturada em n8n, com Supabase como base operacional.

A automação cobre quatro responsabilidades principais:

1. Receber e validar mensagens vindas do WhatsApp.
2. Processar respostas, áudios e comprovantes enviados por clientes.
3. Notificar a equipe financeira sobre entradas relevantes.
4. Enviar cobranças automáticas para contatos elegíveis.

## Contexto Operacional

O processo foi desenhado para operações financeiras que precisam acompanhar pendências, cobrar clientes de forma recorrente e manter histórico centralizado das interações.

Na versão anterior, a automação utilizava Google Sheets como base operacional, pois era uma forma simples de usuários comuns adicionarem clientes, removerem contatos e cadastrarem novas OSs pendentes. Na versão migrada para n8n, o Supabase assume esse papel, oferecendo mais rastreabilidade e melhor organização dos dados.

## Decisões Importantes

### IA Não Escreve Mensagens De Cobrança

As mensagens automáticas são determinísticas e baseadas em template. A IA é usada apenas para:

- classificar resposta do cliente;
- extrair promessa de pagamento;
- transcrever áudio;
- apoiar a análise de comprovantes.

Essa decisão reduz risco jurídico/operacional, melhora previsibilidade e facilita auditoria.

### Supabase Substitui A Planilha Operacional

O estado da cobrança fica no Supabase:

- clientes autorizados;
- pendências;
- histórico de interações;
- comprovantes;
- configurações;
- filas operacionais por views.

### Comprovante Exige Validação Humana

A IA pode sugerir que um arquivo parece comprovante, mas não marca uma pendência como paga.

O pagamento só deve ser encerrado após validação humana ou regra transacional controlada no banco.

## Resultado Esperado

O case demonstra uma automação com preocupação real de produção:

- controle de horário de envio;
- pausa por promessa de pagamento;
- histórico auditável;
- prevenção de duplicidade por fila e próximo contato;
- separação entre entrada, processamento, notificação e envio;
- publicação segura com dados fictícios.

