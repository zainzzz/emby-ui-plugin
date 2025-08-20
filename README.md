# Emby UI 美化插件

一个专为 Emby 服务器设计的 UI 美化插件，支持多种主题和自定义配置，可轻松集成到 `linuxserver/emby` Docker 容器中。

## ✨ 特性

- 🎨 **多主题支持** - 内置深色现代主题和浅色优雅主题
- 🔧 **高度可定制** - 支持颜色、字体、布局等全方位自定义
- 🐳 **Docker 集成** - 专为 Docker 容器环境优化
- 📱 **响应式设计** - 完美适配桌面和移动设备
- ⚡ **性能优化** - 轻量级设计，不影响 Emby 性能
- 🔒 **安全可靠** - 不修改 Emby 核心文件，安全无风险
- 🌐 **多语言支持** - 支持中文和英文界面

## 🖼️ 预览

### 深色现代主题
![深色主题预览](https://via.placeholder.com/800x450/1a1a1a/667eea?text=Dark+Modern+Theme)

### 浅色优雅主题
![浅色主题预览](https://via.placeholder.com/800x450/f7fafc/718096?text=Light+Elegant+Theme)

## 🚀 快速开始

### 方法一：Docker Compose（推荐）

1. **下载项目文件**
   ```bash
   git clone https://github.com/zainzzz/emby-ui-plugin.git
   cd emby-ui-plugin
   ```

2. **配置环境变量**
   ```bash
   cp .env.example .env
   # 编辑 .env 文件，设置您的配置
   ```

3. **启动容器**
   ```bash
   docker-compose up -d
   ```

4. **访问 Emby**
   - Emby 服务：http://localhost:8096
   - 插件管理：http://localhost:8096/plugins/emby-ui-plugin/

### 方法二：现有容器集成

如果您已经有运行中的 Emby 容器，可以通过以下方式集成插件：

1. **下载插件文件**
   ```bash
   wget https://github.com/zainzzz/emby-ui-plugin/releases/latest/download/emby-ui-plugin.tar.gz
   tar -xzf emby-ui-plugin.tar.gz
   ```

2. **复制到容器**
   ```bash
   docker cp emby-ui-plugin/ your-emby-container:/opt/emby-ui-plugin/
   ```

3. **执行安装脚本**
   ```bash
   docker exec your-emby-container /opt/emby-ui-plugin/scripts/install-plugin.sh
   ```

4. **重启容器**
   ```bash
   docker restart your-emby-container
   ```

## 📋 系统要求

- **Emby 版本**：4.7.0 或更高版本
- **Docker**：20.10 或更高版本
- **浏览器**：支持现代浏览器（Chrome 80+、Firefox 75+、Safari 13+、Edge 80+）
- **系统资源**：额外占用约 10MB 存储空间

## ⚙️ 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `EMBY_UI_PLUGIN_ENABLED` | `true` | 是否启用插件 |
| `EMBY_UI_PLUGIN_THEME` | `dark-modern` | 默认主题 |
| `EMBY_UI_PLUGIN_DEBUG` | `false` | 调试模式 |
| `EMBY_UI_PLUGIN_AUTO_APPLY` | `true` | 自动应用主题 |
| `EMBY_UI_PLUGIN_ALLOW_CUSTOMIZATION` | `true` | 允许用户自定义 |

### 主题配置

插件支持以下主题：

- **dark-modern**：深色现代主题，适合夜间使用
- **light-elegant**：浅色优雅主题，适合日间使用
- **custom**：自定义主题，支持完全自定义

### 自定义配置

您可以通过以下方式自定义插件：

1. **Web 界面**：访问 `http://your-emby-server/plugins/emby-ui-plugin/`
2. **配置文件**：编辑 `/config/emby-ui-plugin/config.json`
3. **环境变量**：在 Docker 启动时设置

## 🎨 主题定制

### 创建自定义主题

1. **复制现有主题**
   ```bash
   cp themes/dark-modern.css themes/my-theme.css
   ```

2. **编辑主题文件**
   ```css
   :root {
     --emby-primary-color: #your-color;
     --emby-secondary-color: #your-color;
     /* 更多自定义变量... */
   }
   ```

3. **注册主题**
   编辑 `theme-config.json`，添加您的主题配置。

### CSS 变量参考

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `--emby-primary-color` | 主色调 | `#667eea` |
| `--emby-secondary-color` | 次要色调 | `#718096` |
| `--emby-accent-color` | 强调色 | `#f093fb` |
| `--emby-background-color` | 背景色 | `#1a1a1a` |
| `--emby-text-color` | 文字色 | `#ffffff` |
| `--emby-border-radius` | 圆角大小 | `8px` |

## 🔧 高级配置

### 性能优化

```json
{
  "performance": {
    "injectDelay": 100,
    "observerThrottle": 50,
    "enableCache": true,
    "preloadThemes": false
  }
}
```

### 自定义 CSS

您可以在配置中添加自定义 CSS：

```json
{
  "advanced": {
    "customCSS": ".emby-card { box-shadow: 0 4px 8px rgba(0,0,0,0.3); }"
  }
}
```

### API 端点

插件提供以下 API 端点：

- `GET /plugins/emby-ui-plugin/api/config` - 获取配置
- `POST /plugins/emby-ui-plugin/api/config` - 保存配置
- `GET /plugins/emby-ui-plugin/api/backups` - 获取备份列表
- `DELETE /plugins/emby-ui-plugin/api/backups/{filename}` - 删除备份

## 🐛 故障排除

### 常见问题

**Q: 插件没有生效？**
A: 请检查：
1. 确认插件已启用（`EMBY_UI_PLUGIN_ENABLED=true`）
2. 清除浏览器缓存
3. 检查 Emby 日志是否有错误信息

**Q: 主题切换后没有变化？**
A: 请尝试：
1. 强制刷新页面（Ctrl+F5）
2. 检查浏览器控制台是否有错误
3. 确认主题文件存在且格式正确

**Q: 自定义 CSS 不生效？**
A: 请确认：
1. CSS 语法正确
2. 选择器优先级足够高
3. 没有被其他样式覆盖

### 调试模式

启用调试模式可以获得更详细的日志信息：

```bash
docker-compose down
EMBY_UI_PLUGIN_DEBUG=true docker-compose up -d
```

### 日志查看

```bash
# 查看插件日志
docker exec your-emby-container tail -f /config/emby-ui-plugin/plugin.log

# 查看 Emby 日志
docker logs your-emby-container
```

## 🔄 更新插件

### 自动更新（推荐）

```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```

### 手动更新

1. **备份配置**
   ```bash
   docker cp your-emby-container:/config/emby-ui-plugin/config.json ./config-backup.json
   ```

2. **下载新版本**
   ```bash
   wget https://github.com/your-username/emby-ui-plugin/releases/latest/download/emby-ui-plugin.tar.gz
   ```

3. **替换文件**
   ```bash
   docker exec your-emby-container rm -rf /opt/emby-ui-plugin
   docker cp emby-ui-plugin/ your-emby-container:/opt/emby-ui-plugin/
   ```

4. **恢复配置**
   ```bash
   docker cp ./config-backup.json your-emby-container:/config/emby-ui-plugin/config.json
   ```

5. **重启容器**
   ```bash
   docker restart your-emby-container
   ```

## 🤝 贡献指南

我们欢迎社区贡献！请遵循以下步骤：

1. **Fork 项目**
2. **创建功能分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
4. **推送分支** (`git push origin feature/AmazingFeature`)
5. **创建 Pull Request**

### 开发环境设置

```bash
# 克隆项目
git clone https://github.com/your-username/emby-ui-plugin.git
cd emby-ui-plugin

# 启动开发环境
docker-compose -f docker-compose.dev.yml up -d

# 查看日志
docker-compose logs -f
```

### 代码规范

- **CSS**：使用 BEM 命名规范
- **JavaScript**：使用 ES6+ 语法
- **PHP**：遵循 PSR-12 标准
- **提交信息**：使用 [Conventional Commits](https://conventionalcommits.org/) 格式

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Emby](https://emby.media/) - 优秀的媒体服务器软件
- [LinuxServer.io](https://www.linuxserver.io/) - 提供优质的 Docker 镜像
- 所有贡献者和用户的支持

## 📞 支持

如果您遇到问题或有建议，请通过以下方式联系我们：

- **GitHub Issues**：[提交问题](https://github.com/zainzzz/emby-ui-plugin/issues)
- **讨论区**：[GitHub Discussions](https://github.com/zainzzz/emby-ui-plugin/discussions)
- **邮箱**：support@example.com

## 🗺️ 路线图

- [ ] 添加更多内置主题
- [ ] 支持主题市场
- [ ] 添加动画效果配置
- [ ] 支持插件热更新
- [ ] 添加移动端专用优化
- [ ] 集成第三方图标库
- [ ] 支持多语言界面

---

**⭐ 如果这个项目对您有帮助，请给我们一个 Star！**