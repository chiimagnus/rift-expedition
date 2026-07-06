# 首章本地分发验收清单

检查日期：2026-07-06

## 本地产物

- 可运行 App：`build/release/RiftExpedition.app`
- 本地 zip 包：`build/release/RiftExpedition-macOS-local.zip`
- App 大小：约 11 MB
- zip 大小：约 3.2 MB
- 产物目录 `build/` 已被 `.gitignore` 忽略，不提交二进制构建产物。

## 已执行验证

- `rtk env DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project RiftExpedition.xcodeproj -scheme RiftExpedition -destination 'platform=macOS' test -quiet`
  - 结果：通过。
- `rtk env DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --package-path Packages/RiftCore`
  - 结果：通过，38 个 RiftCore 测试通过。
- `rtk env DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift run --package-path Tools/RiftValidator RiftValidator RiftExpedition/Resources`
  - 结果：通过，10 张资源地图、世界图谱、地图数据引用和资源授权均无问题。
- `rtk env DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -project RiftExpedition.xcodeproj -scheme RiftExpedition -configuration Release -destination 'platform=macOS' -derivedDataPath build/DerivedData build -quiet`
  - 结果：通过，已生成 Release App。

## 签名与分发状态

- 当前 App 为 ad-hoc 签名，Mach-O universal：`x86_64 arm64`。
- `spctl --assess` 结果：未通过，因为当前没有 Developer ID 签名和 notarization。
- 本 task 只交付本机可运行包；站外发给其他机器前必须补 Developer ID 签名、hardened runtime、notarytool notarization、staple，并重新跑 `spctl --assess`。

## 后续正式发布步骤

1. 配置 Developer ID Application 证书与 Team ID。
2. 打开 hardened runtime，并确认 entitlements 最小化。
3. 使用 `xcodebuild archive` 生成归档。
4. 使用 `xcrun notarytool submit` 提交 notarization。
5. 使用 `xcrun stapler staple` 固化 notarization ticket。
6. 重新执行 Gatekeeper 校验和干净机器启动验收。
