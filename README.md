# adpz

Windows OOPZ 客户端的本地界面精简补丁。项目包含补丁脚本及少量字节变更清单，不分发 OOPZ 程序或用户数据。

补丁针对广告列表、登录与商城广告弹窗、推广横幅和活动入口，以及商城、加速器、娱乐、开通 VIP 和系统通知红点。发现页推广导航也会隐藏，好友和频道提醒保留。具体行为以客户端版本为准。

> OOPZ 服务协议禁止未经许可屏蔽广告，使用本项目存在账号风险，无法保证不被封号。软件更新可能覆盖补丁，也可能增加本项目尚未覆盖的广告。

## 支持版本与验证状态

目前仅针对 Windows OOPZ 主程序文件版本 **0.91.31** 的特定 `data/app.so` 构建：

| 文件 | SHA-256 |
| --- | --- |
| 原始 `app.so` | `94a08a77c3c5138a365afb48e2c0cda9740dea02a14e018c26333217238b5178` |
| 打补丁后 | `05c91a3c05b185ee6947037135dbc9767a0fa9fb9388f3b91edcacf87e6c2b15` |

补丁已在该版本写入，并通过完整文件哈希检查；用户反馈实际使用测试一切正常。其他版本会被脚本拒绝，不能直接使用旧版补丁。

## 使用

1. 备份工作并关闭正在进行的通话。应用或恢复补丁时，脚本会关闭并重新启动 OOPZ。
2. 双击 `Apply.cmd` 应用补丁；双击 `Check.cmd` 检查当前文件状态。
3. 双击 `Restore.cmd` 从本地备份恢复原始版本。

也可以使用 PowerShell：

```powershell
powershell.exe -NoProfile -File .\OOPZ-Clean.ps1
powershell.exe -NoProfile -File .\OOPZ-Clean.ps1 -Check
powershell.exe -NoProfile -File .\OOPZ-Clean.ps1 -Restore
```

备份位于 `%LOCALAPPDATA%\OOPZ-Clean\backups\`，按原文件 SHA-256 命名。脚本检查原文件哈希、各补丁位置的原始字节和最终哈希；恢复时也检查备份哈希。请保留备份，直到不再需要恢复。

## 工作原理与范围

`patch-manifest.json` 列出受支持构建的偏移、原始字节和替换字节。脚本只在完整哈希匹配时修改本地文件，不依赖代理或修改系统 hosts。每次 OOPZ 更新后，需要针对新版本重新分析并验证，不能假设旧偏移仍然有效。

本项目与 OOPZ 官方无关。客户端包含广告曝光及操作埋点；目前没有证据足以判断服务端是否通过这些数据或其他方式检测屏蔽行为。项目不声称消除账号风险。

## 许可证

本项目代码和自行编写的文档采用 [GNU Affero General Public License v3.0](LICENSE)（AGPL-3.0-only）。Copyright © 2026 HosisoraLing。OOPZ 及其资源归各自权利人所有。
