# Simple Scan PDF

[![Licença: GPL v3](https://img.shields.io/badge/Licença-GPLv3-blue.svg)](LICENSE)

Scanner de documentos simples, sem propaganda e sem conta: câmera, detecção
automática do papel, ajuste manual, filtros, OCR local e exportação em PDF
pesquisável para compartilhar por WhatsApp, Google Drive, e-mail etc.

Todo o processamento (detecção, filtros, OCR e PDF) acontece no aparelho.
Nada é enviado para a internet — sem telemetria, sem analytics, sem nuvem.

Repositório: <https://github.com/vandreborba/simple_scan_pdf>

## Recursos

- Captura pela câmera com detecção do documento em tempo real no preview.
- Recorte sugerido automaticamente, com ajuste manual dos 4 cantos.
- Várias páginas no mesmo PDF, com reordenação, rotação e remoção.
- Filtros por página: original, documento (remove sombras), cinza, P&B e
  alto contraste.
- OCR local (ML Kit on-device) com camada de texto invisível no PDF —
  o PDF fica pesquisável e o texto pode ser copiado.
- Exportação com nome, qualidade e OCR configuráveis, mas com bons padrões:
  quem não quiser mexer em nada só toca em "Gerar PDF".
- Compartilhamento pela folha nativa do sistema.

## Stack

| Área | Escolha |
| --- | --- |
| UI | Flutter (Material 3), Android primeiro |
| Câmera | `camera` (CameraX) |
| Visão computacional | `dartcv4` (OpenCV via FFI): Canny + contornos para detecção, `warpPerspective` para recorte, filtros com imgproc |
| OCR | `google_mlkit_text_recognition` (on-device) |
| PDF | `pdf` (API de baixo nível, texto OCR em modo invisível) |
| Compartilhar | `share_plus` |
| Preferências | `shared_preferences` |

## Rodando

```bash
flutter pub get
flutter run            # com um dispositivo Android conectado
flutter test           # testes
flutter build apk      # APK de release
```

Requisitos: Flutter 3.41+ (Dart 3.11+) e Android SDK. O primeiro build
demora mais porque o `dartcv4` compila/baixa o OpenCV nativo.

## Estrutura

```
lib/
  main.dart                    # bootstrap e tema
  session.dart                 # documento em andamento (páginas)
  models/scan_models.dart      # ScanPage, filtros, resultado de OCR
  services/
    document_detector.dart     # detecção de papel (OpenCV)
    live_detector.dart         # detecção em tempo real no preview
    image_processor.dart       # perspectiva, rotação e filtros
    ocr_service.dart           # OCR local (ML Kit)
    pdf_service.dart           # PDF com camada de texto invisível
    settings_service.dart      # preferências com padrões sensatos
  screens/
    home_screen.dart           # entrada
    camera_screen.dart         # captura com overlay de detecção
    crop_screen.dart           # ajuste manual dos cantos
    review_screen.dart         # reordenar/editar/exportar
    page_edit_screen.dart      # filtro, rotação e novo recorte
    export_sheet.dart          # nome, qualidade, OCR e compartilhar
    ocr_text_screen.dart       # texto reconhecido (copiar)
    settings_screen.dart       # preferências
  widgets/
    quad_painter.dart          # contorno detectado no preview
    corner_editor.dart         # cantos arrastáveis
```

## Licença

Copyright © 2025 Vandre Apps

Este projeto é software livre sob a [GNU General Public License v3.0](LICENSE).
O código-fonte é aberto para que a promessa de privacidade seja verificável:
tudo roda no aparelho e nenhum dado do usuário é enviado para servidores nossos.

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para instruções de build, testes e envio
de pull requests.
