param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [Parameter(Mandatory = $true)][string]$ModelsDir,
    [string]$OutDir = "$PSScriptRoot\..\..\..\.temp\curseen-tools\ocr"
)

$ErrorActionPreference = "Stop"
$source = Join-Path $PSScriptRoot "src\main.cpp"
$projectMain = Join-Path $ProjectDir "src\main.cpp"
if (-not (Test-Path $projectMain)) { throw "不是 RapidOcrOnnx 工程目录：$ProjectDir" }
Copy-Item $source $projectMain -Force

$build = Join-Path $ProjectDir "curseen-build"
New-Item -ItemType Directory -Force -Path $build | Out-Null
Push-Location $build
cmake -G "Visual Studio 17 2022" -A x64 `
    -DOpenCV_ARCH=x64 -DOpenCV_RUNTIME=vc16 -DOpenCV_STATIC=ON `
    -DCMAKE_INSTALL_PREFIX=install -DCMAKE_BUILD_TYPE=Release `
    -DOCR_OUTPUT=BIN -DOCR_BUILD_CRT=True -DOCR_ONNX=CPU $ProjectDir
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "cmake configure 失败" }
cmake --build . --config Release -j 8
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "cmake build 失败" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Copy-Item (Join-Path $build "Release\RapidOcrOnnx.exe") (Join-Path $OutDir "CurSeenOcr.exe") -Force
Get-ChildItem $ModelsDir -File | Where-Object {
    $_.Name -in @(
        "ch_PP-OCRv4_det_mobile.onnx",
        "ch_PP-OCRv4_rec_mobile.onnx",
        "ch_ppocr_mobile_v2.0_cls_mobile.onnx",
        "ppocr_keys_v1.txt"
    )
} | Copy-Item -Destination $OutDir -Force
Pop-Location
Write-Host "输出：$OutDir"
