import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  bool get isEnglish => locale.languageCode == 'en';

  String get welcome => isEnglish ? 'Welcome back.' : 'Bienvenue.';
  String get createAccount => isEnglish ? 'Create your account.' : 'Créer un compte.';
  String get loginSubtitle => isEnglish
      ? 'Your REST data, JWT session and offline cache in one place.'
      : 'Vos données REST, votre session JWT et votre cache hors ligne.';
  String get fullName => isEnglish ? 'Full name' : 'Nom complet';
  String get email => isEnglish ? 'Email address' : 'Adresse e-mail';
  String get username => isEnglish ? 'Username' : 'Identifiant';
  String get password => isEnglish ? 'Password' : 'Mot de passe';
  String get login => isEnglish ? 'Sign in' : 'Se connecter';
  String get register => isEnglish ? 'Create account' : 'Créer le compte';
  String get haveAccount => isEnglish ? 'I already have an account' : 'J’ai déjà un compte';
  String get needAccount => isEnglish ? 'Create a new account' : 'Créer un nouveau compte';
  String get demoAccount => isEnglish
      ? 'Demo account: admin / Password@123'
      : 'Compte de démonstration : admin / Password@123';
  String get registrationNote => isEnglish
      ? 'Your account is created securely by the API.'
      : 'Votre compte est créé par l’API de façon sécurisée.';
  String get requiredFields => isEnglish ? 'Complete all fields.' : 'Tous les champs sont obligatoires.';
  String get invalidCredentials => isEnglish
      ? 'Check your username and password.'
      : 'Vérifiez votre identifiant et votre mot de passe.';
  String get nameTooShort => isEnglish ? 'Enter at least 2 characters.' : 'Saisissez au moins 2 caractères.';
  String get usernameTooShort => isEnglish ? 'Use at least 3 characters.' : 'Utilisez au moins 3 caractères.';
  String get passwordTooShort => isEnglish ? 'Use at least 8 characters.' : 'Utilisez au moins 8 caractères.';
  String get invalidEmail => isEnglish ? 'Enter a valid email address.' : 'Saisissez une adresse e-mail valide.';
  String get signOut => isEnglish ? 'Sign out' : 'Se déconnecter';
  String get changeLanguage => isEnglish ? 'Change language' : 'Changer de langue';
  String get dashboard => isEnglish ? 'Overview' : 'Vue d’ensemble';
  String get users => isEnglish ? 'Users' : 'Utilisateurs';
  String get posts => isEnglish ? 'Posts' : 'Articles';
  String get tasks => isEnglish ? 'Tasks' : 'Tâches';
  String get settings => isEnglish ? 'Settings' : 'Réglages';
  String get dashboardSubtitle => isEnglish
      ? 'A quick look at your Pulseboard workspace.'
      : 'Un aperçu rapide de votre espace Pulseboard.';
  String get peopleTracked => isEnglish ? 'People' : 'Personnes';
  String get publishedPosts => isEnglish ? 'Posts' : 'Articles';
  String get taskProgress => isEnglish ? 'Task progress' : 'Progression des tâches';
  String get completed => isEnglish ? 'Completed' : 'Terminées';
  String get activity => isEnglish ? 'Your workspace' : 'Votre espace';
  String get usersSubtitle => isEnglish ? 'People from the public REST API.' : 'Les utilisateurs de l’API REST publique.';
  String get postsSubtitle => isEnglish ? 'Recent publications from the REST API.' : 'Les publications récentes de l’API REST.';
  String get tasksSubtitle => isEnglish ? 'Track completed and open tasks.' : 'Suivez les tâches terminées et à faire.';
  String get allTasks => isEnglish ? 'All' : 'Toutes';
  String get openTasks => isEnglish ? 'Open' : 'À faire';
  String get completedTasks => isEnglish ? 'Done' : 'Terminées';
  String get offline => isEnglish ? 'Offline' : 'Hors ligne';
  String get retry => isEnglish ? 'Try again' : 'Réessayer';
  String get unexpectedError => isEnglish
      ? 'Something unexpected happened.'
      : 'Une erreur inattendue est survenue.';
  String get languageSection => isEnglish ? 'App language' : 'Langue de l’application';
  String get accessibilitySection => isEnglish ? 'Accessibility' : 'Accessibilité';
  String get accessibilityDescription => isEnglish
      ? 'Controls have screen-reader labels, and lists load items as you scroll.'
      : 'Les commandes ont des libellés accessibles, et les listes chargent les éléments au fil du défilement.';
  String get architectureSection => isEnglish ? 'Built for production' : 'Conçue pour la production';
  String get architectureDescription => isEnglish
      ? 'Clean Architecture • JWT authentication • Hive offline cache • automated tests'
      : 'Clean Architecture • authentification JWT • cache Hive hors ligne • tests automatisés';
  String get versionLabel => isEnglish ? 'Version 2.1.0' : 'Version 2.1.0';
  String get noData => isEnglish ? 'No items yet.' : 'Aucun élément pour le moment.';
  String get userLabel => isEnglish ? 'User' : 'Utilisateur';
  String get taskDone => isEnglish ? 'Done' : 'Terminée';
  String get taskToDo => isEnglish ? 'To do' : 'À faire';
  String tabTitle(int index) => switch (index) {
        0 => dashboard,
        1 => users,
        2 => posts,
        3 => tasks,
        _ => settings,
      };
}
