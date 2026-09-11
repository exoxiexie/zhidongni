# 智懂你 · AI 管家集合

> 每个主体身份，都值得一个终身陪伴的 AI 管家。

智懂你是一款基于 Flutter 开发的安卓应用，定位为**垂类 AI 管家的集合产品**。通过铆定用户的主体身份（企业、职业、学生等），为每个身份提供主动式、全生命周期的 AI 管家服务。

## 产品理念

传统的通用 Agent 是"任务式、助手式"的，因为没有身份铆定，无法做到主体式、主动式。智懂你认为：

- **先做垂直，再做通用**：先在高价值身份主体（企业、职业、学生、股票等）上做深做透
- **UniText 上下文宇宙**：为每个主体身份构建持续沉淀的上下文库，让 AI 越来越懂你
- **主动式管家**：不是等用户提问，而是基于数据库主动生成洞察、预警和行动建议

## 功能特性

### 已实现

- **企业主体登录**：基于企业真实名称注册登录（企查查 API 兼容，当前使用模拟数据）
- **AI 对话**：支持 DeepSeek V4 系列模型，流式输出，多模态文件解析
- **历史会话**：多对话管理，左侧抽屉切换，对话标题自动生成
- **数据库（UniText）**：企业主体信息展示，上下文宇宙的具象化
- **洞察**：基于数据库的主动式洞察入口（深入洞察、风险预警）
- **应用内更新**：Gitee + GitHub 双源更新，下载进度实时显示
- **USB OTG 文件读取**：支持手机直连 U 盘/移动硬盘读取文件

### 规划中

- 职业管家（职管家）：全生命周期职业规划
- 企业管家（企管家）：企业风险预警、供应链发现
- 股票管家（票管家）：个股追踪与分析
- 学生管家（学管家）：学习规划与成长
- Agent 长程任务规划与循环执行
- UniText 权重矩阵记忆系统

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端框架 | Flutter 3.x (Dart) |
| 平台 | Android (minSdk 21, targetSdk 34) |
| AI 模型 | DeepSeek V4 系列 (Flash / Pro / Vision Expert / V4.1 Flash) |
| Agent 框架 | DeepSeek Harness (DSH) 插件系统 |
| 状态管理 | Flutter 原生 StatefulWidget |
| 网络请求 | Dio + WebSocket (流式) |
| 本地存储 | SharedPreferences |
| 文件解析 | 多模态模型原生能力 + OCR |
| 持续集成 | Gitee + GitHub 双仓库同步 |

## 项目结构

```
lib/
├── contracts/              # 接口契约（模型无关、框架无关）
│   ├── chat_service.dart   # 对话服务契约 + 模型配置
│   ├── agent_service.dart  # Agent 服务契约
│   └── update_service.dart # 更新服务契约
├── features/               # 业务模块（文件夹硬隔离）
│   ├── chat/               # 对话模块
│   ├── agent/              # Agent 模块
│   ├── enterprise/         # 企业主体模块（登录/注册/数据）
│   ├── tabs/               # 底部 Tab 页面
│   │   ├── home_tab.dart       # 对话页
│   │   ├── database_tab.dart   # 数据库页（UniText）
│   │   ├── insight_tab.dart    # 洞察页
│   │   ├── files_tab.dart      # 文件页
│   │   └── profile_tab.dart    # 我的页
│   ├── shell/              # 主框架（底部导航 + 抽屉）
│   └── update/             # 应用内更新模块
└── main.dart               # 入口
```

**工程铁律**：
1. 前端驱动后端
2. 模块最小化，文件夹硬隔离，修改不产生连带效应
3. 契约层（contracts）与实现层（features）分离，模型无关、框架无关

## 快速开始

### 环境要求

- Flutter 3.10+
- Android Studio / VS Code
- Android SDK (API 21+)

### 构建

```bash
# 安装依赖
flutter pub get

# 构建 Release APK
flutter build apk --release

# 产物位置
build/app/outputs/flutter-apk/app-release.apk
```

### 开发

```bash
# 连接设备后运行
flutter run

# 热重载
r
```

## 版本历史

详见 [Gitee Releases](https://gitee.com/laoxie2076/zhidongni/releases)

| 版本 | 主要内容 |
|------|----------|
| v1.1.x | 企业主体登录、数据库、洞察页、历史会话 |
| v1.0.x | 基础对话、模型选择、流式输出、应用内更新 |

## 提交规范

本项目采用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 修复 bug |
| `docs` | 文档变更 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 重构（既不是新功能也不是修 bug） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具/依赖变更 |
| `ci` | CI/CD 相关 |

### 示例

```
feat(chat): 新增历史会话管理，支持左侧抽屉切换

- 添加 Conversation 模型
- 对话页右上角笔图标新建对话
- 抽屉展示真实历史会话列表
- 对话标题自动用第一条消息前15字生成

fix(update): 修复下载进度条不更新问题

1.1.3 重写时误将 setDialogState 改成 setState，
导致对话框内 StatefulBuilder 不重建，进度条永远0%。
```

## 双仓库同步

本项目采用 **Gitee + GitHub 双仓库同步** 策略：

- **Gitee**：主发布平台，国内访问快，APK 下载、应用内更新
- **GitHub**：技术影响力平台，代码同步、提交记录、开源背书

每次提交自动推送到两个平台。

- Gitee: https://gitee.com/laoxie2076/zhidongni
- GitHub: https://github.com/exoxiexie/zhidongni

## 许可证

MIT License
