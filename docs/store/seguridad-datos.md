# Google Play: "Seguridad de los datos" y "Diseñado para familias"

Guía para completar los formularios de Play Console con lo que hace el juego hoy (19/10/2026).
Revisar de nuevo si se agregan funciones que usen datos.

## Público objetivo y contenido
- **Público objetivo:** incluir menores de 13 → la app entra en el programa de **Familias**.
- **Pregunta de edad neutral:** sí. Se pregunta antes de usar los amigos; todas las edades se muestran igual
  y ninguna viene marcada. Solo se guarda el grupo (menor de 13 / 13 a 17 / adulto) en el dispositivo.
- **Anuncios:** no. **Compras dentro de la app:** no.
- **Funciones sociales / contenido de usuarios:** sí, limitadas:
  - Amigos solo por código, con solicitud que el otro acepta (máximo 10).
  - No hay chat ni texto libre entre jugadores.
  - Dibujos de pixel art (16 × 16) entre amigos: el que los recibe los ve y elige guardarlos o no.
  - Se puede bloquear y denunciar (las denuncias quedan en la tabla `friend_reports` de Supabase).
  - Menores de 13: su nombre de jugador no se publica y activar amigos requiere el permiso de un adulto.

## Seguridad de los datos (formulario)
- **¿Recopila o comparte datos?** Sí (solo si el jugador usa nube o amigos).
- **¿Se cifran en tránsito?** Sí (HTTPS a Supabase).
- **¿El usuario puede pedir que se borren?** Sí, escribiendo a jrsakugawa@gmail.com con su código.

| Tipo de dato (Play Console) | ¿Se recopila? | Para qué | ¿Opcional? | ¿Se comparte? |
|---|---|---|---|---|
| Información personal → **Nombre** (el nombre de jugador que escribe) | Sí | Funcionalidad de la app (nube; tarjeta de amigos, salvo menores de 13) | Sí | No (lo ven solo sus amigos dentro del juego) |
| Fotos y videos / Otros contenidos de usuario → **dibujos de pixel art** | Sí | Funcionalidad de la app (regalos entre amigos) y seguridad (denuncias) | Sí | No |
| Actividad en la app → **progreso del juego** (partida en la nube) | Sí | Funcionalidad de la app (recuperar la partida) | Sí | No |
| Identificadores → **código de amigo / código de partida** (al azar, no del dispositivo) | Sí | Funcionalidad de la app | Sí | No |
| Ubicación, contactos, email, teléfono, identificadores del dispositivo, datos de uso | No | — | — | — |

Notas:
- "Compartir" en Play significa enviar datos a otra empresa; Supabase es el proveedor del servidor (procesador),
  por eso se marca como **no compartido**.
- Las notificaciones son locales (las programa el celular): no envían datos.

## Antes de publicar
- [ ] Subir la política de privacidad (docs/store/privacy-policy.md) a una página pública y poner el enlace en Play Console.
- [ ] Completar "Seguridad de los datos" con la tabla de arriba.
- [ ] Declarar el público objetivo (incluye menores de 13) y responder el cuestionario de Familias.
- [ ] Revisar de vez en cuando la tabla `friend_reports` en Supabase (marcar `reviewed` y borrar la tarjeta si hace falta).
- [ ] Firmar con un keystore de publicación (ver docs/store/publicar.md).
