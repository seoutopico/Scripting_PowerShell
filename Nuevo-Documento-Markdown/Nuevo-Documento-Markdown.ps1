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
