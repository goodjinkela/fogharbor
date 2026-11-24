# 雾港回声 · FogHarbor

> 交互式剧情探索与多分支决策应用 · HarmonyOS / ArkTS / ArkUI
> 《移动应用开发基础》期末大作业（主题一）

---

## 一、项目简介

1937 年的上海，雾夜。你是《申报》记者沈砚，一封匿名信把你引向三年前沉没的「永昌号」。

《雾港回声》是一款**以数据驱动的交互式剧情应用**：剧情节点、选项、触发条件、属性变化全部由数据结构描述，由 `StoryEngine` 真实执行条件判断与结局裁定，而不是把分支写死在界面里。玩家的每一次选择都会改变「线索 / 信任 / 理智」三项属性，并决定最终走向 5 个不同结局。

应用支持**自动存档 + 3 个手动存档位**，关闭进程后重新打开可以从最近的决策点继续；结局图鉴跨周目保留，鼓励重复探索。

---

## 二、功能说明

| 模块 | 功能 |
| --- | --- |
| 剧情探索 | 11 个剧情节点、3 章 + 终章，逐字打字机呈现，可轻触跳过 |
| 多分支决策 | 每个节点 2–3 个选项；8 个条件选项按「线索 / 信任 / 理智」阈值动态解锁，未满足时置灰并提示原因 |
| 属性系统 | 线索、信任、理智三维属性，取值 0–10，属性变化即时反馈并记录 |
| 结局裁定 | 按优先级判定 5 个结局：雾散(S)、余烬(A)、共谋(B)、离岸(C)、失踪者(C) |
| 存档 | 自动存档实时写入；3 个手动存档位，支持覆盖、删除；读取后从该决策点继续 |
| 结局图鉴 | 记录已解锁结局，跨周目保留 |
| 剧情回顾 | 本局所有决策的时间线与属性变化 |
| 设置 | 打字速度（8–60ms/字）、动效开关、清除全部数据 |
| 视觉 | 统一深色雾金主题、渐变背景、卡片按压反馈、选项淡入动效 |

---

## 三、技术栈

- **语言**：ArkTS（API 17）
- **UI**：ArkUI 声明式开发，`Navigation` + `NavPathStack` + `NavDestination` 页面导航
- **状态管理**：`@State` / `@Prop` / `@StorageProp` + `@Watch`，单向数据流（Engine → ViewModel → UI）
- **持久化**：`@kit.ArkData` 的 `preferences`，JSON 序列化 + `flush()` 落盘
- **测试**：`@ohos/hypium` 单元测试（正常 / 边界 / 异常三类）
- **工程模型**：Stage 模型，单 HAP 模块 `entry`

---

## 四、开发与运行环境

| 项 | 版本 |
| --- | --- |
| DevEco Studio | 5.0.13（DS-233.14475.28.36.5013240） |
| HarmonyOS SDK | 5.0.5（API 17） |
| 模拟器 | Huawei_Phone，HarmonyOS 5.0.5(17)，x86_64 |
| 构建工具 | hvigor 5.17.6 |
| 目标设备 | phone / tablet / 2in1 |

---

## 五、目录结构

```
FogHarbor/
├── AppScope/                          # 应用级配置与图标
├── entry/src/main/ets/
│   ├── entryability/EntryAbility.ets  # 入口：深色主题、后台兜底存档
│   ├── pages/
│   │   ├── Index.ets                  # 首页 + Navigation 路由表
│   │   ├── StoryPage.ets              # 故事页（打字机、选项、结局）
│   │   ├── SavesPage.ets              # 存档 / 读档
│   │   ├── GalleryPage.ets            # 结局图鉴
│   │   ├── HistoryPage.ets            # 剧情回顾
│   │   └── SettingsPage.ets           # 设置
│   ├── component/Common.ets           # StatBar / ChoiceCard / MenuRow
│   ├── common/Theme.ets               # 视觉规范
│   ├── model/
│   │   ├── Types.ets                  # 领域模型与视图模型
│   │   ├── StoryData.ets              # 11 个节点 + 5 个结局
│   │   └── GameState.ets              # 对局状态与 JSON 序列化
│   ├── domain/StoryEngine.ets         # 条件判断、属性结算、结局裁定
│   ├── data/SaveRepository.ets        # preferences 读写
│   └── service/GameService.ets        # 应用级单例，串联引擎与仓库
├── entry/src/ohosTest/ets/test/       # Hypium 测试
├── README.md
└── docs/                              # 需求说明书、报告模板、截图
```

---

## 六、运行方式

1. DevEco Studio → `File > Open`，选择本工程根目录（含 `build-profile.json5` 的目录）。
2. 等待 Sync 完成（首次会下载依赖）。
3. 配置签名：`File > Project Structure > Project > Signing Configs`，勾选 **Automatically generate signature**（需登录华为账号，未实名需先实名）。
4. `Tools > Device Manager > Local Emulator`，启动 `Huawei_Phone`。
5. 选择模块 `entry`，点击 ▶ Run，安装到模拟器。
6. 首次进入首页 → 点击「开始调查」。

> 命令行构建（可选）：
> ```powershell
> $env:JAVA_HOME='D:\HUAWEI\DevEco Studio\jbr'
> $env:NODE_HOME='D:\HUAWEI\DevEco Studio\tools\node'
> $env:PATH="$env:JAVA_HOME\bin;$env:NODE_HOME;$env:PATH"
> $env:DEVECO_SDK_HOME='D:\HUAWEI\DevEco Studio\sdk'
> hvigorw --mode module -p product=default -p module=entry@default assembleHap
> ```

---

## 七、单元测试

测试代码位于 `entry/src/ohosTest/ets/test/StoryEngine.test.ets`，覆盖：

| 类型 | 用例 |
| --- | --- |
| 正常 | 选择后节点跳转、属性增加、日志写入；视图包含 3 项属性与 3 个选项 |
| 边界 | 属性恰好等于阈值时解锁、属性上下限夹取、四种比较运算符 |
| 异常 | 不存在的选项、未满足条件的选项、空/损坏的存档 JSON |

运行方式：DevEco Studio 中右键 `StoryEngine.test.ets` → `Run`，或执行 `hvigorw --mode module -p module=entry@ohosTest test`。

---

## 八、页面截图

运行后把截图放到 `docs/screenshots/`，文件名与下表一致即可正常显示。

| 首页 | 故事页 | 结局 |
| --- | --- | --- |
| ![首页](docs/screenshots/01-home.png) | ![故事](docs/screenshots/02-story.png) | ![结局](docs/screenshots/03-ending.png) |

| 存档 | 图鉴 | 回顾 |
| --- | --- | --- |
| ![存档](docs/screenshots/04-saves.png) | ![图鉴](docs/screenshots/05-gallery.png) | ![回顾](docs/screenshots/06-history.png) |

---

## 九、运行录屏

【待补充：录屏文件或链接，建议 3–5 分钟，覆盖「新建 → 选择 → 存档 → 杀进程 → 恢复 → 结局」】

---

## 十、开发说明

- 工程在 DevEco Studio 5.0.13 + SDK 5.0.5(17) 下通过 `assembleHap` 构建（`BUILD SUCCESSFUL`）。
- 业务逻辑与 UI 解耦：`StoryEngine` 不依赖任何 UI 与持久化 API，可独立单元测试。
- 所有分支与结局均由数据 + 规则计算得出，新增剧情只需在 `StoryData.ets` 中追加节点，无需改动页面代码。
