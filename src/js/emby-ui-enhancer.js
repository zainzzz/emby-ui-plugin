/**
 * Emby UI Beautification Plugin - Main Enhancer Script
 * 主要增强脚本 - 负责主题注入、配置管理和UI增强
 */

class EmbyUIEnhancer {
    constructor() {
        this.config = {
            currentTheme: 'dark-modern',
            enableCustomization: true,
            debugMode: false,
            autoApply: true,
            customColors: {},
            version: '1.0.0'
        };
        
        this.themes = {
            'dark-modern': {
                name: '深色现代',
                file: 'themes/dark-modern.css',
                category: 'dark'
            },
            'light-elegant': {
                name: '浅色优雅',
                file: 'themes/light-elegant.css',
                category: 'light'
            }
        };
        
        this.isInitialized = false;
        this.styleElement = null;
        this.observers = [];
        
        this.init();
    }
    
    /**
     * 初始化插件
     */
    async init() {
        try {
            this.log('Emby UI Enhancer 正在初始化...');
            
            // 等待DOM加载完成
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.setup());
            } else {
                await this.setup();
            }
            
        } catch (error) {
            this.error('初始化失败:', error);
        }
    }
    
    /**
     * 设置插件
     */
    async setup() {
        try {
            // 加载配置
            await this.loadConfig();
            
            // 应用主题
            await this.applyTheme(this.config.currentTheme);
            
            // 设置观察器
            this.setupObservers();
            
            // 注册全局方法
            this.registerGlobalMethods();
            
            // 添加自定义样式
            this.addCustomStyles();
            
            this.isInitialized = true;
            this.log('Emby UI Enhancer 初始化完成');
            
            // 触发初始化完成事件
            this.dispatchEvent('emby-enhancer:initialized');
            
        } catch (error) {
            this.error('设置失败:', error);
        }
    }
    
    /**
     * 加载配置
     */
    async loadConfig() {
        try {
            // 从localStorage加载配置
            const savedConfig = localStorage.getItem('emby-ui-enhancer-config');
            if (savedConfig) {
                const parsed = JSON.parse(savedConfig);
                this.config = { ...this.config, ...parsed };
            }
            
            // 从服务器加载配置（如果可用）
            try {
                const response = await fetch('/emby-ui-plugin/api/config');
                if (response.ok) {
                    const serverConfig = await response.json();
                    this.config = { ...this.config, ...serverConfig };
                }
            } catch (e) {
                this.log('服务器配置不可用，使用本地配置');
            }
            
            this.log('配置加载完成:', this.config);
            
        } catch (error) {
            this.error('配置加载失败:', error);
        }
    }
    
    /**
     * 保存配置
     */
    async saveConfig() {
        try {
            // 保存到localStorage
            localStorage.setItem('emby-ui-enhancer-config', JSON.stringify(this.config));
            
            // 保存到服务器（如果可用）
            try {
                await fetch('/emby-ui-plugin/api/config', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(this.config)
                });
            } catch (e) {
                this.log('服务器配置保存失败，仅保存到本地');
            }
            
            this.log('配置保存完成');
            
        } catch (error) {
            this.error('配置保存失败:', error);
        }
    }
    
    /**
     * 应用主题
     */
    async applyTheme(themeName) {
        try {
            if (!this.themes[themeName]) {
                throw new Error(`主题 ${themeName} 不存在`);
            }
            
            const theme = this.themes[themeName];
            
            // 移除现有样式
            this.removeCurrentTheme();
            
            // 加载新主题CSS
            const css = await this.loadThemeCSS(theme.file);
            
            // 应用自定义颜色
            const customizedCSS = this.applyCustomColors(css);
            
            // 注入样式
            this.injectCSS(customizedCSS, `emby-theme-${themeName}`);
            
            // 更新配置
            this.config.currentTheme = themeName;
            await this.saveConfig();
            
            // 添加主题类到body
            document.body.classList.add(`emby-theme-${themeName}`);
            document.body.classList.add(`emby-theme-${theme.category}`);
            
            this.log(`主题 ${theme.name} 应用成功`);
            
            // 触发主题变更事件
            this.dispatchEvent('emby-enhancer:theme-changed', { theme: themeName });
            
        } catch (error) {
            this.error('主题应用失败:', error);
        }
    }
    
    /**
     * 加载主题CSS
     */
    async loadThemeCSS(filePath) {
        try {
            const response = await fetch(`/emby-ui-plugin/${filePath}`);
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            return await response.text();
        } catch (error) {
            this.error('CSS加载失败:', error);
            return '';
        }
    }
    
    /**
     * 应用自定义颜色
     */
    applyCustomColors(css) {
        if (!this.config.enableCustomization || !this.config.customColors) {
            return css;
        }
        
        let customizedCSS = css;
        
        // 替换CSS变量
        Object.entries(this.config.customColors).forEach(([variable, color]) => {
            const regex = new RegExp(`--${variable}:\s*[^;]+;`, 'g');
            customizedCSS = customizedCSS.replace(regex, `--${variable}: ${color};`);
        });
        
        return customizedCSS;
    }
    
    /**
     * 注入CSS
     */
    injectCSS(css, id) {
        const styleElement = document.createElement('style');
        styleElement.id = id;
        styleElement.textContent = css;
        document.head.appendChild(styleElement);
        
        this.styleElement = styleElement;
    }
    
    /**
     * 移除当前主题
     */
    removeCurrentTheme() {
        // 移除主题样式
        const existingStyles = document.querySelectorAll('style[id^="emby-theme-"]');
        existingStyles.forEach(style => style.remove());
        
        // 移除主题类
        document.body.classList.forEach(className => {
            if (className.startsWith('emby-theme-')) {
                document.body.classList.remove(className);
            }
        });
    }
    
    /**
     * 添加自定义样式
     */
    addCustomStyles() {
        const customCSS = `
            /* Emby UI Enhancer - 自定义增强样式 */
            
            /* 平滑过渡动画 */
            * {
                transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease !important;
            }
            
            /* 隐藏原生滚动条在某些浏览器中的显示问题 */
            .emby-scroller {
                scrollbar-width: thin;
            }
            
            /* 增强焦点可见性 */
            *:focus {
                outline: 2px solid var(--focus-color, #3b82f6) !important;
                outline-offset: 2px !important;
            }
            
            /* 加载动画优化 */
            .mdl-spinner {
                animation-duration: 1s !important;
            }
            
            /* 响应式字体大小 */
            @media (max-width: 768px) {
                body {
                    font-size: 14px !important;
                }
            }
        `;
        
        this.injectCSS(customCSS, 'emby-enhancer-custom');
    }
    
    /**
     * 设置观察器
     */
    setupObservers() {
        // 观察DOM变化，确保样式持续应用
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.type === 'childList') {
                    // 检查是否有新的页面元素需要应用样式
                    this.enhanceNewElements(mutation.addedNodes);
                }
            });
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
        
        this.observers.push(observer);
    }
    
    /**
     * 增强新元素
     */
    enhanceNewElements(nodes) {
        nodes.forEach(node => {
            if (node.nodeType === Node.ELEMENT_NODE) {
                // 为新的卡片元素添加动画
                if (node.classList && (node.classList.contains('card') || node.classList.contains('cardBox'))) {
                    node.style.animation = 'fadeIn 0.3s ease-out';
                }
                
                // 查找子元素中的卡片
                const cards = node.querySelectorAll && node.querySelectorAll('.card, .cardBox');
                if (cards) {
                    cards.forEach(card => {
                        card.style.animation = 'fadeIn 0.3s ease-out';
                    });
                }
            }
        });
    }
    
    /**
     * 注册全局方法
     */
    registerGlobalMethods() {
        // 注册到window对象，供外部调用
        window.EmbyUIEnhancer = {
            changeTheme: (themeName) => this.applyTheme(themeName),
            getConfig: () => ({ ...this.config }),
            updateConfig: (newConfig) => this.updateConfig(newConfig),
            getThemes: () => ({ ...this.themes }),
            reload: () => this.reload()
        };
    }
    
    /**
     * 更新配置
     */
    async updateConfig(newConfig) {
        try {
            this.config = { ...this.config, ...newConfig };
            await this.saveConfig();
            
            // 如果主题发生变化，重新应用
            if (newConfig.currentTheme && newConfig.currentTheme !== this.config.currentTheme) {
                await this.applyTheme(newConfig.currentTheme);
            }
            
            this.log('配置更新完成');
            
        } catch (error) {
            this.error('配置更新失败:', error);
        }
    }
    
    /**
     * 重新加载插件
     */
    async reload() {
        try {
            this.log('重新加载插件...');
            
            // 清理现有状态
            this.cleanup();
            
            // 重新初始化
            await this.setup();
            
        } catch (error) {
            this.error('重新加载失败:', error);
        }
    }
    
    /**
     * 清理资源
     */
    cleanup() {
        // 移除观察器
        this.observers.forEach(observer => observer.disconnect());
        this.observers = [];
        
        // 移除样式
        this.removeCurrentTheme();
        
        // 移除自定义样式
        const customStyle = document.getElementById('emby-enhancer-custom');
        if (customStyle) {
            customStyle.remove();
        }
        
        this.isInitialized = false;
    }
    
    /**
     * 触发自定义事件
     */
    dispatchEvent(eventName, detail = {}) {
        const event = new CustomEvent(eventName, { detail });
        document.dispatchEvent(event);
    }
    
    /**
     * 日志输出
     */
    log(...args) {
        if (this.config.debugMode) {
            console.log('[Emby UI Enhancer]', ...args);
        }
    }
    
    /**
     * 错误输出
     */
    error(...args) {
        console.error('[Emby UI Enhancer]', ...args);
    }
}

// 自动初始化
if (typeof window !== 'undefined') {
    // 确保只初始化一次
    if (!window.embyUIEnhancerInstance) {
        window.embyUIEnhancerInstance = new EmbyUIEnhancer();
    }
}

// 导出类（用于模块化环境）
if (typeof module !== 'undefined' && module.exports) {
    module.exports = EmbyUIEnhancer;
}