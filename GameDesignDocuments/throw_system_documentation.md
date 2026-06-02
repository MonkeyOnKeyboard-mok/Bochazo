# ThrowSystem - Documentación Técnica Detallada

## Resumen General

El ThrowSystem es el sistema de lanzamiento de bochas en el juego Bochazo. Permite al jugador (o a la IA) lanzar bochas mediante gestos de mouse, con control de potencia, dirección y curva. El sistema está compuesto por múltiples componentes que trabajan en conjunto para simular un lanzamiento realista de bochas/bocce.

---

## Arquitectura del Sistema

El sistema está dividido en dos implementaciones paralelas:

### 1. Sistema Principal (ThrowSystem)
Ubicado en: `scenes/04_game/components/throw_system/`

**Componentes:**
- `throw_system.gd` - Nodo principal que orquesta todo
- `throw_aim.gd` - Sistema de apuntado y conversión de trayectoria
- `throw_flight.gd` - Sistema de vuelo y física de la bocha

### 2. Sistema Legacy (ThrowController)
Ubicado en: `BochaGian/`

**Componentes:**
- `ThrowController.gd` - Controlador de gestos de lanzamiento
- `ThrowingState.gd` - Estado de lanzamiento en la máquina de estados

### 3. Sistema de IA
Ubicado en: `scenes/04_game/ai/`

**Componentes:**
- `ai_throw_brain.gd` - Cerebro de decisión de la IA
- `ai_throw_params.gd` - Parámetros de lanzamiento de la IA

### 4. Configuración
Ubicado en: `resources/game_config/`

**Componentes:**
- `player_throw_stats.gd` - Estadísticas del jugador (potencia, precisión, control, etc.)

---

## Flujo de Lanzamiento del Jugador

### Fase 1: Inicio del Gesto (GestureTracker -> Power)

1. **GestureTracker** detecta cuando el jugador comienza a arrastrar el mouse
2. Se emite la señal `charge_started` que resetea el indicador de potencia
3. Mientras el jugador arrastra, se emite `charge_dragging` continuamente

### Fase 2: Cálculo de Potencia y Dirección Lateral

El sistema calcula dos valores clave:
- **Potencia (`frac`)**: Proporción de la distancia de arrastre respecto al máximo permitido
- **Dirección lateral (`lateral`)**: Desviación horizontal del arrastre

**Rangos configurables en PlayerThrowStats:**
- `min_charge_distance`: 50.0 píxeles (mínimo para considerar lanzamiento)
- `max_charge_distance`: 300.0 píxeles (potencia máxima)

### Fase 3: Dibujo de Trayectoria (Aim)

1. El jugador dibuja puntos en pantalla que representan la trayectoria deseada
2. Se emite `aim_ended` con un array de puntos 2D (`PackedVector2Array`)
3. Si hay menos de 3 puntos, se lanza recto sin curva

### Fase 4: Conversión de Trayectoria (ThrowAim)

El `ThrowAim` procesa los puntos dibujados:

1. **Proyección al suelo (`_screen_to_ground`)**:
   - Convierte cada punto 2D de pantalla a coordenadas 3D del mundo
   - Usa `camera.project_ray_origin()` y `camera.project_ray_normal()`
   - Calcula la intersección del rayo con el plano del suelo (y = ground_y)

2. **Suavizado (`_smooth_3d`)**:
   - Aplica un filtro de suavizado tipo "media ponderada"
   - Fórmula: `p[i] = p[i-1]*0.25 + p[i]*0.5 + p[i+1]*0.25`
   - Se ejecuta 2 pasadas por defecto

3. **Simplificación (`_simplify`)**:
   - Elimina puntos redundantes usando distancia mínima (0.5 unidades)
   - Mantiene el primer y último punto siempre
   - Reduce la cantidad de waypoints para mejor rendimiento

4. **Offset de corrección**:
   - Aplica un offset basado en la diferencia entre la posición de la bola y el primer punto proyectado

### Fase 5: Lanzamiento (ThrowFlight)

El `ThrowFlight` recibe los parámetros y ejecuta el lanzamiento:

**Parámetros configurables:**
- `efecto`: 0.5 (capacidad de curva)
- `precision`: 0.95 (dispersión angular)
- `control`: 0.85 (estabilidad del lanzamiento)
- `max_force`: 35.0 (fuerza máxima del impulso)
- `min_power`: 0.05 (potencia mínima para lanzar)

#### launch_straight() - Lanzamiento Recto
1. Calcula dispersión basada en precisión: `spread = (1.0 - precision) * 0.04`
2. Aplica rotación aleatoria: `randf_range(-spread, spread)`
3. Espera confirmación `GameManager.throw_for_real`
4. Posiciona la bola en `GameManager.global_ball_pos`
5. Aplica impulso central: `dir * power * max_force`
6. Si control < 1.0, agrega wobble aleatorio

#### launch() - Lanzamiento con Curva
1. Similar a launch_straight pero con waypoints
2. Dispersión mayor: `spread = (1.0 - precision) * 0.06`
3. Almacena waypoints para guiado durante el vuelo
4. Activa `_active = true` para el steering

### Fase 6: Guiado Durante el Vuelo (_physics_process)

Mientras `_active` es verdadero:

1. **Verificación de velocidad**: Si `linear_velocity.length() < 0.3`, desactiva
2. **Verificación de waypoints**: Si se alcanzaron todos, desactiva
3. **Steering hacia waypoint**:
   - Calcula vector hacia el waypoint actual (solo X y Z)
   - Si distancia < `_waypoint_reach` (1.2), pasa al siguiente waypoint
   - Calcula fuerza lateral usando producto cruz y producto punto
   - Aplica fuerza: `right * lateral * efecto * _steer_factor`
   - `_steer_factor` = 20.0

4. **Transición de waypoint**:
   - `_current_wp` incrementa cuando se alcanza un waypoint
   - Cuando `_current_wp >= _waypoints.size()`, se desactiva el guiado

### Fase 7: Post-Lanzamiento

1. `animation_fix_and_etc()`:
   - Congela la bola (`freeze = true`)
   - Reposiciona en `GameManager.global_ball_pos`
   - Resetea velocidades a cero
   - Descongela (`freeze = false`)
   - Espera 1.5 segundos
   - Activa cámara de seguimiento

2. `camera_follow()`:
   - `camera_manager.start_follow(ball)` hace que la cámara siga la bola

---

## Sistema de IA (AIThrowBrain)

### Arquitectura Data-Driven

La IA utiliza un sistema basado en datos de simulaciones previas:

**Archivos de datos:**
- `throws_flat.json` - Cancha plana
- `throws_dirty.json` - Cancha sucia
- `throws_grass.json` - Cancha de césped
- `throws_pro.json` - Cancha profesional
- `throws_sand.json` - Cancha de arena

Cada archivo contiene ~5000 tiros simulados con: posición inicial, parámetros, posición final.

### Proceso de Decisión

1. **Carga de datos** (`load_data`):
   - Carga los JSON en `AIInverseModel`
   - Organiza por tipo de cancha

2. **Decisión** (`decide`):
   - Agrega ruido al objetivo: `rng.randf_range(-noise_radius, noise_radius)`
   - Busca los 5 tiros más cercanos al objetivo usando `find_function()`
   - Promedia parámetros con peso inverso a distancia² × curva
   - Prioriza tiros vistosos según `curve_preference`
   - Si no encuentra datos, usa `find_nearest()` o `_fallback_throw()`

3. **Parámetros generados** (AIThrowParams):
   - `power`: [0.4, 1.0] - Potencia del lanzamiento
   - `angle_offset`: [-0.3, 0.3] radianes - Desviación angular
   - `curve_intensity`: [0, 1] - Intensidad de curva
   - `curve_side`: [-1, 1] - Dirección de curva (-1=izq, 1=der)
   - `is_straight`: bool - Si es tiro recto

4. **Cálculo de waypoints**:
   - Si es recto: waypoints vacíos
   - Si tiene curva: genera 4-12 waypoints con forma sinusoidal
   - Fórmula lateral: `sin(t * PI) * curve_intensity * curve_side * dist * 0.3`

5. **Ejecución** (`execute_throw`):
   - Configura flight con stats y fricción de cancha
   - Llama `flight.launch()` o `flight.launch_straight()`
   - Emite señal `throw_ready`

### Dificultad

| Nivel | difficulty_sigma | Descripción |
|-------|------------------|-------------|
| 0 | 0.4 | Muy fácil (mucho error) |
| 1 | 0.25 | Fácil |
| 2 | 0.15 | Normal |
| 3 | 0.08 | Difícil |
| 4 | 0.02 | Muy difícil (casi perfecto) |

El sigma agrega ruido gaussiano a power y angle_offset.

### Fricción por Cancha

| Cancha | Índice | Multiplicador |
|--------|--------|---------------|
| Flat | 0 | 1.0 |
| Dirty | 1 | 0.8 |
| Grass | 2 | 0.9 |
| Pro | 3 | 1.1 |
| Sand | 4 | 0.6 |

---

## Sistema Legacy (ThrowController)

### Fases del Gesto

1. **IDLE**: Esperando click en la bocha
2. **PULL_BACK**: Arrastrando hacia atrás (cargando)
3. **PUSH_FORWARD**: Empujando hacia adelante (lanzando)
4. **RELEASED**: Soltó el mouse

### Detección de Cambio de Dirección

- Registra `max_pull_distance` durante PULL_BACK
- Cuando el jugador vuelve hacia el punto de inicio:
  - `pullback_amount = max_pull_distance - distance_to_start`
  - Si `pullback_amount > direction_change_threshold` (0.15m), cambia a PUSH_FORWARD

### Cálculo de Lanzamiento

- **Potencia**: `lerpf(min_throw_power, max_throw_power, push_distance / max_drag_distance)`
- **Dirección**: `push_offset.normalized()`
- **Curva**: `clamp(push_offset.z / max_drag_distance * sensitivity, -1.0, 1.0)`

### ThrowingState

Máquina de estados que:
1. Entra al estado y reproduce efecto visual
2. En `physics_update`:
   - Descongela el physics body
   - Obtiene datos del ThrowController
   - Aplica impulso central
   - Si hay curva, aplica `angular_velocity.y`
   - Emite señal `bocha_thrown`
   - Transiciona a ROLLING

---

## Configuración del Jugador (PlayerThrowStats)

| Parámetro | Valor Default | Descripción |
|-----------|---------------|-------------|
| potencia | 35.0 | Fuerza máxima del impulso |
| min_power | 0.05 | Potencia mínima para lanzar |
| efecto | 0.5 | Capacidad de curva |
| precision | 0.95 | Dispersión angular (1.0 = perfecta) |
| control | 0.85 | Estabilidad del lanzamiento |
| max_aim_points | 60 | Máximo puntos de trayectoria |
| min_charge_distance | 50.0 | Píxeles mínimos de arrastre |
| max_charge_distance | 300.0 | Píxeles para potencia máxima |

---

## Señales y Comunicación

### GameManager
- `bocha_spawned` - Notifica cuando se crea una nueva bocha
- `brain_connect` - Conecta el cerebro de IA
- `throw` - Se emite al momento del lanzamiento
- `throw_for_real` - Flag de confirmación de lanzamiento
- `permission_to_throw` - Control de permiso para lanzar
- `global_ball_pos` - Posición global de la bola para reposicionamiento

### ThrowSystem
- `charge_started` - Inicio de arrastre
- `charge_dragging` - Durante el arrastre
- `charge_ended` - Fin de carga de potencia
- `aim_ended` - Fin de dibujo de trayectoria

### AIThrowBrain
- `throw_ready(params)` - Emite cuando la IA ejecuta un tiro

---

## Constantes Clave

| Constante | Valor | Ubicación | Descripción |
|-----------|-------|-----------|-------------|
| start_pos | (-27.54, 1.184, 0) | throw_system.gd | Posición inicial de lanzamiento |
| _waypoint_reach | 1.2 | throw_flight.gd | Distancia para considerar waypoint alcanzado |
| _steer_factor | 20.0 | throw_flight.gd | Factor de fuerza de steering |
| _simplify_dist | 0.5 | throw_aim.gd | Distancia mínima entre waypoints |
| MIN_POWER | 0.4 | ai_throw_brain.gd | Potencia mínima de IA |

---

## Diagrama de Flujo Simplificado

```
Jugador hace click -> GestureTracker detecta
       ↓
Arrastra mouse -> Calcula potencia y dirección lateral
       ↓
Dibuja trayectoria -> ThrowAim convierte puntos 2D a 3D
       ↓
Suelta mouse -> ThrowSystem procesa parámetros
       ↓
ThrowFlight.launch() -> Aplica impulso a RigidBody3D
       ↓
_physics_process -> Steering hacia waypoints
       ↓
Bola se detiene -> Transición a estado ROLLING
```

---

## Notas de Implementación

1. **Sistema dual**: Existen dos implementaciones (ThrowSystem y ThrowController). ThrowSystem es el sistema principal actual, ThrowController parece ser legacy.

2. **Sincronización con GameManager**: El sistema depende fuertemente de GameManager para señales, posiciones y permisos.

3. **Física**: Usa `RigidBody3D` con `apply_central_impulse` para el lanzamiento inicial y `apply_central_force` para el steering durante el vuelo.

4. **IA data-driven**: La IA no calcula física, busca en datos de simulaciones previas para decidir parámetros óptimos.

5. **Curva sinusoidal**: Los waypoints de curva siguen una función sinusoidal para simular efecto natural.
