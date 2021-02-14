# Set this to your local imagemagick path!
$imagemagick = "C:\Program Files\ImageMagick-7.0.10-Q16-HDRI"
$inputFolder = -join($path, "$PSScriptRoot\input\overlay");
$outputFolder = -join($path, "$PSScriptRoot\output\overlay");

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

    # create different backgrounds
    if(!(Test-Path "$imagesFolder\bluebg.png" -PathType Leaf)){
        # create blue background
        $cmd = "& `"$convertexe`" -size 144x144 xc:#0b1b38 `"$imagesFolder\bluebg.png`""
        Invoke-Expression $cmd
    }

    if(!(Test-Path "$imagesFolder\redbg.png" -PathType Leaf)){
        # create red background
        $cmd = "& `"$convertexe`" -size 144x144 xc:#9e0000 `"$imagesFolder\redbg.png`""
        Invoke-Expression $cmd
    }

    if(!(Test-Path "$imagesFolder\greenbg.png" -PathType Leaf)){
        # create green background
        $cmd = "& `"$convertexe`" -size 144x144 xc:#00c605 `"$imagesFolder\greenbg.png`""
        Invoke-Expression $cmd
    }

    if(!(Test-Path "$imagesFolder\orangebg.png" -PathType Leaf)){
        # create orange background
        $cmd = "& `"$convertexe`" -size 144x144 xc:#d46500 `"$imagesFolder\orangebg.png`""
        Invoke-Expression $cmd
    }

    ForEach($file in $files){
		$i++

		$percent = $i / $countFiles * 100
		$percent = [math]::round($percent,0)

		Write-Progress -Id 0 -Activity "Converting Images..." -Status "Image $i / $countFiles" -PercentComplete $percent;

        $filename = $file.FullName
		$basename = $file.BaseName
        $outputName = -join($path, "$outputFolder\$basename");

        New-Item -ItemType Directory -Force -Path $outputName > $null


        $preparedImage = prepareImage -filename $filename
        $mask = extractAlpha -image $preparedImage
        generateColorImages -basename $basename
    }

    # delete temporary files
    Remove-Item "$outputFolder\tmp1.png" > $null
    Remove-Item "$outputFolder\tmp2.png" > $null
    Remove-Item "$outputFolder\tmp3.png" > $null
    # Remove-Item "$outputFolder\tmp4.png"
    Remove-Item "$outputFolder\mask.png" > $null
}

function prepareImage($filename){
    # resize to 100x100
    $cmd = "& `"$convertexe`" `"$filename`" -resize 100x100 -depth 8 -define png:color-type=6 -define png:bit-depth=8 `"png32:$outputFolder\tmp1.png`""
    Invoke-Expression $cmd

    # expand to 144x130
    $cmd = "& `"$convertexe`" `"$outputFolder\tmp1.png`" -background none -gravity north -extent 144x130 `"$outputFolder\tmp2.png`""
    Invoke-Expression $cmd

    # expand to 144
    $cmd = "& `"$convertexe`" `"$outputFolder\tmp2.png`" -background none -gravity center -extent 144x144 `"$outputFolder\tmp3.png`""
    Invoke-Expression $cmd

    return "$outputFolder\tmp3.png"
}

function extractAlpha($image){
    # extract alpha channel
    $cmd = "& `"$convertexe`" `"$image`" -alpha extract `"$outputFolder\mask.png`""
    Invoke-Expression $cmd

    return "$outputFolder\mask.png"
}

function generateImageBackground($basename, $color, $bgcolor){
    # generate version
    $colorPath = -join($path, "$colorsFolder\$color.png");
    $backgroundPath = -join("$imagesFolder\", $bgcolor, "bg.png")

    # blue background
    $cmd = "& `"$compositeexe`" -gravity center `"$colorPath`" `"$backgroundPath`" `"$outputFolder\mask.png`" `"$outputName\$basename $color.png`""
    Invoke-Expression $cmd

    generateAnimation -basename $basename -color $color -bgcolor $bgcolor -bg2color "red" > $null
    generateAnimation -basename $basename -color $color -bgcolor $bgcolor -bg2color "green" > $null
    generateAnimation -basename $basename -color $color -bgcolor $bgcolor -bg2color "orange" > $null

    return "$outputName\$basename $color.png"
}

function generateAnimation($basename, $color, $bgcolor, $bg2color){
    # generate version
    $colorPath = -join($path, "$colorsFolder\$color.png");
    $backgroundPath = -join("$imagesFolder\", $bgcolor, "bg.png")
    $background2Path = -join("$imagesFolder\", $bg2color, "bg.png")

    New-Item -ItemType Directory -Force -Path "$outputName\animated" > $null
    New-Item -ItemType Directory -Force -Path "$outputName\animated\$color" > $null

    # first background
    $cmd = "& `"$compositeexe`" -gravity center `"$colorPath`" `"$backgroundPath`" `"$outputFolder\mask.png`" `"$outputFolder\bg1.png`""
    Invoke-Expression $cmd

    # second background
    $cmd = "& `"$compositeexe`" -gravity center `"$colorPath`" `"$background2Path`" `"$outputFolder\mask.png`" `"$outputFolder\bg2.png`""
    Invoke-Expression $cmd

    # generate gif
    $cmd = "& `"$convertexe`" -delay 1/2 -size 144x144 `"$outputFolder\bg2.png`" `"$outputFolder\bg1.png`" -loop 0 `"$outputName\animated\$color\$basename $bg2color.gif`""
    Invoke-Expression $cmd

    Remove-Item "$outputFolder\bg1.png" > $null
    Remove-Item "$outputFolder\bg2.png" > $null

    return "$outputName\animated\$color\$basename $bg2color.gif"
}

function generateColorImages($basename){
    # Write-Progress -Id 1 -Activity $basename -Status 'Progress' -PercentComplete $j -CurrentOperation InnerLoop

    $colors = @("aqua", "green", "blue", "orange", "pink", "pink2")

    $colorsCount = $colors.Length
    $j = 0

    ForEach($color in $colors){
        $j++

        $p2 = $j / $colorsCount * 100
		$p2 = [math]::round($p2,0)

        Write-Progress -Id 1 -ParentId 0 -Activity "Generating $basename $color" -PercentComplete $p2
        generateImageBackground -basename $basename -color $color -bgcolor "blue" > $null
    }
}

init
