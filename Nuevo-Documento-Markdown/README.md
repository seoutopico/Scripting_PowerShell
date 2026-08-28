# Crear un archivo Markdown con el clic derecho en Windows

Añade una opción al menú **Nuevo** del Explorador de archivos para crear directamente un archivo Markdown vacío dentro de cualquier carpeta.

## Vídeo paso a paso

[![Cómo crear archivos Markdown con clic derecho en Windows](./miniatura-youtube.png)](https://youtu.be/c1ET5uzwpeI)

[▶ Ver el tutorial completo en YouTube](https://youtu.be/c1ET5uzwpeI)

El script:

- Añade los archivos `.md` al menú **Nuevo** de Windows.
- Aplica el cambio únicamente al usuario actual.
- Conserva el editor Markdown registrado; si no existe ninguno, utiliza el Bloc de notas.
- No instala programas ni módulos adicionales.
- Permite deshacer el cambio con el mismo script.

## Requisitos

- Windows 10 u 11.
- Windows PowerShell 5.1, incluido en Windows.
- Una carpeta donde guardar el script.

No es necesario tener conocimientos de PowerShell ni permisos de administrador.

## 1. Preparar la carpeta

Crea una carpeta para guardar el script. Por ejemplo:

```text
%USERPROFILE%\Documents\Herramienta_IA
```

Puedes pegar esta ruta directamente en la barra de direcciones del Explorador. Windows sustituirá `%USERPROFILE%` por la ruta de tu usuario.

## 2. Mostrar las extensiones de archivo

En el Explorador de archivos:

1. Abre **Ver**.
2. Selecciona **Mostrar**.
3. Activa **Extensiones de nombre de archivo**.

Esto evita guardar accidentalmente el script como `Nuevo-Documento-Markdown.ps1.txt`.

## 3. Crear el script

Abre el Bloc de notas y pega el siguiente código:

```powershell
[CmdletBinding()]
param(
    [ValidateSet('Instalar', 'Desinstalar')]
    [string]$Accion = 'Instalar'
)

$ErrorActionPreference = 'Stop'

$rutaExtension = 'HKCU:\Software\Classes\.md'
$rutaShellNew = Join-Path $rutaExtension 'ShellNew'
$rutaProgIdPropio = 'HKCU:\Software\Classes\ScriptingPowerShell.MarkdownFile'
$nombreMarca = 'ScriptingPowerShell'
$valorMarca = 'Nuevo-Documento-Markdown'

function Actualizar-Explorador {
    if (-not ('ScriptingPowerShell.NotificadorShell' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace ScriptingPowerShell {
    public static class NotificadorShell {
        [DllImport("shell32.dll")]
        public static extern void SHChangeNotify(
            uint eventId,
            uint flags,
            IntPtr item1,
            IntPtr item2
        );
    }
}
'@
    }

    [ScriptingPowerShell.NotificadorShell]::SHChangeNotify(
        0x08000000,
        0,
        [IntPtr]::Zero,
        [IntPtr]::Zero
    )
}

try {
    if ($Accion -eq 'Instalar') {
        $asociacionYaConfigurada = $false

        if (Test-Path -LiteralPath $rutaShellNew) {
            $claveExistente = Get-Item -LiteralPath $rutaShellNew
            $valoresExistentes = $claveExistente.GetValueNames()
            $marcaExistente = $claveExistente.GetValue($nombreMarca, '')

            if ($valoresExistentes.Count -gt 0 -and $marcaExistente -ne $valorMarca) {
                throw @"
Windows ya tiene una configuracion para crear archivos .md desde el menu Nuevo.
No se ha modificado para evitar sobrescribir una configuracion anterior.
Ruta: $rutaShellNew
"@
            }

            $asociacionYaConfigurada =
                $marcaExistente -eq $valorMarca -and
                $valoresExistentes -contains 'ProgIdConfigurado'
        }
        else {
            New-Item -Path $rutaShellNew -Force | Out-Null
        }

        $claveExtension = Get-Item -LiteralPath $rutaExtension
        if ($asociacionYaConfigurada) {
            $progIdAnterior = [string]$claveExistente.GetValue('ProgIdAnterior', '')
            $progIdConfigurado = [string]$claveExistente.GetValue('ProgIdConfigurado', '')
            $progIdPropioCreado = [int]$claveExistente.GetValue('ProgIdPropioCreado', 0)
        }
        else {
            $progIdAnterior = [string]$claveExtension.GetValue('', '')
            $progIdConfigurado = ''
            $progIdPropioCreado = 0
        }

        if (-not $asociacionYaConfigurada -and [string]::IsNullOrWhiteSpace($progIdAnterior)) {
            $rutaOpenWith = Join-Path $rutaExtension 'OpenWithProgids'
            $candidatos = @()

            if (Test-Path -LiteralPath $rutaOpenWith) {
                $candidatos = (Get-Item -LiteralPath $rutaOpenWith).GetValueNames() |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace($_) -and
                        (Test-Path -LiteralPath "Registry::HKEY_CLASSES_ROOT\$_")
                    }
            }

            $progIdConfigurado = $candidatos | Select-Object -First 1

            if ([string]::IsNullOrWhiteSpace($progIdConfigurado)) {
                $progIdConfigurado = 'ScriptingPowerShell.MarkdownFile'
                New-Item -Path $rutaProgIdPropio -Force | Out-Null
                Set-Item -LiteralPath $rutaProgIdPropio -Value 'Documento Markdown'

                $rutaComando = Join-Path $rutaProgIdPropio 'shell\open\command'
                New-Item -Path $rutaComando -Force | Out-Null
                Set-Item -LiteralPath $rutaComando -Value ('"{0}\System32\notepad.exe" "%1"' -f $env:SystemRoot)
                $progIdPropioCreado = 1
            }

            Set-Item -LiteralPath $rutaExtension -Value $progIdConfigurado
        }

        New-ItemProperty -LiteralPath $rutaShellNew -Name 'NullFile' -Value '' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $rutaShellNew -Name $nombreMarca -Value $valorMarca -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $rutaShellNew -Name 'ProgIdAnterior' -Value $progIdAnterior -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $rutaShellNew -Name 'ProgIdConfigurado' -Value $progIdConfigurado -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $rutaShellNew -Name 'ProgIdPropioCreado' -Value $progIdPropioCreado -PropertyType DWord -Force | Out-Null

        Actualizar-Explorador

        Write-Host 'Instalacion completada.' -ForegroundColor Green
        Write-Host 'Abre una carpeta y prueba: clic derecho > Nuevo > archivo Markdown.'
    }
    else {
        if (-not (Test-Path -LiteralPath $rutaShellNew)) {
            Write-Host 'Esta opcion no esta instalada.' -ForegroundColor Yellow
            exit 0
        }

        $claveExistente = Get-Item -LiteralPath $rutaShellNew
        $marcaExistente = $claveExistente.GetValue($nombreMarca, '')

        if ($marcaExistente -ne $valorMarca) {
            throw @"
La configuracion existente no fue creada por este script.
No se ha eliminado nada.
Ruta: $rutaShellNew
"@
        }

        $progIdAnterior = [string]$claveExistente.GetValue('ProgIdAnterior', '')
        $progIdConfigurado = [string]$claveExistente.GetValue('ProgIdConfigurado', '')
        $progIdPropioCreado = [int]$claveExistente.GetValue('ProgIdPropioCreado', 0)

        if (-not [string]::IsNullOrWhiteSpace($progIdConfigurado)) {
            $claveExtension = Get-Item -LiteralPath $rutaExtension
            $progIdActual = [string]$claveExtension.GetValue('', '')

            if ($progIdActual -eq $progIdConfigurado) {
                if ([string]::IsNullOrWhiteSpace($progIdAnterior)) {
                    Set-Item -LiteralPath $rutaExtension -Value ''
                }
                else {
                    Set-Item -LiteralPath $rutaExtension -Value $progIdAnterior
                }
            }
        }

        if ($progIdPropioCreado -eq 1 -and (Test-Path -LiteralPath $rutaProgIdPropio)) {
            Remove-Item -LiteralPath $rutaProgIdPropio -Recurse -Force
        }

        Remove-ItemProperty -LiteralPath $rutaShellNew -Name 'NullFile' -ErrorAction SilentlyContinue
        Remove-ItemProperty -LiteralPath $rutaShellNew -Name $nombreMarca -ErrorAction SilentlyContinue
        Remove-ItemProperty -LiteralPath $rutaShellNew -Name 'ProgIdAnterior' -ErrorAction SilentlyContinue
        Remove-ItemProperty -LiteralPath $rutaShellNew -Name 'ProgIdConfigurado' -ErrorAction SilentlyContinue
        Remove-ItemProperty -LiteralPath $rutaShellNew -Name 'ProgIdPropioCreado' -ErrorAction SilentlyContinue

        $valoresRestantes = (Get-Item -LiteralPath $rutaShellNew).GetValueNames()
        if ($valoresRestantes.Count -eq 0) {
            Remove-Item -LiteralPath $rutaShellNew -Force
        }

        Actualizar-Explorador

        Write-Host 'Desinstalacion completada.' -ForegroundColor Green
        Write-Host 'Se ha quitado el archivo Markdown del menu Nuevo.'
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
```

No tienes que cambiar ninguna ruta ni personalizar ninguna línea del código.

## 4. Guardar el script

En el Bloc de notas:

1. Selecciona **Archivo > Guardar como**.
2. En **Tipo**, elige **Todos los archivos**.
3. Escribe `Nuevo-Documento-Markdown.ps1`.
4. Guárdalo dentro de la carpeta `Herramienta_IA`.

Comprueba que el archivo termina exactamente en `.ps1`, no en `.ps1.txt`.

## 5. Probar el script

1. Abre la carpeta `Herramienta_IA`.
2. Haz clic derecho en una zona vacía.
3. Selecciona **Abrir en Terminal**.
4. Ejecuta:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Nuevo-Documento-Markdown.ps1"
```

Si todo ha ido bien, verás:

```text
Instalacion completada.
```

Si PowerShell indica que el script no existe, muestra los nombres reales de los archivos con:

```powershell
Get-ChildItem -File | Select-Object -ExpandProperty Name
```

No continúes hasta que la instalación termine sin errores.

## 6. Probar el menú Nuevo

1. Abre cualquier carpeta del Explorador.
2. Haz clic derecho en una zona vacía.
3. Abre **Nuevo**.
4. Selecciona la opción correspondiente a Markdown.
5. Escribe un nombre para el archivo y pulsa `Enter`.

El nombre exacto puede variar según el idioma de Windows y la aplicación asociada a `.md`. Puede aparecer como **Documento Markdown**, **Archivo Markdown**, **Markdown Source File** o un nombre parecido.

Lo importante es comprobar que Windows crea un archivo como este:

```text
Nuevo documento Markdown.md
```

En algunas versiones de Windows 11 puede ser necesario pulsar primero **Mostrar más opciones**.

No continúes hasta que puedas crear un archivo terminado en `.md`.

## 7. Desinstalar la opción

No necesitas desinstalarla para utilizarla. Este paso sirve para comprobar que el cambio es reversible o para eliminarlo en el futuro.

1. Abre la carpeta `Herramienta_IA`.
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

Si quieres volver a instalarla, ejecuta otra vez el comando del paso 5.

## Uso

Una vez instalado, no necesitas volver a ejecutar el script:

```text
Abrir una carpeta -> Clic derecho -> Nuevo -> Markdown
```

El archivo se crea vacío y listo para escribir. Si Windows ya conoce un editor compatible con `.md`, el script conserva ese tipo de archivo. Si no encuentra ninguno, registra **Documento Markdown** y utiliza el Bloc de notas.

## Solución de problemas

### La opción Markdown no aparece

Cierra todas las ventanas del Explorador y abre una carpeta nueva.

Si continúa sin aparecer, cierra sesión en Windows y vuelve a entrar. No debería ser necesario reiniciar el ordenador.

### El script aparece como archivo de texto

Activa las extensiones de archivo y comprueba que el nombre no termina en `.ps1.txt`.

El nombre correcto es:

```text
Nuevo-Documento-Markdown.ps1
```

### PowerShell no encuentra el script

Ejecuta:

```powershell
Get-ChildItem -File | Select-Object -ExpandProperty Name
```

Si `Nuevo-Documento-Markdown.ps1` no aparece, la terminal está abierta en otra carpeta o el archivo tiene un nombre diferente.

### Windows ya tiene una configuración para `.md`

Otra aplicación o una configuración anterior ya ha añadido `.md` al menú **Nuevo**. El script se detiene sin modificarla para evitar conflictos.

Abre una carpeta y comprueba si ya aparece una opción que cree archivos `.md`.

### La opción tiene otro nombre

Windows obtiene el nombre del tipo de archivo o de la aplicación asociada. Crea un archivo y comprueba su extensión. Si termina en `.md`, está funcionando correctamente.

## Seguridad

El comando utiliza `-ExecutionPolicy Bypass` únicamente para ese proceso de PowerShell. No modifica de forma permanente la política de ejecución del sistema.

El script modifica solamente esta clave del usuario actual:

```text
HKEY_CURRENT_USER\Software\Classes\.md\ShellNew
```

Windows utiliza `ShellNew` para decidir qué tipos de archivo aparecen en el menú **Nuevo**. El valor `NullFile` le indica que debe crear un archivo vacío.

El script no necesita permisos de administrador ni instala programas. Si `.md` no tiene un tipo principal, reutiliza un editor Markdown registrado. Si tampoco encuentra uno, crea su propio tipo y utiliza el Bloc de notas.

Al desinstalar, restaura el tipo de archivo que existía antes de ejecutar el script.

Antes de realizar el cambio, comprueba si ya existe una configuración para `.md`. Si encuentra una que no ha creado él, se detiene sin sobrescribirla.

Microsoft documenta el funcionamiento de `ShellNew` y `NullFile` en [Extending Shortcut Menus](https://learn.microsoft.com/en-us/windows/win32/shell/context).
