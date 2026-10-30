param(
    [Parameter(Mandatory = $true)][string]$ZXingDir,
    [Parameter(Mandatory = $true)][string]$StbIncludeDir,
    [string]$OutDir = "$PSScriptRoot\..\..\..\.temp\curseen-tools\barcode"
)

$ErrorActionPreference = "Stop"
$example = Join-Path $ZXingDir "example\ZXingReader.cpp"
if (-not (Test-Path $example)) { throw "不是 zxing-cpp 源码目录：$ZXingDir" }
Copy-Item (Join-Path $PSScriptRoot "src\main.cpp") $example -Force

# docs 子目录会 FetchContent 拉 doxygen 主题；构建工具不需要它。
$rootCMake = Join-Path $ZXingDir "CMakeLists.txt"
(Get-Content $rootCMake -Raw) `
    -replace '(?m)^add_subdirectory \(docs\)$', '# add_subdirectory (docs)' `
    | Set-Content $rootCMake -NoNewline

$build = Join-Path $ZXingDir "curseen-build"
New-Item -ItemType Directory -Force -Path $build | Out-Null
Push-Location $build
cmake -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF `
    -DZXING_EXAMPLES=ON -DZXING_WRITERS=OFF -DZXING_C_API=OFF `
    -DZXING_LINK_CPP_STATICALLY=ON `
    -DSTB_IMAGE_INCLUDE_DIR="$StbIncludeDir" $ZXingDir
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "cmake configure 失败" }
cmake --build . --config Release --target ZXingReader -j 8
if ($LASTEXITCODE -ne 0) { Pop-Location; throw "cmake build 失败" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Copy-Item (Join-Path $build "example\Release\ZXingReader.exe") (Join-Path $OutDir "CurSeenBarcode.exe") -Force
Pop-Location
Write-Host "输出：$OutDir"
