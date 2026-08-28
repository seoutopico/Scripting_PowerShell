# Crear un archivo Markdown con el clic derecho en Windows

Windows permite crear una carpeta, un acceso directo o un documento de texto desde el menú **Nuevo**, pero normalmente no incluye una opción para crear archivos Markdown.

Con este tutorial vamos a añadirla:

```text
Clic derecho dentro de una carpeta > Nuevo > archivo Markdown
```

El resultado será un archivo vacío terminado en `.md`, listo para escribir contexto para tus agentes, abrirlo con Obsidian o editarlo con cualquier aplicación compatible.

## Qué vamos a hacer

Vamos a utilizar un pequeño script de PowerShell que:

- Añade los archivos `.md` al menú **Nuevo** del Explorador.
- Aplica el cambio únicamente a tu usuario de Windows.
- No cambia la aplicación con la que abres tus Markdown.
- No instala programas ni módulos adicionales.
- Incluye una opción para deshacer el cambio.

## Requisitos

- Windows 10 u 11.
- Windows PowerShell 5.1, incluido en Windows.
- No necesitas permisos de administrador.

## 1. Crear una carpeta para la herramienta

Abre el Explorador de archivos y crea una carpeta para guardar el script. Por ejemplo:

```text
%USERPROFILE%\Documents\Herramientas-PowerShell
```

Puedes pegar esa ruta directamente en la barra de direcciones del Explorador. Windows sustituirá `%USERPROFILE%` por la ruta de tu usuario.

## 2. Mostrar las extensiones de archivo

Antes de descargar el script, comprueba que Windows muestra las extensiones:

1. Abre una ventana del Explorador.
2. Pulsa **Ver**.
3. Selecciona **Mostrar**.
4. Activa **Extensiones de nombre de archivo**.

Esto te permitirá comprobar que el script termina realmente en `.ps1` y que el archivo creado termina en `.md`.

## 3. Descargar el script

Abre el archivo [`Nuevo-Documento-Markdown.ps1`](./Nuevo-Documento-Markdown.ps1) en GitHub.

1. Pulsa el botón **Download raw file** de la parte superior derecha del código.
2. Guarda el archivo dentro de `Herramientas-PowerShell`.
3. Comprueba que se llama exactamente:

```text
Nuevo-Documento-Markdown.ps1
```

No debe llamarse `Nuevo-Documento-Markdown.ps1.txt`.

## 4. Abrir una terminal en la carpeta

Entra en la carpeta `Herramientas-PowerShell`.

1. Haz clic derecho en una zona vacía de la carpeta.
2. Selecciona **Abrir en Terminal**.

La terminal debe abrirse mostrando la ruta de esa carpeta. No importa si ves `PowerShell` o `Windows PowerShell`: el siguiente comando llama expresamente a la versión incluida con Windows.

## 5. Instalar la opción

Copia este comando completo, pégalo en la terminal y pulsa `Enter`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Nuevo-Documento-Markdown.ps1"
```

Si todo ha ido bien, verás:

```text
Instalacion completada.
```

No cierres todavía la terminal. Primero vamos a probar el resultado.

## 6. Crear tu primer Markdown con el clic derecho

1. Abre cualquier carpeta del Explorador.
2. Haz clic derecho en una zona vacía.
3. Abre el menú **Nuevo**.
4. Selecciona la opción correspondiente a Markdown.
5. Escribe un nombre para el archivo y pulsa `Enter`.

El nombre exacto puede variar según el idioma de Windows y la aplicación asociada a `.md`. Puede aparecer como **Documento Markdown**, **Archivo Markdown**, **Markdown Source File** o un nombre parecido.

Lo importante es comprobar que Windows crea un archivo como este:

```text
Nuevo documento Markdown.md
```

En algunas versiones de Windows 11 puede ser necesario pulsar primero **Mostrar más opciones** para encontrar el menú **Nuevo**.

No continúes hasta que puedas crear un archivo terminado en `.md`.

## 7. Abrir y editar el archivo

Haz doble clic sobre el Markdown que acabas de crear.

Windows lo abrirá con la aplicación que ya tengas asociada a `.md`, por ejemplo Obsidian, Visual Studio Code, Typora o el Bloc de notas.

El script no decide qué editor se utiliza y no modifica esa asociación.

## Cómo desinstalarlo

Si quieres retirar la opción del menú **Nuevo**:

1. Vuelve a la carpeta `Herramientas-PowerShell`.
2. Haz clic derecho en una zona vacía.
3. Selecciona **Abrir en Terminal**.
4. Ejecuta:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Nuevo-Documento-Markdown.ps1" -Accion Desinstalar
```

Si todo ha ido bien, verás:

```text
Desinstalacion completada.
```

El script solo elimina la configuración que él mismo haya creado.

## Qué está haciendo PowerShell

Windows construye el menú **Nuevo** a partir de una zona del Registro. El script crea esta clave para el usuario actual:

```text
HKEY_CURRENT_USER\Software\Classes\.md\ShellNew
```

Dentro añade un valor llamado `NullFile`. Ese valor le indica al Explorador que puede crear un archivo `.md` vacío.

El script también avisa al Explorador para que vuelva a leer la configuración. Por eso normalmente no es necesario reiniciar el ordenador.

Esta es la técnica documentada por Microsoft para añadir tipos de archivo al menú **Nuevo** mediante `ShellNew` y `NullFile`:

- [Extending Shortcut Menus — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/shell/context)

## Seguridad

El script trabaja dentro de `HKEY_CURRENT_USER`, por lo que:

- El cambio solo afecta al usuario de Windows que lo ejecuta.
- No solicita permisos de administrador.
- No modifica la configuración de otros usuarios.
- No cambia la política de ejecución de PowerShell de forma permanente.

El parámetro `-ExecutionPolicy Bypass` se aplica únicamente al proceso utilizado para ejecutar este archivo y termina cuando cierras esa ejecución.

Antes de instalar, el script comprueba si ya existe una configuración para crear `.md`. Si encuentra una que no ha creado él, se detiene para no sobrescribirla.

## Solución de problemas

### No aparece ninguna opción Markdown

El Explorador puede tardar en actualizar el menú:

1. Cierra todas las ventanas del Explorador.
2. Abre una carpeta nueva y vuelve a comprobarlo.
3. Si continúa sin aparecer, cierra sesión en Windows y vuelve a entrar.

### El archivo se ha guardado como `.ps1.txt`

Activa **Ver > Mostrar > Extensiones de nombre de archivo** y elimina solamente el `.txt` final. El nombre correcto es:

```text
Nuevo-Documento-Markdown.ps1
```

### PowerShell dice que no encuentra el script

Comprueba qué archivos hay en la carpeta ejecutando:

```powershell
Get-ChildItem -File | Select-Object -ExpandProperty Name
```

Si `Nuevo-Documento-Markdown.ps1` no aparece, la terminal está abierta en otra carpeta o el archivo tiene un nombre diferente.

### Aparece «Windows ya tiene una configuración»

Otra aplicación o una configuración anterior ya ha añadido `.md` al menú **Nuevo**. El script se detiene sin modificarla para evitar conflictos.

Antes de hacer nada más, abre una carpeta y comprueba si ya aparece una opción que cree archivos `.md`.

### La opción tiene otro nombre

Es normal. Windows obtiene el nombre del tipo de archivo o de la aplicación asociada. Comprueba el resultado creando un archivo: si termina en `.md`, la herramienta está funcionando.

## Uso habitual

Una vez instalado, ya no necesitas volver a ejecutar el script:

```text
Entrar en una carpeta
→ Clic derecho
→ Nuevo
→ Markdown
→ Escribir el nombre
```

El script debe conservarse únicamente si quieres disponer fácilmente del comando de desinstalación.
