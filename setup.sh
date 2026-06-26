#!/usr/bin/env bash
# Платформын хавтас үүсгэх + микрофоны зөвшөөрөл нэмэх туслах скрипт.
set -e
flutter create --platforms=android --project-name hooloi_clone .
cp AndroidManifest.template.xml android/app/src/main/AndroidManifest.xml
flutter pub get
echo "Бэлэн! Одоо:  flutter build apk --release"
