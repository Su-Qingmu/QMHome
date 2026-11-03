# Harmtwo 智能家居 App — 全面改造计划

> **项目概述**: HarmonyOS 智能家居 / IoT 控制应用  
> **当前基线**: compatibleSdkVersion 5.0.2(14) → targetSdkVersion 6.0.1(21)  
> **目标**: 升级到 HarmonyOS 7 (API 26)，向下兼容 HarmonyOS 5，补齐功能，美化 UI

---

## 一、版本升级方案（鸿蒙 7 适配 + 向下兼容鸿蒙 5）

### 1.1 配置变更

#### ① 工程级 `build-profile.json5`

```json5
{
  app: {
    products: [
      {
        name: 'default',
        signingConfig: 'default',
        compatibleSdkVersion: '5.0.0(12)',   // ← 降到 API 12（覆盖全部 HarmonyOS NEXT 5.x 设备）
        targetSdkVersion: '26.0.0',            // ← 升到 API 26（HarmonyOS 7）
        runtimeOS: 'HarmonyOS',
        buildOption: {
          strictMode: {
            caseSensitiveCheck: true,
            useNormalizedOHMUrl: true,
          },
        },
      },
    ],
  },
}
```

> **原则**: `compatibleSdkVersion` 决定安装门槛，保持低值；`targetSdkVersion` 决定行为开关，设为最新。

#### ② `oh-package.json5` — 依赖准备

```json5
{
  "dependencies": {
    // 无额外依赖，保持纯净
  }
}
```

### 1.2 废弃 API 替换清单（API 18+ 废弃，API 26 必须改）

| 废弃旧用法 | 替换为新用法 | 涉及文件 |
|---|---|---|
| `router.pushUrl()` / `router.back()` | `this.getUIContext().getRouter().pushUrl()` / `.back()` | Facility, Environment, Light, Monitor, Smokealarm, test2 |
| `router.getParams()` | `this.getUIContext().getRouter().getParams()` | 所有页面 |
| `getContext()` | `this.getUIContext().getHostContext()` | 所有页面 |
| `promptAction.showToast()` | `this.getUIContext().getPromptAction().showToast()` | 所有页面 |
| `vp2px()` / `px2vp()` 全局函数 | `this.getUIContext().vp2px()` / `.px2vp()` | 所有使用单位转换的地方 |
| `animateTo()` 全局函数 | `this.getUIContext().animateTo()` | 需要动画的地方 |
| `import router from '@ohos.router'` | `import { router } from '@kit.ArkUI'` | 所有页面 |
| `TextDecoder.decodeWithStream()` | `TextDecoder.decodeToString()` | server.ets, tcp_on.ets |

### 1.3 兼容性保护策略

对于使用 API 26 新增特性的代码，需要做版本判断：

```typescript
import { deviceInfo } from '@kit.BasicServicesKit';

// 对 OpenHarmony 底座接口
if (deviceInfo.sdkApiVersion >= 26) {
  // 使用 API 26 新特性
} else {
  // 降级方案
}

// 对 HarmonyOS 独有接口
if (deviceInfo.distributionOSApiVersion >= 260000) {
  // 使用 HMS 特性
} else {
  // 降级方案
}

// 对 SysCap（系统能力）判断
if (canIUse('SystemCapability.XXX.YYY')) {
  // 使用该能力
}
```

---

## 二、功能补齐计划（分 Phase 执行）

### Phase 1: 基础清理与 Bug 修复（1-2 天）

| 编号 | 任务 | 说明 |
|---|---|---|
| 1.1 | 🗑️ 清理重复/测试页面 | 删除 `test.ets`、`test2.ets`、`receDataTest.ets`；从 `main_pages.json` 中移除注册 |
| 1.2 | 🔧 **合并灯光控制** | 将 `test2.ets`（功能最完整，含 Socket 发送与频率控制）重命名为正式组件，替换 `Light.ets` |
| 1.3 | 🐛 **修复烟雾弹窗 Bug** | `SmokePrivacy.ets` 第 48 行 `this.showAlert = true` → `false`，使"我知道了"按钮正确关闭弹窗 |
| 1.4 | 🔄 **页面路由统一** | 全部从 `@ohos.router` 迁移到 `@kit.ArkUI` 的 Navigation 路由方案 |
| 1.5 | 📁 **文件结构调整** | `SmokePrivacy.ets` 从 `entryability/` 移到 `pages/view/` 或新建 `pages/components/` 目录 |

### Phase 2: 补齐核心功能 WIP（3-5 天）

| 编号 | 任务 | 说明 |
|---|---|---|
| 2.1 | 🌡️ **环境监测 - 数据联动** | 恢复 `Environment.ets` 中 `aboutToAppear` 的注释代码，接入 TCP 实时数据更新；增加温湿度趋势图表（SimpleLine） |
| 2.2 | 📷 **门锁监控 - 开锁记录** | 恢复 `Monitor.ets` 中被注释的 `lockRecords` 列表，增加真实数据源（TCP 回调）+ 动态刷新 |
| 2.3 | 🏠 **生活页 - 场景联动** | 为 `Dailylife.ets` 中 6 个场景卡片（离家/回家/灯全关/人来灯亮/氛围/观影/空气净化）实现 onClick 跳转和功能 |
| 2.4 | 👤 **个人中心 - 功能实现** | 为 `MineContent.ets` 的 8 个设置项（个人资料/语音控制/中枢网关/密保问题/设备管理/应用授权/检测更新/关于）添加路由跳转或弹窗 |
| 2.5 | 🔌 **TCP 连接 UI 优化** | 将各页面暴露的 TCP 连接原始输入框封装为可复用的 `TcpConnectPanel` 组件，统一管理连接状态 |

### Phase 3: 新增功能（5-7 天）

| 编号 | 任务 | 说明 |
|---|---|---|
| 3.1 | 📡 **设备发现扫描页** | 新建 `DeviceDiscovery.ets`，展示 BLE/UDP 扫描到的设备列表，支持一键配网绑定 |
| 3.2 | 🔔 **场景自动化配置** | 新建 `SceneConfig.ets`，允许用户创建条件-动作自动化规则（如"温度 > 30°C 时关灯"） |
| 3.3 | 📊 **数据持久化** | 使用 `Preferences`（首选项）保存用户配置（灯光偏好、场景设置、TCP 地址） |
| 3.4 | 🔐 **NFC 门禁绑定 UI** | 新建 `NfcBinding.ets`，对接蓝牙工具类的 BLE 配网流程（当前 `Bluetooth.ets` 中 UUID 为占位值 XXXX/YYYY/ZZZZ，需替换为实际值） |
| 3.5 | 📱 **设备配对引导页** | 新建 `DevicePairing.ets`，引导用户通过 BLE / 扫码 / 手动输入方式添加新设备 |
| 3.6 | 📈 **环境历史趋势** | 在 `Environment.ets` 中增加温湿度历史曲线（使用 `Canvas` 自定义绘制或简单折线图组件） |

---

## 三、UI 美化方案

### 3.1 设计语言升级

当前评价：**功能完备但视觉粗糙**，纯色背景 + 硬编码布局，缺乏层次感。

改造方向：采用 **HarmonyOS Design System** 设计规范，打造 Smart Home 沉浸式体验。

### 3.2 具体美化项

| 编号 | 美化项 | 当前状态 | 改造方案 |
|---|---|---|---|
| 4.1 | 🎨 **配色系统** | 橄榄绿 + 森林绿，颜色偏单一 | 升级为渐变色主题：深色模式（深蓝灰 `#1A1A2E`） + 浅色模式（冰蓝白 `#F0F4F8`），主色调改为科技蓝 `#007AFF` / 翡翠绿 `#00C853` |
| 4.2 | 🌓 **深色模式** | `setColorMode(COLOR_MODE_NOT_SET)` 未启用 | 在 `EntryAbility.ets` 中监听系统深色模式变化，用 `@Provide` 下发主题色；所有页面适配深色配色 |
| 4.3 | ✨ **卡片动效** | 无动画，静态展示 | 添加入场动效（`animateTo` + `transition`）、按压反馈（`scale` 缩放）、列表项滑动删除等 |
| 4.4 | 🖼️ **设备卡片** | 纯白底 + 文本，无层次感 | 增加阴影层级（`shadow`）、毛玻璃效果（`.backgroundBlurStyle()`）、圆角+边界光效 |
| 4.5 | 🌐 **响应式布局** | 硬编码宽高比 | 使用 `Grid` 断点布局 + `MediaQuery` 适配折叠屏/平板/PC |
| 4.6 | 🎯 **图标升级** | 单色 SVG 图标 | 使用 HarmonyOS Symbol 符号字体（`$r('sys.symbol.xxx')`）或彩色 SVG 图标集 |
| 4.7 | 📊 **数据可视化** | 纯文本数字 | 温湿度环状进度条、设备状态指示徽章、历史趋势图（Canvas 绘制） |
| 4.8 | 🔄 **过渡动画** | Tab 切换无动画 | Tabs 切换动画 + 页面转场动画（`pageTransition`） |
| 4.9 | 🏠 **顶部天气区** | 固定"苏州 14°" | 调用 Location Kit 获取真实位置 + Weather Service Kit（API 26 新增）获取实时天气 |
| 4.10 | 📱 **启动屏** | 默认白色启动屏 | 自定义启动屏（品牌 Logo + 加载动画） |

### 3.3 全局样式提取

创建 `GlobalStyles.ets` 集中管理通用样式：

```typescript
// 通用卡片样式
@Styles function cardStyle() {
  .backgroundColor(Color.White)
  .borderRadius(16)
  .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
}

// 通用标题样式
@Styles function titleStyle() {
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
}

// 通用图标尺寸
const ICON_SIZE_SMALL = 20;
const ICON_SIZE_MEDIUM = 24;
const ICON_SIZE_LARGE = 40;
```

---

## 四、实施路线图（总工期约 4-6 周）

```
Week 1:  Phase 1（清理修复）+ 版本升级配置
         ├── 清理重复页面 + 路由配置
         ├── 废弃 API 替换（router, getContext, animateTo 等）
         ├── 版本配置更新（compatibleSdk→12, targetSdk→26）
         ├── Bug 修复（烟雾弹窗、灯光合并）
         └── 编译验证 + 真机测试

Week 2:  Phase 2（核心功能补齐）
         ├── 环境监测数据联动 + 图表
         ├── 门锁监控记录恢复
         ├── 生活页场景跳转实现
         ├── 个人中心设置项功能
         └── TCP 连接组件化封装

Week 3-4: Phase 3（新增功能）
          ├── 设备发现扫描页
          ├── 场景自动化配置页
          ├── 数据持久化（Preferences）
          ├── NFC 门禁绑定 UI
          ├── 设备配对引导页
          └── 环境历史趋势图表

Week 4-6: UI 美化 + 综合测试
          ├── 配色系统升级（浅色+深色）
          ├── 全局样式提取（GlobalStyles）
          ├── 卡片动效 + 阴影层次
          ├── 响应式布局适配
          ├── 数据可视化增强
          ├── 过渡动画 + 启动屏
          └── 兼容性回归测试（API 12 ~ API 26）
```

---

## 五、兼容性测试 Checklist

| 测试项 | 覆盖设备 | 验证方式 |
|---|---|---|
| 安装测试 | API 12 / 14 / 17 / 20 / 26 | 全部可正常安装 |
| 基础导航 | 手机 / 平板 / 2in1 | 3 Tab 切换正常 |
| 灯光控制 | 所有 API 版本 | 亮度/色温/开关操作正常 |
| 环境监测 | 所有 API 版本 | 温湿度显示 + 图表渲染 |
| 门锁监控 | 所有 API 版本 | 摄像头区 + 开锁记录 |
| 烟雾报警 | 所有 API 版本 | 模拟触发 + 弹窗 + 关闭 |
| TCP 通信 | 所有 API 版本 | 连接/发送/接收/断开 |
| BLE 配网 | API 18+（需蓝牙） | 扫描/连接/配网 |
| 场景联动 | 所有 API 版本 | 6 个场景卡片可触发 |
| 深色模式 | API 18+ | 手动/自动切换 |
| 废弃 API | API 26 设备 | 无 deprecated 警告 |

---

## 六、注意事项

1. **签名配置不变**：`build-profile.json5` 中的签名路径指向本地调试证书，更换机器需重新配置
2. **`compatibleSdkVersion` 降到 12**：覆盖全部 HarmonyOS NEXT 5.x 设备，扩大安装范围
3. **API 26 新特性可选接入**：沉浸光感（`ohos.arkui.UIMaterial.state`）、Agent/Skill 等可在 Phase 3 之后评估
4. **`Bluetooth.ets` 中占位 UUID**：`SERVICE_UUID = 'XXXX'`, `CHAR_WRITE_UUID = 'YYYY'`, `CHAR_NOTIFY_UUID = 'ZZZZ'` 需替换为实际 ESP32 设备 UUID
5. **`oh-package.json5` 保持纯净**：不引入额外三方依赖，所有功能基于系统 Kit 实现
