# Reflection - 日程专注应用

一个基于 Swift 和 SwiftUI 开发的日程/专注应用，帮助用户管理时间分配、专注工作和分析效率。

## 功能特点

### 📅 计划管理
- 创建时间分配计划表（项目：对应时间）
- 查看计划进度和完成情况
- 显示计划与实际时间的差异

### ⏰ 专注会话
- 开始专注活动（可选择已有项目或自定义）
- 实时计时器显示专注时间
- 随时结束专注会话

### 📊 统计分析
- 统计时间分配情况
- 分析计划表与实际投入时间的差异
- 项目效率分析
- 总体完成率展示

## 项目结构

```
reflection/
├── App/                           # 应用入口
│   ├── ContentView.swift          # 主界面（TabView）
│   └── reflectionApp.swift        # 应用入口
├── Features/                      # 功能模块
│   ├── Planning/                  # 计划管理
│   │   ├── Views/
│   │   │   ├── PlanView.swift     # 计划界面
│   │   │   └── CreatePlanView.swift # 创建计划界面
│   │   └── Models/
│   │       └── PlanModel.swift    # 计划数据模型
│   ├── Focus/                     # 专注功能
│   │   ├── Views/
│   │   │   ├── SessionView.swift  # 专注界面
│   │   │   ├── TimerView.swift    # 计时器组件
│   │   │   └── StartSessionView.swift # 开始会话界面
│   │   └── Models/
│   │       └── SessionModel.swift # 专注会话模型
│   └── Statistics/                # 统计分析
│       ├── Views/
│       │   └── StatisticsView.swift # 统计界面
│       └── Models/
│           └── StatisticsModel.swift # 统计数据模型
├── Core/                          # 核心功能
│   ├── Data/
│   │   └── DataManager.swift      # 数据管理
│   └── Utils/
│       └── TimeFormatters.swift   # 时间格式化工具
└── Assets.xcassets/               # 资源文件
```

## 技术栈

- **Swift 5+**
- **SwiftUI** - 用户界面框架
- **UserDefaults** - 本地数据存储
- **Combine** - 响应式编程
- **Foundation** - 基础框架

## 使用说明

### 1. 创建计划
1. 点击"计划"标签页
2. 点击右上角的"+"按钮
3. 输入项目名称和计划时间
4. 支持的时间格式：
   - `30` (30分钟)
   - `1:30` (1小时30分钟)
   - `2:30:45` (2小时30分45秒)

### 2. 开始专注
1. 点击"专注"标签页
2. 点击右上角的播放按钮
3. 选择已有项目或创建自定义项目
4. 输入具体任务描述
5. 开始专注会话

### 3. 查看统计
1. 点击"统计"标签页
2. 查看总体统计数据
3. 查看各项目的详细统计
4. 分析效率和完成情况

## 特色功能

- 🎯 **智能时间追踪**：自动记录专注时间并关联到对应项目
- 📈 **详细统计分析**：多维度展示时间使用情况
- 🎨 **现代化界面**：使用 SwiftUI 构建的美观界面
- 💾 **本地数据存储**：使用 UserDefaults 实现数据持久化
- 🔄 **实时更新**：数据变化时自动刷新界面

## 开发环境

- Xcode 15.0+
- macOS 13.0+
- Swift 5.9+

## 构建和运行

1. 克隆项目到本地
2. 使用 Xcode 打开 `reflection.xcodeproj`
3. 选择目标设备
4. 点击运行按钮或按 `Cmd+R`

## 未来规划

- [ ] 支持数据导出功能
- [ ] 添加提醒通知
- [ ] 支持多种统计图表
- [ ] 添加番茄钟功能
- [ ] 支持云同步
- [ ] 深色模式优化

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License
