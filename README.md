# Catálogo de Pássaros
Applicativo móvel desenvolvido em Flutter com acesso ao Firebase para catalogar fotografias de pássaros

## Pré-requisitos
Antes de iniciar, certifique-se de ter instalado em sua máquina:
* Flutter SDK (versão estável mais recente)
* Dart SDK
* Firebase CLI
* Node.js (necessário para o Firebase CLI)

## Configuração do Firebase
Por motivos de segurança, os arquivos de configuração do Firebase (`firebase_options.dart`, `google-services.json`, entre outros) não estão incluídos neste repositório.

Caso você tenha acesso ao console do Firebase deste projeto, siga os passos abaixo para gerar as credenciais localmente:

1. Certifique-se de estar logado na sua conta Google no terminal:
```bash
firebase  login
```

2. Ative o FlutterFire CLI globalmente (caso ainda não tenha ativado):
```bash
dart  pub  global  activate  flutterfire_cli
```

3. Execute o comando de configuração na raiz do projeto:
```bash
flutterfire  configure
```

4. Durante o assistente no terminal:
- Selecione o projeto correspondente no Firebase.
- Selecione as plataformas desejadas (Android, iOS, Web, etc.).

Este comando gerará automaticamente o arquivo `lib/firebase_options.dart` e atualizará as configurações nativas necessárias de forma segura na sua máquina.

## Como Executar o Projeto (Android - Versão de Debug)

Com o Firebase configurado e o dispositivo Android (físico ou emulador) conectado, execute os seguintes comandos no terminal:
1. Obter as dependências do Flutter:
```bash
flutter pub get
```

Verificar se o dispositivo Android é reconhecido pelo sistema:
```bash
flutter devices
```

Executar o aplicativo em modo de desenvolvimento (Debug):
```bash
flutter run
```

Caso possua mais de um dispositivo ativo, especifique o alvo utilizando o ID listado no passo anterior:
```bash
flutter run -d ID_DO_DISPOSITIVO
```

Com o aplicativo rodando em modo de Debug, você pode utilizar o recurso de Hot Reload pressionando a tecla r no terminal para aplicar alterações no código em tempo real.