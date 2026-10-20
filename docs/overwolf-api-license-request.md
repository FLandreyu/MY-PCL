# 向 Overwolf / CurseForge 申请「公开发布版内置 API Key」的书面许可（草稿）

## 为什么需要这一步

CurseForge 第三方 API 条款（[官方原文](https://support.curseforge.com/support/solutions/articles/9000207405)）：

- **§2.2**：API Key 是个人专属、不可转让的，**不得与任何第三方共享**，只能向负有保密义务的内部人员披露。
- **§2.3**：应用用量超过 Overwolf 设定的配额时，继续使用可能需要与 Overwolf 签订**书面许可协议**（可能含付费条款）。

按 §2.2，把 Key 编进公开发布的 exe 等于向所有下载者披露，属于违规；一旦被发现，Key 会被吊销，发布版全部失效。因此**唯一合法实现「下载即用」的路径，是拿到 Overwolf 的书面许可**（§2.3 的协议），而不是直接内置。

## 怎么发

1. 打开 <https://support.curseforge.com/>，右上角 **Contact support** 新建工单；
2. 分类选 **3rd Party API**，主题用下面的英文标题；
3. 正文粘贴英文草稿，按实际情况替换 `<...>` 占位符；
4. 附上：GitHub 仓库链接、Release 链接、Entra 应用 ID（`7674a7ae-35c1-437c-b97b-a44025124f67`）、已有 API 申请单号（若有）；
5. 等待回复（API 类工单通常 48–72 小时首次响应，许可事项可能更久）。

> 也可以在提交 API Key 申请表单时，在用途说明里直接写明「计划内置到公开发布的开源启动器，请求 §2.3 书面许可」，两边信息一致更好。

## 英文草稿

```text
Subject: Request for written permission under §2.3 — embedding a CurseForge API key in a publicly distributed open-source Minecraft launcher

Dear Overwolf / CurseForge API team,

We maintain MY-PCL (https://github.com/FLandreyu/MY-PCL), a free, non-commercial,
community-built fork of the open-source PCL launcher for Minecraft: Java Edition.
The launcher is distributed as a single Windows executable through GitHub Releases;
its full source and built binaries are public.

We would like CurseForge integration to work out of the box for our users:
searching for mods and modpacks, and resolving file metadata plus download URLs so a
user who imports a CurseForge modpack (a .zip whose manifest.json has no "addons"
section) can install it.

Under the CurseForge 3rd Party API Terms §2.2 the API key is personal, non-transferable
and must not be shared with third parties. Today every one of our users would therefore
have to apply for, obtain and configure their own key, which is impractical for a
general-purpose launcher. §2.3 allows Overwolf to require a written licensing agreement
for continued API use, so we would like to request written permission to embed an API key
issued to us inside our publicly distributed builds.

Details:
- Application: MY-PCL Launcher (Entra app ID 7674a7ae-35c1-437c-b97b-a44025124f67),
  Windows x64 desktop, .NET Framework 4.8, single-file exe
- Distribution: GitHub Releases, free of charge, no ads, no bundling of CurseForge
  content beyond what the API returns for user-initiated installs
- API usage (read-only): GET /v1/mods/search, GET /v1/mods/{id}/files,
  GET /v1/mods/files — on demand, initiated by the user
- Volume: expected to be modest at first; we can report usage and accept the rate
  limits and quota you set
- Compliance: no proxy/VPN to conceal location (§3.1(e)); no redistribution or resale
  of CurseForge content or data; UI attribution to CurseForge; the key is stored only
  inside the build and never printed in logs or exposed to users
- Non-commercial: the project has no revenue; we are willing to sign an agreement and
  pay reasonable fees if required

Could you confirm whether such written permission (or a partner/quota arrangement) is
possible, and what you would need from us — expected volume, application review, a
signed agreement? If approval is not possible, we will keep CurseForge as an optional
feature that requires a user-supplied key, and recommend Modrinth by default.

Thank you for your time.

<your name>
Maintainer, MY-PCL
https://github.com/FLandreyu/MY-PCL
<contact email>
```

## 如果被拒绝

不批是常态，按下面处理即可，不影响「下载即用」的主线：

1. **CurseForge 保持「用户自备 Key」的可选增强**，并在 README / Release 里写清；
2. **默认推荐 Modrinth**：无需 Key、无需配置，搜索和整合包安装开箱即用；
3. 继续保留从 CurseForge 网页手动下载整合包再拖进启动器的路径（不需要 Key）。

## 如果获批

拿到书面许可后：

1. 把 Key 写入 `Plain Craft Launcher 2/Modules/ModSecret.vb:12` 的默认值（保留环境变量优先，方便高级用户覆盖）；
2. 在 README 注明「本版本内置的 CurseForge Key 依据 §2.3 书面许可使用」，并遵守协议里的配额与归属要求；
3. 重编、发版，用户零配置即可使用 CurseForge 搜索。
