# Set this to your local imagemagick path!
$imagemagick = "C:\Program Files\ImageMagick-7.0.10-Q16-HDRI"
$inputFolder = -join($path, "$PSScriptRoot\input\hue");
$outputFolder = -join($path, "$PSScriptRoot\output\hue");

# some helper variables. Don't change those
$convertexe = -join($path, "$imagemagick\convert.exe");
$compositeexe = -join($path, "$imagemagick\composite.exe");
$imagesFolder = -join($path, "$PSScriptRoot\images");
$colorsFolder = -join($path, "$PSScriptRoot\images\colors");

$background = -join($path, "$imagesFolder\background.png");

$aqua = -join($path, "$colorsFolder\aqua.png");
$blue = -join($path, "$colorsFolder\blue.png");
$green = -join($path, "$colorsFolder\green.png");
$orange = -join($path, "$colorsFolder\orange.png");
$pink = -join($path, "$colorsFolder\pink.png");
$pink2 = -join($path, "$colorsFolder\pink2.png");

function init {
    $files = Get-ChildItem "$inputFolder\" -Include "*.png" -Recurse;

    $countFiles = $files.Length
	$i = 0

    ForEach($file in $files){
		$i++

		$percent = $i / $countFiles * 100
		$percent = [math]::round($percent,0)

		Write-Progress -Activity "Converting Images..." -Status "$percent% Complete:" -PercentComplete $percent;

        $filename = $file.FullName
		$basename = $file.BaseName
        $outputName = -join($path, "$outputFolder\$basename");

        New-Item -ItemType Directory -Force -Path $outputName

        # Write-Host $filename

        # resize to 100x100
        $cmd = "& `"$convertexe`" `"$filename`" -resize 100x100 `"$outputFolder\tmp1.png`""
        Invoke-Expression $cmd

        # expand to 144x130
        $cmd = "& `"$convertexe`" `"$outputFolder\tmp1.png`" -background none -gravity north -extent 144x130 `"$outputFolder\tmp2.png`""
        Invoke-Expression $cmd

        # expand to 144
        $cmd = "& `"$convertexe`" `"$outputFolder\tmp2.png`" -background none -gravity center -extent 144x144 `"$outputFolder\tmp3.png`""
        Invoke-Expression $cmd

        # extract alpha channel
        $cmd = "& `"$convertexe`" `"$outputFolder\tmp3.png`" -alpha extract `"$outputFolder\mask.png`""
        Invoke-Expression $cmd

        # generate aqua version
        $cmd = "& `"$compositeexe`" -compose Hue `"$aqua`" `"$outputFolder\tmp3.png`" `"$outputFolder\mask.png`" `"$outputFolder\tmp4.png`""
        Invoke-Expression $cmd
        $cmd = "& `"$compositeexe`" -gravity center `"$outputFolder\tmp4.png`" `"$background`" `"$outputName\$basename aqua.png`""
        Invoke-Expression $cmd

        # generate green version
        $cmd = "& `"$compositeexe`" -compose Hue `"$green`" `"$outputFolder\tmp3.png`" `"$outputFolder\mask.png`" `"$outputFolder\tmp4.png`""
        Invoke-Expression $cmd
        $cmd = "& `"$compositeexe`" -gravity center `"$outputFolder\tmp4.png`" `"$background`" `"$outputName\$basename green.png`""
        Invoke-Expression $cmd

        # generate blue version
        $cmd = "& `"$compositeexe`" -compose Hue `"$blue`" `"$outputFolder\tmp3.png`" `"$outputFolder\mask.png`" `"$outputFolder\tmp4.png`""
        Invoke-Expression $cmd
        $cmd = "& `"$compositeexe`" -gravity center `"$outputFolder\tmp4.png`" `"$background`" `"$outputName\$basename blue.png`""
        Invoke-Expression $cmd

        # generate orange version
        $cmd = "& `"$compositeexe`" -compose Hue `"$orange`" `"$outputFolder\tmp3.png`" `"$outputFolder\mask.png`" `"$outputFolder\tmp4.png`""
        Invoke-Expression $cmd
        $cmd = "& `"$compositeexe`" -gravity center `"$outputFolder\tmp4.png`" `"$background`" `"$outputName\$basename orange.png`""
        Invoke-Expression $cmd

        # generate pink version
        $cmd = "& `"$compositeexe`" -compose Hue `"$pink`" `"$outputFolder\tmp3.png`" `"$outputFolder\mask.png`" `"$outputFolder\tmp4.png`""
        Invoke-Expression $cmd
        $cmd = "& `"$compositeexe`" -gravity center `"$outputFolder\tmp4.png`" `"$background`" `"$outputName\$basename pink.png`""
        Invoke-Expression $cmd

        # generate pink2 version
        $cmd = "& `"$compositeexe`" -compose Hue `"$pink2`" `"$outputFolder\tmp3.png`" `"$outputFolder\mask.png`" `"$outputFolder\tmp4.png`""
        Invoke-Expression $cmd
        $cmd = "& `"$compositeexe`" -gravity center `"$outputFolder\tmp4.png`" `"$background`" `"$outputName\$basename pink2.png`""
        Invoke-Expression $cmd

        

        

    }

    # delete temporary files
    Remove-Item "$outputFolder\tmp1.png"
    Remove-Item "$outputFolder\tmp2.png"
    Remove-Item "$outputFolder\tmp3.png"
    Remove-Item "$outputFolder\tmp4.png"
    Remove-Item "$outputFolder\mask.png"
}

init
