# 🚀 Cloudflare Worker 快速创建工具

一键创建 Cloudflare Worker (Next.js) 工程，自动初始化 Git 仓库并推送到 GitHub。

## ✨ 功能特性

- 🎯 自动创建 Next.js + Cloudflare Workers 项目
- 📦 自动初始化 Git 仓库
- 🔗 自动创建 GitHub 仓库并推送代码
- 📝 自动生成部署配置文档
- 🌍 支持 macOS/Linux (Bash) 和 Windows (PowerShell)

## 📋 前置要求

在使用此工具之前，请确保已安装以下依赖：

| 工具 | macOS | Linux | Windows |
|------|-------|-------|---------|
| **Node.js & npm** | `brew install node` | `apt install nodejs npm` | [官网下载](https://nodejs.org/) |
| **Git** | `xcode-select --install` | `apt install git` | `winget install Git.Git` |
| **GitHub CLI** | `brew install gh` | `apt install gh` | `winget install GitHub.cli` |

安装完成后，请登录 GitHub CLI：

```bash
gh auth login
```

## 🔧 安装

### 方法一：直接下载使用

```bash
# macOS/Linux
curl -O https://raw.githubusercontent.com/ceociocto/cloudflare/main/create-cf-worker.sh
chmod +x create-cf-worker.sh

# Windows (PowerShell)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ceociocto/cloudflare/main/create-cf-worker.ps1" -OutFile "create-cf-worker.ps1"
```

### 方法二：克隆仓库

```bash
git clone https://github.com/ceociocto/cloudflare.git
cd cloudflare
chmod +x create-cf-worker.sh  # macOS/Linux
```

## 📖 使用方法

### macOS/Linux (Bash)

```bash
# 基础用法 - 在当前目录创建项目
./create-cf-worker.sh <项目名称>

# 指定目录创建项目
./create-cf-worker.sh <项目名称> -d /path/to/directory

# 创建私有仓库
./create-cf-worker.sh <项目名称> --private

# 组合使用
./create-cf-worker.sh <项目名称> -d ~/projects --private
```

### Windows (PowerShell)

```powershell
# 基础用法
.\create-cf-worker.ps1 <项目名称>

# 创建私有仓库
.\create-cf-worker.ps1 <项目名称> -Private
```

### 查看帮助

```bash
# macOS/Linux
./create-cf-worker.sh --help

# Windows
.\create-cf-worker.ps1 -Help
```

## 💡 完整参数示例

### 示例 1：创建公开项目（默认）

```bash
# macOS/Linux
./create-cf-worker.sh my-blog

# Windows
.\create-cf-worker.ps1 my-blog
```

**效果：**
- 在当前目录下创建 `my-blog` 文件夹
- 初始化 Next.js + Cloudflare Workers 项目
- 创建公开的 GitHub 仓库 `https://github.com/<你的用户名>/my-blog`
- 推送初始代码到 GitHub

### 示例 2：创建私有项目

```bash
# macOS/Linux
./create-cf-worker.sh my-secret-app --private

# Windows
.\create-cf-worker.ps1 my-secret-app -Private
```

**效果：**
- 创建私有的 GitHub 仓库

### 示例 3：指定项目目录（仅 macOS/Linux）

```bash
# 在 ~/projects 目录下创建项目
./create-cf-worker.sh my-worker-app -d ~/projects

# 组合私有仓库选项
./create-cf-worker.sh my-worker-app -d ~/projects --private
```

**效果：**
- 在 `~/projects/my-worker-app` 创建项目
- 目录不存在时自动创建

### 示例 4：查看帮助信息

```bash
# macOS/Linux
./create-cf-worker.sh -h
./create-cf-worker.sh --help

# Windows
.\create-cf-worker.ps1 -Help
```

## 📁 生成的项目结构

执行脚本后，将生成以下项目结构：

```
my-worker-app/
├── .git/                  # Git 仓库
├── .gitignore
├── README.md              # 包含部署指南
├── package.json
├── next.config.js
├── wrangler.toml          # Cloudflare 配置
├── src/
│   └── app/
│       ├── layout.tsx
│       └── page.tsx
└── ...
```

## ☁️ 部署到 Cloudflare Pages

项目创建后，按照生成的 README.md 配置 Cloudflare Pages 自动部署：

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 进入 **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
3. 授权 GitHub 并选择刚创建的仓库
4. 配置构建设置：

| 设置项 | 值 |
|--------|-----|
| 生产分支 | `main` |
| 构建命令 | `npx @opennextjs/cloudflare` |
| 输出目录 | `.worker` |

5. 点击 **Save and Deploy**

> ✅ 完成后，每次推送到 `main` 分支都会自动部署！

## 🔑 配置 Cloudflare 凭据（本地开发）

在项目根目录创建 `.env` 文件：

```ini
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
```

### 获取 API Token

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 点击右上角头像 → **My Profile** → **API Tokens**
3. 点击 **Create Token** → 选择 **Edit Cloudflare Workers** 模板
4. 完成创建并复制 Token

### 获取 Account ID

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 进入 **Workers & Pages**
3. 右侧边栏可看到 **Account ID**

## 🐛 常见问题

### Q: 提示 "gh: command not found"
A: 请先安装 GitHub CLI 并登录：
```bash
# macOS
brew install gh
gh auth login
```

### Q: 项目创建失败
A: 可能是 npm 缓存问题，尝试：
```bash
npm cache clean --force
```

### Q: 仓库已存在错误
A: 请使用不同的项目名称，或先删除 GitHub 上同名的仓库。

## 📄 License

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
