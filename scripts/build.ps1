# ��ɫ�������
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red; exit 1 }

# ����Ҫ�Ĺ���
function Test-Requirements {
  $tools = @("cargo", "protoc", "npm", "node")
  $missing = @()

  foreach ($tool in $tools) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
      $missing += $tool
    }
  }

  if ($missing.Count -gt 0) {
    Write-Error "ȱ�ٱ�Ҫ����: $($missing -join ', ')"
  }
}

# �� Test-Requirements ����������º���
function Initialize-VSEnvironment {
    Write-Info "���ڳ�ʼ�� Visual Studio ����..."

    # ֱ��ʹ����֪�� vcvarsall.bat ·��
    $vcvarsallPath = "E:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"

    if (-not (Test-Path $vcvarsallPath)) {
        Write-Error "δ�ҵ� vcvarsall.bat: $vcvarsallPath"
        return
    }

    Write-Info "ʹ�� vcvarsall.bat ·��: $vcvarsallPath"

    # ��ȡ��������
    $archArg = "x64"
    $command = "`"$vcvarsallPath`" $archArg && set"

    try {
        $output = cmd /c "$command" 2>&1

        # ��������Ƿ�ɹ�ִ��
        if ($LASTEXITCODE -ne 0) {
            Write-Error "vcvarsall.bat ִ��ʧ�ܣ��˳���: $LASTEXITCODE"
            return
        }

        # ���µ�ǰ PowerShell �Ự�Ļ�������
        foreach ($line in $output) {
            if ($line -match "^([^=]+)=(.*)$") {
                $name = $matches[1]
                $value = $matches[2]
                if (![string]::IsNullOrEmpty($name)) {
                    Set-Item -Path "env:$name" -Value $value -ErrorAction SilentlyContinue
                }
            }
        }

        Write-Info "Visual Studio ������ʼ�����"
    }
    catch {
        Write-Error "��ʼ�� Visual Studio ����ʱ��������: $_"
    }
}

# ������Ϣ
function Show-Help {
  Write-Host @"
�÷�: $(Split-Path $MyInvocation.MyCommand.Path -Leaf) [ѡ��]

ѡ��:
  --static        ʹ�þ�̬���ӣ�Ĭ�϶�̬���ӣ�
  --help          ��ʾ�˰�����Ϣ

Ĭ�ϱ������� Windows ֧�ֵļܹ� (x64 �� arm64)
"@
}

# ��������
function New-Target {
  param (
    [string]$target,
    [string]$rustflags
  )

  Write-Info "���ڹ��� $target..."

  # ���û���������ִ�й���
  $env:RUSTFLAGS = $rustflags
  cargo build --target $target --release

  # �ƶ���������
  $binaryName = "cursor-api"
  if ($UseStatic) {
    $binaryName += "-static"
  }

  $sourcePath = "target/$target/release/cursor-api.exe"
  $targetPath = "release/${binaryName}-${target}.exe"

  if (Test-Path $sourcePath) {
    Copy-Item $sourcePath $targetPath -Force
    Write-Info "��ɹ��� $target"
  }
  else {
    Write-Warn "��������δ�ҵ�: $target"
    return $false
  }
  return $true
}

# ��������
$UseStatic = $false

foreach ($arg in $args) {
  switch ($arg) {
    "--static" { $UseStatic = $true }
    "--help" { Show-Help; exit 0 }
    default { Write-Error "δ֪����: $arg" }
  }
}

# ������
try {
  # �������
  Test-Requirements

  # ��ʼ�� Visual Studio ����
  Initialize-VSEnvironment

  # ���� release Ŀ¼
  New-Item -ItemType Directory -Force -Path "release" | Out-Null

  # ����Ŀ��ƽ̨
  $targets = @(
    "x86_64-pc-windows-msvc",
    "aarch64-pc-windows-msvc"
  )

  # ���þ�̬���ӱ�־
  $rustflags = ""
  if ($UseStatic) {
    $rustflags = "-C target-feature=+crt-static"
  }

  Write-Info "��ʼ����..."

  # ��������Ŀ��
  foreach ($target in $targets) {
    New-Target -target $target -rustflags $rustflags
  }

  Write-Info "������ɣ�"
}
catch {
  Write-Error "���������з�������: $_"
}