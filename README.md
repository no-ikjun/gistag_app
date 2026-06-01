# gistag_app

A new Flutter project.

## Auth environment

Create a local `.env` from `.env.example`. The app loads it at startup with
`flutter_dotenv`, so `flutter run` is enough for local development.

Required keys:

- `GISTAG_API_DEBUG_BASE_URL`
- `GISTAG_API_PROD_BASE_URL`
- `GISTAG_IDP_AUTHORIZE_URL` (`https://api.account.gistory.me/oauth/authorize`)
- `GISTAG_IDP_CLIENT_ID`
- `GISTAG_IDP_REDIRECT_URI`

Debug/profile builds use `GISTAG_API_DEBUG_BASE_URL`. Release builds, including
`flutter build ipa --release`, use `GISTAG_API_PROD_BASE_URL`.

The default mobile redirect URI is `gistag://oauth/callback`. Android and iOS
are currently configured for `gistag://oauth/callback`.

For mobile development, keep using:

```sh
GISTAG_IDP_REDIRECT_URI=gistag://oauth/callback
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
