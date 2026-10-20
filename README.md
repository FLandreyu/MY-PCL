# Plain Craft Launcher

> **本仓库为第三方修复版（PCL 修复版）**，基于龙腾猫跃的 [PCL](https://github.com/Meloong-Git/PCL) 2.99.0.0 源码修改编译，**并非官方发布**，与官方无关。  
> 主要改动：将 `Plain Craft Launcher 2/Modules/ModSecret.vb` 中的 `RestrictMcDownload` 由 `True` 改为 `False`，恢复 Minecraft 版本列表与整合包下载入口，并移除 2.99 更新日志中「删除 MC 下载功能」的两条提示。  
> 依据《PCL 存储库合理使用指南》进行第三方二次创作，继续沿用原许可文件（[LICENCE](LICENCE)）并公开全部源代码。

[![Stars](https://img.shields.io/github/stars/Meloong-Git/PCL?style=flat&logo=data:image/svg%2bxml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEiIHdpZHRoPSIxNiIgaGVpZ2h0PSIxNiI+PHBhdGggZD0iTTggLjI1YS43NS43NSAwIDAgMSAuNjczLjQxOGwxLjg4MiAzLjgxNSA0LjIxLjYxMmEuNzUuNzUgMCAwIDEgLjQxNiAxLjI3OWwtMy4wNDYgMi45Ny43MTkgNC4xOTJhLjc1MS43NTEgMCAwIDEtMS4wODguNzkxTDggMTIuMzQ3bC0zLjc2NiAxLjk4YS43NS43NSAwIDAgMS0xLjA4OC0uNzlsLjcyLTQuMTk0TC44MTggNi4zNzRhLjc1Ljc1IDAgMCAxIC40MTYtMS4yOGw0LjIxLS42MTFMNy4zMjcuNjY4QS43NS43NSAwIDAgMSA4IC4yNVoiIGZpbGw9IiNlYWM1NGYiLz48L3N2Zz4=&logoSize=auto&label=Stars&labelColor=444444&color=eac54f)](https://github.com/Meloong-Git/PCL/)
[![Issues](https://img.shields.io/github/issues/Meloong-Git/PCL?style=flat&label=Issues&labelColor=444444&color=1F883D)](https://github.com/Meloong-Git/PCL/issues)
[![哔哩哔哩](https://img.shields.io/badge/动态-BiliBili-00A4DB?style=flat&labelColor=444444&logoSize=auto)](https://space.bilibili.com/11343203/dynamic)
[![爱发电](https://img.shields.io/badge/赞助-爱发电-946ce6?style=flat&labelColor=444444&logoSize=auto)](https://meloong.com/afd/a/LTCat)

包含 PCL 的大部分源代码，包括 UI 库、动画模块、下载模块、Minecraft 启动模块等！<br/>
代码并不是实时更新的，它会在每次 PCL 发布更新时同步一次。<br/>
非常感谢社区的大力支持！

<br/>

### 正版登录说明（第三方修复版）

本仓库与官方源码一样，**不包含微软 OAuth 客户端 ID**（官方构建由 CI 注入密钥）。因此自行编译的版本点「正版登录」会报 `AADSTS900144: client_id` 缺失。要让它工作，需要你自备一个已获 **Mojang 白名单**批准的 Entra 应用：

1. 在 [Microsoft Entra 管理中心](https://entra.microsoft.com) 注册应用：受支持的账户类型选「任何组织目录中的账户和个人 Microsoft 帐户」，并在「身份验证」中开启「允许公共客户端流」。
2. 复制「应用程序(客户端) ID」，启动前设置环境变量 `PCL_MS_CLIENT_ID=<你的 client id>`（或在 `ModSecret.vb` 中填写默认值后重新编译）。
3. 通过 [Minecraft 官方 AppID 表单](https://help.minecraft.net/hc/en-us/articles/16254801392141) 提交 client id 申请白名单——**审核通过前登录无法完成**。
4. 审批通过后即可正常登录。

登录进度到 55%（第 4/6 步）并提示 `403 Invalid app registration` 表示账号授权全部成功，仅应用未获 Mojang 批准；这与网络、IP、VPN 无关。

> 不想折腾的话，可以直接用官方 PCL 登录并启动游戏，再用本修复版下载版本与整合包（两者数据目录互不干扰）。

### 维护：同步上游

上游每次发版后，用 `scripts/sync-upstream.sh` 同步并重编（Windows / Git Bash）：

```bash
# 只合并，遇到冲突会打印需要保留的点
scripts/sync-upstream.sh
# 合并 + 编译 + 打包 zip 到 ../dist
scripts/sync-upstream.sh --build
# 合并 + 编译 + 打包 + 打 tag + 更新 GitHub Release（需要 GITHUB_TOKEN）
scripts/sync-upstream.sh --publish
```

冲突时固定保留：`RestrictMcDownload = False`、删除的两条「删除 MC 下载」更新日志、`ModLaunch.vb` 的 403 白名单判断、本 README 的「正版登录说明」。

另外 `.github/workflows/fix-build.yml` 会在推送 `v*-fix` tag 时于 GitHub Actions 自动编译并创建 Release，也可以手动运行只拿 artifact。

### 相关文档
- [隐私政策](PRIVACY.md)
- [使用条款](TERMS.md)

### 相关资源
- [PCL 下载](https://meloong.com/pcl)：下载可免费使用的正式版 PCL！
- [PCL 功能投票](https://github.com/Meloong-Git/PCL/discussions/2)：来参加投票吧，开发者会优先处理票数较高的项目！
- [帮助文档库](https://github.com/LTCatt/PCL2Help)：PCL 内置帮助文档的存储库
