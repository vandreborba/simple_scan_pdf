#!/bin/bash

# Script para compilar aplicativo Flutter para Android no Linux
# Equivalente ao compilar_android.ps1

# Garante que o Flutter está no PATH mesmo em ambientes não-interativos
# (extensões de editor, scripts externos, etc.)
export PATH="$HOME/flutter/bin:$PATH"

# Cores para output (verifica se o terminal suporta cores)
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    # Terminal não suporta cores ou não é interativo
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Função para imprimir mensagens coloridas
print_message() {
    printf "${GREEN}%s${NC}\n" "$1"
}

print_warning() {
    printf "${YELLOW}%s${NC}\n" "$1"
}

print_error() {
    printf "${RED}%s${NC}\n" "$1"
}

# Verifica se está no diretório "0_arquivos_uteis" e sobe um nível se necessário
if [[ "$(basename "$PWD")" == "0_arquivos_uteis" ]]; then
    cd ..
    print_message "Navegando para o diretório do projeto..."
fi

# Atualiza automaticamente a versão no pubspec.yaml antes de compilar
pubspec_path="pubspec.yaml"
if [[ -f "$pubspec_path" ]]; then
    print_message "Atualizando versão no pubspec.yaml..."
    
    # Cria backup do pubspec.yaml
    cp "$pubspec_path" "${pubspec_path}.backup"
    
    # Lê a versão atual e incrementa
    if grep -q "^version:" "$pubspec_path"; then
        current_version=$(grep "^version:" "$pubspec_path" | sed 's/version: *//')
        
        # Extrai os números da versão (formato: major.minor.patch+build)
        if [[ $current_version =~ ([0-9]+)\.([0-9]+)\.([0-9]+)\+([0-9]+) ]]; then
            major=${BASH_REMATCH[1]}
            minor=${BASH_REMATCH[2]}
            patch=$((${BASH_REMATCH[3]} + 1))
            build=$((${BASH_REMATCH[4]} + 1))
            
            nova_versao="$major.$minor.$patch"
            novo_build="$build"
            
            # Atualiza o pubspec.yaml
            sed -i "s/^version: .*/version: $nova_versao+$novo_build/" "$pubspec_path"
            print_message "Versão atualizada para: $nova_versao+$novo_build"
        else
            print_warning "Formato de versão não reconhecido no pubspec.yaml"
        fi
    else
        print_warning "Campo 'version' não encontrado no pubspec.yaml"
    fi
else
    print_error "Arquivo pubspec.yaml não encontrado!"
    exit 1
fi

# Limpa build anterior
# print_message "Limpando build anterior..."
# flutter clean

# Obtém dependências
print_message "Obtendo dependências..."
flutter pub get

# Compila o aplicativo Flutter
print_message "Compilando aplicativo Flutter..."
flutter build appbundle --obfuscate --split-debug-info=debug_info

# Verifica se o build foi bem-sucedido
if [[ $? -ne 0 ]]; then
    print_error "Erro durante o processo de build. Verifique os erros acima."
    exit 1
fi

# Navega para a pasta do bundle de release
bundle_path="./build/app/outputs/bundle/release"
if [[ -d "$bundle_path" ]]; then
    print_message "Abrindo pasta do bundle de release..."
    
    # Abre a pasta do bundle no gerenciador de arquivos
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$bundle_path"
    elif command -v nautilus >/dev/null 2>&1; then
        nautilus "$bundle_path" &
    elif command -v dolphin >/dev/null 2>&1; then
        dolphin "$bundle_path" &
    else
        print_warning "Gerenciador de arquivos não encontrado. Pasta do bundle: $(realpath "$bundle_path")"
    fi
else
    print_error "Pasta do bundle não encontrada: $bundle_path"
fi

# Abre o Google Play Console no navegador padrão
print_message "Abrindo Google Play Console..."
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "https://play.google.com/console/u/0/developers/7961447969216777975/app-list?hl=pt-br" &
elif command -v firefox >/dev/null 2>&1; then
    firefox "https://play.google.com/console/u/0/developers/7961447969216777975/app-list?hl=pt-br" &
elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome "https://play.google.com/console/u/0/developers/7961447969216777975/app-list?hl=pt-br" &
else
    print_warning "Navegador não encontrado. Acesse manualmente:"
    echo "https://play.google.com/console/u/0/developers/7961447969216777975/app-list?hl=pt-br"
fi

print_message "Compilação concluída com sucesso!"
exit 0