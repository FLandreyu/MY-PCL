# PCL 修复版 · 重新开启 Minecraft 下载

> **官方 PCL 从 2.99.0.0 起不再提供 Minecraft 下载功能，这个仓库只做一件事：把它打开。**
> 基于官方 2.99.0.0 源码重新编译，非官方发布；除下载入口外，其余行为与官方一致。

[![最新版本](https://img.shields.io/github/v/release/FLandreyu/MY-PCL?label=%E6%9C%80%E6%96%B0%E7%89%88&color=1F6FEB)](https://github.com/FLandreyu/MY-PCL/releases/latest)
[![下载量](https://img.shields.io/github/downloads/FLandreyu/MY-PCL/total?label=%E4%B8%8B%E8%BD%BD&color=3FB950)](https://github.com/FLandreyu/MY-PCL/releases)
[![使用条款](https://img.shields.io/badge/%E4%BD%BF%E7%94%A8%E6%9D%A1%E6%AC%BE-TERMS.md-8250df)](TERMS.md)
[![隐私政策](https://img.shields.io/badge/%E9%9A%90%E7%A7%81%E6%94%BF%E7%AD%96-PRIVACY.md-8250df)](PRIVACY.md)

## 下载与使用

1. 到 [Releases](https://github.com/FLandreyu/MY-PCL/releases/latest) 下载 `PCL-2.99.0.0-fix-win.zip`；
2. 解压到任意目录（免安装），双击 `Plain Craft Launcher 2.exe`；
3. 打开「下载」页，安装游戏版本、模组加载器和整合包。

> 首次运行如果弹出 Windows SmartScreen（未知发布者），点「更多信息 → 仍要运行」即可：程序没有做代码签名。

## 这个版本能做什么

| 功能 | 状态 |
| --- | --- |
| 下载 Minecraft 正式版 / 快照 / 远古版本 | ✅ |
| 安装 Forge、NeoForge、Fabric、LiteLoader、OptiFine | ✅ 可选推荐版本，一键安装 |
| 下载并安装整合包（`.zip` / `.mrpack`，也可直接拖进启动器） | ✅ CurseForge、Modrinth 整合包都支持 |
| 修改已安装版本（增删模组加载器、更新 Forge / Fabric 等组件） | ✅ |
| 离线登录、第三方（authlib-injector）登录 | ✅ |
| 正版（微软）登录 | ⚠️ 需自备已获 Mojang 白名单批准的 Entra 应用，见下 |
| CurseForge 在线搜索 | ❌ 本构建没有 CurseForge API Key；Modrinth 搜索正常 |
| 自动更新 | ❌ 开源版本不含更新模块，请关注 Releases |

## 和官方版共存

修复版与官方 PCL 的设置分别存在 `HKCU\Software\PCLDebug` 和 `HKCU\Software\PCL`，可以同时装在一台电脑上、指向同一个 `.minecraft`，互不覆盖。

常见用法是：官方版负责正版登录与启动，修复版负责下载版本和整合包。

## 正版登录（可选）

本仓库和官方源码一样**不含微软 OAuth 客户端 ID**（官方由 CI 注入密钥），所以自编译版本点「正版登录」会提示 `AADSTS900144: client_id` 缺失。要让它工作，需要自备一个已获 Mojang 白名单批准的 Entra 应用：

1. 在 [Microsoft Entra 管理中心](https://entra.microsoft.com) 注册应用：账户类型选「任何组织目录中的账户和个人 Microsoft 帐户」，并开启「允许公共客户端流」；
2. 复制「应用程序(客户端) ID」，启动前设置环境变量 `PCL_MS_CLIENT_ID=<你的 client id>`（或填写到 `ModSecret.vb` 后自行编译）；
3. 通过 [Minecraft 官方 AppID 表单](https://help.minecraft.net/hc/en-us/articles/16254801392141) 申请白名单——**审核通过前登录无法完成**；
4. 审核通过后即可正常登录。

进度到 55% 并提示 `403 Invalid app registration`，说明账号授权已经成功，只是这个应用还没被 Mojang 批准，与网络、IP、VPN 无关——本版对这个错误有单独提示。

## 改了什么

只动了三处，下载引擎、界面和启动逻辑都没改：

- `Plain Craft Launcher 2/Modules/ModSecret.vb`：`RestrictMcDownload` 由 `True` 改为 `False`，重新打开下载入口；
- `Plain Craft Launcher 2/FormMain.xaml.vb`：删掉 2.99 更新日志里两条「删除 MC 下载功能」的提示；
- `Plain Craft Launcher 2/Modules/Minecraft/ModLaunch.vb`：正版登录返回 403 时区分「应用未过白名单」和「网络异常」，避免误报 IP 问题。

## 声明与许可

- 本项目基于龙腾猫跃的 [PCL](https://github.com/Meloong-Git/PCL) 2.99.0.0 源码修改编译，**非官方发布**，与官方无关；
- 依据《PCL 存储库合理使用指南》进行二次创作：保留关于页署名与赞助入口、沿用原许可文件 [LICENCE](LICENCE)、公开全部源代码；
- 仅限已购买 Minecraft: Java Edition 的用户使用，请勿用于绕过正版验证、售卖或冒充官方版本；
- 按原样提供，不对使用后果作任何担保。详见[使用条款](TERMS.md)与[隐私政策](PRIVACY.md)。

## 反馈

遇到问题欢迎开 [Issue](https://github.com/FLandreyu/MY-PCL/issues)，附上 PCL 的日志（设置 → 其他 → 日志）会更快定位。

<details>
<summary>维护者：同步上游更新</summary>

上游每次发版后，用 `scripts/sync-upstream.sh` 同步并重编（Windows / Git Bash）：

```bash
scripts/sync-upstream.sh            # 只合并，冲突时打印需要保留的点
scripts/sync-upstream.sh --build    # 合并 + 编译 + 打包 zip 到 ../dist
scripts/sync-upstream.sh --publish  # 合并 + 编译 + 打包 + 打 tag + 更新 Release（需 GITHUB_TOKEN）
```

冲突时固定保留：`RestrictMcDownload = False`、删除的两条「删除 MC 下载」更新日志、`ModLaunch.vb` 的 403 白名单判断、本 README 的「正版登录」小节。

`.github/workflows/fix-build.yml` 会在推送 `v*-fix` tag 时自动编译并更新 Release，也可以手动运行只取 artifact。

</details>

## 相关资源

- [PCL 下载](https://meloong.com/pcl)：官方正式版
- [PCL 帮助文档库](https://github.com/LTCatt/PCL2Help)
- [PCL 功能投票](https://github.com/Meloong-Git/PCL/discussions/2)
