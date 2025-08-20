# 🤝 贡献指南

感谢您对 Emby UI 美化插件项目的关注！我们欢迎所有形式的贡献，无论是代码、文档、设计还是反馈。

## 📋 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发环境设置](#开发环境设置)
- [代码规范](#代码规范)
- [提交规范](#提交规范)
- [Pull Request 流程](#pull-request-流程)
- [问题报告](#问题报告)
- [功能请求](#功能请求)
- [文档贡献](#文档贡献)
- [社区支持](#社区支持)

## 🤝 行为准则

### 我们的承诺

为了营造一个开放和友好的环境，我们作为贡献者和维护者承诺：无论年龄、体型、残疾、种族、性别认同和表达、经验水平、国籍、个人形象、种族、宗教或性取向如何，参与我们项目和社区的每个人都能获得无骚扰的体验。

### 我们的标准

**积极行为包括：**
- ✅ 使用友好和包容的语言
- ✅ 尊重不同的观点和经验
- ✅ 优雅地接受建设性批评
- ✅ 关注对社区最有利的事情
- ✅ 对其他社区成员表示同理心

**不可接受的行为包括：**
- ❌ 使用性化的语言或图像
- ❌ 恶意评论、人身攻击或政治攻击
- ❌ 公开或私下骚扰
- ❌ 未经明确许可发布他人的私人信息
- ❌ 在专业环境中被认为不当的其他行为

## 🚀 如何贡献

### 贡献类型

我们欢迎以下类型的贡献：

1. **🐛 Bug 修复**
   - 修复现有功能中的错误
   - 改进错误处理
   - 性能问题修复

2. **✨ 新功能**
   - 新的主题设计
   - 用户界面改进
   - 新的配置选项
   - API 功能扩展

3. **📖 文档改进**
   - 修正文档错误
   - 添加使用示例
   - 翻译文档
   - 改进代码注释

4. **🎨 设计优化**
   - UI/UX 改进
   - 新的主题设计
   - 图标和图像优化
   - 响应式设计改进

5. **🧪 测试**
   - 添加单元测试
   - 集成测试
   - 性能测试
   - 兼容性测试

## 🛠️ 开发环境设置

### 前置要求

- **Node.js** 16+ 和 npm/yarn
- **Docker** 和 Docker Compose（用于测试）
- **Git** 版本控制
- **现代代码编辑器**（推荐 VS Code）

### 环境配置

1. **Fork 和克隆项目**
   ```bash
   # Fork 项目到您的 GitHub 账户
   # 然后克隆您的 fork
   git clone https://github.com/YOUR_USERNAME/emby-ui-plugin.git
   cd emby-ui-plugin
   
   # 添加上游仓库
   git remote add upstream https://github.com/original-repo/emby-ui-plugin.git
   ```

2. **安装依赖**
   ```bash
   # 如果项目有 package.json
   npm install
   # 或
   yarn install
   ```

3. **设置开发环境**
   ```bash
   # 复制环境变量模板
   cp .env.example .env
   
   # 编辑配置文件
   nano .env
   ```

4. **启动开发环境**
   ```bash
   # 使用 Docker Compose 启动测试环境
   docker-compose -f docker-compose.dev.yml up -d
   
   # 或手动设置 Emby 测试环境
   ```

### VS Code 配置

推荐的 VS Code 扩展：
- **ESLint** - JavaScript 代码检查
- **Prettier** - 代码格式化
- **CSS Peek** - CSS 类名跳转
- **Live Server** - 本地开发服务器
- **GitLens** - Git 增强功能

## 📝 代码规范

### JavaScript 规范

```javascript
// ✅ 好的示例
class ThemeManager {
  constructor(config) {
    this.config = config;
    this.themes = new Map();
  }
  
  /**
   * 应用主题到页面
   * @param {string} themeName - 主题名称
   * @returns {Promise<boolean>} 是否成功应用
   */
  async applyTheme(themeName) {
    try {
      const theme = await this.loadTheme(themeName);
      this.injectCSS(theme.css);
      return true;
    } catch (error) {
      console.error(`Failed to apply theme ${themeName}:`, error);
      return false;
    }
  }
}

// ❌ 避免的写法
function apply_theme(name) {
  var css = get_theme_css(name);
  document.head.innerHTML += '<style>' + css + '</style>';
}
```

### CSS 规范

```css
/* ✅ 好的示例 */
:root {
  --emby-primary-color: #667eea;
  --emby-secondary-color: #718096;
  --emby-accent-color: #f093fb;
  --emby-background-opacity: 0.9;
}

.emby-card {
  background: var(--emby-card-background);
  border-radius: var(--emby-border-radius);
  box-shadow: var(--emby-shadow-medium);
  transition: all 0.3s ease;
}

.emby-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--emby-shadow-large);
}

/* ❌ 避免的写法 */
.card {
  background: #333 !important;
  border-radius: 8px !important;
}
```

### 命名规范

- **CSS 类名**：使用 `emby-` 前缀，kebab-case 格式
- **JavaScript 变量**：camelCase 格式
- **常量**：UPPER_SNAKE_CASE 格式
- **文件名**：kebab-case 格式

### 注释规范

```javascript
/**
 * 配置管理器类
 * 负责加载、保存和验证插件配置
 */
class ConfigManager {
  /**
   * 加载配置文件
   * @param {string} configPath - 配置文件路径
   * @param {Object} defaultConfig - 默认配置
   * @returns {Promise<Object>} 配置对象
   * @throws {Error} 当配置文件无效时抛出错误
   */
  async loadConfig(configPath, defaultConfig = {}) {
    // 实现代码...
  }
}
```

## 📤 提交规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

### 提交消息格式

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 提交类型

- **feat**: 新功能
- **fix**: Bug 修复
- **docs**: 文档更新
- **style**: 代码格式化（不影响功能）
- **refactor**: 代码重构
- **perf**: 性能优化
- **test**: 测试相关
- **chore**: 构建过程或辅助工具的变动

### 示例

```bash
# 新功能
git commit -m "feat(themes): add light elegant theme with custom variables"

# Bug 修复
git commit -m "fix(config): resolve theme switching issue on mobile devices"

# 文档更新
git commit -m "docs(readme): update installation instructions for Windows"

# 重构
git commit -m "refactor(css): reorganize theme variables for better maintainability"
```

## 🔄 Pull Request 流程

### 1. 准备工作

```bash
# 确保您的 fork 是最新的
git checkout main
git pull upstream main
git push origin main

# 创建新的功能分支
git checkout -b feature/your-feature-name
```

### 2. 开发和测试

- 编写代码并遵循代码规范
- 添加必要的测试
- 确保所有测试通过
- 更新相关文档

### 3. 提交更改

```bash
# 添加更改
git add .

# 提交（遵循提交规范）
git commit -m "feat(themes): add dark mode toggle functionality"

# 推送到您的 fork
git push origin feature/your-feature-name
```

### 4. 创建 Pull Request

1. 访问 GitHub 上的原始仓库
2. 点击 "New Pull Request"
3. 选择您的分支
4. 填写 PR 模板

### PR 模板

```markdown
## 📝 变更描述

简要描述此 PR 的变更内容。

## 🔧 变更类型

- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 代码重构
- [ ] 性能优化
- [ ] 其他（请说明）

## 🧪 测试

- [ ] 已添加单元测试
- [ ] 已进行手动测试
- [ ] 所有现有测试通过
- [ ] 已测试多种浏览器
- [ ] 已测试移动端

## 📱 截图（如适用）

添加相关截图来展示变更效果。

## ✅ 检查清单

- [ ] 代码遵循项目规范
- [ ] 已更新相关文档
- [ ] 提交消息遵循规范
- [ ] 已解决所有冲突
- [ ] PR 标题清晰明确
```

## 🐛 问题报告

### 报告 Bug

使用 [GitHub Issues](https://github.com/your-repo/emby-ui-plugin/issues) 报告 Bug。

**Bug 报告应包含：**

1. **环境信息**
   - Emby Server 版本
   - 浏览器和版本
   - 操作系统
   - 插件版本

2. **重现步骤**
   - 详细的操作步骤
   - 预期行为
   - 实际行为

3. **附加信息**
   - 错误截图
   - 浏览器控制台日志
   - Emby 服务器日志
   - 配置文件（去除敏感信息）

### Bug 报告模板

```markdown
## 🐛 Bug 描述

简要描述遇到的问题。

## 🔄 重现步骤

1. 进入 '...'
2. 点击 '...'
3. 滚动到 '...'
4. 看到错误

## ✅ 预期行为

描述您期望发生的行为。

## ❌ 实际行为

描述实际发生的行为。

## 📱 环境信息

- **Emby Server**: [版本]
- **浏览器**: [浏览器和版本]
- **操作系统**: [操作系统和版本]
- **插件版本**: [插件版本]

## 📎 附加信息

添加任何其他有助于解决问题的信息。
```

## 💡 功能请求

### 提出新功能

使用 [GitHub Discussions](https://github.com/your-repo/emby-ui-plugin/discussions) 讨论新功能想法。

**功能请求应包含：**

1. **问题描述**：当前的痛点或需求
2. **解决方案**：建议的功能实现
3. **替代方案**：考虑过的其他解决方案
4. **使用场景**：具体的使用案例
5. **优先级**：功能的重要性评估

## 📖 文档贡献

### 文档类型

- **用户文档**：安装、配置、使用指南
- **开发文档**：API 文档、架构说明
- **示例代码**：使用示例和最佳实践
- **翻译**：多语言支持

### 文档规范

- 使用清晰的标题结构
- 提供代码示例
- 包含截图和图表
- 保持内容更新
- 使用友好的语调

## 🌐 国际化

我们欢迎翻译贡献！

### 支持的语言

- 🇺🇸 English（主要语言）
- 🇨🇳 简体中文
- 🇹🇼 繁体中文
- 🇯🇵 日本語
- 🇰🇷 한국어
- 🇩🇪 Deutsch
- 🇫🇷 Français
- 🇪🇸 Español

### 翻译流程

1. 检查现有翻译状态
2. 创建或更新语言文件
3. 遵循翻译规范
4. 提交 Pull Request

## 🏆 贡献者认可

我们重视每一个贡献！贡献者将获得：

- 📝 在 README 中的贡献者列表
- 🏅 GitHub 贡献者徽章
- 🎉 在发布说明中的特别感谢
- 💌 贡献者专属邮件更新

## 📞 获取帮助

如果您在贡献过程中遇到问题：

- 💬 **GitHub Discussions**：[项目讨论区](https://github.com/your-repo/emby-ui-plugin/discussions)
- 📧 **邮件联系**：dev@example.com
- 🐛 **问题报告**：[GitHub Issues](https://github.com/your-repo/emby-ui-plugin/issues)
- 💭 **实时聊天**：[Discord 服务器](https://discord.gg/your-server)

## 🙏 感谢

感谢您考虑为 Emby UI 美化插件做出贡献！每一个贡献，无论大小，都让这个项目变得更好。

我们期待与您一起构建更好的 Emby 用户体验！ 🚀