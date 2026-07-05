# TODO

## Tornar o app open source (futuro)

Decisão: publicar o código como **open source sob a licença GPLv3**.

Motivo: reforça o diferencial de privacidade do app ("offline, sem anúncios, seus
dados ficam no aparelho") — com o código aberto, a privacidade deixa de ser
promessa e passa a ser verificável. A GPLv3 (copyleft) foi escolhida para evitar
que alguém feche o código e venda um clone proprietário.

### Checklist antes de tornar o repositório público
- [ ] Garantir que a keystore de assinatura NÃO está versionada
      (`*.jks` / `*.keystore` / `key.properties` no `.gitignore`).
- [ ] Adicionar arquivo `LICENSE` com o texto da GPLv3.
- [ ] Adicionar cabeçalho/menção da licença GPLv3 (ex.: no `README.md`).
- [ ] Melhorar o `README.md`: o que é o app, screenshots, como buildar/rodar.
- [ ] Incluir nota de privacidade no README ("100% offline, sem telemetria").
- [ ] Revisar o histórico do git para garantir que nenhum segredo foi commitado.

## Doação / apoio ("pague um café") — só se houver bastante usuários

Decisão: **não fazer agora** — muito trabalho para pouco retorno sem uma base de
usuários. Reavaliar quando o app tiver volume que justifique.

Quando fizer, opção escolhida: **doação in-app via RevenueCat** (wrapper do
Google Play Billing).

Por que RevenueCat / Play Billing (e não PayPal dentro do app):
- Doação in-app por PayPal / link externo é **proibida** pela política de
  pagamentos do Google Play para desenvolvedor pessoa física (não isento de
  impostos). Levar o usuário a pagamento externo dentro do app pode derrubar o
  app na revisão.
- Doação via Play Billing (RevenueCat facilita a configuração) **é compatível** —
  mas passa pela loja e tem a comissão do Google.

Alternativa sem comissão e sem risco (disponível desde já, fora do app):
- Link de apoio **fora do app** — GitHub Sponsors / Ko-fi / Pix no repositório
  open source e/ou no site `vandreapps.top`. Nunca linkado/promovido de dentro
  do app.
