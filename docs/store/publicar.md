# Cómo publicar Pompon Friends en Google Play

Estado técnico: el proyecto ya apunta a **Android 16 (API 36)**, requisito de Google para apps nuevas desde el 31 de agosto de 2026, y se exporta como **AAB** con Gradle.

## 1. Lo que tienes que hacer tú (cuentas e identidad)

1. **Cuenta de desarrollador de Google Play** (pago único de unos 25 USD) en <https://play.google.com/console>. Google verifica tu identidad (documento y a veces dirección).
2. **Política de privacidad en una URL pública.** Publica el contenido de `privacy-policy.md` (por ejemplo en GitHub Pages o Google Sites) y reemplaza el correo de contacto.
3. **Pruebas cerradas:** las cuentas personales nuevas suelen necesitar un período de prueba cerrada con un mínimo de testers antes de poder publicar en producción. Revisa en tu Play Console el requisito vigente (hoy: unos 12 testers durante 14 días).

## 2. Clave de firma de lanzamiento (importante)

El AAB de producción debe firmarse con una clave propia. **Si la pierdes, no podrás actualizar la app nunca más.**

```
keytool -genkey -v -keystore pompon-release.keystore -alias pompon -keyalg RSA -keysize 2048 -validity 10000
```

- Usa solo letras y números en la contraseña y el alias.
- Guarda el archivo `.keystore` y las contraseñas en **al menos dos lugares** (por ejemplo, un gestor de contraseñas y un disco externo). Nunca la subas a un repositorio público.
- Además, activa **Play App Signing** al subir la app: Google guarda la clave final y la tuya queda como clave de subida (se puede restablecer si la pierdes).

## 3. Exportar el AAB de producción

En Godot: **Proyecto → Exportar → Android**: desactiva "Export With Debug", en *Keystore* elige tu `pompon-release.keystore` (usuario = alias, y la contraseña) y exporta a `build/PomponFriends.aab`. Antes de cada nueva subida, aumenta **Version Code** (entero) en el preset.

Por línea de comandos (con la misma configuración en el preset):

```
godot --headless --path . --export-release "Android" build/PomponFriends.aab
```

## 4. Subir y configurar en Play Console

1. Crear app → idioma predeterminado español (Latinoamérica), "Juego", "Gratis". Después, en la ficha, agregar la traducción al inglés (`en-US`) con los textos y capturas en inglés.
2. **Panel → Configurar la app:** política de privacidad, acceso a la app (todo disponible), anuncios (**no**), clasificación de contenido (hay interacción limitada entre usuarios: amigos por código y dibujos, sin chat), público objetivo (incluye menores de 13: programa Familias) y **seguridad de los datos: sí se recopilan datos, solo si el jugador usa la nube o los amigos** (nombre de jugador, progreso, dibujos y códigos al azar; cifrados en tránsito, no se comparten). La tabla para completar el formulario está en `seguridad-datos.md`; los textos de la ficha, en `store-listing.md`.
3. **Ficha de la tienda:** textos, ícono 512 × 512, gráfico de funciones 1024 × 500 y capturas (`docs/store/images/es/` para español y `docs/store/images/en/` para inglés).
4. **Pruebas → Pruebas internas / cerradas:** sube `PomponFriends.aab`, agrega testers y compártelo.
5. Cuando cumplas los requisitos, **Producción → Crear versión** y envía a revisión (suele tardar de horas a unos días).

## 5. Pendientes del juego antes de lanzar

- **Probar en un Android real:** instala `build/PomponFriends.apk` (APK de prueba) y revisa tamaños, sonido y fluidez.
- **Compras dentro de la app:** el GDD las menciona, pero **no están implementadas**. Requieren el plugin de Google Play Billing y productos creados en Play Console. La versión 1.0 puede salir sin ellas.
- **Nube y amigos de verdad:** ya funcionan con Supabase. Antes de publicar, correr en Supabase el bloque "LIMITES EN EL SERVIDOR" del final de `server/supabase.sql` (paso a paso en `HANDOFF.md`) y probarlo en dos celulares.
- Tablets y pantallas grandes: con API 36, en pantallas de 600 dp o más Android no respeta el bloqueo de orientación. El juego usa escalado "expand", así que se verá bien, pero conviene probarlo en una tablet.
