# Probar Pompon Friends en un celular Android

APK de prueba: `build/PomponFriends.apk` (preset "Android APK (prueba)", firmado con la clave de debug,
~84 MB, Android 10 o más nuevo, celulares de 64 bits). No pasa por la Play Store: se instala a mano.

Para regenerarlo con lo último de `main` (Godot cerrado o en otra carpeta, la plantilla `android/` instalada):

```
Godot_v4.7.2-stable_win64_console.exe --headless --path . --export-debug "Android APK (prueba)" build/PomponFriends.apk
```

## Instalarlo

1. **Pasar el APK al celular** (elegí una):
   - **Por USB**: conectá el celular a la PC, en el celular elegí "Transferencia de archivos" en el aviso de USB,
     y copiá `PomponFriends.apk` a la carpeta `Download` del celular.
   - **Por Google Drive**: subí `PomponFriends.apk` a tu Drive desde la PC. En el celular abrí la app Drive,
     tocá el archivo y "Descargar" (si Drive lo abre directo con "Instalar", mejor).
2. **Abrirlo**: en el celular abrí la app **Archivos** (o "Mis archivos"), entrá a **Descargas** y tocá
   `PomponFriends.apk`.
3. **Permitir instalar apps desconocidas**: la primera vez Android avisa que esa app (Archivos, Drive o el
   navegador) no tiene permiso. Tocá **Configuración** → activá **Permitir de esta fuente** → volvé atrás.
   (También está en Ajustes → Apps → Acceso especial → Instalar apps desconocidas.)
4. Tocá **Instalar**. Si aparece **Play Protect** ("app no reconocida"), tocá **Más detalles → Instalar de
   todas formas**: pasa porque está firmada con la clave de prueba, no es un problema.
5. Abrí **Pompon Friends** desde el ícono.

**Actualizar a un APK nuevo**: instalarlo encima conserva la partida. Si Android dice "conflicto con un paquete
existente", hay que desinstalar la versión anterior (eso **borra la partida**: antes, "Guardar en la nube" y
anotar el código).

Después de probar se puede volver a apagar "Permitir de esta fuente".

## Qué mirar en la primera prueba

- [ ] **Pantalla de carga**: rosa con el Pompon (no negra con el logo de Godot).
- [ ] **Idioma**: la primera vez pregunta el idioma con el del celular ya marcado. Cambiar a EN con el botón
      "ES/EN" del menú y volver: los textos cambian y no quedan cosas mezcladas.
- [ ] **Sonido**: hay música y efectos al tocar botones; bajan/suben con el volumen del celular; se callan
      al salir de la app y vuelven al entrar.
- [ ] **Tamaño de textos**: se leen bien sin acercar el celular; nada cortado ni tapado por la cámara o la
      barra de abajo (probar en vertical).
- [ ] **Deslizar listas**: la tienda, misiones, vecinos y el vestidor se deslizan con el dedo **también
      empezando sobre un botón**, sin comprar nada sin querer. La casa se desliza suave.
- [ ] **Guardado al cerrar**: comprar algo o darle de comer, cerrar la app desde "recientes" (deslizarla
      afuera), volver a abrir: está todo como lo dejaste. Lo mismo con el botón "atrás" desde el menú.
- [ ] **Botón atrás de Android**: en cada pantalla vuelve un paso (no cierra el juego de golpe).
- [ ] **Avisos**: desde el segundo día pregunta "¿Te avisamos?"; con "Sí" Android pide permiso de
      notificaciones. (El aviso llega recién a los 7 días sin entrar, así que en la primera prueba solo se
      mira que la pregunta y el permiso aparezcan.)
- [ ] **Internet**: "Guardar en la nube" da un código; con amigos activados se ve la tarjeta y los vecinos.
- [ ] **Rendimiento y batería**: que no se trabe ni se caliente mucho en 10–15 minutos de juego.

Anotá el modelo del celular y la versión de Android, y sacá captura (encendido + bajar volumen) de lo que
se vea raro.
