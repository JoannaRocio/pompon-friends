# Cómo aprende el jugador: diseño del sistema de matemáticas

Todo el sistema vive en `scripts/math_problems.gd` (reglas y generación de cuentas) y `scripts/game_state.gd`
(progreso guardado). Las constantes se pueden ajustar sin tocar el resto del juego.

## El trabajo

El botón **Trabajo** abre las *ofertas de empleo del periódico* (`scripts/jobs.gd`, `scripts/job_board.gd`). Hoy hay un puesto disponible, **profesor/a de Matemáticas**, y dos bloqueados con el cartel "Próximamente": **profesor/a de Inglés** y **profesor/a de Geografía**. La primera vez que se toca **Jugar** el juego pregunta el **nombre** y los **pronombres** ("Soy ella" / "Soy él") del jugador, con un botón para inventar nombres tiernos (`scripts/profile_dialog.gd`); con eso el puesto dice *Profesora Ana*, *Profesor Leo* o *Profesor/a* (si prefiere no decirlo), y el saludo de la clase usa el nombre. Se puede cambiar con el botón *Cambiar* de las ofertas. Para agregar un trabajo nuevo basta con sumar una entrada en `Jobs.JOBS` con `available: true` y la escena que lo juega.

## El turno de trabajo

Hay un reloj de **75 segundos** (se frena mientras se resuelve un examen). Al corregir el **primer examen** aparece "Terminar y cobrar": se puede cobrar la paga de siempre (40 monedas, alcanza para la cuna junto al regalo del día) y salir. Quien juega hasta el final (los 5 exámenes o se acaba el tiempo) se lleva **+20 monedas extra** y más experiencia: más cuentas respondidas para dominar el nivel y más inteligencia para su Pompon.

## Principios

1. **El jugador elige qué mejorar:** tres caminos independientes — *Sumas y restas*, *Multiplicaciones* y *Divisiones*.
2. **Empezar muy fácil y avanzar de a poco:** cada camino tiene **10 niveles** y cada nivel agrega una sola idea nueva.
3. **El juego decide cuándo se aprendió:** no basta una respuesta ni un turno bueno; se mira el desempeño en varios turnos (acierto **y** rapidez).
4. **Se premia intentar, no saber:** la paga del turno es siempre la misma (**40 monedas**) y el premio por subir de nivel también (**30 monedas**). Nadie gana más por acertar más, así no hay presión ni trampa.
5. **Equivocarse enseña:** al fallar se muestra la respuesta correcta, una explicación por partes y un dibujo con puntitos; la cuenta vuelve a salir más adelante hasta acertarla dos veces seguidas.
6. **Pensado para todas las edades:** el nivel 1 es apto para quien recién empieza (niños o adultos que sienten que les cuestan las cuentas), y quien ya sabe puede saltar niveles.

## Los niveles

### Sumas y restas
| Nivel | Qué se practica | Tiempo "rápido" |
|---|---|---|
| 1 | Sumas muy fáciles (números del 1 al 5) | 4 s |
| 2 | Sumas hasta 10 | 5 s |
| 3 | Restas hasta 10 (mezcladas con sumas) | 6 s |
| 4 | Sumas hasta 20 (completar la decena) | 7 s |
| 5 | Restas hasta 20 (bajar hasta la decena) | 8 s |
| 6 | Decenas y unidades, sin pasar de decena | 9 s |
| 7 | Cruzar la decena (38 + 7, 52 − 6) | 11 s |
| 8 | Dos cifras con dos cifras, sin llevar | 12 s |
| 9 | Dos cifras con dos cifras, llevando | 14 s |
| 10 | Tres cifras | 18 s |

### Multiplicaciones
| Nivel | Qué se practica | Tiempo "rápido" |
|---|---|---|
| 1 | Tabla del 2 | 4 s |
| 2 | Tablas del 5 y del 10 | 4 s |
| 3 | Tabla del 3 | 4 s |
| 4 | Tabla del 4 | 4 s |
| 5 | Tablas 2, 3, 4, 5 y 10 mezcladas | 5 s |
| 6 | Tablas del 6 y del 9 | 5 s |
| 7 | Tablas del 7 y del 8 | 6 s |
| 8 | Todas las tablas mezcladas | 6 s |
| 9 | Dos cifras × una cifra (fácil) | 10 s |
| 10 | Dos cifras × una cifra | 14 s |

### Divisiones
Mismos pasos que las multiplicaciones (dividir es "multiplicar al revés"), siempre con resultado exacto:
tiempos "rápidos" de 5 s a 16 s (ver `FAST_SECONDS` en el código).

Antes de practicar un nivel por primera vez se muestra una **lección** (truco y ejemplos; en las tablas, la tabla completa).
Se puede volver a ver con **Ver lección** en la oficina del periódico.

## Cómo decide el juego si se domina un nivel

Se guarda el **historial de las últimas respuestas del nivel actual** (acierto y segundos). Al terminar cada turno de
trabajo (5 cuentas) se evalúa:

| Situación (últimas respuestas) | Qué pasa |
|---|---|
| Las **últimas 8** bien y con mediana ≤ tiempo "rápido" del nivel | **Sube 1 nivel** |
| Las últimas 8 bien y con mediana ≤ la **mitad** del tiempo "rápido" | **Salta 2 niveles** (para quien ya sabe mucho) |
| Las **últimas 15** bien, aunque despacio | **Sube 1 nivel** por constancia (para quien necesita más tiempo) |
| Una sola respuesta mala entre las últimas 8 | No sube todavía; el error sale de la ventana al avanzar |
| **4 o menos aciertos de las últimas 8** (y nivel > 1) | **Baja 1 nivel** con calma, para afirmar |
| En el nivel 10 con las condiciones de subir | "Camino completado" (premio una sola vez) |

Notas:
- 8 respuestas son **al menos dos turnos**: un turno perfecto nunca alcanza solo ("no solo una vez sino varias veces").
- Al cambiar de nivel el historial empieza de cero (se junta evidencia nueva).
- Los tiempos incluyen leer la cuenta, por eso son generosos; el nivel 1 acepta 4 segundos.
- En la oficina y en el cartel final se ven las últimas 8 respuestas como puntitos: **verde** (bien y rápido),
  **amarillo** (bien pero despacio), **rojo** (error), vacío (falta). Con 8 verdes seguidos se sube.

### Simulaciones (de `tests/test_math_problems.gd`)
| Jugador simulado | Resultado en 8 turnos |
|---|---|
| Experto (perfecto y rapidísimo) | niveles 1 → 3 → 5 → 7 → 9 (salta de a dos cada 2 turnos) |
| Fluido (97% y rápido) | 1 → 2 → 3 → 4 → 5 (sube uno cada 2 turnos) |
| Adulto preciso pero lento | 1 → 2 → 3 (sube con constancia cada 3 turnos) |
| Con dificultades (30% de aciertos) | baja de a poco hasta el nivel 1 y se queda ahí practicando |
| Irregular (75%) | se queda en el nivel hasta afirmarlo (nunca sube de más) |

## Repaso inteligente
- Cada cuenta fallada se anota (hasta 12 por camino) y en los turnos siguientes **~30% de las preguntas son repasos** de esas cuentas.
- Una cuenta repasada sale de la lista cuando se acierta **dos veces seguidas**.
- No se repite la misma cuenta si apareció en las últimas 4 preguntas. `7 × 8` y `8 × 7` cuentan como la misma.
- Las opciones incorrectas se parecen a la correcta (±1, ±2, ±10, errores típicos de tablas) para que acertar exija saber.

## La paga y los premios
| Concepto | Valor | Dónde se cambia |
|---|---|---|
| Paga por turno de trabajo | 40 monedas, siempre | `JOB_PAY` |
| Premio por subir de nivel | 30 monedas, siempre | `LEVEL_UP_BONUS` |
| Extra por terminar el turno completo | 20 monedas (opcional) | `FULL_SHIFT_BONUS` |
| Duración del turno | 75 s (el reloj se frena al resolver un examen) | `SHIFT_SECONDS` |
| Cuna del huevo | 50 monedas (un turno + el regalo del día alcanzan) | `Catalog` |

Ordenar objetos en el salón es solo diversión (relajante, sin tiempo ni castigos): **no da monedas** ni cambia el nivel.

## Ajustes y mejoras posibles
- Si el nivel 1 resulta muy fácil o difícil, ajustar los tiempos en `FAST_SECONDS` o los rangos en `_addsub()` / `_tables()`.
- Una **prueba de nivel inicial** opcional para adultos que ya saben bastante (hoy lo resuelve el salto de 2 niveles).
- Más opciones de respuesta (4) en niveles altos para reducir los aciertos por suerte.
- Cuentas con resto en divisiones y problemas con palabras para niveles avanzados.
