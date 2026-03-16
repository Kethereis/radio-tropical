# tropical

Aplicativo Flutter da Rádio Tropical.

## Build iOS no CI (App Store Connect)

Se o step de assinatura falhar com erro similar a:

- `Unable to process request - PLA Update available`
- `You currently don't have access to this membership resource`

isso **não é erro de código**. A conta Apple Developer está bloqueando chamadas da API até o aceite do contrato vigente.

### Como resolver

1. O **Account Holder** da conta Apple Developer deve entrar no painel:
   - Apple Developer Program
   - App Store Connect
2. Aceitar o contrato/PLA pendente.
3. Reexecutar o pipeline de build iOS.

> Sem esse aceite, comandos como `app-store-connect fetch-signing-files ...` retornam `403` e o build não consegue baixar arquivos de signing.

## Firebase no iOS

O app inicializa Firebase durante o bootstrap. Para iOS, confira se os valores de `lib/firebase_options.dart` correspondem ao app `app.radio.tropical`.
