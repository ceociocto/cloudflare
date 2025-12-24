#!/bin/bash
#
# create-cf-worker.sh
# 快速创建 Cloudflare Worker (Next.js) 工程
# 适用于 macOS 和 Linux
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 显示帮助信息
show_help() {
    cat << EOF
用法: $0 <项目名称> [选项]

创建一个新的 Cloudflare Worker (Next.js) 工程并推送到 GitHub

选项:
  -d, --directory  指定项目创建目录 (默认: 当前目录)
  -p, --private    创建私有仓库 (默认: 公开)
  -h, --help       显示此帮助信息

示例:
  $0 my-worker-app
  $0 my-worker-app --private
  $0 my-worker-app -d ~/projects

依赖工具安装:

  npm (包管理器):
    通常随 Node.js 一起安装
    官方下载: https://nodejs.org/

  gh (GitHub CLI):
    macOS:   brew install gh
    Linux:   参考 https://github.com/cli/cli/blob/trunk/docs/install_linux.md
             Ubuntu/Debian: sudo apt install gh
             Fedora: sudo dnf install gh
    Windows: winget install --id GitHub.cli
             或: choco install gh
    安装后登录: gh auth login

  git (版本控制):
    macOS:   xcode-select --install  或  brew install git
    Linux:   sudo apt install git  或  sudo dnf install git
    Windows: winget install --id Git.Git
             或: https://git-scm.com/download/win

EOF
    exit 0
}

# 检查依赖工具
check_dependencies() {
    info "检查依赖工具..."
    
    local missing=()
    
    if ! command -v npm &> /dev/null; then
        missing+=("npm")
    fi
    
    if ! command -v gh &> /dev/null; then
        missing+=("gh (GitHub CLI)")
    fi
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "缺少以下工具: ${missing[*]}\n请先安装后再运行此脚本。"
    fi
    
    success "所有依赖工具已就绪"
}

# 检查 GitHub CLI 登录状态
check_gh_auth() {
    info "检查 GitHub CLI 登录状态..."
    
    if ! gh auth status &> /dev/null; then
        error "请先运行 'gh auth login' 登录 GitHub"
    fi
    
    GITHUB_USER=$(gh api user -q .login)
    success "已登录 GitHub: $GITHUB_USER"
}

# 解析命令行参数
parse_args() {
    PROJECT_NAME=""
    PRIVATE_REPO=false
    TARGET_DIR="."
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--directory)
                TARGET_DIR="$2"
                shift 2
                ;;
            -p|--private)
                PRIVATE_REPO=true
                shift
                ;;
            -h|--help)
                show_help
                ;;
            -*)
                error "未知选项: $1\n使用 --help 查看帮助"
                ;;
            *)
                if [ -z "$PROJECT_NAME" ]; then
                    PROJECT_NAME="$1"
                else
                    error "只能指定一个项目名称"
                fi
                shift
                ;;
        esac
    done
    
    if [ -z "$PROJECT_NAME" ]; then
        error "请提供项目名称\n用法: $0 <项目名称> [选项]"
    fi
    
    # 验证项目名称格式
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "项目名称只能包含字母、数字、下划线和连字符"
    fi
}

# 创建 GitHub 仓库
create_github_repo() {
    info "创建 GitHub 仓库: $PROJECT_NAME..."
    
    local visibility="public"
    if [ "$PRIVATE_REPO" = true ]; then
        visibility="private"
    fi
    
    if gh repo view "$GITHUB_USER/$PROJECT_NAME" &> /dev/null; then
        error "仓库 $GITHUB_USER/$PROJECT_NAME 已存在"
    fi
    
    gh repo create "$PROJECT_NAME" --"$visibility" --description "Cloudflare Worker with Next.js" --clone=false
    
    success "GitHub 仓库创建成功: https://github.com/$GITHUB_USER/$PROJECT_NAME"
}

# 生成 Cloudflare 工程
generate_cloudflare_project() {
    info "生成 Cloudflare Worker 工程 (Next.js)..."
    
    # 切换到目标目录
    if [ "$TARGET_DIR" != "." ]; then
        # 展开 ~ 为 home 目录
        TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
        
        if [ ! -d "$TARGET_DIR" ]; then
            info "创建目标目录: $TARGET_DIR"
            mkdir -p "$TARGET_DIR"
        fi
        cd "$TARGET_DIR"
    fi
    
    # 创建工程 (使用 OpenNext 推荐的方式)
    # 参考: https://opennext.js.org/cloudflare
    npm create cloudflare@latest -- "$PROJECT_NAME" \
        --framework=next \
        --platform=workers \
        --no-deploy
    
    # 检查目录是否创建成功
    if [ ! -d "$PROJECT_NAME" ]; then
        error "工程创建失败：目录 '$PROJECT_NAME' 不存在。\n请检查上面的错误信息，可能是网络问题或 npm 缓存问题。\n尝试运行: npm cache clean --force 后重试。"
    fi
    
    cd "$PROJECT_NAME"
    
    # 保存完整项目路径，供后续使用
    PROJECT_PATH="$(pwd)"
    
    success "Cloudflare 工程生成完成: $PROJECT_PATH"
}


# 更新 README.md
update_readme() {
    info "更新 README.md..."
    
    local readme_header
    readme_header=$(cat << 'EOF'
# 🚀 快速开始

## 📋 环境配置

在项目根目录创建 `.env` 文件：

```ini
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_ACCOUNT_ID=your_account_id_here
```

## 🔑 获取 Cloudflare 凭据

登录 [Cloudflare Dashboard](https://dash.cloudflare.com/) 后：

| 凭据 | 获取路径 |
|------|----------|
| **API Token** | 头像 → My Profile → API Tokens → Create Token → 选择 **Edit Cloudflare Workers** 模板 |
| **Account ID** | Workers & Pages → 右侧边栏 |

## ☁️ 设置自动部署

1. 进入 **Workers & Pages** → **Create** → **Pages** → **Connect to Git**
2. 授权并选择本仓库
3. 配置构建设置：

| 设置项 | 值 |
|--------|-----|
| 生产分支 | `main` |
| 构建命令 | `npx @opennextjs/cloudflare` |
| 输出目录 | `.worker` |

4. 点击 **Save and Deploy**

> ✅ 完成！每次推送到 `main` 分支都会自动部署

---

EOF
)
    
    # 读取现有 README 内容
    local existing_readme=""
    if [ -f "README.md" ]; then
        existing_readme=$(cat README.md)
    fi
    
    # 写入新的 README (头部 + 原内容)
    echo "$readme_header" > README.md
    echo "$existing_readme" >> README.md
    
    success "README.md 更新完成"
}

# 提交 README 更新并推送
commit_and_push_git() {
    info "提交 README 更新并推送到 GitHub..."
    
    # 提交 README 更新
    git add README.md
    git commit -m "docs: 添加环境配置和部署指南"
    
    # 添加远程仓库并推送
    git remote add origin "https://github.com/$GITHUB_USER/$PROJECT_NAME.git" 2>/dev/null || \
        git remote set-url origin "https://github.com/$GITHUB_USER/$PROJECT_NAME.git"
    
    git branch -M main
    git push -u origin main
    
    success "代码已推送到 GitHub"
}

# 打印完成信息
print_completion() {
    local visibility="公开"
    if [ "$PRIVATE_REPO" = true ]; then
        visibility="私有"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}       工程创建完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "📁 项目路径: ${BLUE}$PROJECT_PATH${NC}"
    echo -e "🔒 仓库类型: ${YELLOW}$visibility${NC}"
    echo -e "🔗 GitHub:   ${BLUE}https://github.com/$GITHUB_USER/$PROJECT_NAME${NC}"
    echo ""
    echo -e "${YELLOW}下一步操作:${NC}"
    echo ""
    echo "1. 配置 Cloudflare Pages 自动部署 (参见 README.md)"
    echo ""
    echo "2. 开始本地开发:"
    echo -e "   ${GREEN}cd $PROJECT_PATH${NC}"
    echo "   # 按照 README.md 创建 .env 文件"
    echo "   npm run dev"
    echo ""
}

# 主函数
main() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Cloudflare Worker 工程快速创建工具      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""
    
    parse_args "$@"
    check_dependencies
    check_gh_auth
    # 先生成本地代码，成功后再创建 GitHub 仓库
    # 避免代码生成失败后需要手动删除已创建的仓库
    generate_cloudflare_project
    create_github_repo
    update_readme
    commit_and_push_git
    print_completion
}

main "$@"
