# SaniTask

Aplicación de escritorio para la gestión de tareas del sector sanitario, desarrollada como
proyecto de la asignatura Desarrollo de Interfaces (2º Trimestre).

**Autora:** Helena Franz Folgueira

## Descripción

SaniTask es un producto mínimo viable (MVP) orientado a facilitar la gestión diaria de un
hospital. La plantilla puede iniciar sesión con su nombre y código de empleado, y acceder a
un conjunto de aplicaciones adaptadas a su rol dentro del centro: administración, equipo
médico o equipo de gestión.

El diseño gráfico está inspirado en las primeras interfaces de Windows (estilo Windows 95),
aplicando la teoría de historia de interfaces impartida a lo largo del trimestre: ventanas,
iconos y una estética retro alejada del modelo de consola.

## Características principales

- Inicio de sesión con validación de nombre y código de empleado.
- Sistema de roles y permisos (administrador, equipo médico, equipo de gestión).
- Aplicaciones auxiliares disponibles para todos los roles:
  - Calculadora (operaciones básicas: suma, resta, multiplicación y división).
  - Bloc de notas personal (base de datos local SQLite).
  - Lista de tareas personal (base de datos local SQLite).
- Aplicaciones de gestión conectadas a un servidor con base de datos MySQL:
  - Gestión de empleados (alta, edición, baja y búsqueda).
  - Gestión de historiales clínicos de pacientes (alta, edición, baja y búsqueda).
  - Gestión de citas médicas del día, exclusivas por médico responsable.
- Envío de recordatorios por correo electrónico (citas y recetas) mediante un script en
  Python, con generación previa del documento en PDF.

## Roles y permisos

| Rol | Código | Permisos |
|---|---|---|
| Administrador | ADM— | Aplicaciones auxiliares y gestión completa de empleados (crear, editar, borrar). |
| Equipo médico | DOC— | Aplicaciones auxiliares, control completo de historiales clínicos (excepto alta de nuevos pacientes) y gestión completa de sus propias citas y tratamientos. |
| Equipo de gestión | GER— | Aplicaciones auxiliares, alta y visualización de historiales clínicos, y visualización (sin edición) de las fichas de empleados. |

## Arquitectura y tecnologías

- **Cliente de escritorio:** Godot Engine (GDScript).
- **Base de datos local:** SQLite, para las notas y tareas personales de cada usuario.
- **Servidor:** Node.js con Express, con una API REST propia sobre las tablas de
  empleados, pacientes y citas (operaciones CRUD y búsquedas específicas por nombre).
- **Base de datos remota:** MySQL (mysql2), con relación uno a muchos entre empleados
  (equipo médico) y citas.
- **Envío de correos:** Script en Python, invocado desde el servidor, que recibe los datos
  del correo como argumentos y adjunta el documento generado en PDF.
- **Plugins de Godot utilizados:**
  - `godot-sqlite`, para la conexión con la base de datos local SQLite.
  - `godotpdf`, para la generación de los documentos PDF de recordatorio.

## Estructura del repositorio

```
SaniTask/
├── README.md
├── SaniTask/                    # Proyecto de Godot (cliente de escritorio)
│   ├── project.godot
│   ├── *.gd                     # Scripts (login, calculadora, notas, tareas,
│   │                             # empleados, historiales, citas, correo, etc.)
│   ├── *.tscn                   # Escenas (WindowsDesktop.tscn, inicioSesion.tscn...)
│   ├── addons/
│   │   ├── godot-sqlite/        # Plugin de conexión con SQLite
│   │   └── godotpdf/            # Plugin de generación de PDF
│   ├── w95fa/                   # Tipografía utilizada para la estética Windows 95
│   └── LICENSE
└── Sevidor/
    └── sevidor/                 # Servidor Node.js
        ├── server.js
        ├── conexionSQL.js
        ├── enviarCorreo.py
        ├── package.json
        └── node_modules/
```

## Puesta en marcha

### Requisitos previos

- [Godot Engine](https://godotengine.org/) (versión utilizada en el desarrollo).
- Node.js.
- Servidor MySQL accesible.
- Python 3, para el envío de correos electrónicos.

### Servidor

```bash
cd Sevidor/sevidor
npm install
node server.js
```

Configura la conexión a la base de datos MySQL en `conexionSQL.js` antes de arrancar el
servidor.

### Cliente

Abre la carpeta `SaniTask/` con Godot Engine y ejecuta la escena principal
(`WindowsDesktop.tscn` o `inicioSesion.tscn`, según corresponda).

## Problemas conocidos

- Al borrar un empleado o un paciente, el registro se elimina correctamente de la base de
  datos, pero la lista mostrada en la aplicación tarda en actualizarse.

## Próximas actualizaciones

- Implementación completa de la aplicación de gestión de recetas médicas, incluyendo su
  gestión de errores.
- Desarrollo de funcionalidades adicionales para el rol de equipo de gestión.

## Licencia

Proyecto académico desarrollado para la asignatura Desarrollo de Interfaces.
