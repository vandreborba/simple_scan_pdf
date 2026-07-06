# Contribuindo

Obrigado pelo interesse em contribuir com o Simple Scan PDF!

## Antes de começar

- Leia o [README.md](README.md) para entender o escopo do app.
- O projeto segue a [GPLv3](LICENSE): forks e distribuições derivadas precisam
  manter o código aberto sob a mesma licença.
- **Nunca** commite segredos de assinatura (`*.jks`, `*.keystore`,
  `key.properties`). O build de release funciona com a chave de debug quando
  esses arquivos não existem.

## Ambiente de desenvolvimento

Requisitos: Flutter 3.41+ (Dart 3.11+) e Android SDK.

```bash
flutter pub get
flutter run            # dispositivo Android conectado
flutter test           # testes
flutter build apk      # APK de release
```

O primeiro build demora mais porque o `dartcv4` compila/baixa o OpenCV nativo.

## Convenções do projeto

- Nomes de variáveis, funções, classes e comentários em **português**.
- Textos de interface sempre via `AppLocalizations` (ARBs em `lib/l10n/`).
- Tema via `Theme.of(context).colorScheme` / `.textTheme` (ver `lib/theme.dart`).
- Processamento local por padrão: sem telemetria, sem analytics, sem envio de
  dados do usuário para servidores nossos.

## Pull requests

1. Abra uma issue para discutir mudanças grandes, se possível.
2. Mantenha o escopo focado — uma correção ou feature por PR.
3. Rode `flutter test` antes de enviar.
4. Descreva o que mudou e por quê.
