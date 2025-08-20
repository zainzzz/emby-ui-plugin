# Emby UI Beautification Plugin - Dockerfile
# 基于 linuxserver/emby 的美化插件容器

FROM linuxserver/emby:latest

# 设置维护者信息
LABEL maintainer="Emby UI Plugin Team"
LABEL description="Emby Server with UI Beautification Plugin"
LABEL version="1.0.0"

# 设置环境变量
ENV EMBY_UI_PLUGIN_VERSION=1.0.0
ENV EMBY_UI_PLUGIN_PATH=/config/plugins/emby-ui-plugin
ENV EMBY_WEB_PATH=/opt/emby-server/system/dashboard-ui

# 创建插件目录
RUN mkdir -p ${EMBY_UI_PLUGIN_PATH} \
    && mkdir -p /tmp/emby-ui-plugin

# 复制插件文件
COPY . /tmp/emby-ui-plugin/

# 安装插件脚本
COPY scripts/install-plugin.sh /tmp/install-plugin.sh
RUN chmod +x /tmp/install-plugin.sh

# 复制启动脚本
COPY scripts/init-plugin.sh /etc/cont-init.d/99-emby-ui-plugin
RUN chmod +x /etc/cont-init.d/99-emby-ui-plugin

# 复制服务脚本
COPY scripts/plugin-service.sh /etc/services.d/emby-ui-plugin/run
RUN mkdir -p /etc/services.d/emby-ui-plugin \
    && chmod +x /etc/services.d/emby-ui-plugin/run

# 设置权限
RUN chown -R abc:abc /tmp/emby-ui-plugin \
    && chmod -R 755 /tmp/emby-ui-plugin

# 暴露端口（继承自基础镜像）
# 8096: Emby HTTP端口
# 8920: Emby HTTPS端口
# 1900: DLNA端口
# 7359: Emby自动发现端口

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8096/health || exit 1

# 数据卷
VOLUME ["/config", "/data/tvshows", "/data/movies"]

# 工作目录
WORKDIR /config

# 启动命令（继承自基础镜像）