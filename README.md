# Pulseboard — Projet de certification Flutter

Application Flutter complète démontrant les exigences du projet de certification :

- authentification **login / register / logout** ;
- **JWT access token + refresh token** ;
- appels REST avec **Dio** ;
- **intercepteur Dio** qui injecte automatiquement `Authorization: Bearer ...` ;
- **refresh automatique** après un `401`, avec rotation du refresh token ;
- **3 écrans REST distincts** : Utilisateurs, Articles, Tâches ;
- cache local avec **Hive** ;
- fonctionnement **hors connexion** avec lecture du cache ;
- indication visuelle `Hors ligne` quand les données proviennent du cache ;
- messages d'erreur utilisateur + bouton Réessayer ;
- architecture **Clean Architecture `data / domain / presentation`** ;
- **Repository Pattern** par interfaces dans `domain` ;
- **8 tests unitaires** ciblés repository + authentification + intercepteur.

## API publique utilisée

Le projet utilise **Playground API**, un backend REST public avec authentification JWT, inscription, refresh token et ressources REST persistées dans une session sandbox. La documentation officielle décrit notamment `/api/v1/auth/login`, `/api/v1/auth/register`, `/api/v1/auth/refresh`, `/api/v1/auth/me`, ainsi que les collections `users`, `posts` et `todos`.

Base URL :

```text
https://playground.nileslabs.com/api/v1
```

Endpoints utilisés :

```text
POST /auth/login
POST /auth/register
POST /auth/refresh
GET  /auth/me
GET  /users?limit=12
GET  /posts?limit=12
GET  /todos?limit=12
```

Documentation :
https://playground.nileslabs.com/docs

### Compte de démonstration

```text
username: admin
password: Password@123
```

## Authentification JWT

Le flux Login/Register reçoit :

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "user": { "name": "..." }
}
```

Les deux tokens et le nom utilisateur sont stockés dans Hive.

L'intercepteur `AuthInterceptor` :

1. lit `accessToken` depuis `SessionStore` ;
2. ajoute `Authorization: Bearer <token>` à chaque requête ;
3. intercepte une réponse `401` ;
4. envoie `refresh_token` à `/auth/refresh` ;
5. enregistre les nouveaux tokens ;
6. rejoue la requête initiale une seule fois ;
7. supprime la session si le refresh échoue.

Après Login ou Register, `/auth/me` est également appelé pour vérifier que le JWT permet bien d'accéder à une ressource protégée.

## Register réellement intégré

Contrairement à la version précédente basée sur DummyJSON, l'écran Register utilise ici `/auth/register` et reçoit immédiatement les deux JWT. L'utilisateur est donc connecté automatiquement après une inscription réussie.

## Logout

L'API publique ne nécessite pas de révocation serveur pour cet exercice. Le logout de l'application supprime immédiatement `access_token`, `refresh_token` et le nom utilisateur de Hive, ce qui invalide la session côté application.

## Architecture

```text
lib/
├── core/
│   └── app_failure.dart
├── data/
│   ├── api_client.dart
│   ├── dtos.dart
│   ├── local_store.dart
│   └── repositories.dart
├── domain/
│   ├── models.dart
│   └── repositories.dart
├── presentation/
│   └── pages.dart
└── main.dart
```

### Domain

Le `domain` ne dépend ni de Dio, ni de Hive, ni de Flutter.

- `models.dart` contient les modèles métier purs.
- `repositories.dart` contient les contrats.
- `DataResult` indique si les données viennent du réseau ou du cache.

### Data

- `dtos.dart` transforme les réponses JSON en modèles du domaine.
- `api_client.dart` encapsule Dio et l'intercepteur JWT.
- `local_store.dart` encapsule Hive.
- `repositories.dart` contient les implémentations concrètes des repositories.

### Presentation

Les écrans dépendent uniquement des interfaces `domain/repositories.dart`.

## Cache et mode hors connexion

Chaque repository suit le même principe :

```text
                 ┌── Réseau OK ──→ REST ──→ Hive ──→ écran
Repository ──────┤
                 └── Réseau KO ──→ Hive ──────────→ écran
                                      │
                                      └── absence cache → AppFailure
```

Les clés Hive utilisées sont :

```text
users
posts
todos
```

Quand un écran utilise le cache, l'interface affiche automatiquement :

```text
Hors ligne
```

## Gestion des erreurs

Les erreurs réseau et les réponses invalides sont converties en `AppFailure` avant l'interface.

L'utilisateur reçoit un message clair, par exemple :

```text
Connexion réseau indisponible. Vérifie Internet et réessaie.
```

ou, en absence de cache :

```text
Hors connexion : aucune donnée en cache pour cet écran.
```

## Tests

`test/repository_test.dart` contient 8 tests :

1. récupération REST des utilisateurs + cache ;
2. lecture du cache hors ligne ;
3. erreur sans cache ;
4. stockage des JWT après Login ;
5. inscription et ouverture automatique d'une session JWT ;
6. logout et suppression de session ;
7. injection `Bearer` par l'intercepteur ;
8. refresh token après `401` et rejeu de la requête.

## Installation

Prérequis : Flutter stable + Dart compatible avec `sdk >=3.10.0 <4.0.0`.

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

## Vérification du hors ligne

1. lancer l'application avec Internet ;
2. se connecter ;
3. ouvrir successivement les trois onglets ;
4. attendre le chargement des données ;
5. couper Internet ;
6. tirer la liste vers le bas pour actualiser ;
7. les données précédemment téléchargées sont affichées depuis Hive avec le badge `Hors ligne`.

## Correspondance avec le barème

| Exigence | Implémentation |
|---|---|
| Login | `POST /auth/login` + `AuthRepository.login()` |
| Register | `POST /auth/register` + ouverture automatique de session |
| Logout | suppression de la session locale |
| JWT | access + refresh token |
| 3 écrans REST | Utilisateurs, Articles, Tâches |
| Dio | `ApiClient` |
| Intercepteur | `AuthInterceptor.onRequest` |
| Refresh token | `AuthInterceptor.onError` + `/auth/refresh` |
| Cache local | Hive |
| Hors ligne | fallback repository vers Hive |
| Gestion erreurs | `AppFailure` + messages UI |
| Clean Architecture | `data / domain / presentation` |
| Repository Pattern | interfaces dans `domain/repositories.dart` |
| Tests repository | 8 tests |
| README | documentation complète |
