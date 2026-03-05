# ❓ FAQ — LUNA

> Questions fréquentes sur LUNA, son fonctionnement et sa politique de confidentialité.
> Ce fichier est embarqué dans le bundle de l'application (accessible hors connexion).

---

## 🔒 Confidentialité & Données

### Où sont stockées mes données ?
**Sur ton appareil uniquement.** LUNA ne possède aucun serveur. Tes données ne quittent jamais ton téléphone, sauf si tu actives la synchronisation iCloud (iOS) — et dans ce cas, elles sont chiffrées *avant* d'être envoyées, avec une clé que seul ton PIN connaît. Même Apple ne peut pas les lire.

### LUNA peut-il accéder à mes données ?
**Non.** Techniquement impossible. L'application n'a pas de permission réseau (`INTERNET` est absent du manifeste Android ; `NSAppTransportSecurity` est configuré pour bloquer tout réseau externe sur iOS). Le code source de LUNA est partiellement ouvert — tu peux le vérifier.

### Mes données sont-elles chiffrées ?
**Oui, avec AES-256-GCM.** La base de données est chiffrée via SQLCipher. La clé est dérivée de ton PIN via Argon2id (algorithme résistant aux attaques par force brute), stockée dans le Secure Enclave (iOS) ou l'Android Keystore. Sans ton PIN, les données sont illisibles, même pour quelqu'un qui accède physiquement à ton téléphone.

### Que se passe-t-il si je perds mon PIN ?
Si tu oublies ton PIN et que tu n'as pas de sauvegarde chiffrée, les données sont **irrécupérables** — c'est une conséquence intentionnelle de la conception : personne (ni toi, ni LUNA) ne peut déverrouiller les données sans le PIN. Conserve une note de ton PIN dans un endroit sûr, ou active la sauvegarde chiffrée.

### Qu'est-ce que le "mode panique" ?
C'est une fonction d'effacement d'urgence. En maintenant le logo LUNA 5 secondes dans les Paramètres, puis en confirmant par biométrie, l'app :
1. Écrase les clés de chiffrement en mémoire (zeroize).
2. Supprime et réécrit la base de données SQLite.
3. Supprime les enregistrements CloudKit (si sync activée).
4. Réinitialise l'app comme à l'état d'installation.

L'opération est **irréversible**. Elle est conçue pour les situations où tu dois effacer rapidement tes données (pression externe, frontière, etc.).

### LUNA utilise-t-il des analytics ou du tracking ?
**Zéro.** Aucun SDK Analytics, Firebase, Mixpanel, Sentry, Crashlytics, ni aucun équivalent n'est intégré dans LUNA. L'app ne sait même pas combien d'utilisatrices elle a. Aucun identifiant n'est créé ou partagé.

---

## 📅 Suivi du Cycle

### Combien de cycles faut-il pour que les prédictions soient précises ?
- **1 cycle** : prédiction basée sur ta durée saisie + médiane populationnelle. Confiance : faible.
- **3 cycles** : prédiction personnalisée. Confiance : moyenne. Erreur moyenne ≈ ±3 jours.
- **6+ cycles** : haute précision. Confiance : élevée. Erreur moyenne ≈ ±1–2 jours.

### Mon cycle n'est pas de 28 jours — est-ce normal ?
**Absolument.** La durée "normale" va de 21 à 35 jours. 28 jours est une moyenne populationnelle, pas une norme individuelle. LUNA calcule toujours à partir de *ton* historique personnel, jamais d'une norme externe.

### Pourquoi LUNA dit que mon ovulation n'est pas au jour 14 ?
Parce que c'est vrai pour la plupart des femmes. L'ovulation au jour 14 n'est juste que pour les cycles de exactement 28 jours avec une phase lutéale de 14 jours — une minorité. LUNA prédit l'ovulation à partir de ta durée de cycle personnelle (règle générale : ovulation ≈ J-14 depuis la fin estimée du cycle, pas depuis le début).

### Mes règles varient de quelques jours chaque mois — est-ce un problème ?
Une variation de ±3–5 jours est tout à fait normale. Si tes cycles varient de plus de 7 jours d'un cycle à l'autre, tu peux activer le mode "Cycle irrégulier" dans Paramètres > Mon cycle, ce qui ajuste les intervalles de confiance affichés.

### Puis-je utiliser LUNA comme contraceptif ?
**Non.** LUNA n'est pas certifiée comme dispositif contraceptif. L'algorithme n'est pas validé cliniquement pour la contraception (contrairement à Natural Cycles, certifié FDA). LUNA peut t'aider à *comprendre* ton cycle et identifier ta fenêtre fertile, mais ne doit pas être ton seul moyen de contraception si tu souhaites éviter une grossesse.

---

## 🌡️ BBT & Tests LH

### Quand et comment mesurer ma BBT ?
La Température Basale du Corps (BBT) doit être mesurée **au réveil, avant tout mouvement**, à la même heure chaque jour (±30 minutes), après au moins 3 heures de sommeil continu. Utilise un thermomètre basal (précision 0,01°C). La bouche ou le vagin donnent des mesures plus stables que l'aisselle.

### Ma BBT est erratique — pourquoi ?
La BBT peut être perturbée par : alcool la veille, maladie (fièvre), sommeil décalé, voyage (fuseau horaire), stress intense. LUNA affiche ces jours avec un indicateur "perturbé" si tu le signales dans le log quotidien.

### Les tests LH remplacent-ils la BBT ?
Non, ils sont complémentaires. Le LH détecte le pic *avant* l'ovulation (24–36h à l'avance), utile pour planifier. La BBT confirme l'ovulation *après* coup. Ensemble, ils donnent la meilleure précision possible sans équipement médical.

---

## 📱 Technique

### Sur quels appareils fonctionne LUNA ?
- **iOS** : iPhone avec iOS 16.0 ou supérieur.
- **Android** : appareils avec Android 8.0 (API 26) ou supérieur.

### L'app fonctionne-t-elle hors connexion ?
**Oui, totalement.** 100% des fonctions de LUNA fonctionnent hors connexion. Aucune connexion internet n'est jamais requise.

### LUNA se synchronise-t-il entre plusieurs appareils ?
Sur iOS, tu peux activer la sync iCloud (Paramètres > Stockage > Sync iCloud). Les données sont chiffrées côté client avant tout envoi. Sur Android, l'export/import manuel de sauvegarde chiffrée est disponible (Paramètres > Exporter mes données).

### Comment exporter mes données ?
Paramètres > Exporter mes données → PDF (rapport médecin) ou CSV (données brutes). L'export se fait en local, aucune donnée n'est envoyée à des serveurs. Tu peux envoyer le fichier par email, AirDrop, ou le stocker où tu veux.

### Puis-je importer mes données depuis Flo ou Clue ?
Pas encore directement. Si tu exportes tes données depuis Flo/Clue en CSV, un outil d'import est prévu en Phase 2 du développement. En attendant, tu peux re-saisir tes derniers 3–6 cycles dans l'onboarding pour obtenir de bonnes prédictions rapidement.

---

## ♿ Accessibilité

### LUNA est-elle accessible aux personnes aveugles ?
Oui. LUNA est conçue pour être entièrement utilisable avec VoiceOver (iOS) et TalkBack (Android). Tous les éléments interactifs ont des labels d'accessibilité. Le parcours principal (log du jour, consultation du cycle, paramètres) est entièrement navigable avec un lecteur d'écran.

### Les animations peuvent-elles être désactivées ?
Oui. Si "Réduire les animations" est activé dans les paramètres système d'accessibilité (iOS : Paramètres > Accessibilité > Mouvement > Réduire le mouvement ; Android : Paramètres > Accessibilité > Enlever les animations), LUNA désactive automatiquement toutes les animations et transitions.

### Les textes sont-ils lisibles en grande taille ?
LUNA supporte Dynamic Type sur iOS (toutes les tailles jusqu'à Accessibilité 5) et le grand texte sur Android (jusqu'à 200%). Aucun texte n'est tronqué sur les écrans principaux.

---

## 🌍 Langues

### En combien de langues est disponible LUNA ?
LUNA est disponible au lancement en **15 langues** (français, anglais, espagnol, portugais brésilien, allemand, italien, néerlandais, polonais, russe, ukrainien, turc, japonais, coréen, chinois simplifié, chinois traditionnel). Le support de l'arabe, hébreu, hindi et d'autres langues est prévu dans les 6 mois suivants le lancement.

### LUNA supporte-t-il l'arabe et l'hébreu (de droite à gauche) ?
Oui. Le support RTL complet (mise en page, calendrier, chiffres arabes) est prévu pour la version avec l'arabe et l'hébreu (Tier 2, ~6 mois post-lancement).

---

## ❤️ À propos de LUNA

### Qui développe LUNA ?
LUNA est un projet open-source développé par une équipe indépendante. L'application est gratuite et sans publicité. Le code du noyau Rust est disponible sur GitHub (licence Apache 2.0 / MIT).

### Comment signaler un bug ou suggérer une feature ?
Via GitHub Issues sur le dépôt public, ou par email à l'adresse indiquée dans les stores. La politique de confidentialité s'applique également aux retours : tu peux rester anonyme.

---

*FAQ v1.0 — 2026-03-05*
