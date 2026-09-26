# Pulseboard — Projet de certification Flutter

Application Flutter complète construite pour démontrer les compétences demandées dans le projet de certification :

- authentification login / register / logout ;
- JWT avec access token + refresh token ;
- appels REST avec Dio ;
- injection automatique du JWT via intercepteur Dio ;
- refresh automatique après HTTP 401 ;
- 3 écrans de données provenant d'une API REST ;
- cache local avec Hive ;
- fonctionnement hors connexion grâce aux données mises en cache ;
- messages d'erreur lisibles pour l'utilisateur ;
- Clean Architecture `data / domain / presentation` ;
- Repository Pattern ;
- 5 tests unitaires de la couche repository/auth.

## 0. Vérification locale

Après installation des dépendances, exécuter `flutter analyze` et `flutter test`.
Le client API déclare explicitement son `SessionStore` afin que l’injection du token, le refresh JWT et la persistance de session compilent correctement.

## 1. API utilisée

L'application utilise **DummyJSON** :

- Base URL : `https://dummyjson.com`
- Authentification : `/auth/login`
- Refresh JWT : `/auth/refresh`
- Inscription simulée : `/users/add`
- Produits : `/products?limit=12`
- Articles : `/posts?limit=12`
- Utilisateurs : `/users?limit=12`

Documentation officielle : https://dummyjson.com/docs

### Compte de démonstration

```text
username: emilys
password: emilyspass
```

DummyJSON fournit un JWT et un refresh token à la connexion.

> Important : DummyJSON documente `/users/add` comme une opération simulée : l'utilisateur retourné est créé dans la réponse mais n'est pas persisté côté serveur. L'écran Register est donc volontairement documenté comme une inscription de démonstration. Pour une inscription réellement persistante, le même `AuthRepository` peut être branché sur un backend réel sans modifier la couche presentation.

## 2. Architecture

Le projet suit une séparation Clean Architecture simplifiée :

```text
lib/
├── core/
│   └── app_failure.dart
│
├── data/
│   ├── api_client.dart
│   ├── local_store.dart
│   └── repositories.dart
│
├── domain/
│   ├── models.dart
│   └── repositories.dart
│
├── presentation/
│   └── pages.dart
│
└── main.dart
```

### Domain

Le dossier `domain` ne dépend pas de Dio, Hive ou Flutter.

- `models.dart` contient les modèles métier.
- `repositories.dart` contient les contrats des repositories.

### Data

Le dossier `data` contient les détails techniques :

- `ApiClient` encapsule Dio ;
- `LocalStore` encapsule Hive ;
- `AuthRepository` gère login/register/logout ;
- `CatalogRepository` gère les trois sources REST et le cache.

### Presentation

`pages.dart` contient les écrans Flutter :

1. Produits
2. Articles
3. Équipe
4. Login/Register

Les écrans ne font jamais directement d'appel Dio ou Hive : ils passent par les repositories.

## 3. Authentification JWT

Le flux de connexion est :

```text
LoginPage
   ↓
AuthRepository.login()
   ↓
ApiClient / Dio
   ↓
POST /auth/login
   ↓
accessToken + refreshToken
   ↓
Hive
```

Pour les appels suivants, l'intercepteur Dio lit le token depuis `SessionStore` et ajoute automatiquement :

```http
Authorization: Bearer <accessToken>
```

### Refresh automatique

Si une requête reçoit `401` :

```text
API → 401
 ↓
Dio Interceptor
 ↓
POST /auth/refresh
 ↓
nouveau accessToken
 ↓
sauvegarde Hive
 ↓
rejoue la requête initiale
```

Si le refresh échoue, la session locale est supprimée et l'utilisateur doit se reconnecter.

## 4. Persistance et mode hors connexion

Hive contient deux boxes :

```text
auth
cache
```

La box `auth` contient :

- `accessToken`
- `refreshToken`
- `userName`

La box `cache` contient les réponses REST sérialisées :

- `products`
- `articles`
- `people`

Lorsqu'une requête REST réussit, sa réponse est enregistrée dans Hive.

Si le réseau échoue, le repository tente automatiquement de lire la donnée correspondante dans le cache.

```text
                 ┌── Réseau OK ──→ API ──→ cache Hive ──→ écran
Repository ──────┤
                 └── Réseau KO ──→ cache Hive ──────────→ écran
                                      │
                                      └── cache absent → message utilisateur
```

## 5. Gestion des erreurs

Les erreurs techniques sont converties en `AppFailure` avant d'atteindre l'interface.

Exemples :

- connexion indisponible ;
- timeout ;
- réponse API invalide ;
- cache local corrompu ;
- aucune donnée disponible hors connexion ;
- erreur d'authentification.

L'interface affiche le message utilisateur et propose un bouton **Réessayer** sur les écrans de données.

## 6. Tests

Les tests sont dans :

```text
test/repository_test.dart
```

Ils couvrent notamment :

1. récupération des produits depuis l'API + mise en cache ;
2. lecture des articles depuis le cache lorsque le réseau échoue ;
3. erreur explicite lorsqu'il n'existe aucun cache hors connexion ;
4. stockage du JWT et du refresh token après login ;
5. suppression de la session lors du logout.

L'objectif demandé était d'avoir au moins 3 tests unitaires de repository ; le projet en contient 5.

## 7. Installation

Prérequis :

- Flutter stable ;
- Dart compatible avec `sdk >=3.10.0 <4.0.0`.

Installer les dépendances :

```bash
flutter pub get
```

Lancer les tests :

```bash
flutter test
```

Analyser le projet :

```bash
flutter analyze
```

Lancer l'application :

```bash
flutter run
```

## 8. Vérification du mode hors connexion

Pour vérifier le cache :

1. lancer l'application avec Internet ;
2. se connecter avec `emilys / emilyspass` ;
3. ouvrir les trois onglets ;
4. laisser les données se charger ;
5. couper Internet ;
6. revenir sur les écrans ;
7. les données déjà téléchargées restent disponibles depuis Hive.

Pour vérifier le cas sans cache, supprimer les données de l'application puis couper Internet : un message d'erreur utilisateur sera affiché.

## 9. Correspondance avec le cahier des charges

| Exigence | Implémentation |
|---|---|
| Login | `AuthRepository.login()` + `/auth/login` |
| Register | `AuthRepository.register()` + `/users/add` |
| Logout | `AuthRepository.logout()` |
| JWT | access token stocké dans Hive |
| Intercepteur token | `ApiClient` / `InterceptorsWrapper.onRequest` |
| Refresh token | `InterceptorsWrapper.onError` + `/auth/refresh` |
| 3 écrans API | Produits, Articles, Équipe |
| REST | Dio |
| Cache local | Hive |
| Hors connexion | fallback automatique vers Hive |
| Gestion erreurs | `AppFailure` + messages UI |
| Architecture | `data / domain / presentation` |
| Repository Pattern | contrats dans `domain/repositories.dart` |
| Tests repository | 5 tests dans `test/repository_test.dart` |
| README | ce document |

## 10. Commandes de validation avant livraison

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

Le dépôt peut ensuite être publié sur GitHub avec le contenu du dossier du projet.
