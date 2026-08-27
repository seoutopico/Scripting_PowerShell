Add-Type -AssemblyName System.Windows.Forms

try {
    $inbox = "PEGA_AQUI_LA_RUTA_DE_TU_INBOX"

    if (-not (Test-Path -LiteralPath $inbox)) {
        throw "No existe la carpeta: $inbox"
    }

    $texto = Get-Clipboard -Raw

    if ([string]::IsNullOrWhiteSpace($texto)) {
        throw "El portapapeles no contiene texto."
    }

    $primeraLinea = $texto -split "\r?\n" |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1

    $titulo = $primeraLinea.Trim()
    $titulo = $titulo -replace '^[\s#>*+-]+', ''

    if ($titulo -match '^https?://\S+$') {
        $direccion = [Uri]$titulo
        $titulo = $direccion.Host + $direccion.AbsolutePath
        $titulo = $titulo -replace '^www\.', ''
        $titulo = $titulo.TrimEnd('/')
    }

    $titulo = $titulo -replace '[<>:"/\\|?*]', ' '
    $titulo = $titulo -replace '[^\p{L}\p{Nd}\s_-]', ''
    $titulo = $titulo -replace '[_\s]+', '-'
    $titulo = $titulo -replace '-+', '-'
    $titulo = $titulo.Trim('-').ToLowerInvariant()

    if ([string]::IsNullOrWhiteSpace($titulo)) {
        $titulo = "nota"
    }

    if ($titulo.Length -gt 70) {
        $titulo = $titulo.Substring(0, 70).TrimEnd('-')
    }

    $fecha = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $archivo = Join-Path $inbox "$fecha-$titulo.md"

    Set-Content -LiteralPath $archivo -Value $texto -Encoding UTF8
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        $_.Exception.Message,
        "Error al crear la nota"
    ) | Out-Null
}
