# Configuración de Autenticación Google OAuth Móvil

## Qué Es

La app móvil en React Native permite que los usuarios se logueen con su cuenta de Gmail. El endpoint valida el token JWT de Google y devuelve un `auth_token` para acceder a la API.

Flujo simple: usuario toca "Loguearme con Google" → Google valida → vuelve autenticado con su `auth_token`.

## Que Necesitas Antes de Empezar

- Proyecto activo en Google Cloud Console
- Credenciales OAuth 2.0 creadas (Android y/o iOS — o ambas si querés andar en todos lados)
- Variables de entorno configuradas en `.env`

## Configuración en Google Cloud

### 1. Crear Credenciales OAuth 2.0

1. Andá a [Google Cloud Console](https://console.cloud.google.com)
2. Elegí tu proyecto
3. **APIs & Services > Credentials**
4. **Create Credentials > OAuth 2.0 Client ID**
5. Elegí **Android** o **iOS** (o los dos)
   - **Android:** Dame el package name y el SHA-1 fingerprint
   - **iOS:** Dame el bundle ID
6. Copiá el **Client ID** — lo vas a necesitar

### 2. Habilitar la API de Google Sign-In

1. **APIs & Services > Library**
2. Buscá "Google Sign-In"
3. Dale a **Enable**

Listo, eso es todo lo que Google necesita.

## Configuración en Rails

### 1. Variables de Entorno

Creá o actualizá `.env`:
```
GOOGLE_CLIENT_ID=tu_client_id_aca.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=tu_secret_aca
```

O si usás Heroku, Docker, etc., configuralo en la plataforma que corresponda.

### 2. Verificar que el Gem Esté Instalado

Controlá que `google_sign_in` esté en el Gemfile y cargado:
```bash
bundle list | grep google
```

Debería salir algo con `google_sign_in`.

### 3. Ejecutar la Migración de Base de Datos

Asegurate que la migración corrió:
```bash
rails db:migrate
```

Esto agrega las columnas `google_uid` y `provider` a la tabla de usuarios.

## Integración en la App Móvil

### Configuración React Native

#### 1. Instalar la Librería de Google Sign-In
```bash
npm install @react-native-google-signin/google-signin
```

#### 2. Configurar iOS (si aplica)
Seguí [la documentación oficial](https://github.com/react-native-google-signin/google-signin/blob/master/docs/ios-guide.md). No es tan quilombo como parece.

#### 3. Configurar Android (si aplica)
Seguí [la documentación oficial](https://github.com/react-native-google-signin/google-signin/blob/master/docs/android-guide.md). Básicamente lo mismo pero para Android.

#### 4. Ejemplo de Implementación

Acá está lo importante. Este es el código que hace la diferencia:

```typescript
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import AsyncStorage from '@react-native-async-storage/async-storage';

GoogleSignin.configure({
  webClientId: 'TU_WEB_CLIENT_ID.apps.googleusercontent.com',
});

async function loginWithGoogle() {
  try {
    // El usuario toca el botón, Google abre su login
    const userInfo = await GoogleSignin.signIn();
    const idToken = userInfo.idToken;

    // Enviá el token a Rails
    const response = await fetch('TU_API_URL/api/v1/auth/google', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_token: idToken }),
    });

    const data = await response.json();

    if (response.ok) {
      // Guardá el token de forma segura (esto es crítico — no en plain text)
      await AsyncStorage.setItem('auth_token', data.auth_token);
      // Usuario autenticado. ¡Listo!
      return data.user;
    } else {
      // Si algo falló, avisá qué fue
      console.error('Error de autenticación:', data.error);
    }
  } catch (error) {
    console.error('Google Sign-In se rompió:', error);
  }
}
```

#### 5. Guardar el Token de Forma Segura

Esto NO es opcional. Usá `react-native-secure-storage` o `AsyncStorage` encriptado:

```typescript
import SecureStorage from 'react-native-secure-storage';

// Guardar el token en secure storage (no en plain text)
await SecureStorage.setItem('auth_token', token);
```

#### 6. Incluir el Token en Todos los Requests a la API

Cada request que hagas a la API que requiera autenticación debe llevar el token:

```typescript
const headers = {
  'Authorization': `Token ${authToken}`,
  'Content-Type': 'application/json',
};

const response = await fetch(apiUrl, { method: 'GET', headers });
```

Sin esto, Rails va a rechazar el request con 401. Es la forma en que le decís "che, soy yo, ya me logueé".

## Testing

### Tests Unitarios
Correlos así:
```bash
bundle exec rspec spec/models/user_spec.rb
```

### Tests de Integración
Correlos así:
```bash
bundle exec rspec spec/requests/api/v1/auth_google_spec.rb
```

Todos deberían pasar. Si no pasan, hay un quilombo en el backend.
Culpa mía seguro.

### Testing Manual

1. Arrancá el server: `rails s`
2. Generá un JWT de prueba (mirá la Task 9 en el plan de implementación si necesitás detalles)
3. Testea con curl o Postman

### Testing en Dispositivo Real

Esto es lo que importa:

1. Compilá la app e instalá en el teléfono (iOS o Android, o ambos)
2. Tocá el botón "Loguearme con Google"
3. Verificá que el email que devuelve Google match exactamente con el registrado en la BD
4. Confirmá que recibís el `auth_token` y que los requests a la API funcionan

No hagas testing en emulador. Es al pedo. Los emuladores tienen seguridad de cartón.

## Qué Puede Salir Mal (y Cómo Arreglarlo)

### El Token No Valida

- Verificá que el `GOOGLE_CLIENT_ID` en tu `.env` sea el correcto (debe matchear con lo que creaste en Google Cloud)
- Checkea que el token no haya expirado (los tokens de Google duran ~1 hora nomás)
- Asegurate de que el token se generó para la app correcta (Android genera tokens de Android, iOS genera tokens de iOS)

### Usuario No Encontrado (Error 401)

- Confirmá que el usuario existe en la BD con `status: "active"` (si está en "lead", no puede loguear)
- Verificá que el email en Google matchee exactamente con el registrado (es case-insensitive, pero tiene que ser la misma dirección)
- El usuario tiene que haber completado el questionnaire y pagado antes de intentar loguear en la app

### Problemas de Almacenamiento Seguro (Mobile)

- **En Android:** El Keystore tiene que estar configurado. Si no, pierdes el token.
- **En iOS:** Los Keychain entitlements tienen que estar en orden. Si no, no te deja guardar nada.
- **En general:** Siempre testea en un dispositivo real. Los emuladores meten la pata con seguridad.

## Lo Crítico de Seguridad (Leete Esto)

- Los tokens de Google son **single-use** — usalos una sola vez y listo
- No hay "refresh" para los tokens de Google — si expiran, el usuario tiene que loguear de nuevo
- Los `auth_token` que devuelve Rails **tienen que guardarse en secure storage**, no en plain text
- Nunca loguees un token. Nunca lo transmitas por una conexión sin encriptar.
- En producción, agregá rate limiting al endpoint (usá `rack-attack` gem) así los atacantes no pueden hacer fuerza bruta
