param(
    [string]$InputFile
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::InvariantCulture

function Ch { param([int]$Code) return [char]$Code }
$eacute = Ch 233
$egrave = Ch 232

function Show-Error {
    param([string]$Message)
    [System.Windows.Forms.MessageBox]::Show($Message, "FFActions - Media info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Quote-Arg {
    param([string]$Value)
    return '"' + ($Value -replace '"', '\"') + '"'
}

function Resolve-FFProbe {
    $candidates = @()

    $exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if (-not [string]::IsNullOrWhiteSpace($exePath)) {
        $exeDir = Split-Path -Parent $exePath
        $appRoot = Split-Path -Parent $exeDir
        $candidates += Join-Path $appRoot "tools\ffmpeg\ffprobe.exe"
        $candidates += Join-Path $exeDir "..\tools\ffmpeg\ffprobe.exe"
        $candidates += Join-Path $exeDir "ffprobe.exe"
    }

    if ($PSScriptRoot) {
        $candidates += Join-Path $PSScriptRoot "..\tools\ffmpeg\ffprobe.exe"
        $candidates += Join-Path $PSScriptRoot "tools\ffmpeg\ffprobe.exe"
        $candidates += Join-Path $PSScriptRoot "ffprobe.exe"
    }

    $candidates += Join-Path (Get-Location).Path "tools\ffmpeg\ffprobe.exe"
    $candidates += Join-Path (Get-Location).Path "ffprobe.exe"

    foreach ($candidate in $candidates) {
        $full = [System.IO.Path]::GetFullPath($candidate)
        if ([System.IO.File]::Exists($full)) { return $full }
    }

    return $null
}

function Invoke-FFProbeJson {
    param(
        [string]$FfprobePath,
        [string]$FilePath
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FfprobePath
    $psi.Arguments = "-v quiet -print_format json -show_streams -show_format " + (Quote-Arg $FilePath)
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($process.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($stdout)) {
            throw "ffprobe failed.`r`n`r`n$stderr"
        }

        return ($stdout | ConvertFrom-Json)
    }
    finally {
        if ($process -ne $null) { $process.Dispose() }
    }
}

function Format-Size {
    param([Int64]$Bytes)

    if ($Bytes -ge 1GB) { return ("{0:N2} Gio" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N0} Mio" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N0} Kio" -f ($Bytes / 1KB)) }
    return "$Bytes octets"
}

function Format-Duration {
    param($Seconds)

    if ($null -eq $Seconds) { return "-" }

    $value = 0.0
    if (-not [double]::TryParse(([string]$Seconds), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$value)) { return "-" }
    if ($value -le 0) { return "-" }

    $ts = [TimeSpan]::FromSeconds($value)

    if ($ts.Hours -gt 0) {
        return "{0} h {1:D2} min {2:D2} s" -f $ts.Hours, $ts.Minutes, $ts.Seconds
    }

    if ($ts.Minutes -gt 0) {
        return "{0} min {1:D2} s" -f $ts.Minutes, $ts.Seconds
    }

    return "{0} s {1:D3} ms" -f $ts.Seconds, $ts.Milliseconds
}

function Format-Bitrate {
    param($Value)

    if ($null -eq $Value) { return "-" }

    $number = 0.0
    if (-not [double]::TryParse(([string]$Value), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$number)) { return "-" }
    if ($number -le 0) { return "-" }

    $kbps = $number / 1000

    if ($kbps -ge 1000) { return ("{0:N1} Mb/s" -f ($kbps / 1000)) }
    return ("{0:N0} kb/s" -f $kbps)
}

function Format-Fps {
    param([string]$Rate)

    if ([string]::IsNullOrWhiteSpace($Rate) -or $Rate -eq "0/0") { return "-" }

    $parts = $Rate.Split("/")
    if ($parts.Count -ne 2) { return $Rate }

    $num = 0.0
    $den = 0.0
    if (-not [double]::TryParse($parts[0], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$num)) { return "-" }
    if (-not [double]::TryParse($parts[1], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$den)) { return "-" }
    if ($den -eq 0) { return "-" }

    return ("{0:N3} im/s" -f ($num / $den))
}

function Add-Line {
    param([string]$Label, [string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { $Value = "-" }
    return ("{0,-42}: {1}" -f $Label, $Value)
}

function Get-VideoFormat {
    param([string]$CodecName)
    if ([string]::IsNullOrWhiteSpace($CodecName)) { return "-" }

    switch ($CodecName.ToLowerInvariant()) {
        "h264"  { return "AVC" }
        "hevc"  { return "HEVC" }
        "mpeg4" { return "MPEG-4 Visual" }
        "vp9"   { return "VP9" }
        "av1"   { return "AV1" }
        "mjpeg" { return "JPEG" }
        default { return $CodecName.ToUpperInvariant() }
    }
}

function Get-VideoFormatInfo {
    param([string]$CodecName)
    if ([string]::IsNullOrWhiteSpace($CodecName)) { return "-" }

    switch ($CodecName.ToLowerInvariant()) {
        "h264"  { return "Advanced Video Coding" }
        "hevc"  { return "High Efficiency Video Coding" }
        "mpeg4" { return "MPEG-4 Visual" }
        "vp9"   { return "Google VP9" }
        "av1"   { return "AOMedia Video 1" }
        default { return "-" }
    }
}

function Get-AudioFormat {
    param([string]$CodecName)
    if ([string]::IsNullOrWhiteSpace($CodecName)) { return "-" }

    switch ($CodecName.ToLowerInvariant()) {
        "aac"       { return "AAC LC" }
        "mp3"       { return "MPEG Audio" }
        "flac"      { return "FLAC" }
        "opus"      { return "Opus" }
        "vorbis"    { return "Vorbis" }
        "pcm_s16le" { return "PCM" }
        default { return $CodecName.ToUpperInvariant() }
    }
}

function Get-AudioFormatInfo {
    param([string]$CodecName)
    if ([string]::IsNullOrWhiteSpace($CodecName)) { return "-" }

    switch ($CodecName.ToLowerInvariant()) {
        "aac"    { return "Advanced Audio Codec Low Complexity" }
        "mp3"    { return "MPEG Audio" }
        "flac"   { return "Free Lossless Audio Codec" }
        "opus"   { return "Opus" }
        "vorbis" { return "Vorbis" }
        default { return "-" }
    }
}

function Get-CompressionMode {
    param([string]$CodecName)
    if ([string]::IsNullOrWhiteSpace($CodecName)) { return "-" }

    switch ($CodecName.ToLowerInvariant()) {
        "flac"      { return "Sans perte" }
        "pcm_s16le" { return "Sans perte" }
        "wav"       { return "Sans perte" }
        "png"       { return "Sans perte" }
        "bmp"       { return "Non compresse" }
        "tiff"      { return "Variable" }
        default { return "Avec perte" }
    }
}

function Get-MediaKind {
    param($Data, [string]$FilePath)

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLowerInvariant()
    $imageExtensions = @(".jpg", ".jpeg", ".png", ".bmp", ".webp", ".gif", ".tif", ".tiff")

    if ($imageExtensions -contains $extension) { return "Image" }

    $video = $Data.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
    $audio = $Data.streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1

    if ($video) { return "Video" }
    if ($audio) { return "Audio" }
    return "Unknown"
}

function Build-ImageText {
    param($Data, [System.IO.FileInfo]$FileInfo)

    $stream = $Data.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1

    $format = "-"
    $width = "-"
    $height = "-"
    $colorSpace = "-"
    $bitDepth = "-"
    $compression = "-"
    $size = Format-Size -Bytes $FileInfo.Length

    if ($stream) {
        $format = Get-VideoFormat $stream.codec_name
        if ($stream.width) { $width = "$($stream.width) pixels" }
        if ($stream.height) { $height = "$($stream.height) pixels" }

        if ($stream.color_space) { $colorSpace = $stream.color_space.ToUpperInvariant() }
        elseif ($stream.pix_fmt) { $colorSpace = $stream.pix_fmt }

        if ($stream.bits_per_raw_sample) { $bitDepth = "$($stream.bits_per_raw_sample) bits" }
        elseif ($stream.pix_fmt -match "rgb|yuv|gray") { $bitDepth = "8 bits" }

        $compression = Get-CompressionMode $stream.codec_name
    }

    $lines = @()
    $lines += "General"
    $lines += Add-Line "Nom complet" $FileInfo.FullName
    $lines += Add-Line "Nom du fichier" $FileInfo.Name
    $lines += Add-Line "Format" $format
    $lines += Add-Line "Taille du fichier" $size
    $lines += ""
    $lines += "Image"
    $lines += Add-Line "Format" $format
    $lines += Add-Line "Largeur" $width
    $lines += Add-Line "Hauteur" $height
    $lines += Add-Line "Espace de couleurs" $colorSpace
    $lines += Add-Line "Profondeur binaire" $bitDepth
    $lines += Add-Line "Mode de compression" $compression
    $lines += Add-Line "Taille du flux" "$size (100%)"

    return $lines -join "`r`n"
}

function Build-AudioText {
    param($Data, [System.IO.FileInfo]$FileInfo)

    $audioStream = $Data.streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1

    $fileSize = Format-Size -Bytes $FileInfo.Length
    $duration = Format-Duration $Data.format.duration
    $globalBitrate = Format-Bitrate $Data.format.bit_rate
    $library = "-"
    if ($Data.format.tags.encoder) { $library = $Data.format.tags.encoder }

    $format = "-"
    $version = "-"
    $profile = "-"
    $bitrate = $globalBitrate
    $channels = "-"
    $sampleRate = "-"
    $frameRate = "-"
    $compression = "-"

    if ($audioStream) {
        $codec = $audioStream.codec_name
        $format = Get-AudioFormat $codec

        $sr = 0
        if ($audioStream.sample_rate) {
            $sr = [int]$audioStream.sample_rate
            $sampleRate = ("{0:N1} kHz" -f ($sr / 1000))
        }

        if ($codec -eq "mp3") {
            if ($sr -le 24000) { $version = "Version 2" } else { $version = "Version 1" }
            $profile = "Layer 3"
        } elseif ($codec -eq "aac") {
            $profile = "LC"
        }

        if ($audioStream.bit_rate) { $bitrate = Format-Bitrate $audioStream.bit_rate }

        if ($audioStream.channels) {
            if ([int]$audioStream.channels -eq 1) { $channels = "1 canal" }
            elseif ([int]$audioStream.channels -eq 2) { $channels = "2 canaux" }
            else { $channels = "$($audioStream.channels) canaux" }
        }

        if ($sr -gt 0) {
            $spf = 1024
            if ($codec -eq "mp3" -and $sr -le 24000) { $spf = 576 }
            elseif ($codec -eq "mp3") { $spf = 1152 }

            $frameRate = ("{0:N3} im/s ({1} SPF)" -f ($sr / $spf), $spf)
        }

        $compression = Get-CompressionMode $codec
    }

    $lines = @()
    $lines += ("G{0}n{0}ral" -f $eacute)
    $lines += Add-Line "Nom complet" $FileInfo.FullName
    $lines += Add-Line "Format" $format
    $lines += Add-Line "Taille du fichier" $fileSize
    $lines += Add-Line ("Dur{0}e" -f $eacute) $duration
    $lines += Add-Line ("Type de d{0}bit global" -f $eacute) "Variable"
    $lines += Add-Line ("D{0}bit global" -f $eacute) $globalBitrate
    $lines += Add-Line ("Biblioth{0}que utilis{1}e" -f $egrave, $eacute) $library
    $lines += ""
    $lines += "Audio"
    $lines += Add-Line "Format" $format
    $lines += Add-Line "Format, Version" $version
    $lines += Add-Line "Format, Profil" $profile
    $lines += Add-Line ("Dur{0}e" -f $eacute) $duration
    $lines += Add-Line ("Type de d{0}bit" -f $eacute) "Variable"
    $lines += Add-Line ("D{0}bit" -f $eacute) $bitrate
    $lines += Add-Line "Canal(aux)" $channels
    $lines += Add-Line "Echantillonnage" $sampleRate
    $lines += Add-Line ("D{0}bit im/s" -f $eacute) $frameRate
    $lines += Add-Line "Mode de compression" $compression
    $lines += Add-Line "Taille du flux" "$fileSize (100%)"

    return $lines -join "`r`n"
}

function Build-VideoText {
    param($Data, [System.IO.FileInfo]$FileInfo)

    $videoStream = $Data.streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
    $audioStream = $Data.streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1

    $fileSize = Format-Size -Bytes $FileInfo.Length
    $duration = Format-Duration $Data.format.duration
    $globalBitrate = Format-Bitrate $Data.format.bit_rate

    $formatName = "-"
    if ($Data.format.format_name) {
        if ($Data.format.format_name -match "mp4") { $formatName = "MPEG-4" }
        elseif ($Data.format.format_long_name) { $formatName = $Data.format.format_long_name }
        else { $formatName = $Data.format.format_name }
    }

    $formatProfile = "-"
    if ($Data.format.format_name -match "mp4") { $formatProfile = "Base Media / Version 2" }

    $codecId = "-"
    if ($Data.format.format_name -match "mp4") { $codecId = "mp42 (isom/mp42)" }

    $encodedDate = "-"
    $taggedDate = "-"
    if ($Data.format.tags.creation_time) {
        $encodedDate = $Data.format.tags.creation_time
        $taggedDate = $Data.format.tags.creation_time
    }

    $lines = @()
    $lines += ("G{0}n{0}ral" -f $eacute)
    $lines += Add-Line "Nom complet" $FileInfo.FullName
    $lines += Add-Line "Format" $formatName
    $lines += Add-Line "Format, Profil" $formatProfile
    $lines += Add-Line "Identifiant du codec" $codecId
    $lines += Add-Line "Taille du fichier" $fileSize
    $lines += Add-Line ("Dur{0}e" -f $eacute) $duration
    $lines += Add-Line ("Type de d{0}bit global" -f $eacute) "Variable"
    $lines += Add-Line ("D{0}bit global" -f $eacute) $globalBitrate

    if ($videoStream) { $lines += Add-Line ("D{0}bit im/s" -f $eacute) (Format-Fps $videoStream.avg_frame_rate) }

    $lines += Add-Line "Date d'encodage" $encodedDate
    $lines += Add-Line "Date de marquage" $taggedDate
    $lines += ""

    if ($videoStream) {
        $vCodec = $videoStream.codec_name
        $vFormat = Get-VideoFormat $vCodec
        $vFormatInfo = Get-VideoFormatInfo $vCodec
        $vBitrate = Format-Bitrate $videoStream.bit_rate
        $vFps = Format-Fps $videoStream.avg_frame_rate

        $width = "-"
        $height = "-"
        if ($videoStream.width) { $width = ("{0:N0} pixels" -f [int]$videoStream.width) }
        if ($videoStream.height) { $height = ("{0:N0} pixels" -f [int]$videoStream.height) }

        $aspect = "-"
        if ($videoStream.display_aspect_ratio) { $aspect = $videoStream.display_aspect_ratio }

        $pixFmt = "-"
        if ($videoStream.pix_fmt) { $pixFmt = $videoStream.pix_fmt }

        $chroma = "-"
        if ($videoStream.pix_fmt -match "420") { $chroma = "4:2:0" }
        elseif ($videoStream.pix_fmt -match "422") { $chroma = "4:2:2" }
        elseif ($videoStream.pix_fmt -match "444") { $chroma = "4:4:4" }

        $bitDepth = "-"
        if ($videoStream.bits_per_raw_sample) { $bitDepth = "$($videoStream.bits_per_raw_sample) bits" }
        elseif ($videoStream.pix_fmt -match "10") { $bitDepth = "10 bits" }
        elseif ($videoStream.pix_fmt -match "yuv|rgb|gray") { $bitDepth = "8 bits" }

        $codecTag = "-"
        if ($videoStream.codec_tag_string) { $codecTag = $videoStream.codec_tag_string }

        $profile = "-"
        if ($videoStream.profile) { $profile = $videoStream.profile }

        $language = "-"
        if ($videoStream.tags.language) { $language = $videoStream.tags.language }

        $vEncoder = "-"
        if ($videoStream.tags.encoder) { $vEncoder = $videoStream.tags.encoder }

        $vEncodedDate = "-"
        if ($videoStream.tags.creation_time) { $vEncodedDate = $videoStream.tags.creation_time }

        $colorRange = "-"
        if ($videoStream.color_range) { $colorRange = $videoStream.color_range }

        $lines += ("Vid{0}o" -f $eacute)
        $lines += Add-Line "ID" "$($videoStream.index)"
        $lines += Add-Line "Format" $vFormat
        $lines += Add-Line "Format/Infos" $vFormatInfo
        $lines += Add-Line "Format, Profil" $profile
        $lines += Add-Line "Identifiant du codec" $codecTag
        $lines += Add-Line "Identifiant du codec/Infos" $vFormatInfo
        $lines += Add-Line ("Dur{0}e" -f $eacute) $duration
        $lines += Add-Line ("D{0}bit" -f $eacute) $vBitrate
        $lines += Add-Line "Largeur" $width
        $lines += Add-Line "Hauteur" $height
        $lines += Add-Line "Facteur de forme l/h" $aspect
        $lines += Add-Line ("Type de d{0}bit im/s" -f $eacute) "Constant"
        $lines += Add-Line ("D{0}bit im/s" -f $eacute) $vFps
        $lines += Add-Line "Espace de couleurs" $pixFmt
        $lines += Add-Line "Sous-echantillonnage de la chrominance" $chroma
        $lines += Add-Line "Profondeur binaire" $bitDepth
        $lines += Add-Line "Bits/(Pixel*Image)" "-"
        $lines += Add-Line "Taille du flux" "-"
        $lines += Add-Line ("Biblioth{0}que utilis{1}e" -f $egrave, $eacute) $vEncoder
        $lines += Add-Line "Langue" $language
        $lines += Add-Line "Date d'encodage" $vEncodedDate
        $lines += Add-Line "Date de marquage" $vEncodedDate
        $lines += Add-Line "Gamme de couleurs" $colorRange
        $lines += Add-Line "Configuration des codecs" $codecTag
        $lines += ""
    }

    if ($audioStream) {
        $aCodec = $audioStream.codec_name
        $aFormat = Get-AudioFormat $aCodec
        $aFormatInfo = Get-AudioFormatInfo $aCodec
        $aBitrate = Format-Bitrate $audioStream.bit_rate

        $channels = "-"
        if ($audioStream.channels) {
            if ([int]$audioStream.channels -eq 1) { $channels = "1 canal" }
            elseif ([int]$audioStream.channels -eq 2) { $channels = "2 canaux" }
            else { $channels = "$($audioStream.channels) canaux" }
        }

        $channelLayout = "-"
        if ($audioStream.channel_layout) { $channelLayout = $audioStream.channel_layout.ToUpperInvariant() }

        $sampleRate = "-"
        $sr = 0
        if ($audioStream.sample_rate) {
            $sr = [int]$audioStream.sample_rate
            $sampleRate = ("{0:N1} kHz" -f ($sr / 1000))
        }

        $frameRate = "-"
        if ($sr -gt 0) {
            $spf = 1024
            if ($aCodec -eq "mp3" -and $sr -le 24000) { $spf = 576 }
            elseif ($aCodec -eq "mp3") { $spf = 1152 }

            $frameRate = ("{0:N3} im/s ({1} SPF)" -f ($sr / $spf), $spf)
        }

        $codecTagA = "-"
        if ($audioStream.codec_tag_string) { $codecTagA = $audioStream.codec_tag_string }

        $languageA = "-"
        if ($audioStream.tags.language) { $languageA = $audioStream.tags.language }

        $aEncodedDate = "-"
        if ($audioStream.tags.creation_time) { $aEncodedDate = $audioStream.tags.creation_time }

        $lines += "Audio"
        $lines += Add-Line "ID" "$($audioStream.index)"
        $lines += Add-Line "Format" $aFormat
        $lines += Add-Line "Format/Infos" $aFormatInfo
        $lines += Add-Line "Identifiant du codec" $codecTagA
        $lines += Add-Line ("Dur{0}e" -f $eacute) $duration
        $lines += Add-Line ("Type de d{0}bit" -f $eacute) "Variable"
        $lines += Add-Line ("D{0}bit" -f $eacute) $aBitrate
        $lines += Add-Line ("D{0}bit maximum" -f $eacute) "-"
        $lines += Add-Line "Canal(aux)" $channels
        $lines += Add-Line "Agencement des canaux" $channelLayout
        $lines += Add-Line "Echantillonnage" $sampleRate
        $lines += Add-Line ("D{0}bit im/s" -f $eacute) $frameRate
        $lines += Add-Line "Mode de compression" (Get-CompressionMode $aCodec)
        $lines += Add-Line "Taille du flux" "-"
        $lines += Add-Line "Langue" $languageA
        $lines += Add-Line "Date d'encodage" $aEncodedDate
        $lines += Add-Line "Date de marquage" $aEncodedDate
    }

    return $lines -join "`r`n"
}

function Show-InfoWindow {
    param(
        [string]$Text,
        [string]$Kind
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "FFActions - Media info"
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.ShowIcon = $false

    if ($Kind -eq "Video") {
        $form.Size = New-Object System.Drawing.Size(760, 640)
        $textSize = New-Object System.Drawing.Size(720, 500)
        $buttonY = 525
        $copyX = 542
        $closeX = 642
    } else {
        $form.Size = New-Object System.Drawing.Size(620, 430)
        $textSize = New-Object System.Drawing.Size(580, 320)
        $buttonY = 345
        $copyX = 402
        $closeX = 502
    }

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ReadOnly = $true
    $textBox.ScrollBars = "Both"
    $textBox.WordWrap = $false
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.Location = New-Object System.Drawing.Point(12, 12)
    $textBox.Size = $textSize
    $textBox.Text = $Text

    $btnCopy = New-Object System.Windows.Forms.Button
    $btnCopy.Text = "Copy"
    $btnCopy.Size = New-Object System.Drawing.Size(90, 30)
    $btnCopy.Location = New-Object System.Drawing.Point($copyX, $buttonY)
    $btnCopy.Add_Click({ [System.Windows.Forms.Clipboard]::SetText($textBox.Text) })

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Size = New-Object System.Drawing.Size(90, 30)
    $btnClose.Location = New-Object System.Drawing.Point($closeX, $buttonY)
    $btnClose.Add_Click({ $form.Close() })

    $form.Controls.Add($textBox)
    $form.Controls.Add($btnCopy)
    $form.Controls.Add($btnClose)
    $form.Add_Shown({
        $textBox.SelectionStart = 0
        $textBox.SelectionLength = 0
        $btnClose.Focus() | Out-Null
    })

    [void]$form.ShowDialog()
}

if ([string]::IsNullOrWhiteSpace($InputFile) -or -not (Test-Path $InputFile)) {
    Show-Error "File not found."
    exit 1
}

$ffprobePath = Resolve-FFProbe
if (-not $ffprobePath) {
    Show-Error "ffprobe not found."
    exit 1
}

try {
    $fileInfo = Get-Item $InputFile
    $data = Invoke-FFProbeJson -FfprobePath $ffprobePath -FilePath $fileInfo.FullName
    $kind = Get-MediaKind -Data $data -FilePath $fileInfo.FullName

    if ($kind -eq "Video") {
        $text = Build-VideoText -Data $data -FileInfo $fileInfo
    } elseif ($kind -eq "Audio") {
        $text = Build-AudioText -Data $data -FileInfo $fileInfo
    } elseif ($kind -eq "Image") {
        $text = Build-ImageText -Data $data -FileInfo $fileInfo
    } else {
        Show-Error "Unsupported media type."
        exit 1
    }

    Show-InfoWindow -Text $text -Kind $kind
}
catch {
    Show-Error $_.Exception.Message
    exit 1
}
