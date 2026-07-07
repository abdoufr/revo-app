#!/bin/bash

# Télécharger Flutter sur le serveur Vercel
echo "Cloning Flutter..."
git clone https://github.com/flutter/flutter.git -b stable

# Ajouter Flutter au PATH temporaire
export PATH="$PATH:`pwd`/flutter/bin"

# Télécharger les dépendances du projet
echo "Getting dependencies..."
flutter pub get

# Compiler l'application Web
echo "Building Web App..."
flutter build web
