class Config
{

   $ConfigurationArray =
   @(
      "Debug",
      "Release"
   )

   $TargetArray =
   @(
      "cpu",
      "cuda",
      "mkl",
      "arm"
   )

   $PlatformArray =
   @(
      "desktop",
      "android",
      "ios",
      "uwp"
   )

   $ArchitectureArray =
   @(
      32,
      64
   )

   $CudaVersionArray =
   @(
      90,
      91,
      92,
      100,
      101,
      102,
      110
   )

   $CudaVersionHash =
   @{
      90 = "CUDA_PATH_V9_0";
      91 = "CUDA_PATH_V9_1";
      92 = "CUDA_PATH_V9_2";
      100 = "CUDA_PATH_V10_0";
      101 = "CUDA_PATH_V10_1";
      102 = "CUDA_PATH_V10_2";
      110 = "CUDA_PATH_V11_0"
   }

   $VisualStudio = "Visual Studio 15 2017"

   $iOSPlatformArray =
   @(
      "OS64",
      "SIMULATOR64",
      "OS64COMBINED"
   )
   
   static $BuildLibraryWindowsHash = 
   @{
      "DlibDotNet.Native"     = "DlibDotNetNative.dll";
      "DlibDotNet.Native.Dnn" = "DlibDotNetNativeDnn.dll"
   }
   
   static $BuildLibraryLinuxHash = 
   @{
      "DlibDotNet.Native"     = "libDlibDotNetNative.so";
      "DlibDotNet.Native.Dnn" = "libDlibDotNetNativeDnn.so"
   }
   
   static $BuildLibraryOSXHash = 
   @{
      "DlibDotNet.Native"     = "libDlibDotNetNative.dylib";
      "DlibDotNet.Native.Dnn" = "libDlibDotNetNativeDnn.dylib"
   }
   
   static $BuildLibraryIOSHash = 
   @{
      "DlibDotNet.Native"     = "libDlibDotNetNative.a";
      "DlibDotNet.Native.Dnn" = "libDlibDotNetNativeDnn.a"
   }

   [string]   $_Root
   [string]   $_Configuration
   [int]      $_Architecture
   [string]   $_Target
   [string]   $_Platform
   [string]   $_MklDirectory
   [int]      $_CudaVersion
   [string]   $_AndroidABI
   [string]   $_AndroidNativeAPILevel
   [string]   $_iOSPlatform

   #***************************************
   # Arguments
   #  %1: Root directory of DlibDotNet
   #  %2: Build Configuration (Release/Debug)
   #  %3: Target (cpu/cuda/mkl/arm)
   #  %4: Architecture (32/64)
   #  %5: Platform (desktop/android/ios/uwp)
   #  %6: Optional Argument
   #    if Target is cuda, CUDA version if Target is cuda [90/91/92/100/101/102/110]
   #    if Target is mkl and Windows, IntelMKL directory path
   #    if Platform is ios and Target is arm, build platform of iOS (OS64/OS64COMBINED/SIMULATOR64)
   #***************************************
   Config(  [string]$Root,
            [string]$Configuration,
            [string]$Target,
            [int]   $Architecture,
            [string]$Platform,
            [string]$Option
         )
   {
      if ($this.ConfigurationArray.Contains($Configuration) -eq $False)
      {
         $candidate = $this.ConfigurationArray -join "/"
         Write-Host "Error: Specify build configuration [${candidate}]" -ForegroundColor Red
         exit -1
      }

      if ($this.TargetArray.Contains($Target) -eq $False)
      {
         $candidate = $this.TargetArray -join "/"
         Write-Host "Error: Specify Target [${candidate}]" -ForegroundColor Red
         exit -1
      }

      if ($this.ArchitectureArray.Contains($Architecture) -eq $False)
      {
         $candidate = $this.ArchitectureArray -join "/"
         Write-Host "Error: Specify Architecture [${candidate}]" -ForegroundColor Red
         exit -1
      }

      if ($this.PlatformArray.Contains($Platform) -eq $False)
      {
         $candidate = $this.PlatformArray -join "/"
         Write-Host "Error: Specify Platform [${candidate}]" -ForegroundColor Red
         exit -1
      }

      switch ($Target)
      {
         "cuda"
         {
            $this._CudaVersion = [int]$Option
            if ($this.CudaVersionArray.Contains($this._CudaVersion) -ne $True)
            {
               $candidate = $this.CudaVersionArray -join "/"
               Write-Host "Error: Specify CUDA version [${candidate}]" -ForegroundColor Red
               exit -1
            }
         }
         "mkl"
         {
            $this._MklDirectory = $Option
         }
      }

      switch ($Platform)
      {
         "android"
         {
            $decoded = [Config]::Base64Decode($Option)
            $setting = ConvertFrom-Json $decoded
            $this._AndroidABI            = $setting.ANDROID_ABI
            $this._AndroidNativeAPILevel = $setting.ANDROID_NATIVE_API_LEVEL
         }
         "ios"
         {
            if ($Target -eq "arm")
            {
               $this._iOSPlatform = $Option
               if ($this.iOSPlatformArray.Contains($this._iOSPlatform) -ne $True)
               {
                  $candidate = $this.iOSPlatformArray -join "/"
                  Write-Host "Error: Specify iOS platform [${candidate}]" -ForegroundColor Red
                  exit -1
               }
            }
         }
      }

      $this._Root = $Root
      $this._Configuration = $Configuration
      $this._Architecture = $Architecture
      $this._Target = $Target
      $this._Platform = $Platform
   }

   static [string] Base64Encode([string]$text)
   {
      $byte = ([System.Text.Encoding]::Default).GetBytes($text)
      return [Convert]::ToBase64String($byte)
   }

   static [string] Base64Decode([string]$base64)
   {
      $byte = [System.Convert]::FromBase64String($base64)
      return [System.Text.Encoding]::Default.GetString($byte)
   }

   static [hashtable] GetBinaryLibraryWindowsHash()
   {
      return [Config]::BuildLibraryWindowsHash
   }

   static [hashtable] GetBinaryLibraryOSXHash()
   {
      return [Config]::BuildLibraryOSXHash
   }

   static [hashtable] GetBinaryLibraryLinuxHash()
   {
      return [Config]::BuildLibraryLinuxHash
   }

   static [hashtable] GetBinaryLibraryIOSHash()
   {
      return [Config]::BuildLibraryIOSHash
   }

   [string] GetRootDir()
   {
      return $this._Root
   }

   [string] GetDlibRootDir()
   {
      return   Join-Path $this.GetRootDir() src |
               Join-Path -ChildPath dlib
   }

   [string] GetNugetDir()
   {
      return   Join-Path $this.GetRootDir() nuget
   }

   [int] GetArchitecture()
   {
      return $this._Architecture
   }

   [string] GetConfigurationName()
   {
      return $this._Configuration
   }

   [string] GetAndroidABI()
   {
      return $this._AndroidABI
   }

   [string] GetAndroidNativeAPILevel()
   {
      return $this._AndroidNativeAPILevel
   }

   [string] GetIOSPlatform()
   {
      return $this._iOSPlatform
   }

   [string] GetArtifactDirectoryName()
   {
      $target = $this._Target
      $platform = $this._Platform
      $name = ""

      switch ($platform)
      {
         "desktop"
         {
            if ($target -eq "cuda")
            {
               $cudaVersion = $this._CudaVersion
               $name = "${target}-${cudaVersion}"
            }
            else
            {
               $name = $target
            }
         }
         "android"
         {
            $name = $platform
         }
         "ios"
         {
            $name = $platform
         }
         "uwp"
         {
            $name = Join-Path $platform $target
         }
      }

      return $name
   }

   [string] GetOSName()
   {
      $os = ""

      if ($global:IsWindows)
      {
         $os = "win"
      }
      elseif ($global:IsMacOS)
      {
         $os = "osx"
      }
      elseif ($global:IsLinux)
      {
         $os = "linux"
      }
      else
      {
         Write-Host "Error: This plaform is not support" -ForegroundColor Red
         exit -1
      }

      return $os
   }

   [string] GetIntelMklDirectory()
   {
      return [string]$this._MklDirectory
   }

   [string] GetArchitectureName()
   {
      $arch = ""
      $target = $this._Target
      $architecture = $this._Architecture

      if ($target -eq "arm")
      {
         if ($architecture -eq 32)
         {
            $arch = "arm"
         }
         elseif ($architecture -eq 64)
         {
            $arch = "arm64"
         }
      }
      else
      {
         if ($architecture -eq 32)
         {
            $arch = "x86"
         }
         elseif ($architecture -eq 64)
         {
            $arch = "x64"
         }
      }

      return $arch
   }

   [string] GetTarget()
   {
      return $this._Target
   }

   [string] GetPlatform()
   {
      return $this._Platform
   }

   [string] GetBuildDirectoryName([string]$os="")
   {
      if (![string]::IsNullOrEmpty($os))
      {
         $osname = $os
      }
      elseif (![string]::IsNullOrEmpty($env:TARGETRID))
      {
         $osname = $env:TARGETRID
      }
      else
      {
         $osname = $this.GetOSName()
      }
      
      $target = $this._Target
      $platform = $this._Platform
      $architecture = $this.GetArchitectureName()

      if ($target -eq "cuda")
      {
         $version = $this._CudaVersion
         return "build_${osname}_${platform}_cuda-${version}_${architecture}"
      }
      elseif ($target -eq "arm" -and $platform -eq "ios")
      {
         $iosplatform = $this._iOSPlatform.ToLower()
         switch($iosplatform)
         {
            "os64"
            {
               # build_osx_ios_arm_os64
               return "build_${osname}_${platform}_${target}_${iosplatform}"
            }
            "simulator64"
            {
               # build_osx_ios_arm_simulator64
               return "build_${osname}_${platform}_${target}_${iosplatform}"
            }
            "os64combined"
            {
               # build_osx_ios_arm_os64combined
               return "build_${osname}_${platform}_${target}_${iosplatform}"
            }
         }
         
         return "build_${osname}_${platform}_${target}_${architecture}"
      }
      else
      {
         return "build_${osname}_${platform}_${target}_${architecture}"
      }
   }

   [string] GetVisualStudio()
   {
      return $this.VisualStudio
   }

   [string] GetVisualStudioArchitecture()
   {
      $architecture = $this._Architecture
      $target = $this._Target
      
      if ($target -eq "arm")
      {
         if ($architecture -eq 32)
         {
            return "ARM"
         }
         elseif ($architecture -eq 64)
         {
            return "ARM64"
         }
      }
      else
      {
         if ($architecture -eq 32)
         {
            return "Win32"
         }
         elseif ($architecture -eq 64)
         {
            return "x64"
         }
      }

      Write-Host "${architecture} and ${target} do not support" -ForegroundColor Red
      exit -1
   }

   [string] GetCUDAPath()
   {
      # CUDA_PATH_V10_0=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.0
      # CUDA_PATH_V10_1=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1
      # CUDA_PATH_V10_2=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.2
      # CUDA_PATH_V11_0=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v11.0
      # CUDA_PATH_V9_0=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.0
      # CUDA_PATH_V9_1=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.1
      # CUDA_PATH_V9_2=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v9.2
      $version = $this.CudaVersionHash[$this._CudaVersion]      
      return [environment]::GetEnvironmentVariable($version, 'Machine')
   }

   [string] GetAVXINSTRUCTIONS()
   {
      return "ON"
   }

   [string] GetSSE4INSTRUCTIONS()
   {
      return "ON"
   }

   [string] GetSSE2INSTRUCTIONS()
   {
      return "OFF"
   }

}

function ConfigCPU([Config]$Config)
{
   if ($IsWindows)
   {
      $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
      $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
      $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()

      cmake -G $Config.GetVisualStudio() -A $Config.GetVisualStudioArchitecture() -T host=x64 `
            -D DLIB_USE_CUDA=OFF `
            -D DLIB_USE_LAPACK=OFF `
            -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
            -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
            -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
            ..
   }
   else
   {
      $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
      $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
      $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()

      $arch_type = $Config.GetArchitecture()
      cmake -D ARCH_TYPE="$arch_type" `
            -D DLIB_USE_CUDA=OFF `
            -D DLIB_USE_LAPACK=OFF `
            -D mkl_include_dir="" `
            -D mkl_intel="" `
            -D mkl_rt="" `
            -D mkl_thread="" `
            -D mkl_pthread="" `
            -D LIBPNG_IS_GOOD=OFF `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
            -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
            -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
            ..
   }
}

function ConfigCUDA([Config]$Config)
{
   if ($IsWindows)
   {
      $cudaPath = $Config.GetCUDAPath()
      if (!(Test-Path $cudaPath))
      {
         Write-Host "Error: '${cudaPath}' does not found" -ForegroundColor Red
         exit -1
      }

      $env:CUDA_PATH="${cudaPath}"
      $env:PATH="$env:CUDA_PATH\bin;$env:CUDA_PATH\libnvvp;$ENV:PATH"
      Write-Host "Info: CUDA_PATH: ${env:CUDA_PATH}" -ForegroundColor Green

      $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
      $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
      $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()

      cmake -G $Config.GetVisualStudio() -A $Config.GetVisualStudioArchitecture() -T host=x64 `
            -D DLIB_USE_CUDA=ON `
            -D DLIB_USE_BLAS=OFF `
            -D DLIB_USE_LAPACK=OFF `
            -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
            -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
            -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
            ..
   }
   else
   {
      $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
      $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
      $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()

      cmake -D DLIB_USE_CUDA=ON `
            -D DLIB_USE_BLAS=OFF `
            -D DLIB_USE_LAPACK=OFF `
            -D LIBPNG_IS_GOOD=OFF  `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
            -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
            -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
            ..
   }
}

function ConfigMKL([Config]$Config)
{
   if ($IsWindows)
   {
      $intelMklDirectory = $Config.GetIntelMklDirectory()
      if (!$intelMklDirectory) {
         Write-Host "Error: Specify Intel MKL directory" -ForegroundColor Red
         exit -1
      }

      if ((Test-Path $intelMklDirectory) -eq $False) {
         Write-Host "Error: Specified IntelMKL directory '${intelMklDirectory}' does not found" -ForegroundColor Red
         exit -1
      }
 
      $architecture = $Config.GetArchitecture()
      $architectureDir = ""
      switch ($architecture)
      {
         32
         { 
            $architectureDir = "ia32_win"
            $MKL_INCLUDE_DIR = Join-Path $intelMklDirectory "mkl/include"
            $LIBIOMP5MD_LIB = Join-Path $intelMklDirectory "compiler/lib/${architectureDir}/libiomp5md.lib"
            $MKLCOREDLL_LIB = Join-Path $intelMklDirectory "mkl/lib/${architectureDir}/mkl_core_dll.lib"
            $MKLINTELC_LIB = Join-Path $intelMklDirectory "mkl/lib/${architectureDir}/mkl_intel_c.lib"            
            $MKLINTELTHREADDLL_LIB = Join-Path $intelMklDirectory "mkl/lib/${architectureDir}/mkl_intel_thread_dll.lib"
      
            if ((Test-Path $LIBIOMP5MD_LIB) -eq $False) {
               Write-Host "Error: ${LIBIOMP5MD_LIB} does not found" -ForegroundColor Red
               exit -1
            }
            if ((Test-Path $MKLCOREDLL_LIB) -eq $False) {
               Write-Host "Error: ${MKLCOREDLL_LIB} does not found" -ForegroundColor Red
               exit -1
            }
            if ((Test-Path $MKLINTELC_LIB) -eq $False) {
               Write-Host "Error: ${MKLINTELC_LIB} does not found" -ForegroundColor Red
               exit -1
            }
            if ((Test-Path $MKLINTELTHREADDLL_LIB) -eq $False) {
               Write-Host "Error: ${MKLINTELTHREADDLL_LIB} does not found" -ForegroundColor Red
               exit -1
            }
      
            $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
            $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
            $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()

            cmake -G $Config.GetVisualStudio() -A $Config.GetVisualStudioArchitecture() -T host=x64 `
                  -D DLIB_USE_CUDA=OFF `
                  -D DLIB_USE_BLAS=ON `
                  -D DLIB_USE_LAPACK=OFF `
                  -D mkl_include_dir="${MKL_INCLUDE_DIR}" `
                  -D BLAS_libiomp5md_LIBRARY="${LIBIOMP5MD_LIB}" `
                  -D BLAS_mkl_core_dll_LIBRARY="${MKLCOREDLL_LIB}" `
                  -D BLAS_mkl_intel_c_dll_LIBRARY="${MKLINTELC_LIB}" `
                  -D BLAS_mkl_intel_thread_dll_LIBRARY="${MKLINTELTHREADDLL_LIB}" `
                  -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
                  -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
                  -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
                  ..
         }
         64
         { 
            $architectureDir = "intel64_win"
            $MKL_INCLUDE_DIR = Join-Path $intelMklDirectory "mkl/include"
            $LIBIOMP5MD_LIB = Join-Path $intelMklDirectory "compiler/lib/${architectureDir}/libiomp5md.lib"
            $MKLCOREDLL_LIB = Join-Path $intelMklDirectory "mkl/lib/${architectureDir}/mkl_core_dll.lib"
            $MKLINTELLP64DLL_LIB = Join-Path $intelMklDirectory "mkl/lib/${architectureDir}/mkl_intel_lp64_dll.lib"
            $MKLINTELTHREADDLL_LIB = Join-Path $intelMklDirectory "mkl/lib/${architectureDir}/mkl_intel_thread_dll.lib"
      
            if ((Test-Path $LIBIOMP5MD_LIB) -eq $False) {
               Write-Host "Error: ${LIBIOMP5MD_LIB} does not found" -ForegroundColor Red
               exit -1
            }
            if ((Test-Path $MKLCOREDLL_LIB) -eq $False) {
               Write-Host "Error: ${MKLCOREDLL_LIB} does not found" -ForegroundColor Red
               exit -1
            }
            if ((Test-Path $MKLINTELLP64DLL_LIB) -eq $False) {
               Write-Host "Error: ${MKLINTELLP64DLL_LIB} does not found" -ForegroundColor Red
               exit -1
            }
            if ((Test-Path $MKLINTELTHREADDLL_LIB) -eq $False) {
               Write-Host "Error: ${MKLINTELTHREADDLL_LIB} does not found" -ForegroundColor Red
               exit -1
            }

            $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
            $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
            $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()
      
            cmake -G $Config.GetVisualStudio() -A $Config.GetVisualStudioArchitecture() -T host=x64 `
                  -D DLIB_USE_CUDA=OFF `
                  -D DLIB_USE_BLAS=ON `
                  -D DLIB_USE_LAPACK=OFF `
                  -D mkl_include_dir="${MKL_INCLUDE_DIR}" `
                  -D BLAS_libiomp5md_LIBRARY="${LIBIOMP5MD_LIB}" `
                  -D BLAS_mkl_core_dll_LIBRARY="${MKLCOREDLL_LIB}" `
                  -D BLAS_mkl_intel_lp64_dll_LIBRARY="${MKLINTELLP64DLL_LIB}" `
                  -D BLAS_mkl_intel_thread_dll_LIBRARY="${MKLINTELTHREADDLL_LIB}" `
                  -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
                  -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
                  -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
                  ..
         }
      }
   }
   else
   {
      $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
      $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
      $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()
      
      $arch_type = $Config.GetArchitecture()
      cmake -D ARCH_TYPE="$arch_type" `
            -D DLIB_USE_CUDA=OFF `
            -D DLIB_USE_BLAS=ON `
            -D DLIB_USE_LAPACK=OFF `
            -D LIBPNG_IS_GOOD=OFF `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
            -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
            -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
            ..
   }
}

function ConfigARM([Config]$Config)
{
   if ($Config.GetArchitecture() -eq 32)
   {
      cmake -D DLIB_USE_CUDA=OFF `
            -D ENABLE_NEON=ON `
            -D DLIB_USE_BLAS=ON `
            -D DLIB_USE_LAPACK=OFF `
            -D CMAKE_C_COMPILER="/usr/bin/arm-linux-gnueabihf-gcc" `
            -D CMAKE_CXX_COMPILER="/usr/bin/arm-linux-gnueabihf-g++" `
            -D LIBPNG_IS_GOOD=OFF `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            ..
   }
   else
   {
      cmake -D DLIB_USE_CUDA=OFF `
            -D ENABLE_NEON=ON `
            -D DLIB_USE_BLAS=ON `
            -D DLIB_USE_LAPACK=OFF `
            -D CMAKE_C_COMPILER="/usr/bin/aarch64-linux-gnu-gcc" `
            -D CMAKE_CXX_COMPILER="/usr/bin/aarch64-linux-gnu-g++" `
            -D LIBPNG_IS_GOOD=OFF `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            ..
   }
}

function ConfigUWP([Config]$Config)
{
   if ($IsWindows)
   {
      # apply patch
      $patch = "uwp.patch"
      $nugetDir = $Config.GetNugetDir()
      $dlibDir = $Config.GetDlibRootDir()
      $patchFullPath = Join-Path $nugetDir $patch
      $current = Get-Location
      Set-Location -Path $dlibDir
      Write-Host "Apply ${patch} to ${dlibDir}" -ForegroundColor Yellow
      Write-Host "git apply ""${patchFullPath}""" -ForegroundColor Yellow
      git apply """${patchFullPath}"""
      Set-Location -Path $current

      if ($Config.GetTarget() -eq "arm")
      {
         cmake -G $Config.GetVisualStudio() -A $Config.GetVisualStudioArchitecture() -T host=x64 `
               -D CMAKE_SYSTEM_NAME=WindowsStore `
               -D USE_AVX_INSTRUCTIONS:BOOL=OFF `
               -D USE_SSE2_INSTRUCTIONS:BOOL=OFF `
               -D USE_SSE4_INSTRUCTIONS:BOOL=OFF `
               -D CMAKE_SYSTEM_VERSION=10.0 `
               -D WINAPI_FAMILY=WINAPI_FAMILY_APP `
               -D _WINDLL=ON `
               -D _WIN32_UNIVERSAL_APP=ON `
               -D DLIB_USE_CUDA=OFF `
               -D DLIB_USE_BLAS=OFF `
               -D DLIB_USE_LAPACK=OFF `
               -D DLIB_NO_GUI_SUPPORT=ON `
               ..
      }
      else
      {
         $USE_AVX_INSTRUCTIONS  = $Config.GetAVXINSTRUCTIONS()
         $USE_SSE4_INSTRUCTIONS = $Config.GetSSE4INSTRUCTIONS()
         $USE_SSE2_INSTRUCTIONS = $Config.GetSSE2INSTRUCTIONS()
         
         cmake -G $Config.GetVisualStudio() -A $Config.GetVisualStudioArchitecture() -T host=x64 `
               -D CMAKE_SYSTEM_NAME=WindowsStore `
               -D CMAKE_SYSTEM_VERSION=10.0 `
               -D WINAPI_FAMILY=WINAPI_FAMILY_APP `
               -D _WINDLL=ON `
               -D _WIN32_UNIVERSAL_APP=ON `
               -D DLIB_USE_CUDA=OFF `
               -D DLIB_USE_BLAS=OFF `
               -D DLIB_USE_LAPACK=OFF `
               -D DLIB_NO_GUI_SUPPORT=ON `
               -D USE_AVX_INSTRUCTIONS=$USE_AVX_INSTRUCTIONS `
               -D USE_SSE4_INSTRUCTIONS=$USE_SSE4_INSTRUCTIONS `
               -D USE_SSE2_INSTRUCTIONS=$USE_SSE2_INSTRUCTIONS `
               ..
      }

   }
}

function ConfigANDROID([Config]$Config)
{
   if ($IsLinux)
   {
      if (!${env:ANDROID_NDK_HOME})
      {
         Write-Host "Error: Specify ANDROID_NDK_HOME environmental value" -ForegroundColor Red
         exit -1
      }

      if ((Test-Path "${env:ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake") -eq $False)
      {
         Write-Host "Error: Specified Android NDK toolchain '${env:ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake' does not found" -ForegroundColor Red
         exit -1
      }

      $level = $Config.GetAndroidNativeAPILevel()
      $abi = $Config.GetAndroidABI()

      cmake -G Ninja `
            -D CMAKE_TOOLCHAIN_FILE=${env:ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake `
            -D ANDROID_NDK=${env:ANDROID_NDK_HOME} `
            -D CMAKE_MAKE_PROGRAM=ninja `
            -D ANDROID_NATIVE_API_LEVEL=${level} `
            -D ANDROID_ABI=${abi} `
            -D ANDROID_TOOLCHAIN=clang `
            -D DLIB_USE_CUDA=OFF `
            -D DLIB_USE_BLAS=OFF `
            -D DLIB_USE_LAPACK=OFF `
            -D mkl_include_dir="" `
            -D mkl_intel="" `
            -D mkl_rt="" `
            -D mkl_thread="" `
            -D mkl_pthread="" `
            -D LIBPNG_IS_GOOD=OFF `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            -D DLIB_NO_GUI_SUPPORT=ON `
            ..
   }
   else
   {      
      Write-Host "Error: This platform can not build android binary" -ForegroundColor Red
      exit -1
   }
}

function ConfigIOS([Config]$Config)
{
   if ($IsMacOS)
   {
      # Requirement: CMake 3.14 or higher
      $iosplatform = $Config.GetIOSPlatform().ToLower()
      $iosArchitectures = ""
      $combined = 0
      switch($iosplatform)
      {
         "os64"
         {
            $iosArchitectures = "arm64"
         }
         "simulator64"
         {
            $iosArchitectures = "x86_64"
         }
         "os64combined"
         {
            $iosArchitectures = "arm64;x86_64"
            $combined = 1
         }
      }
      cmake -G Xcode `
            -D CMAKE_TOOLCHAIN_FILE=../../ios-cmake/ios.toolchain.cmake `
            -D CMAKE_SYSTEM_NAME=iOS `
            -D CMAKE_OSX_ARCHITECTURES=$iosArchitectures `
            -D CMAKE_IOS_INSTALL_COMBINED=$combined `
            -D DLIB_USE_CUDA=OFF `
            -D DLIB_USE_BLAS=OFF `
            -D DLIB_USE_LAPACK=OFF `
            -D mkl_include_dir="" `
            -D mkl_intel="" `
            -D mkl_rt="" `
            -D mkl_thread="" `
            -D mkl_pthread="" `
            -D LIBPNG_IS_GOOD=OFF `
            -D PNG_FOUND=OFF `
            -D PNG_LIBRARY_RELEASE="" `
            -D PNG_LIBRARY_DEBUG="" `
            -D PNG_PNG_INCLUDE_DIR="" `
            -D DLIB_NO_GUI_SUPPORT=ON `
            ..
      # cmake -G Xcode `
      #       -D CMAKE_TOOLCHAIN_FILE=../../ios-cmake/ios.toolchain.cmake `
      #       -D PLATFORM=$iOSPlatform `
      #       -D DLIB_USE_CUDA=OFF `
      #       -D DLIB_USE_BLAS=OFF `
      #       -D DLIB_USE_LAPACK=OFF `
      #       -D mkl_include_dir="" `
      #       -D mkl_intel="" `
      #       -D mkl_rt="" `
      #       -D mkl_thread="" `
      #       -D mkl_pthread="" `
      #       -D LIBPNG_IS_GOOD=OFF `
      #       -D PNG_FOUND=OFF `
      #       -D PNG_LIBRARY_RELEASE="" `
      #       -D PNG_LIBRARY_DEBUG="" `
      #       -D PNG_PNG_INCLUDE_DIR="" `
      #       -D DLIB_NO_GUI_SUPPORT=ON `
      #       ..
   }
   else
   {      
      Write-Host "Error: This platform can not build iOS binary" -ForegroundColor Red
      exit -1
   }
}

function Reset-Dlib-Modification([Config]$Config, [string]$currentDir)
{
   $dlibDir = $Config.GetDlibRootDir()
   Set-Location -Path $dlibDir
   Write-Host "Reset modification of ${dlibDir}" -ForegroundColor Yellow
   git checkout .
   Set-Location -Path $currentDir
}

function Build([Config]$Config)
{
   $Current = Get-Location

   $Output = $Config.GetBuildDirectoryName("")
   if ((Test-Path $Output) -eq $False)
   {
      New-Item $Output -ItemType Directory
   }

   Set-Location -Path $Output

   $Target = $Config.GetTarget()
   $Platform = $Config.GetPlatform()

   # revert dlib
   Reset-Dlib-Modification $Config (Join-Path $Current $Output)

   switch ($Platform)
   {
      "desktop"
      {
         switch ($Target)
         {
            "cpu"
            {
               ConfigCPU $Config
            }
            "mkl"
            {
               ConfigMKL $Config
            }
            "cuda"
            {
               ConfigCUDA $Config
            }
            "arm"
            {
               ConfigARM $Config
            }
         }
      }
      "android"
      {
         ConfigANDROID $Config
      }
      "ios"
      {
         ConfigIOS $Config
      }
      "uwp"
      {
         ConfigUWP $Config
      }
   }

   cmake --build . --config $Config.GetConfigurationName()

   # Move to Root directory
   Set-Location -Path $Current
}

function CopyToArtifact()
{
   Param([string]$srcDir, [string]$build, [string]$libraryName, [string]$dstDir, [string]$rid, [string]$configuration="")

   if ($configuration)
   {
      $binary = Join-Path ${srcDir} ${build}  | `
               Join-Path -ChildPath ${configuration} | `
               Join-Path -ChildPath ${libraryName}
   }
   else
   {
      $binary = Join-Path ${srcDir} ${build}  | `
               Join-Path -ChildPath ${libraryName}
   }

   $output = Join-Path $dstDir runtimes | `
            Join-Path -ChildPath ${rid} | `
            Join-Path -ChildPath native | `
            Join-Path -ChildPath $libraryName

   Write-Host "Copy ${libraryName} to ${output}" -ForegroundColor Green
   Copy-Item ${binary} ${output}
}

function CopyiOSToArtifact()
{
   Param([string]$srcDir, [string]$build, [string]$libraryName, [string]$dstDir, [string]$platform, [string]$configuration)

   $binary = Join-Path ${srcDir} ${build}  | `
            Join-Path -ChildPath ${configuration}  | `
            Join-Path -ChildPath ${libraryName}

   $output = Join-Path $dstDir native | `
            Join-Path -ChildPath $platform | `
            Join-Path -ChildPath $libraryName

   Write-Host "Copy ${libraryName} to ${output}" -ForegroundColor Green
   Copy-Item ${binary} ${output}
}