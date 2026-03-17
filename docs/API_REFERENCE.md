# Rado Fitness - Guía Práctica de la API para el Cliente React

Todos nuestros endpoints viven bajo la ruta `/api/v1/`.

## URL Base
**Desarrollo local:** `http://localhost:3000/api/v1`
**Producción:** `https://www.radoteentrena.com/api/v1`
*(Asegúrate de cambiar esto según el entorno donde estés probando la app).*

## Autenticación
Nuestra API es privada, por lo que **cada petición** que hagas debe incluir un token de autenticación. Este token (`auth_token`) se genera cuando el usuario inicia sesión.

**Headers obligatorios en tus peticiones:**
```http
Authorization: Token AQUI_VA_EL_TOKEN_DEL_USUARIO
Accept: application/json
Content-Type: application/json
```

---

## 1. Sincronización Inicial (Datos del Dashboard)

Este es el endpoint principal que debes llamar apenas la app termina de cargar o el usuario hace login. Te trae toda la información de "estado actual" para armar la pantalla de inicio.

- **Endpoint:** `GET /sync`
- **¿Qué hace?:** Te devuelve el plan a largo plazo (programa) del usuario, su bloque de entrenamiento actual (rutina), los entrenamientos específicos para esta semana organizados por día, y sus porcentajes de cumplimiento (importantes para gamificar la app!).
- **Parámetros:** Ninguno.
- **¿Qué recibes? (Ejemplo de respuesta JSON):**
  ```json
  {
    "user": { ... },
    "active_program": { ... },
    "active_routine": { ... },
    "current_week_workouts": {
      "1": [ { "routine_exercise": ... } ], // Ejercicios del Día 1
      "2": [ ... ]                          // Ejercicios del Día 2
    },
    "metrics": {
      "workout_compliance": 85, // % de entrenamientos completados
      "metric_compliance": 90   // % de constancia con la dieta/hábitos
    }
  }
  ```

---

## 2. Biblioteca de Ejercicios

Útil por si necesitas armar un buscador, filtros o un dropdown en la app para seleccionar ejercicios.

- **Endpoint:** `GET /exercises`
- **¿Qué hace?:** Devuelve el catálogo completo de ejercicios que tenemos en la base de datos, ordenaditos alfabéticamente.
- **Parámetros:** Ninguno.
- **¿Qué recibes?:** Un array o lista de objetos con la info de cada ejercicio (nombre, grupo muscular, etc).

---

## 3. Mensajes (Chat con Rado AI Coach)

Aquí es donde pasa la magia de la IA integrada en la app.

### Descargar Conversación
- **Endpoint:** `GET /messages`
- **¿Qué hace?:** Carga el historial del chat. Para no saturar la app, te devuelve los últimos 50 mensajes del usuario, ordenados del más reciente al más antiguo.
- **Parámetros:** Ninguno.

### Enviar un Mensaje
- **Endpoint:** `POST /messages`
- **¿Qué hace?:** Envía lo que el usuario escribió (por ejemplo, "Hoy comí pollo con arroz y me pesé en 80kg") para que la IA lo procese.
- **Body de la petición:**
  ```json
  {
    "message": {
      "content": "Hoy comí arroz con pollo."
    }
  }
  ```
- **Si todo sale bien (Status 201):** Recibes de vuelta el objeto del mensaje guardado.
- **Si hay un error (Status 422):** Recibes un JSON con un array `"errors"` explicando qué falló (ej. el mensaje estaba vacío).

---

## 4. Métricas Diarias

Si en vez del chat quieres ofrecer un formulario clásico para que el usuario registre su pedo, pasos, o calorías.

- **Endpoint:** `POST /daily_metrics`
- **¿Qué hace?:** Crea (o actualiza si ya existía uno ese mismo día) el registro de variables diarias del usuario.
- **Body de la petición:**
  ```json
  {
    "daily_metric": {
      "date_logged": "2026-02-26", // Opcional, si no lo mandas asume que es hoy
      "weight": 82.5,
      "calories_consumed": 2500,
      "protein_consumed": 180,
      "steps": 10000,
      "workout_completed": true
    }
  }
  ```
- **Si todo sale bien (Status 200):** Recibes el registro guardado.
- **Si hay un error (Status 422):** Recibes `{ "errors": [...] }`.

---

## 5. Fotos de Progreso

Para que los clientes suban sus fotos semanales al sistema.

- **Endpoint:** `POST /progress_photos`
- **OJO con esto:** Al enviar una imagen real desde React Native, **NO** mandes un JSON común y corriente. Debes armar la petición usando `FormData` (`multipart/form-data`).
- **Cómo estructurar el FormData:**
  - `progress_photo[image]`: El archivo de la foto (Blob/File).
  - `progress_photo[date]`: La fecha (ej. "2026-02-26").
  - `progress_photo[note]`: (Opcional) Una notita como "Me veo más grande".
- **Si todo sale bien (Status 201):**
  ```json
  {
    "id": 1,
    "date": "2026-02-26",
    "note": "Me veo más grande",
    "image_url": "https://www.radoteentrena.com/rails/active_storage/blobs/..." // URL lista para mostrar en un tag <img>
  }
  ```

---

## 6. Ejecución de Entrenamientos (Loggear Workout)

El endpoint más denso de la API. Se usa cuando el usuario termina su rutina en el gimnasio y le da a "Guardar entrenamiento".

- **Endpoint:** `POST /program_executions`
- **¿Qué hace?:** Guarda los resultados exactos que el usuario hizo en el gimnasio: peso usado, repeticiones sacadas y el RIR (Repeticiones en Reserva) de cada serie individual.
- **Body de la petición (Fíjate bien en la estructura anidada):**
  ```json
  {
    "program_execution": {
      "routine_id": 12, // El ID de la rutina que acaba de hacer
      "completed_at": "2026-02-26T14:30:00Z",
      "duration_minutes": 65, // Cuánto tardó en minutos
      "exercise_logs_attributes": [
        {
          "routine_exercise_id": 45, // ID del primer ejercicio (ej. Press Banca)
          "actual_sets": [
            { "reps": 10, "load": 100, "rir": 2 }, // Primera serie
            { "reps": 8, "load": 105, "rir": 1 }   // Segunda serie
          ]
        },
        {
          "routine_exercise_id": 46, // Segundo ejercicio
          "actual_sets": [
             { "reps": 12, "load": 50, "rir": 2 }
          ]
        }
      ]
    }
  }
  ```
- **Si todo sale bien (Status 201):**
  `{ "id": 5, "message": "Workout successfully logged" }`
- **Si hay un error (Status 422):** `{ "errors": [...] }`. Revisa si te falta algún ID obligatorio que rompa las validaciones de Rails.

---

## Manejo de Errores (Checklist)
Siempre revisa el código HTTP de respuesta para mostrar alertas correctas en el UI de la app:
- `200 / 201`: Todo bien!
- `401 Unauthorized`: El token `Authorization` falta, caducó, o es incorrecto. Toca mandar al usuario a la pantalla de login.
- `422 Unprocessable Entity`: Falló una validación del modelo. Revisa el array `"errors"` de la respuesta para saber si faltó un campo o mandaste algo mal formateado y muéstraselo al usuario.
- `500 Internal Server Error`: Esto es culpa mía. Ouch. Avísame y reviso los logs del servidor.

Cualquier duda con los payloads me avisas.
