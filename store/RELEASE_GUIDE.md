# Guía de Publicación en Google Play Store · Hydra

Sigue estos 5 pasos para publicar **Hydra** en Google Play Store.

---

## Paso 1: Generar tu Upload Keystore (en tu PC Windows)

Ejecuta esto en PowerShell (solo una vez) y **guarda el archivo `.jks` y las contraseñas en un lugar seguro** (ej. Google Drive privado o gestor de contraseñas; si lo pierdes, no podrás actualizar la app sin resetear la clave en Play Console):

```powershell
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

1. Mueve `upload-keystore.jks` a la carpeta `android/` de tu proyecto (está en `.gitignore`, nunca se subirá a Git).
2. Copia `android/key.properties.example` como `android/key.properties` y escribe tus contraseñas reales:
   ```properties
   storePassword=TU_PASSWORD
   keyPassword=TU_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

---

## Paso 2: Compilar el App Bundle (`.aab`) firmado

En la raíz de `WaterApp`:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

El archivo listo para subir quedará en:
`build\app\outputs\bundle\release\app-release.aab`

---

## Paso 3: Activar tu Política de Privacidad en GitHub Pages

1. Entra a tu repositorio en GitHub → **Settings → Pages**.
2. En **Branch**, selecciona `main` y carpeta `/docs`, luego haz clic en **Save**.
3. En ~1 minuto tu política estará publicada en:
   `https://alexdotel.github.io/WaterApp/privacy-policy.html`

---

## Paso 4: Subir la primera versión a Google Play Console

1. Crea una nueva app en [Google Play Console](https://play.google.com/console) con el nombre **Hydra: Agua y Recordatorios**.
2. Copia los textos y respuestas de Seguridad de Datos desde `store/play_store_listing.md`.
3. Sube los gráficos ya generados en tu repo:
   - **Ícono de la app (512×512):** `store/play_store_icon_512.png`
   - **Gráfico de funciones (1024×500):** `store/feature_graphic_1024x500.png`
   - **Capturas de teléfono (1080×1920, 6 pantallas):** `store/screenshots/phone/`
   - **Capturas de tablet 7" (1200×1920, 4 pantallas):** `store/screenshots/tablet-7/`
   - **Capturas de tablet 10" (1920×1200, 3 pantallas):** `store/screenshots/tablet-10/`
4. Ve a **Pruebas internas (Internal testing)** o **Pruebas cerradas (Closed testing)** → **Crear nueva versión** → sube `app-release.aab`.
   *(Nota: las cuentas personales nuevas de Google Play requieren 12 testers en pruebas cerradas durante 14 días antes de pasar a Producción.)*

---

## Paso 5: Automatizar futuras actualizaciones con GitHub Actions (Opcional)

El workflow `.github/workflows/play-store-release.yml` ya está listo. Para activarlo, agrega estos Secrets en GitHub (**Settings → Secrets and variables → Actions**):

- `ANDROID_KEYSTORE_BASE64`: resultado de `[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\upload-keystore.jks"))` en PowerShell.
- `ANDROID_KEYSTORE_PASSWORD`: tu `storePassword`.
- `ANDROID_KEY_ALIAS`: `upload`.
- `ANDROID_KEY_PASSWORD`: tu `keyPassword`.
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` *(opcional)*: JSON de tu cuenta de servicio vinculada en Play Console para subir automáticamente.

Cada vez que incrementes `version:` en `pubspec.yaml` (ej. `1.0.1+2`) y hagas `git tag v1.0.1 && git push --tags`, GitHub compilará, probará y generará tu `.aab` automáticamente.
