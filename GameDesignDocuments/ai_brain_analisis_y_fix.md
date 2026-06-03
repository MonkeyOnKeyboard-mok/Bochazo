# Análisis del Sistema de IA de Tiro — Diagnóstico y Propuestas

## Resumen del Problema

La IA (`ai_throw_brain.gd`) no está tirando correctamente, es decir, no reproduce el "mejor tiro" que fue generado durante la fase de simulación (`ai_simulation_controller.gd`) y almacenado en los JSON. Este documento analiza las causas raíz, los bugs encontrados, y propone soluciones concretas.

---

## Archivos Analizados

| Archivo | Ubicación | Rol |
|---------|-----------|-----|
| `ai_training_controller.gd` | `scenes/04_game/ai/data/` | UI para cargar/guardar datos del modelo |
| `ai_simulation_controller.gd` | `scenes/04_game/ai/data/` | Genera datos de simulación (JSON) |
| `ai_throw_brain.gd` | `scenes/04_game/ai/` | Cerebro de la IA en juego |
| `ai_inverse_model.gd` | `scenes/04_game/ai/data/` | Búsqueda de tiros más cercanos |
| `ai_throw_params.gd` | `scenes/04_game/ai/` | Parámetros del tiro (power, angle, curve, waypoints) |
| `throw_flight.gd` | `scenes/04_game/components/throw_system/` | Ejecución física del tiro |
| `court_setter.gd` | `scenes/04_game/components/GameCourt/` | Instanciación de cancha y cerebro |

---

## 🔴 BUGS CRÍTICOS ENCONTRADOS

### BUG 1: `curve_intensity` está en escala totalmente diferente entre simulación y juego

**Este es el bug más grave y la causa principal de que los tiros no funcionen.**

**En la simulación** (`ai_simulation_controller.gd`, línea 157):
```gdscript
var curve_intensity = _rng.randf_range(10, 100)
```
Los datos generados tienen `ci` (curve_intensity) con valores entre **10 y 100**.

Ejemplo real de los JSON:
```json
{"ci": 63.14, "cs": 0.905, "pw": 0.608, ...}
{"ci": 72.96, "cs": -0.996, "pw": 0.967, ...}
{"ci": 51.62, "cs": 0.794, "pw": 0.691, ...}
```

**En el cerebro** (`ai_throw_brain.gd`, línea 127):
```gdscript
p.curve_intensity = clampf(float(params_dict.get("ci", 0.0)), 0.0, 1.0)
```
El `clampf` **aplasta** cualquier valor >1.0 a 1.0. Los valores originales de 10-100 se convierten TODOS en 1.0.

**En `ai_throw_params.gd`** (`compute_waypoints`, línea 28-29):
```gdscript
var wp_count = int(3 + curve_intensity * 8)
wp_count = clampi(wp_count, 4, 12)
```
Y la fórmula lateral (línea 35):
```gdscript
var lateral = sin(t * PI) * curve_intensity * curve_side * dist * 0.3
```

**Impacto**: Como `curve_intensity` siempre queda en 1.0 después del clamp, TODOS los tiros curvos se ejecutan con curva máxima. La IA nunca puede hacer tiros rectos o con poca curva, porque el dato original (~50-70) se convierte siempre en 1.0.

**Además**, `is_straight` (línea 129) se calcula como:
```gdscript
p.is_straight = p.curve_intensity < 0.05
```
Pero como `ci` en los datos es SIEMPRE ≥ 10 (por el `randf_range(10, 100)`) y luego se clampea a 1.0, **NUNCA** será `< 0.05`, así que `is_straight` **siempre será `false`**. La IA no puede hacer tiros rectos.

#### Solución Propuesta

**Opción A (Recomendada)**: Regenerar los datos de simulación con `curve_intensity` en rango `[0.0, 1.0]`:
```gdscript
# En ai_simulation_controller.gd, línea 157, cambiar:
var curve_intensity = _rng.randf_range(10, 100)
# Por:
var curve_intensity = _rng.randf_range(0.0, 1.0)
```
Y volver a correr la simulación para regenerar los 5 JSON.

**Opción B**: Normalizar en el cerebro al leer:
```gdscript
# En ai_throw_brain.gd, línea 127, cambiar:
p.curve_intensity = clampf(float(params_dict.get("ci", 0.0)), 0.0, 1.0)
# Por:
p.curve_intensity = clampf(float(params_dict.get("ci", 0.0)) / 100.0, 0.0, 1.0)
```
Pero esto es un parche. Si los datos se regeneran, el parche se rompe. Opción A es preferible.

---

### BUG 2: La dirección de steering en `throw_flight.gd` es estática y no se adapta a la dirección del tiro

**En `throw_flight.gd`**, `_physics_process` (líneas 80-84):
```gdscript
var forward = Vector3.RIGHT
var right = Vector3.BACK
var desired = to_target.normalized()
var lateral = desired.dot(right)
ball.apply_central_force(right * lateral * efecto * _steer_factor)
```

`forward` y `right` están **hardcodeados** como `Vector3.RIGHT` y `Vector3.BACK`. Esto significa que el steering **solo funciona correctamente si la bocha se mueve en dirección +X**. Si la bocha se mueve en cualquier otra dirección (diagonal, por ejemplo), el steering está fundamentalmente roto.

En la **simulación** funciona "aceptablemente" porque el spawn siempre está en X=-25 y los targets están en X positivo, así que la dirección dominante es +X. Pero en juego real, dependiendo de la posición del bochin y el ángulo, el steering puede empujar la bocha en direcciones incorrectas.

#### Solución Propuesta

Usar la dirección actual de la velocidad de la bocha como base:
```gdscript
func _physics_process(_delta):
    if not _active or not ball: return
    if ball.linear_velocity.length() < 0.3:
        _active = false
        return
    if _current_wp >= _waypoints.size():
        _active = false
        return

    var target = _waypoints[_current_wp]
    var to_target = Vector3(target.x - ball.global_position.x, 0, target.z - ball.global_position.z)
    var dist = to_target.length()

    if dist < _waypoint_reach:
        _current_wp += 1
        if _current_wp >= _waypoints.size():
            _active = false
        return

    var vel = ball.linear_velocity
    var vel_horiz = Vector3(vel.x, 0, vel.z)
    if vel_horiz.length() < 0.2: return

    # NUEVO: usar la dirección de la velocidad como base
    var forward = vel_horiz.normalized()
    var right = forward.cross(Vector3.UP).normalized()
    var desired = to_target.normalized()
    var lateral = desired.dot(right)
    ball.apply_central_force(right * lateral * efecto * _steer_factor)
```

---

### BUG 3: `bocha_pos` hardcodeada en `ai_throw_brain.gd`

En `ai_throw_brain.gd`, línea 72:
```gdscript
var bocha_pos = Vector3(-28.2, 0.438, -0.06)
```

Y en `execute_throw` (línea 165):
```gdscript
execute_throw(bocha_pos, GameManager.bochin.global_position)
```

El problema es que `bocha_pos` es una **constante hardcodeada**, no la posición real de la bocha que se va a tirar. Cuando se llama `setup_for_throw`, ya se tiene la referencia `ball` (la bocha real), pero se ignora su posición y se usa siempre `(-28.2, 0.438, -0.06)`.

Esto afecta:
- `compute_direction()`: calcula la dirección basándose en la posición equivocada
- `compute_waypoints()`: genera waypoints partiendo de un punto que no es donde está la bocha
- La búsqueda del modelo: busca tiros que empezaron en posiciones que no coinciden con donde la bocha realmente está

#### Solución Propuesta

Usar la posición real de la bocha:
```gdscript
# En setup_for_throw, cambiar línea 165:
execute_throw(bocha_pos, GameManager.bochin.global_position)
# Por:
execute_throw(ball.global_position, GameManager.bochin.global_position)
```

Y eliminar la variable `bocha_pos` hardcodeada (línea 72) o convertirla en fallback.

---

### BUG 4: `flight` puede ser `null` cuando el brain se inicializa

**Flujo de inicialización:**

1. `court_setter.gd` instancia el brain y lo agrega como hijo → emite `brain_connect`
2. `throw_system.gd` escucha `brain_connect` y asigna `flight` al brain
3. **PERO** el brain en su `_ready()` (línea 86) llama `load_data()` y configura todo inmediatamente
4. `update_bocha()` se conecta a `bocha_spawned`

El problema es una **race condition**: el brain se crea y conecta a `bocha_spawned` en su `_ready()`. Cuando llega `bocha_spawned`, el brain intenta `setup_for_throw(stats, ball, flight)`, pero `flight` podría seguir siendo `null` si `brain_connect` aún no fue procesado por `throw_system.gd`.

Específicamente, en `court_setter.gd`:
```gdscript
var brain = scene.instantiate()
get_parent().add_child(brain)  # Esto ejecuta brain._ready()
GameManager.emit_signal("brain_connect")  # Esto está DESPUÉS
```

El `_ready()` del brain se ejecuta en `add_child`, ANTES de que se emita `brain_connect`. Si una bocha ya está en el spawner o se spawna rápido, `flight` será `null`.

En `execute_throw` (línea 145-147) hay un check:
```gdscript
if not flight or not ball:
    print("returned")
    return
```

Pero esto silenciosamente **aborta el tiro sin avisar al usuario/sistema**, lo que hace que la IA simplemente "no tire" sin error visible.

#### Solución Propuesta

Mover la emisión de `brain_connect` **antes** de que se pueda recibir `bocha_spawned`, o esperar en `setup_for_throw` hasta que flight esté disponible:

```gdscript
# Opción: en update_bocha, esperar a que flight esté disponible
func update_bocha(bocha: RigidBody3D) -> void:
    ball = bocha
    if !GameManager.p1_turn and GameManager.vsAI:
        await get_tree().create_timer(3).timeout
        # Esperar a que flight se asigne
        while flight == null:
            await get_tree().create_timer(0.1).timeout
        setup_for_throw(stats, ball, flight)
        print("playing vs ai ... computer throwing")
    else:
        print("not playing against ai")
```

---

## 🟡 PROBLEMAS SECUNDARIOS

### PROBLEMA 5: El modelo de búsqueda (`_score`) puede priorizar curvas sobre precisión

En `ai_inverse_model.gd`, la función `_score` (líneas 109-112):
```gdscript
func _score(target_x: float, target_z: float, t: Dictionary) -> float:
    var d2 = _dist2(target_x, target_z, t)
    var curve_bonus = t["ci"] * curve_preference
    return d2 - curve_bonus
```

Como `ci` en los datos está en rango [10, 100], el `curve_bonus` puede ser enorme (hasta 100 × 1.0 = 100). Esto hace que un tiro que cayó a **10 metros del objetivo** pero con curva alta tenga mejor score que un tiro que cayó **exacto** en el objetivo pero sin curva.

`d2` es la distancia al cuadrado. Un tiro a 3 metros del target tiene `d2 = 9`. Pero un tiro con `ci = 50` y `curve_preference = 1.0` tiene bonus de 50. El score sería `9 - 50 = -41`, increíblemente bueno, aunque cayó lejos.

#### Solución Propuesta (depende de si se arregla el BUG 1)

Si se corrige el rango de `ci` a [0, 1]:
- El bonus máximo sería 1.0, que es razonable contra `d2` que es distancia²
- Esto ya funcionaría bien sin cambios adicionales

Si NO se corrige el rango:
```gdscript
func _score(target_x: float, target_z: float, t: Dictionary) -> float:
    var d2 = _dist2(target_x, target_z, t)
    var ci_normalized = clampf(t["ci"] / 100.0, 0.0, 1.0)
    var curve_bonus = ci_normalized * curve_preference
    return d2 - curve_bonus
```

---

### PROBLEMA 6: `find_function` promedia parámetros que pueden ser contradictorioss

En `ai_inverse_model.gd`, `find_function` (línea 68-97) promedia los 5 tiros más cercanos. Pero si los 5 tiros cercanos tienen:
- 3 tiros con `cs = 1.0` (curva a la derecha)
- 2 tiros con `cs = -1.0` (curva a la izquierda)

El promedio de `cs` sería ~0.2, produciendo un tiro con curva "ligeramente a la derecha" que **ninguno** de los 5 tiros originales representaba. La bocha va a un lugar que no coincide con ningún dato.

#### Solución Propuesta

En lugar de promediar, elegir el mejor tiro individual de los 5 más cercanos, usando el promedio solo para `power` y `angle_offset`:

```gdscript
# O más simple: usar find_nearest (el más cercano) directamente
# En lugar de find_function cuando curve_preference > 0
```

---

## 🟢 PROPUESTA: Variedad en los Tiros de la IA

Actualmente, para una misma posición de bochin, la IA siempre encuentra los mismos 5 tiros y genera el mismo promedio, resultando en un tiro **determinístico e idéntico** cada vez.

### Estrategia 1: Selección Aleatoria Ponderada (Recomendada)

En lugar de promediar los K vecinos, **elegir uno** aleatoriamente con peso inversamente proporcional a la distancia:

```gdscript
# En ai_throw_brain.gd, modificar decide():
func decide(ball_pos: Vector3, bochin_pos: Vector3) -> AIThrowParams:
    if not _loaded:
        return _fallback_throw(ball_pos, bochin_pos)

    var target_x = bochin_pos.x + rng.randf_range(-noise_radius, noise_radius)
    var target_z = bochin_pos.z + rng.randf_range(-noise_radius, noise_radius)

    # Buscar los K=10 más cercanos (más candidatos = más variedad)
    var candidates = model.find_nearest_k(target_x, target_z, court_type, 10)
    if candidates.is_empty():
        return _fallback_throw(ball_pos, bochin_pos)

    # Selección aleatoria ponderada
    var params_dict = _weighted_random_pick(candidates, target_x, target_z)

    # ... resto igual
```

```gdscript
func _weighted_random_pick(candidates: Array, tx: float, tz: float) -> Dictionary:
    var weights: Array[float] = []
    var total: float = 0.0
    for t in candidates:
        var dx = t["fx"] - tx
        var dz = t["fz"] - tz
        var d2 = dx * dx + dz * dz
        var w = 1.0 / maxf(sqrt(d2), 0.01)
        weights.append(w)
        total += w

    var roll = rng.randf() * total
    var acc = 0.0
    for i in range(candidates.size()):
        acc += weights[i]
        if roll <= acc:
            return candidates[i]
    return candidates[candidates.size() - 1]
```

**Ventajas:**
- Tiros más cercanos al objetivo tienen más probabilidad de ser elegidos
- Pero no siempre se elige el mismo → variedad natural
- El parámetro `K` controla cuánta variedad (K=5 poco, K=20 mucho)

### Estrategia 2: Perturbación del Target

Ya existe el mecanismo de `noise_radius`, que agrega ruido a la posición objetivo. Actualmente está en `0.0`:

```gdscript
# Subir noise_radius según dificultad:
func set_difficulty(level: int):
    match level:
        0: 
            difficulty_sigma = 0.4
            noise_radius = 2.0  # MUY impreciso
        1: 
            difficulty_sigma = 0.25
            noise_radius = 1.0
        2: 
            difficulty_sigma = 0.15
            noise_radius = 0.5
        3: 
            difficulty_sigma = 0.08
            noise_radius = 0.2
        4: 
            difficulty_sigma = 0.02
            noise_radius = 0.05  # Casi exacto pero con mínima variación
```

### Estrategia 3: Pool de Estilos de Tiro

Crear "personalidades" de tiro que se seleccionen aleatoriamente por ronda:

```gdscript
enum ThrowStyle { SAFE, AGGRESSIVE, CURVE_LOVER, PRECISION }

var throw_style: ThrowStyle = ThrowStyle.SAFE

func randomize_style():
    var roll = rng.randf()
    if roll < 0.4:
        throw_style = ThrowStyle.SAFE  # 40% - tiro seguro, recto
        curve_preference = 0.0
    elif roll < 0.65:
        throw_style = ThrowStyle.AGGRESSIVE  # 25% - mucha potencia
        curve_preference = 0.3
    elif roll < 0.85:
        throw_style = ThrowStyle.CURVE_LOVER  # 20% - curvas vistosas
        curve_preference = 1.5
    else:
        throw_style = ThrowStyle.PRECISION  # 15% - mínimo error
        curve_preference = 0.2
        difficulty_sigma *= 0.5  # Reduce error a la mitad
```

### Recomendación

Combinar las 3 estrategias:
1. **Selección aleatoria ponderada** como método base (reemplazar `find_function`)
2. **`noise_radius` ligado a dificultad** para variabilidad natural
3. **Estilos de tiro** para dar "personalidad" a la IA entre rondas

---

## 📋 RESUMEN DE CAMBIOS NECESARIOS

### Prioridad ALTA (Bugs que causan tiros incorrectos)

| # | Archivo | Cambio | Impacto |
|---|---------|--------|---------|
| 1 | `ai_simulation_controller.gd` | Cambiar `randf_range(10, 100)` → `randf_range(0.0, 1.0)` para `ci` + regenerar datos | **CRÍTICO** - Sin esto, todos los tiros curvos están rotos |
| 2 | `throw_flight.gd` | Cambiar `forward`/`right` hardcodeados → usar dirección de velocidad | **ALTO** - Steering no funciona correctamente |
| 3 | `ai_throw_brain.gd` | Usar `ball.global_position` en vez de `bocha_pos` hardcodeada | **ALTO** - Posición incorrecta para cálculos |
| 4 | `court_setter.gd` / `ai_throw_brain.gd` | Manejar race condition de `flight == null` | **ALTO** - La IA puede no tirar |

### Prioridad MEDIA (Mejoras de calidad)

| # | Archivo | Cambio | Impacto |
|---|---------|--------|---------|
| 5 | `ai_inverse_model.gd` | Normalizar `ci` en `_score` si no se regeneran datos | Mejora precisión de búsqueda |
| 6 | `ai_inverse_model.gd` | No promediar `cs` de tiros contradictorios | Evita tiros "promedio" inválidos |

### Prioridad BAJA (Variedad y personalidad)

| # | Archivo | Cambio | Impacto |
|---|---------|--------|---------|
| 7 | `ai_throw_brain.gd` | Selección aleatoria ponderada | Variedad natural en tiros |
| 8 | `ai_throw_brain.gd` | `noise_radius` ligado a dificultad | Variabilidad adaptativa |
| 9 | `ai_throw_brain.gd` | Estilos de tiro | Personalidad de la IA |

---

## 🔄 ORDEN DE EJECUCIÓN SUGERIDO

1. **Primero**: Arreglar BUG 1 (regenerar datos con `ci` en [0, 1]) — esto es lo que más impacto tiene
2. **Segundo**: Arreglar BUG 3 (usar posición real de la bocha)
3. **Tercero**: Arreglar BUG 4 (race condition de flight)
4. **Cuarto**: Arreglar BUG 2 (steering dinámico en throw_flight)
5. **Quinto**: Implementar variedad (Estrategia 1 + 2)
6. **Sexto**: Agregar estilos de tiro (Estrategia 3)

Después de cada fix, testear en la escena de juego para validar que los tiros mejoran progresivamente.

---

## ⚠️ NOTA SOBRE `ai_training_controller.gd`

Este archivo es simplemente una UI con dos botones (Load/Save) que carga los JSON en el `AIInverseModel` y los guarda como recurso `.tres`. **No tiene bugs propios**, pero depende de que los datos en los JSON sean correctos (que actualmente no lo son, por el BUG 1).

Si se regeneran los datos (BUG 1), este archivo no necesita cambios.
