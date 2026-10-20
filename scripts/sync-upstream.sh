#!/usr/bin/env bash
# 同步上游 Meloong-Git/PCL → 本仓库（MY-PCL），按需重编并发布修复版。
#
# 用法：
#   scripts/sync-upstream.sh              # fetch + merge，有冲突就停下
#   scripts/sync-upstream.sh --build      # 合并后重新编译并打包 zip
#   scripts/sync-upstream.sh --publish    # 编译 + 打 tag + 推送到 fork + 创建/更新 Release
#   可选环境变量：GITHUB_TOKEN（发布用）、DIST_DIR（产物目录，默认仓库上级 dist/）、
#                 UPSTREAM_REMOTE（默认 origin）、FORK_REMOTE（默认 mine）、MSBUILD（MSBuild.exe 路径）
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-origin}"
FORK_REMOTE="${FORK_REMOTE:-mine}"
DO_BUILD=0
DO_PUBLISH=0

for arg in "$@"; do
  case "$arg" in
    --build) DO_BUILD=1 ;;
    --publish) DO_BUILD=1; DO_PUBLISH=1 ;;
    --no-build) DO_BUILD=0 ;;
    -h|--help)
      cat <<'USAGE'
用法：scripts/sync-upstream.sh [--build|--publish|--no-build]

  （无参数）    fetch + merge 上游，遇到冲突打印处理指引后退出
  --build       合并后重新编译并打包 zip 到 DIST_DIR（默认仓库上级 dist/）
  --publish     编译 + 打 tag + 推送 fork + 创建/更新 GitHub Release（需要 token）
  --no-build    只合并

环境变量：GITHUB_TOKEN、DIST_DIR、UPSTREAM_REMOTE（默认 origin）、FORK_REMOTE（默认 mine）、MSBUILD
USAGE
      exit 0 ;;
    *) echo "未知参数：$arg（用 --help 查看用法）"; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"
DIST_DIR="${DIST_DIR:-$(cd "$REPO_DIR/.." && pwd)/dist}"
MSBUILD="${MSBUILD:-}"

say() { printf '\n\033[36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m注意：%s\033[0m\n' "$*"; }
die() { printf '\033[31m错误：%s\033[0m\n' "$*" >&2; exit 1; }

MODSECRET="Plain Craft Launcher 2/Modules/ModSecret.vb"
FORM_MAIN="Plain Craft Launcher 2/FormMain.xaml.vb"
LAUNCH="Plain Craft Launcher 2/Modules/Minecraft/ModLaunch.vb"
MODBASE="Plain Craft Launcher 2/Modules/Base/ModBase.vb"

# ---------- 1. 拉取与合并 ----------
say "拉取 $UPSTREAM_REMOTE 与 $FORK_REMOTE"
git fetch "$UPSTREAM_REMOTE" --tags --prune
git fetch "$FORK_REMOTE" --prune 2>/dev/null || warn "无法拉取 $FORK_REMOTE（不影响合并）"

BEHIND=$(git rev-list --count "HEAD..$UPSTREAM_REMOTE/main")
AHEAD=$(git rev-list --count "$UPSTREAM_REMOTE/main..HEAD")
say "上游 main 领先本地 $BEHIND 个提交；本地（我们的修复）领先 $AHEAD 个提交"

if [ "$BEHIND" -gt 0 ]; then
  say "合并 $UPSTREAM_REMOTE/main"
  if ! git merge --no-edit "$UPSTREAM_REMOTE/main"; then
    echo
    echo "合并冲突，解决后重新运行本脚本："
    git diff --name-only --diff-filter=U | sed 's/^/  - /'
    cat <<'HINT'

  —— 本仓库的固定改动，冲突时按下面保留 ——
  * ModSecret.vb:18                RestrictMcDownload As Boolean = False
  * FormMain.xaml.vb               删掉「删除：……不再提供 MC 下载功能……」两条更新日志
  * ModLaunch.vb 的 403 分支        保留「Invalid app registration → 白名单」判断
  * README.md                      保留「正版登录说明（第三方修复版）」一节
HINT
    exit 2
  fi
else
  say "已是最新，无需合并"
fi

# ---------- 2. 完整性检查 ----------
grep -q 'RestrictMcDownload As Boolean = False' "$MODSECRET" \
  || die "ModSecret.vb 里 RestrictMcDownload 不是 False。若上游删除了该开关（恢复下载），请删掉本仓库剩下的开关补丁并更新脚本。"
grep -q 'Invalid app registration' "$LAUNCH" \
  || warn "ModLaunch.vb 里找不到 403 白名单判断，可能被上游重写了，发版前请人工确认。"

VERSION=$(sed -n 's/.*VersionBaseName As String = "\([^"]*\)".*/\1/p' "$MODBASE" | head -1)
[ -n "$VERSION" ] || die "无法从 $MODBASE 解析版本号"
TAG="v${VERSION}-fix"
say "当前版本 $VERSION，对应 tag $TAG"

if [ "$DO_BUILD" = 0 ]; then
  say "完成（未编译；加 --build 可在合并后重编）"
  exit 0
fi

# ---------- 3. 编译 ----------
if [ -z "$MSBUILD" ]; then
  if [ -x "/d/VS2022BuildTools/MSBuild/Current/Bin/MSBuild.exe" ]; then
    MSBUILD="/d/VS2022BuildTools/MSBuild/Current/Bin/MSBuild.exe"
  elif command -v msbuild >/dev/null 2>&1; then
    MSBUILD="msbuild"
  else
    die "找不到 MSBuild.exe，请安装 VS 2022 Build Tools 或设置 MSBUILD 环境变量"
  fi
fi

DOTNET_EXE="$(command -v dotnet || true)"
[ -n "$DOTNET_EXE" ] || die "找不到 dotnet（需要 .NET SDK 做 restore）"

say "还原 NuGet 包"
dotnet restore PCLCS/PCLCS.csproj -v:m

if [ -z "${MSBuildSDKsPath:-}" ]; then
  SDK_ROOT=$(dotnet --list-sdks | tail -1 | sed -n 's/.*\[\(.*\)\]/\1/p')
  [ -n "$SDK_ROOT" ] && export MSBuildSDKsPath="$(cygpath -w "$(cygpath -u "$SDK_ROOT")/Sdks")"
fi
export MSBuildEnableWorkloadResolver=false

say "编译 Release"
"$MSBUILD" "Plain Craft Launcher 2/Plain Craft Launcher 2.vbproj" -p:Configuration=Release -nologo -v:m

EXE=""
for candidate in "Plain Craft Launcher 2/bin/Plain Craft Launcher 2.exe" "Plain Craft Launcher 2/obj/Release/Plain Craft Launcher 2.exe"; do
  [ -f "$candidate" ] && EXE="$candidate" && break
done
[ -n "$EXE" ] || die "编译结束但找不到 exe"

if grep -aq '关闭下载' "$EXE"; then
  warn "exe 中仍含「关闭下载」文案，下载入口可能没恢复，请检查 ModSecret.vb"
fi
say "产物：$EXE（$(stat -c%s "$EXE") 字节）"

# ---------- 4. 打包 ----------
STAGE="$DIST_DIR/_stage"
ZIP="$DIST_DIR/PCL-${VERSION}-fix-win.zip"
rm -rf "$STAGE"
mkdir -p "$STAGE" "$DIST_DIR"
cp "$EXE" "$STAGE/Plain Craft Launcher 2.exe"
cp LICENCE "$STAGE/LICENCE"
cat > "$STAGE/修复说明.txt" <<EOF
PCL ${VERSION} 第三方修复版（恢复 MC 下载）

构建时间：$(date '+%Y-%m-%d %H:%M')
来源：https://github.com/FLandreyu/MY-PCL （基于 Meloong-Git/PCL 的 ${VERSION} 源码）

本版改动：
1. RestrictMcDownload 由 True 改为 False，恢复 Minecraft 版本列表、整合包与安装页下载入口。
2. 移除更新日志中「删除 MC 下载功能」的提示。
3. 正版登录 403 时提示「应用未通过 Mojang 白名单审核」，不再误报为 IP 异常。

已知限制：
- 未注入官方 CI 的微软 OAuth 密钥：正版登录需自备已获 Mojang 白名单批准的 Entra 应用（环境变量 PCL_MS_CLIENT_ID）。
- 未注入 CurseForge API Key：CurseForge 搜索不可用。
- exe 未签名，Windows SmartScreen 可能提示。

许可：沿用《PCL 分发有限许可》，见 LICENCE。
EOF

rm -f "$ZIP"
powershell.exe -NoProfile -Command "Compress-Archive -Path '$(cygpath -w "$STAGE")\\*' -DestinationPath '$(cygpath -w "$ZIP")' -CompressionLevel Optimal -Force" >/dev/null
say "已打包：$ZIP（$(stat -c%s "$ZIP") 字节）"

if [ "$DO_PUBLISH" = 0 ]; then
  say "完成（未发布；加 --publish 可推 tag 并更新 Release）"
  exit 0
fi

# ---------- 5. 发布 ----------
TOKEN="${GITHUB_TOKEN:-}"
if [ -z "$TOKEN" ] && command -v gh >/dev/null 2>&1; then
  TOKEN=$(gh auth token 2>/dev/null || true)
fi
if [ -z "$TOKEN" ]; then
  TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill 2>/dev/null | sed -n 's/^password=//p')
fi
[ -n "$TOKEN" ] || die "没有 GitHub token：设置 GITHUB_TOKEN，或先 git credential 登录"

SLUG=$(git remote get-url "$FORK_REMOTE" | sed -E 's#.*github\.com[:/]##; s#\.git$##')
[ -n "$SLUG" ] || die "无法解析 $FORK_REMOTE 的仓库地址"
say "发布到 $SLUG，tag $TAG"

git push "$FORK_REMOTE" main
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  git push "$FORK_REMOTE" "refs/tags/$TAG" --force
else
  git tag -a "$TAG" -m "PCL ${VERSION} 第三方修复版（恢复 MC 下载）"
  git push "$FORK_REMOTE" "refs/tags/$TAG"
fi

BODY_FILE=$(mktemp)
export VERSION TAG
python - "$BODY_FILE" <<'PY'
import json, os, sys
body = f"""## PCL {os.environ['VERSION']} 第三方修复版（恢复 MC 下载）

基于 [Meloong-Git/PCL](https://github.com/Meloong-Git/PCL) 的 {os.environ['VERSION']} 源码重新编译，**非官方发布**，与官方无关。

### 改动
- `RestrictMcDownload` 改为 `False`，恢复 Minecraft 版本列表、整合包与安装页下载入口
- 移除更新日志中「删除 MC 下载功能」的提示
- 正版登录 403 时提示「应用未通过 Mojang 白名单审核」，不再误报为 IP 异常

### 下载
`PCL-{os.environ['VERSION']}-fix-win.zip` —— 内含 `Plain Craft Launcher 2.exe`、`LICENCE`、`修复说明.txt`

### 注意
- 未注入官方 CI 密钥：正版登录需自备已获 Mojang 白名单批准的 Entra 应用（环境变量 `PCL_MS_CLIENT_ID`），详见 [README](https://github.com/FLandreyu/MY-PCL#正版登录说明第三方修复版)
- 未注入 CurseForge API Key：CurseForge 搜索不可用
- exe 未签名，Windows SmartScreen 可能提示
- 隐私政策：[PRIVACY.md](https://github.com/FLandreyu/MY-PCL/blob/main/PRIVACY.md)；使用条款：[TERMS.md](https://github.com/FLandreyu/MY-PCL/blob/main/TERMS.md)
"""
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({"tag_name": os.environ["TAG"], "name": f"PCL {os.environ['VERSION']} 第三方修复版（恢复 MC 下载）", "body": body, "draft": False, "prerelease": False}, f, ensure_ascii=False)
PY

EXISTING=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$SLUG/releases/tags/$TAG")
RELEASE_ID=$(printf '%s' "$EXISTING" | python -c 'import json,sys; d=json.load(sys.stdin); print(d.get("id",""))' 2>/dev/null || true)
if [ -z "$RELEASE_ID" ]; then
  say "创建 Release"
  curl -s -o /dev/null -w 'HTTP %{http_code}\n' -X POST \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    --data-binary @"$(cygpath -w "$BODY_FILE")" \
    "https://api.github.com/repos/$SLUG/releases"
  RELEASE_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$SLUG/releases/tags/$TAG" | python -c 'import json,sys; print(json.load(sys.stdin)["id"])')
else
  say "更新 Release #$RELEASE_ID"
  curl -s -o /dev/null -w 'HTTP %{http_code}\n' -X PATCH \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    --data-binary @"$(cygpath -w "$BODY_FILE")" \
    "https://api.github.com/repos/$SLUG/releases/$RELEASE_ID"
fi

OLD_ASSET=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$SLUG/releases/$RELEASE_ID/assets" \
  | python -c 'import json,sys; print(" ".join(str(a["id"]) for a in json.load(sys.stdin)))')
for id in $OLD_ASSET; do
  curl -s -o /dev/null -X DELETE -H "Authorization: Bearer $TOKEN" "https://api.github.com/repos/$SLUG/releases/assets/$id"
done

say "上传资产 $(basename "$ZIP")"
curl -s -o /dev/null -w 'HTTP %{http_code}\n' -X POST \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/zip" \
  --data-binary @"$(cygpath -w "$ZIP")" \
  "https://uploads.github.com/repos/$SLUG/releases/$RELEASE_ID/assets?name=$(basename "$ZIP")"

rm -f "$BODY_FILE"
say "发布完成：https://github.com/$SLUG/releases/tag/$TAG"
