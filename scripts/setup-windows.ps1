# ���� PowerShell ����Ϊ UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ����Ƿ��Թ���ԱȨ������
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "���Թ���ԱȨ�����д˽ű�"
    exit 1
}

# ��鲢��װ Chocolatey
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Output "���ڰ�װ Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# ��װ��Ҫ�Ĺ���
Write-Output "���ڰ�װ��Ҫ�Ĺ���..."
choco install -y mingw
choco install -y protoc
choco install -y git

# ��װ Rust ����
Write-Output "���ڰ�װ Rust ����..."
rustup target add x86_64-pc-windows-msvc
rustup target add x86_64-unknown-linux-gnu
cargo install cross

Write-Output "��װ��ɣ�"