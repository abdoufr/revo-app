#!/bin/bash

# Télécharger Flutter sur le serveur Vercel
echo "Cleaning old Flutter cache..."
rm -rf flutter
echo "Cloning Flutter version 3.22.2..."
git clone https://github.com/flutter/flutter.git -b 3.22.2

# Ajouter Flutter au PATH temporaire
export PATH="$PATH:`pwd`/flutter/bin"

# Télécharger les dépendances du projet
echo "Cleaning up..."
flutter clean
echo "Getting dependencies..."
flutter pub get

# Compiler l'application Web
echo "Building Web App..."
flutter build web --pwa-strategy=none -v
