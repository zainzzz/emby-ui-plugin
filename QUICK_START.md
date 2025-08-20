# 🚀 Emby UI 美化插件 - 快速开始指南

本指南将帮助您在 5 分钟内快速部署和使用 Emby UI 美化插件。

## 📋 前置要求

- Emby Server 4.7+ 或 Docker 环境
- 管理员权限（用于安装插件）
- 现代浏览器（Chrome 90+, Firefox 88+, Safari 14+）

## 🐳 方式一：Docker 快速部署（推荐）

### 1. 下载项目
```bash
git clone https://github.com/zainzzz/emby-ui-plugin.git
cd emby-ui-plugin
```

### 2. 配置环境变量
```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置文件（可选）
nano .env
```

### 3. 启动服务
```bash
# 使用 Docker Compose 启动
docker-compose up -d

# 查看启动状态
docker-compose logs -f
```

### 4. 访问 Emby
打开浏览器访问：`http://localhost:8096`

🎉 **完成！** 您现在应该能看到美化后的 Emby 界面。

---

## 💻 方式二：现有 Emby 服务器安装

### Windows 用户

1. **下载插件**
   ```powershell
   # 下载到本地目录
   git clone https://github.com/zainzzz/emby-ui-plugin.git
   cd emby-ui-plugin
   ```

2. **运行安装脚本**
   ```powershell
   # 以管理员身份运行 PowerShell
   .\scripts\install-plugin.ps1
   
   # 自定义 Emby 路径（如果需要）
   .\scripts\install-plugin.ps1 -EmbyPath "D:\Emby"
   ```

3. **重启 Emby 服务**
   - 在服务管理器中重启 Emby Server 服务
   - 或使用命令：`Restart-Service EmbyServer`

### Linux/macOS 用户

1. **下载插件**
   ```bash
   git clone https://github.com/zainzzz/emby-ui-plugin.git
   cd emby-ui-plugin
   ```

2. **运行安装脚本**
   ```bash
   chmod +x scripts/install-plugin.sh
   sudo ./scripts/install-plugin.sh
   
   # 自定义 Emby 路径（如果需要）
   sudo ./scripts/install-plugin.sh /opt/emby-server
   ```

3. **重启 Emby 服务**
   ```bash
   sudo systemctl restart emby-server
   # 或
   sudo service emby-server restart
   ```

---

## ⚙️ 基本配置

### 1. 访问插件设置
访问：`http://your-emby-server:8096/plugins/emby-ui-plugin/pages/settings.html`

### 2. 选择主题
- **深色现代主题**：适合夜间使用，现代感强
- **浅色优雅主题**：适合日间使用，简洁优雅
- **自定义主题**：根据个人喜好自定义颜色

### 3. 自定义颜色（可选）
在设置页面的「外观」选项卡中：
- 调整主色调
- 修改强调色
- 设置背景透明度
- 自定义按钮样式

---

## 🔧 常见问题解决

### 问题 1：插件没有生效
**解决方案：**
1. 清除浏览器缓存
2. 强制刷新页面（Ctrl+F5 或 Cmd+Shift+R）
3. 检查 Emby 服务器日志
4. 确认插件文件权限正确

### 问题 2：主题显示异常
**解决方案：**
1. 检查浏览器控制台是否有错误
2. 尝试切换到默认主题
3. 重新安装插件

### 问题 3：Docker 容器启动失败
**解决方案：**
1. 检查端口是否被占用：`netstat -an | grep 8096`
2. 查看容器日志：`docker-compose logs`
3. 确认 Docker 版本兼容性

### 问题 4：权限错误
**解决方案：**
1. 确保以管理员身份运行安装脚本
2. 检查文件夹权限：`ls -la /path/to/emby`
3. 修复权限：`sudo chown -R emby:emby /path/to/emby`

---

## 📱 移动端优化

插件自动适配移动设备，但您可以进一步优化：

1. **启用移动端优化**
   ```javascript
   // 在自定义 CSS 中添加
   @media (max-width: 768px) {
     .emby-card {
       margin: 0.5rem;
       border-radius: 8px;
     }
   }
   ```

2. **调整触摸友好性**
   - 增大按钮尺寸
   - 优化滑动手势
   - 简化导航菜单

---

## 🎨 主题预览

### 深色现代主题
- 🌙 深色背景，护眼舒适
- ✨ 现代渐变效果
- 🎯 高对比度文字
- 💫 流畅动画过渡

### 浅色优雅主题
- ☀️ 明亮清新界面
- 🎨 柔和色彩搭配
- 📖 优秀可读性
- 🌸 简洁优雅设计

---

## 🔄 更新插件

### 自动更新（Docker）
```bash
# 拉取最新镜像
docker-compose pull

# 重启服务
docker-compose up -d
```

### 手动更新
```bash
# 下载最新版本
git pull origin main

# 重新安装
./scripts/install-plugin.sh

# 重启 Emby
sudo systemctl restart emby-server
```

---

## 📞 获取帮助

- 📖 **完整文档**：[README.md](./README.md)
- 🐛 **问题反馈**：[GitHub Issues](https://github.com/zainzzz/emby-ui-plugin/issues)
- 💬 **社区讨论**：[GitHub Discussions](https://github.com/zainzzz/emby-ui-plugin/discussions)
- 📧 **邮件支持**：support@example.com

---

## 🎯 下一步

1. **探索高级功能**：查看 [README.md](./README.md) 了解更多配置选项
2. **自定义主题**：学习如何创建自己的主题
3. **性能优化**：根据服务器配置调整性能参数
4. **备份配置**：定期备份您的自定义设置

---

**🎉 享受您的全新 Emby 体验！**

如果这个插件对您有帮助，请考虑给我们一个 ⭐ Star！