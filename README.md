# flutter_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

✅ Documentation Added

1. main.dart - Point d'entrée de l'application
Initialisation de SharedPreferences : Expliqué comment les préférences sont initialisées avant le démarrage de l'app
Configuration du thème : Détails sur l'application du thème personnalisé et de la police Inter
Architecture de l'app : Explication de la structure MaterialApp et de la page d'accueil

2. home.dart - Page d'accueil avec les régions
Gestion des états : Comment l'état de chargement, les erreurs et les données sont gérés
Interface utilisateur : Explication de la grille des régions et des icônes personnalisées
Navigation : Comment la navigation vers les villes est implémentée

3. cities_page.dart - Page des villes par région
Filtrage des données : Comment les villes sont récupérées et affichées pour une région spécifique
Interface adaptative : Explication des états de chargement, d'erreur et de données
Transitions fluides : Comment les animations de navigation sont configurées

4. pharmacies_page.dart - Page des pharmacies
Affichage des pharmacies : Comment les pharmacies sont listées avec leurs informations
Cartes interactives : Explication de la structure des cartes de pharmacies
Gestion des états : États de chargement, d'erreur et de données vides

5. pharmacy_model.dart - Modèle de données
Structure des données : Définition des propriétés d'une pharmacie
Sérialisation JSON : Comment les données sont converties en JSON et vice versa

6. pharmacy_service.dart - Service de récupération des données
Scraping web : Explication de la récupération des données depuis le site web
Traitement des données : Comment les informations sont extraites et nettoyées
Gestion des erreurs : Stratégies de gestion des erreurs réseau

7. pharmacy_repository.dart - Gestionnaire de cache et de données
Système de cache : Explication du cache 24h avec persistance
Optimisation des performances : Comment les données sont mises en cache et récupérées
Synchronisation : Gestion de la synchronisation entre cache et API

8. theme.dart - Thème et styles
Palette de couleurs : Définition et utilisation des couleurs du thème
Styles réutilisables : Explication des styles pour cartes, boutons et séparateurs
Hiérarchie visuelle : Comment la hiérarchie typographique est organisée

9. tile_regions.dart - Composant non utilisé
Code obsolète : Explication que ce fichier n'est plus utilisé dans l'application

10. widget_test.dart - Tests
Tests unitaires : Explication des tests de base pour l'application

✅ Benefits of This Documentation
Facilité de maintenance : Les futurs développeurs comprendront rapidement l'architecture
Réduction des erreurs : Les commentaires expliquent les choix techniques et les pièges à éviter
Évolutivité : Structure claire pour ajouter de nouvelles fonctionnalités
Formation : Idéal pour former de nouveaux développeurs sur le projet
Debugging : Facilite la résolution de problèmes futurs