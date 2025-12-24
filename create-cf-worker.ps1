<#
.SYNOPSIS
    快速创建 Cloudflare Worker (Next.js) 工程
.DESCRIPTION
    创建一个新的 Cloudflare Worker (Next.js) 工程并推送到 GitHub
.PARAMETER ProjectName
    项目名称
.PARAMETER Private
    创建私有仓库 (默认: 公开)
.EXAMPLE
    .\create-cf-worker.ps1 my-worker-app
    .\create-cf-worker.ps1 my-worker-app -Private
#>

param(
    [Parameter(Position=0, Mandatory=$false)]
    [string]$ProjectName,
    
    [switch]$Private,
    
    [switch]$Help
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Blue }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor Yellow }
function Write-Error { 
    Write-Host "[ERROR] $args" -ForegroundColor Red
    exit 1
}

# 显示帮助信息
function Show-Help {
    Write-Host @"
用法: .\create-cf-worker.ps1 <项目名称> [选项]

创建一个新的 Cloudflare Worker (Next.js) 工程并推送到 GitHub

选项:
  -Private         创建私有仓库 (默认: 公开)
  -Help            显示此帮助信息

示例:
  .\create-cf-worker.ps1 my-worker-app
  .\create-cf-worker.ps1 my-worker-app -Private

依赖工具安装:

  pnpm (包管理器):
    Windows: iwr https://get.pnpm.io/install.ps1 -useb | iex
    或通过 npm: npm install -g pnpm

  gh (GitHub CLI):
    Windows: winget install --id GitHub.cli
             或: choco install gh
    安装后登录: gh auth login

  git (版本控制):
    Windows: winget install --id Git.Git
             或: https://git-scm.com/download/win

"@
    exit 0
}

# 检查依赖工具
function Test-Dependencies {
    Write-Info "检查依赖工具..."
    
    $missing = @()
    
    if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
        $missing += "pnpm"
    }
    
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        $missing += "gh (GitHub CLI)"
    }
    
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $missing += "git"
    }
    
    if ($missing.Count -gt 0) {
        Write-Error "缺少以下工具: $($missing -join ', ')`n请先安装后再运行此脚本。"
    }
    
    Write-Success "所有依赖工具已就绪"
}

# 检查 GitHub CLI 登录状态
function Test-GhAuth {
    Write-Info "检查 GitHub CLI 登录状态..."
    
    try {
        $null = gh auth status 2>&1
    } catch {
        Write-Error "请先运行 'gh auth login' 登录 GitHub"
    }
    
    $script:GitHubUser = (gh api user -q .login)
    Write-Success "已登录 GitHub: $script:GitHubUser"
}

# 验证参数
function Test-Parameters {
    if ($Help) {
        Show-Help
    }
    
    if ([string]::IsNullOrEmpty($ProjectName)) {
        Write-Error "请提供项目名称`n用法: .\create-cf-worker.ps1 <项目名称> [选项]"
    }
    
    if ($ProjectName -notmatch '^[a-zA-Z0-9_-]+$') {
        Write-Error "项目名称只能包含字母、数字、下划线和连字符"
    }
}

# 创建 GitHub 仓库
function New-GitHubRepo {
    Write-Info "创建 GitHub 仓库: $ProjectName..."
    
    $visibility = "public"
    if ($Private) {
        $visibility = "private"
    }
    
    # 检查仓库是否已存在
    try {
        $null = gh repo view "$script:GitHubUser/$ProjectName" 2>&1
        Write-Error "仓库 $script:GitHubUser/$ProjectName 已存在"
    } catch {
        # 仓库不存在，继续创建
    }
    
    gh repo create $ProjectName --$visibility --description "Cloudflare Worker with Next.js"
    
    Write-Success "GitHub 仓库创建成功: https://github.com/$script:GitHubUser/$ProjectName"
}

# 生成 Cloudflare 工程
function New-CloudflareProject {
    Write-Info "生成 Cloudflare Worker 工程 (Next.js)..."
    
    # 完全非交互模式
    pnpm create cloudflare@latest $ProjectName `
        --framework=next `
        --lang=ts `
        --no-deploy `
        --no-git `
        -- --yes --turbopack
    
    # 检查目录是否创建成功
    if (-not (Test-Path $ProjectName -PathType Container)) {
        Write-Error "工程创建失败：目录 '$ProjectName' 不存在。`n请检查上面的错误信息，可能是网络问题或 pnpm 缓存问题。`n尝试运行: pnpm store prune 后重试。"
    }
    
    Set-Location $ProjectName
    
    Write-Success "Cloudflare 工程生成完成"
}

# 创建 .env.example 文件
function New-EnvTemplate {
    Write-Info "创建 .env.example 文件..."
    
    $envContent = @"
# Cloudflare 配置
# 请复制此文件为 .env 并填入真实值

# API Token: Cloudflare Dashboard -> My Profile -> API Tokens -> Create Token
# 建议使用 "Edit Cloudflare Workers" 模板创建
CLOUDFLARE_API_TOKEN=xxx

# Account ID: Cloudflare Dashboard -> Workers & Pages -> 右侧边栏可查看
CLOUDFLARE_ACCOUNT_ID=yyy
"@
    
    $envContent | Out-File -FilePath ".env.example" -Encoding utf8
    
    Write-Success ".env.example 创建完成"
}

# 更新 README.md
function Update-Readme {
    Write-Info "更新 README.md..."
    
    $readmeHeader = @"
# 快速开始

## 1. 环境配置

复制环境变量模板文件：

``````bash
cp .env.example .env
``````

## 2. 获取 Cloudflare 凭据

### 获取 API Token

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 点击右上角头像 -> **My Profile**
3. 左侧菜单选择 **API Tokens**
4. 点击 **Create Token**
5. 选择 **Edit Cloudflare Workers** 模板
6. 点击 **Continue to summary** -> **Create Token**
7. 复制 Token 到 ``.env`` 文件的 ``CLOUDFLARE_API_TOKEN``

### 获取 Account ID

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 左侧菜单选择 **Workers & Pages**
3. 右侧边栏可看到 **Account ID**
4. 复制到 ``.env`` 文件的 ``CLOUDFLARE_ACCOUNT_ID``

## 3. 设置 Cloudflare Pages 自动部署

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 进入 **Workers & Pages**
3. 点击 **Create** -> **Pages** -> **Connect to Git**
4. 选择 GitHub 并授权
5. 选择本仓库，设置：
   - 生产分支: ``main``
   - 构建命令: ``npx @cloudflare/next-on-pages``
   - 输出目录: ``.vercel/output/static``
6. 点击 **Save and Deploy**

完成后，每次推送到 ``main`` 分支都会自动部署！

---

"@
    
    $existingReadme = ""
    if (Test-Path "README.md") {
        $existingReadme = Get-Content "README.md" -Raw
    }
    
    ($readmeHeader + $existingReadme) | Out-File -FilePath "README.md" -Encoding utf8
    
    Write-Success "README.md 更新完成"
}

# 初始化 Git 并推送
function Initialize-AndPushGit {
    Write-Info "初始化 Git 并推送到 GitHub..."
    
    if (-not (Test-Path ".git")) {
        git init
    }
    
    git add .
    git commit -m "Initial commit: Cloudflare Worker with Next.js"
    
    # 添加远程仓库
    try {
        git remote add origin "https://github.com/$script:GitHubUser/$ProjectName.git"
    } catch {
        git remote set-url origin "https://github.com/$script:GitHubUser/$ProjectName.git"
    }
    
    git branch -M main
    git push -u origin main
    
    Write-Success "代码已推送到 GitHub"
}

# 打印完成信息
function Write-Completion {
    $visibility = "公开"
    if ($Private) {
        $visibility = "私有"
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "       工程创建完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 项目名称: " -NoNewline; Write-Host $ProjectName -ForegroundColor Blue
    Write-Host "🔒 仓库类型: " -NoNewline; Write-Host $visibility -ForegroundColor Yellow
    Write-Host "🔗 GitHub:   " -NoNewline; Write-Host "https://github.com/$script:GitHubUser/$ProjectName" -ForegroundColor Blue
    Write-Host ""
    Write-Host "下一步操作:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 克隆仓库到本地:"
    Write-Host "   git clone https://github.com/$script:GitHubUser/$ProjectName.git" -ForegroundColor Green
    Write-Host ""
    Write-Host "2. 配置 Cloudflare Pages 自动部署 (参见 README.md)"
    Write-Host ""
    Write-Host "3. 开始本地开发:"
    Write-Host "   cd $ProjectName"
    Write-Host "   cp .env.template .env"
    Write-Host "   # 编辑 .env 填入 Cloudflare 凭据"
    Write-Host "   pnpm install"
    Write-Host "   pnpm dev"
    Write-Host ""
}

# 主函数
function Main {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║  Cloudflare Worker 工程快速创建工具      ║" -ForegroundColor Blue
    Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
    
    Test-Parameters
    Test-Dependencies
    Test-GhAuth
    New-GitHubRepo
    New-CloudflareProject
    New-EnvTemplate
    Update-Readme
    Initialize-AndPushGit
    Write-Completion
}

Main
