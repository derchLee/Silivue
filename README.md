# Silivue

[English](README_EN.md) · 简体中文

![Silivue 图标](Design/Silivue-AppIcon-Source.png)

Silivue 是一款原生、轻量、完全免费的 macOS 菜单栏系统监控工具。它可以实时查看 CPU、内存、网络、磁盘、电池、温度和进程状态，并提供历史趋势与详细数据窗口。

## 功能

- CPU 总体、用户和系统占用率
- 内存使用量、缓存、交换空间和内存压力
- 网络上传/下载速度与连接信息
- 磁盘容量和读写活动
- 电池电量、充电状态与健康信息
- 温度和风扇状态（取决于设备支持情况）
- 进程 CPU、内存、路径和端口信息
- 实时图表与本地历史数据
- 多种菜单栏显示模式和刷新频率
- 登录时自动启动

所有功能均免费，无订阅、应用内购买或功能门槛。

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15 或兼容 Swift 5.9 的工具链

## 构建与运行

```bash
git clone <repository-url>
cd Silivue
swift build
swift run Silivue
```

也可以在 Xcode 中打开 `Package.swift`，选择 `Silivue` Scheme 后运行。

## 测试

```bash
swift test
```

## 打包

生成调试安装包：

```bash
./Scripts/build-debug-package.sh
```

生成 DMG 和 PKG 分发包：

```bash
./Scripts/build-dmg.sh
```

正式分发前需要在 Xcode 和 Apple Developer 后台配置对应的签名、Bundle ID 与 App Group：

- Bundle ID：`com.upupdays.silivue`
- App Group：`group.com.upupdays.silivue`

## 隐私

Silivue 的系统监控和历史记录在本机完成。当前版本不会上传进程名称、文件路径、网络地址或系统监控数据。

## 项目结构

```text
Sources/MonitorEngine   系统数据采集与监控引擎
Sources/DataLayer       设置与历史数据存储
Sources/UIComponents    SwiftUI/AppKit 界面组件
Sources/StatusStats     应用入口（内部源码目录名）
Tests                   单元测试与集成测试
```

## 许可证

当前仓库尚未附加开源许可证。未经许可，不代表授予复制、修改或分发权利。
