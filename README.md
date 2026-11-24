# CAVALEA — Equestrian Studio 🐎

**Application Flutter de gestion des concours équestres**, distincte du projet football. Elle met en avant le duo cavalier-cheval, les écuries et le bien-être équin.

## Les exigences du professeur

Le modèle de base est conservé dans SQLite, avec la présentation métier :
- `Club(Id, Libelle)` — affiché comme **Écurie**, avec ville, téléphone et photo.
- `Joueur(Id, Nom, Prenom, DateNaiss, Tel, Photo, #ClubId)` — affiché comme **Cavalier**, avec niveau et licence.
- Navigation, listes, ajout/modification/suppression des clubs et cavaliers, recherche par nom, prénom, écurie et téléphone ; bouton Appeler via le téléphone connecté.

## Extension équitation (identité propre)

- **Chevaux** : race, robe, âge, écurie, cavalier associé, disponibilité et échéance de soins.
- **Concours** : CSO, dressage, endurance ; lieu, niveau, hauteur, date et statut.
- **Engagements** : association d'un cavalier ET d'un cheval à une épreuve.
- **Résultats** : pénalités, temps, classement, enregistrés manuellement ; règles simplifiées de démonstration, **pas un calcul officiel FEI**.
- **Tableau de bord** : indicateurs, épreuves à venir et alertes de soins. Les alertes sont informatives et ne remplacent pas des avis vétérinaires.
- Images des écuries, cavaliers et chevaux par URL ou import de fichiers ; les fichiers importés sont compressés puis enregistrés en Base64 dans SQLite.
- Démo locale initialisée au premier lancement : 4 écuries, 10 cavaliers fictifs, 11 chevaux, 4 concours et 7 engagements, entièrement modifiables.

## Identité visuelle

L'application utilise une palette **vert forêt `#1D382F`, crème `#F7F5F0`, laiton `#BD9363`**, avec photographie équestre, cartes animées, navigation latérale sur desktop et barre inférieure mobile. Elle est indépendante de Championnat Pro et partage seulement la structure relationnelle exigée dans le TP.

## Comment lancer sur Chrome (Windows / IntelliJ ou terminal)

```powershell
git clone https://github.com/Ahmed-Braiek/horseracing-flutter.git
cd horseracing-flutter
flutter create --platforms=android,windows,web --project-name cavalea .
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8081
```

**Pourquoi le port 8081 ?** Pour éviter une collision avec le projet football utilisant 8080. Chrome stocke la base dans IndexedDB par origine (port compris).

## Lancer sur Android

```powershell
flutter devices
flutter run -d <ID_APPAREIL_ANDROID>
```

Pour Windows : `flutter run -d windows` après l'installation des outils C++ Flutter. Aucune installation de MySQL ou de serveur SQLite n'est nécessaire.

## Tests

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build web
```

GitHub Actions génère également un APK debug téléchargeable depuis l'onglet **Actions**, après réussite du pipeline.

## Base de données et intégrité

La base `cavalea.db` comprend `clubs`, `joueurs`, `chevaux`, `concours`, `engagements`. Les clés étrangères empêchent la suppression d'une écurie encore associée à un cavalier ou un cheval. Un engagement référence un cavalier, un cheval et un concours. L'interface empêche d'engager un duo provenant de deux écuries différentes.

Le projet est **offline-first** ; images distantes nécessitent une connexion. Sur navigateur la base est conservée par IndexedDB, sur Android et Windows dans le répertoire local de l'application. Les bases de chaque appareil ne sont pas synchronisées.

## Images de démonstration

L'image équestre d'accueil provient d'Unsplash : https://unsplash.com/photos/horse-jumping (photo hébergée sur `images.unsplash.com`). Une photographie de cheval historique est référencée depuis Wikimedia Commons : https://commons.wikimedia.org/wiki/File:Majestic_stallion%27s_head_(Unsplash).jpg — CC0. Respecter les crédits et conditions des sources avant diffusion externe. Les montures et cavaliers du jeu de données sont fictifs et les images illustratives ne prétendent pas montrer ces individus.

## Démo orale rapide

1. Explorer les statistiques du tableau de bord et les alertes de soins.
2. Ajouter une écurie avec photo, puis un cavalier rattaché à celle-ci.
3. Ajouter un cheval et l'affecter au cavalier.
4. Créer un concours CSO, inscrire un duo et saisir pénalités, temps, classement.
5. Vérifier la recherche, la modification, l'appel sur téléphone compatible, et les confirmations de suppression.

Le projet est conçu comme une démonstration académique et non comme un système officiel de gestion sportive ou de santé animale.


## Nouveau mode : COURSE 2D — arcade hippique

CAVALEA propose un mini-jeu 2D **jouable** depuis le sixième menu **Course 2D** (et depuis l'accueil via **Jouer une course 2D**).

- Les chevaux proviennent **directement de la table SQLite `chevaux`**. Les chevaux avec statut `Repos` sont exclus des sélections.
- Choisissez **2 à 6 chevaux**, puis cliquez **Lancer la course** : compte à rebours animé `3 → 2 → 1`, départ, défilement visuel et arrivée.
- Le champ de course a été dessiné entièrement en Flutter Canvas : **chevaux vectoriels 2D originaux** avec animation des jambes, crinière, queue, corps et jockey ; rails, pistes, drapeau d'arrivée, spectateurs, ciel, soleil et nuages en parallaxe. Il fonctionne même sans télécharger de sprites externes.
- La course mesure **700 mètres fictifs**, avec variation de rythme, âge et capacité arcade. Les résultats ne correspondent à aucune performance sportive réelle.
- **ENCOURAGER** : choisir un cheval dans le panneau de contrôle et lui attribuer jusqu'à deux encouragements ; chacun augmente temporairement sa vitesse. La fonction est strictement ludique.
- **Pause, Reprendre, Nouvelle grille, Rejouer**, classement live avec barres de progression, podium et temps d'arrivée.
- Les résultats sont conservés dans la nouvelle table **`race_history`**, créée par migration SQLite **v1 → v2** sans supprimer les données antérieures.
- L'écran demeure utilisable en Chrome / Windows / Android, au format desktop ou mobile.

Ce mode est conçu comme un **jeu de simulation simplifié sans paris, ni chronométrage réglementaire**, indépendant des vraies inscriptions de compétitions. Les épreuves officielles/administratives restent dans le menu **Concours**.

### Test rapide du jeu

```powershell
git pull origin main
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8081
```

Ouvrir **Course 2D**, sélectionner des chevaux, démarrer, encourager un cheval pendant la course et vérifier la sauvegarde du podium dans l'historique.

### Architecture du module de jeu

- `lib/race_engine.dart` : simulation testable, vitesse, dynamique, encouragements, classement et finish.
- `lib/race_scene.dart` : rendu du stade et des chevaux/jockeys via `CustomPainter`.
- `lib/race_game.dart` : interface interactive, moteur de frames Flutter, choix des participants, boutons et podium.
- `lib/equestrian_db.dart` : migration et sauvegarde atomique de l'historique.
- `test/race_engine_test.dart` : tests du classement, de la progression, des encouragements, de la reproductibilité et des frames nulles.
