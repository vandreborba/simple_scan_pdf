# Regras do Projeto

1. **Pergunte antes de agir** — Confirme com o usuário antes de modificar código ou tomar decisões. Esta regra tem precedência sobre todas as outras.

   - **Sugira alternativas** — Se eu pedir algo que tenha uma solução melhor ou mais adequada, questione e sugira a abordagem ideal com justificativa.

1. **Processamento local por padrão** — Detecção, filtros, OCR e PDF rodam no
   aparelho; o app não envia dados para servidores nossos. Não adicione
   telemetria nem analytics. Permissões de rede herdadas de dependências (ex.:
   libs do ML Kit) são aceitáveis — não precisa ser 100% offline/airgapped.

2. **Pensando em open source (GPLv3)** — O código será público, então a
   privacidade precisa ser verificável. Nunca versione segredos: keystore
   (`*.jks`), `key.properties` ou senhas.

3. **Português** — Nomes de variáveis, funções, classes e comentários em
   português e descritivos.

4. **Tema** — Use `Theme.of(context).colorScheme` / `.textTheme` (ver `theme.dart`).

5. **Textos de UI** — Sempre via `AppLocalizations` (ARBs em `lib/l10n/`), nunca
   strings fixas na interface.
