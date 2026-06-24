## HuariqueHub

Aplicación Flutter orientada a la búsqueda, registro y gestión de huariques.  
Permite a los usuarios explorar locales, revisar promociones, gestionar favoritos y acceder a funcionalidades según su tipo de cuenta.

## Tecnologías

- Flutter
- Dart
- Provider
- GoRouter
- SharedPreferences
- Flutter Map

## Estructura del proyecto

El proyecto está organizado en carpetas para separar responsabilidades y facilitar el mantenimiento del código.

- `lib/core`: contiene configuraciones generales, rutas, estilos y componentes base.
- `lib/data`: contiene modelos y servicios relacionados con la gestión de datos.
- `lib/features`: contiene las pantallas y funcionalidades principales de la aplicación.
- `lib/providers`: contiene los proveedores usados para manejar el estado de la aplicación.
- `android`, `ios`, `windows`, `web`, `linux`, `macos`: carpetas generadas por Flutter para las distintas plataformas compatibles.

## Ejecución del proyecto

Para ejecutar el proyecto localmente, se deben seguir los siguientes pasos:

1. Clonar el repositorio desde GitHub.
2. Abrir el proyecto en Android Studio.
3. Ejecutar el comando `flutter pub get` para instalar las dependencias.
4. Seleccionar un dispositivo disponible, como Windows Desktop o un emulador Android.
5. Ejecutar la aplicación con el botón `Run` o con el comando `flutter run`.

En Windows, es recomendable tener activado el modo desarrollador para evitar problemas con los plugins de Flutter.