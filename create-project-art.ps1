Add-Type -AssemblyName System.Drawing

function New-Canvas([int]$width, [int]$height) {
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function Save-TokenLogo {
    $canvas = New-Canvas 200 200
    $bitmap = $canvas.Bitmap
    $graphics = $canvas.Graphics
    $background = [System.Drawing.Color]::FromArgb(10, 20, 31)
    $green = [System.Drawing.Color]::FromArgb(37, 181, 139)
    $blue = [System.Drawing.Color]::FromArgb(70, 124, 255)
    $white = [System.Drawing.Color]::White
    $graphics.Clear($background)
    $graphics.FillEllipse([System.Drawing.SolidBrush]::new($green), 18, 18, 164, 164)
    $graphics.FillEllipse([System.Drawing.SolidBrush]::new($blue), 31, 31, 138, 138)
    $graphics.FillEllipse([System.Drawing.SolidBrush]::new($background), 44, 44, 112, 112)
    $pen = New-Object System.Drawing.Pen($green, 9)
    $graphics.DrawLine($pen, 72, 67, 128, 67)
    $graphics.DrawLine($pen, 100, 67, 100, 132)
    $graphics.DrawArc($pen, 73, 82, 54, 48, 0, 180)
    $graphics.DrawLine($pen, 76, 143, 124, 143)
    $font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString('ACADEMIC', $font, [System.Drawing.SolidBrush]::new($white), 100, 164, $format)
    $bitmap.Save((Join-Path $PSScriptRoot 'token-logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Save((Join-Path $PSScriptRoot 'logo.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose()
}

function Save-ProjectBanner {
    $canvas = New-Canvas 1360 430
    $bitmap = $canvas.Bitmap
    $graphics = $canvas.Graphics
    $background = [System.Drawing.Color]::FromArgb(10, 20, 31)
    $green = [System.Drawing.Color]::FromArgb(37, 181, 139)
    $blue = [System.Drawing.Color]::FromArgb(70, 124, 255)
    $muted = [System.Drawing.Color]::FromArgb(185, 202, 214)
    $graphics.Clear($background)
    $graphics.FillRectangle([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18, 42, 58)), 0, 0, 1360, 430)
    $graphics.FillEllipse([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(25, 73, 75)), 980, -180, 520, 520)
    $graphics.FillEllipse([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(25, 50, 96)), 1080, 130, 350, 350)
    $pen = New-Object System.Drawing.Pen($green, 14)
    $graphics.DrawEllipse($pen, 75, 84, 230, 230)
    $graphics.DrawLine($pen, 135, 143, 245, 143)
    $graphics.DrawLine($pen, 190, 143, 190, 255)
    $graphics.DrawArc($pen, 135, 168, 110, 92, 0, 180)
    $graphics.DrawLine($pen, 142, 276, 238, 276)
    $title = New-Object System.Drawing.Font('Segoe UI', 42, [System.Drawing.FontStyle]::Bold)
    $subtitle = New-Object System.Drawing.Font('Segoe UI', 23, [System.Drawing.FontStyle]::Regular)
    $label = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
    $graphics.DrawString('TetherUSD Academic', $title, [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White), 370, 105)
    $graphics.DrawString('TRC-20 ecosystem demonstration on TRON', $subtitle, [System.Drawing.SolidBrush]::new($muted), 375, 175)
    $graphics.DrawString('EDUCATIONAL PROJECT  |  NOT AFFILIATED WITH TETHER LTD.', $label, [System.Drawing.SolidBrush]::new($green), 375, 245)
    $graphics.DrawString('Token infrastructure - DEX liquidity - Wallet integration', $subtitle, [System.Drawing.SolidBrush]::new($muted), 375, 295)
    $bitmap.Save((Join-Path $PSScriptRoot 'project-banner.png'), [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose()
}

Save-TokenLogo
Save-ProjectBanner
Write-Output 'Created token-logo.png and project-banner.png'
