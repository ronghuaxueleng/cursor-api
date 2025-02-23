# ���ô���ʱִֹͣ��
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # �ӿ������ٶ�

# ��ɫ�������
function Write-Info  { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Warn  { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red; exit 1 }

# ������ԱȨ��
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $user
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "���Թ���ԱȨ�����д˽ű�"
}

# ������Ϣ
function Show-Help {
    Write-Host @"
�÷�: $(Split-Path $MyInvocation.ScriptName -Leaf) [ѡ��]

ѡ��:
  -NoVS           ����װ Visual Studio Build Tools
  -NoRust         ����װ Rust
  -NoNode         ����װ Node.js
  -Help           ��ʾ�˰�����Ϣ

ʾ��:
  .\setup.ps1
  .\setup.ps1 -NoVS
  .\setup.ps1 -NoRust -NoNode
"@
}

# ��������
param(
    [switch]$NoVS,
    [switch]$NoRust,
    [switch]$NoNode,
    [switch]$Help
)

if ($Help) {
    Show-Help
    exit 0
}

# ��鲢��װ Chocolatey
function Install-Chocolatey {
    Write-Info "��� Chocolatey..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Info "��װ Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        try {
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        catch {
            Write-Error "��װ Chocolatey ʧ��: $_"
        }
        # ˢ�»�������
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

# ��װ Visual Studio Build Tools
function Install-VSBuildTools {
    if ($NoVS) {
        Write-Info "���� Visual Studio Build Tools ��װ"
        return
    }

    Write-Info "��� Visual Studio Build Tools..."
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vsPath)) {
        Write-Info "��װ Visual Studio Build Tools..."
        try {
            # ���ذ�װ����
            $vsInstallerUrl = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
            $vsInstallerPath = "$env:TEMP\vs_BuildTools.exe"
            Invoke-WebRequest -Uri $vsInstallerUrl -OutFile $vsInstallerPath

            # ��װ
            $process = Start-Process -FilePath $vsInstallerPath -ArgumentList `
                "--quiet", "--wait", "--norestart", "--nocache", `
                "--installPath", "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools", `
                "--add", "Microsoft.VisualStudio.Workload.VCTools" `
                -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -ne 0) {
                Write-Error "Visual Studio Build Tools ��װʧ��"
            }

            Remove-Item $vsInstallerPath -Force
        }
        catch {
            Write-Error "��װ Visual Studio Build Tools ʧ��: $_"
        }
    }
    else {
        Write-Info "Visual Studio Build Tools �Ѱ�װ"
    }
}

# ��װ Rust
function Install-Rust {
    if ($NoRust) {
        Write-Info "���� Rust ��װ"
        return
    }

    Write-Info "��� Rust..."
    if (-not (Get-Command rustc -ErrorAction SilentlyContinue)) {
        Write-Info "��װ Rust..."
        try {
            $rustupInit = "$env:TEMP\rustup-init.exe"
            Invoke-WebRequest -Uri "https://win.rustup.rs" -OutFile $rustupInit
            Start-Process -FilePath $rustupInit -ArgumentList "-y" -Wait
            Remove-Item $rustupInit -Force

            # ˢ�»�������
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
        catch {
            Write-Error "��װ Rust ʧ��: $_"
        }
    }

    # ���Ŀ��ƽ̨
    Write-Info "���� Rust Ŀ��ƽ̨..."
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "i686" }
    rustup target add "$arch-pc-windows-msvc"
}

# ��װ��������
function Install-Tools {
    Write-Info "��װ��Ҫ����..."
    
    # ��װ protoc
    if (-not (Get-Command protoc -ErrorAction SilentlyContinue)) {
        Write-Info "��װ Protocol Buffers..."
        choco install -y protoc
    }

    # ��װ Git
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Info "��װ Git..."
        choco install -y git
    }

    # ��װ Node.js
    if (-not $NoNode -and -not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Info "��װ Node.js..."
        choco install -y nodejs
    }

    # ˢ�»�������
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# ������
try {
    Write-Info "��ʼ��װ��Ҫ���..."
    
    Install-Chocolatey
    Install-VSBuildTools
    Install-Rust
    Install-Tools

    Write-Success "��װ��ɣ�"
}
catch {
    Write-Error "��װ�����г��ִ���: $_"
}