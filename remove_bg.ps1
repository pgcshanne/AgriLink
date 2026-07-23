Add-Type -AssemblyName System.Drawing
$inputFile = 'C:\Users\APRIL\.gemini\antigravity-ide\brain\2605cb00-55a8-4ad7-80c7-94845f661d32\media__1783503820169.jpg'
$outputFile = 'c:\Users\APRIL\Desktop\Agri\agrilink\assets\images\agrilink_logo.png'

$img = [System.Drawing.Bitmap]::FromFile($inputFile)
$bmp = new-object System.Drawing.Bitmap $img

for ($x = 0; $x -lt $bmp.Width; $x++) {
    for ($y = 0; $y -lt $bmp.Height; $y++) {
        $pixel = $bmp.GetPixel($x, $y)
        if ($pixel.R -ge 235 -and $pixel.G -ge 235 -and $pixel.B -ge 235) {
            $bmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
        }
    }
}

$bmp.Save($outputFile, [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
$bmp.Dispose()
Write-Output "Successfully processed image"
