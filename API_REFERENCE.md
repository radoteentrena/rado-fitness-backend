# Rado Fitness - Guía Práctica de la API para el Cliente React
Todos nuestros endpoints viven bajo la ruta `/api/v1/`.

## URL Base
**Desarrollo local:** `http://localhost:3000/api/v1`
**Producción:** `https://radoteentrena.com/api/v1`
*(Asegurate de cambiar esto según el entorno donde estés probando.)*

## Autenticación
Mira, la API es privada. Así que **en cada petición** tenés que mandar un token. Este token (`auth_token`) te lo da el sistema cuando el usuario se loguea.

**Headers obligatorios (sí o sí):**
```http
Authorization: Token AQUI_VA_EL_TOKEN_DEL_USUARIO
Accept: application/json
Content-Type: application/json
```

### POST /auth/google

**Descripción:** Autentica un usuario móvil mediante token JWT de Google Sign-In. Valida exactamente el email contra la base de datos y devuelve un token de autenticación si el usuario existe y está activo.

**Flujo:**
1. Usuario inicia sesión con Google en app móvil
2. Google devuelve ID token al app
3. App envía POST con `id_token` al endpoint
4. Rails valida token, busca usuario por email exacto
5. Si usuario existe y status = "active", devuelve `auth_token`
6. App almacena token en secure storage y lo incluye en todos los requests

**Requisito:** Usuario debe existir en la base de datos (creado durante registro web) con `status: "active"`.

**Request:**
```http
POST /auth/google
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200 - OK):**
```json
{
  "auth_token": "abc123xyz789def456",
  "user": {
    "id": 1,
    "email": "patriciopherrero@gmail.com",
    "first_name": "Patricio",
    "last_name": "Perez",
    "status": "active",
    "plan_tier": "high_ticket"
  }
}
```

**Response (401 - Unauthorized):**
```json
{
  "error": "Invalid or expired token"
}
```

O si no existe el usuario:
```json
{
  "error": "No active account found with this email"
}
```

O si la cuenta no está activa:
```json
{
  "error": "Account not yet activated or has been deactivated"
}
```

**Notas de Seguridad:**
- Token JWT debe ser válido y sin expirar (Google ID tokens expiran en ~1 hora)
- Email en token se compara exactamente contra el registrado (case-insensitive)
- Solo usuarios con `status: "active"` pueden autenticarse
- Token no se almacena en la BD (single-use)
- Móvil debe guardar el `auth_token` devuelto en secure storage, NO en plain text

---

### POST /auth/email

**Descripción:** Autentica un usuario con email y contraseña. Alternativa al login con Google para casos donde no se usa OAuth.

**Requisito:** Usuario debe existir con `status: "active"`.

**Request:**
```http
POST /auth/email
Content-Type: application/json

{
  "email": "patriciopherrero@gmail.com",
  "password": "tu_contraseña"
}
```

**Response (200 - OK):**
```json
{
  "auth_token": "abc123xyz789def456",
  "user": {
    "id": 1,
    "email": "patriciopherrero@gmail.com",
    "first_name": "Patricio",
    "last_name": "Perez",
    "status": "active",
    "plan_tier": "high_ticket"
  }
}
```

**Response (401 - Unauthorized):**
```json
{
  "error": "Invalid email or password"
}
```

---

## 1. Sincronización Inicial (El Dashboard)

Este es el principal. Lo llamás apenas la app carga o cuando el usuario hace login. Te trae todo el quilombo de "cómo estamos ahora" para armar la pantalla de inicio.

- **Endpoint:** `GET /sync`
- **Qué labura:** Te devuelve el programa del usuario, la rutina activa, los entrenamientos de esta semana divididos por día, y los porcentajes de cumplimiento (eso es lo que te sirve para gamificar y que el boludo no deje de entrenar).
- **Parámetros:** Nada.
- **Qué te devuelve (JSON):**
  ```json
  {
    "user": {
      "id": 1,
      "first_name": "Patricio",
      "last_name": "Perez",
      "email": "patriciopherrero@gmail.com",
      "plan_tier": "high_ticket",
      "category": "performance",
      "full_name": "Patricio Perez"
    },
    "recent_metrics": {
      "workout_compliance": 85,
      "metric_compliance": 90
    },
    "dietary_plan": {
      "id": 3,
      "calories_target": 2800,
      "protein_target": 200,
      "notes": null,
      "start_date": "2026-01-01",
      "end_date": "2026-03-01",
      "active": true
    },
    "active_program": {
      "id": 7,
      "name": "Programa Fuerza Hipertrofia",
      "duration_weeks": 12,
      "current_week": 4
    },
    "active_routine": {
      "id": 2,
      "name": "Bloque A - Volumen",
      "duration_weeks": 6
    },
    "current_week_workouts": [
      {
        "id": 10,
        "name": "Upper Body A",
        "description": null,
        "day_number": 1,
        "order_index": 0,
        "exercises": [
          {
            "id": 45,
            "sets": 4,
            "reps": "6-8",
            "load": "RPE 8",
            "sub_option_one": null,
            "sub_option_two": null,
            "exercise": {
              "id": 12,
              "name": "Press Banca",
              "muscle_group": "Pecho",
              "video_link": "https://youtube.com/...",
              "description": "Instrucciones del ejercicio"
            }
          }
        ]
      }
    ]
  }
  ```

**Notas:**
- `active_routine` refleja la rutina activa según la semana actual del programa (respeta `duration_weeks` de cada bloque).
- `current_week` es la semana actual del programa desde que fue asignado al usuario (empieza en 1). Sirve para mostrar progreso ("Semana 4 de 12").

---

## 2. Biblioteca de Ejercicios

Si querés armar un buscador o un dropdown para seleccionar ejercicios, acá vas.

- **Endpoint:** `GET /exercises`
- **Qué labura:** Te trae todo el catálogo de ejercicios que tenemos, ordenadito alfabéticamente.
- **Parámetros:** Nada.
- **Qué te devuelve:** Un array de ejercicios con nombre, grupo muscular, todo eso.

---

## 3. Mensajes (Chat con Rado AI Coach)

Acá es donde pasa la magia de la IA.

### Descargar la Conversación
- **Endpoint:** `GET /messages`
- **Qué labura:** Carga el historial del chat. Te devuelve los últimos 50 mensajes, del más reciente al más viejo, para no saturar la app.
- **Parámetros:** Nada.

### Enviar un Mensaje
- **Endpoint:** `POST /messages`
- **Qué labura:** El usuario escribe algo (ej. "Hoy comí pollo con arroz y me pesé en 80kg") y lo mandás acá para que la IA lo procese.
- **Body de la petición:**
  ```json
  {
    "message": {
      "content": "Hoy comí arroz con pollo."
    }
  }
  ```
- **Si anda bien (Status 201):** Recibes el mensaje guardado.
- **Si hay error (Status 422):** Viene un JSON con los `"errors"` (ej. mensaje vacío).

---

## 4. Métricas Diarias

Si en vez del chat querés un formulario clásico para que registre peso, pasos, calorías, lo que sea.

- **Endpoint:** `POST /daily_metrics`
- **Qué labura:** Guarda (o actualiza si ya existe uno de ese día) los datos diarios del usuario.
- **Body de la petición:**
  ```json
  {
    "daily_metric": {
      "date_logged": "2026-02-26", // Opcional, si no lo mandas asume hoy
      "weight": 82.5,
      "calories_consumed": 2500,
      "protein_consumed": 180,
      "steps": 10000,
      "workout_completed": true
    }
  }
  ```
- **Si anda bien (Status 200):** Te devuelve el registro.
- **Si hay error (Status 422):** Recibes los `"errors"`.

---

## 5. Fotos de Progreso

Para que los clientes suban sus fotos semanales.

- **Endpoint:** `POST /progress_photos`
- **Atención acá:** Cuando mandás una foto real desde React Native, **no** mandes un JSON de lo común. Tenés que usar `FormData` (`multipart/form-data`).
- **Cómo estructurar el FormData:**
  - `progress_photo[image]`: El archivo de la foto (Blob/File).
  - `progress_photo[date]`: La fecha (ej. "2026-02-26").
  - `progress_photo[note]`: (Opcional) Una notita (ej. "Me veo más grande").
- **Si anda bien (Status 201):**
  ```json
  {
    "id": 1,
    "date": "2026-02-26",
    "note": "Me veo más grande",
    "image_url": "https://www.radoteentrena.com/rails/active_storage/blobs/..." // URL lista para el <img>
  }
  ```

---

## 6. Entrenamientos (Training Sessions)

Los endpoints que manejan todo el ciclo: iniciar la sesión, completarla, saltarla si es necesario, e historial.

### Obtener la Sesión Actual
- **Endpoint:** `GET /training/current`
- **Qué labura:** Te devuelve la sesión activa del usuario (la que puede completar ahora). Incluye los ejercicios prescritos, series, reps, cargas, y el último registro de cada ejercicio.
- **Parámetros:** Nada.
- **Qué te devuelve:**
  ```json
  {
    "session": {
      "id": 1,
      "session_number": 1,
      "status": "pending",
      "phase_name": "Fase A",
      "cycle_number": 1,
      "workout": {
        "id": 10,
        "name": "Upper Body A",
        "day_number": 1,
        "exercises": [
          {
            "workout_exercise_id": 45,
            "exercise_name": "Press Banca",
            "muscle_group": "Pecho",
            "sets": 4,
            "reps": "6-8",
            "load": "RPE 8",
            "early_rpe": "~7",
            "last_rpe": "~8",
            "last_logged": {
              "date": "2026-02-20",
              "actual_sets": [
                { "reps": 6, "weight": 100, "rpe": 8 }
              ]
            }
          }
        ]
      }
    }
  }
  ```
- **Si no hay sesión activa:**
  ```json
  { "session": null, "status": "no_active_program" }
  ```

### Iniciar la Sesión
- **Endpoint:** `POST /training/start`
- **Qué labura:** Marca la sesión como "en progreso" y registra cuándo empezó.
- **Body:** Nada, solo el token.
- **Qué te devuelve:** La sesión con status `"in_progress"` y toda la info de ejercicios igual que arriba.

### Completar la Sesión (Registrar el Entrenamiento)
- **Endpoint:** `POST /training/complete`
- **Qué labura:** Guarda todos los ejercicios que hizo (series, reps, pesos, RPE) y marca la sesión como completada. También te devuelve la siguiente sesión si existe.
- **Body de la petición:**
  ```json
  {
    "exercise_logs": [
      {
        "workout_exercise_id": 45,
        "actual_sets": [
          { "reps": 6, "weight": 100, "rpe": 8 },
          { "reps": 5, "weight": 105, "rpe": 8 }
        ]
      },
      {
        "workout_exercise_id": 46,
        "actual_sets": [
          { "reps": 10, "weight": 50, "rpe": 7 }
        ]
      }
    ],
    "notes": "Me sentí fuerte hoy"
  }
  ```
- **Campos en `actual_sets`:** `reps`, `weight`, `rpe` (RPE = 1-10, qué tan duro estuvo).
- **Qué te devuelve:**
  ```json
  {
    "session": {
      "id": 1,
      "session_number": 1,
      "status": "completed",
      "phase_name": "Fase A",
      "cycle_number": 1,
      "workout_name": "Upper Body A"
    },
    "next_session": {
      "id": 2,
      "session_number": 2,
      "status": "pending",
      "phase_name": "Fase A",
      "cycle_number": 1,
      "workout_name": "Lower Body A"
    }
  }
  ```

### Saltar la Sesión
- **Endpoint:** `POST /training/skip`
- **Qué labura:** Marca la sesión como saltada, sin registrar ejercicios. Útil cuando no puede entrenar ese día.
- **Body de la petición:**
  ```json
  {
    "reason": "Estoy enfermo"
  }
  ```
- **Qué te devuelve:** Igual que complete, pero con status `"skipped"`.

### Historial de Entrenamientos
- **Endpoint:** `GET /training/history?page=1&per_page=20`
- **Qué labura:** Te devuelve el historial de sesiones completadas o saltadas, paginado (las últimas primero).
- **Parámetros opcionales:**
  - `page`: Número de página (default 1).
  - `per_page`: Cuántos entrenamientos por página (default 20, máximo 100).
- **Qué te devuelve:**
  ```json
  {
    "sessions": [
      {
        "id": 1,
        "session_number": 1,
        "status": "completed",
        "phase_name": "Fase A",
        "workout_name": "Upper Body A",
        "started_at": "2026-02-20T10:30:00Z",
        "completed_at": "2026-02-20T11:35:00Z",
        "skipped_at": null,
        "skip_reason": null,
        "notes": "Me sentí fuerte hoy",
        "exercise_logs": [
          {
            "exercise_name": "Press Banca",
            "prescribed": {
              "sets": 4,
              "reps": 6,
              "load": 100
            },
            "actual_sets": [
              { "reps": 6, "weight": 100, "rpe": 8 },
              { "reps": 5, "weight": 105, "rpe": 8 }
            ]
          }
        ]
      }
    ],
    "meta": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 95
    }
  }
  ```

---

## 7. Token de Dispositivo (Push Notifications)

Para recibir notificaciones push, la app tiene que registrar el token FCM del dispositivo después del login.

- **Endpoint:** `PUT /device_token`
- **Qué labura:** Guarda (o actualiza) el token FCM del dispositivo asociado al usuario autenticado.
- **Body de la petición:**
  ```json
  {
    "fcm_token": "dGhpcyBpcyBhIHNhbXBsZSB0b2tlbg..."
  }
  ```
- **Si anda bien (Status 204):** Sin body. Éxito silencioso.
- **Si hay error (Status 422):**
  ```json
  {
    "errors": ["fcm_token can't be blank"]
  }
  ```

**Cuándo llamarlo:** Al hacer login y cada vez que el SDK de Firebase entregue un nuevo token (el token puede rotar).

---

## Manejo de Errores (Importante)

Siempre revisa el código HTTP de la respuesta:

- **200 / 201** — Todo bien, che. Guardamos los datos.
- **401 Unauthorized** — El token falta, caducó o está mal. Mandalo al login de nuevo.
- **403 Forbidden (`access_locked`)** — La suscripción del usuario venció. La respuesta incluye una URL de pago para redirigir:
  ```json
  {
    "error": "access_locked",
    "payment_url": "https://radoteentrena.com/subscriptions/new"
  }
  ```
  Mostrá un paywall o redirigí al usuario a `payment_url`.
- **404 Not Found** — El recurso no existe (ej. no hay sesión activa para `/training/start`).
- **422 Unprocessable Entity** — Falló una validación. Revisa el array `"errors"` de la respuesta y mostráselo al usuario.
- **500 Internal Server Error** — Esto es culpa mía. Avísame y reviso los logs.

---

Cualquier quilombo con los payloads o algo que no ande, me avisas.
