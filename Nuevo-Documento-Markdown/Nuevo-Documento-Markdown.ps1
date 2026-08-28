[CmdletBinding()]
param(
    [ValidateSet('Instalar', 'Desinstalar')]
    [string]$Accion = 'Instalar'
)

$ErrorActionPreference = 'Stop'

$rutaShellNew = 'HKCU:\Software\Classes\.md\ShellNew'
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
        }
        else {
            New-Item -Path $rutaShellNew -Force | Out-Null
        }

        New-ItemProperty -LiteralPath $rutaShellNew -Name 'NullFile' -Value '' -PropertyType String -Force | Out-Null
        New-ItemProperty -LiteralPath $rutaShellNew -Name $nombreMarca -Value $valorMarca -PropertyType String -Force | Out-Null

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

        Remove-ItemProperty -LiteralPath $rutaShellNew -Name 'NullFile' -ErrorAction SilentlyContinue
        Remove-ItemProperty -LiteralPath $rutaShellNew -Name $nombreMarca -ErrorAction SilentlyContinue

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
