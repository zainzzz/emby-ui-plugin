/**
 * Emby UI Plugin - Configuration Manager
 * 配置管理器 - 负责插件配置的读取、保存和验证
 */

class ConfigManager {
    constructor() {
        this.defaultConfig = {
            version: '1.0.0',
            currentTheme: 'dark-modern',
            enableCustomization: true,
            debugMode: false,
            autoApply: true,
            customColors: {},
            userPreferences: {
                animationSpeed: 'normal',
                borderRadius: 'medium',
                cardSpacing: 'normal'
            },
            advanced: {
                injectDelay: 100,
                observerThrottle: 50,
                cssVariablePrefix: '--emby-'
            }
        };
        
        this.configKey = 'emby-ui-enhancer-config';
        this.apiEndpoint = '/emby-ui-plugin/api/config';
        this.validators = this.setupValidators();
    }
    
    /**
     * 设置配置验证器
     */
    setupValidators() {
        return {
            currentTheme: (value) => {
                const validThemes = ['dark-modern', 'light-elegant'];
                return validThemes.includes(value);
            },
            
            enableCustomization: (value) => typeof value === 'boolean',
            
            debugMode: (value) => typeof value === 'boolean',
            
            autoApply: (value) => typeof value === 'boolean',
            
            customColors: (value) => {
                if (typeof value !== 'object' || value === null) return false;
                // 验证颜色值格式
                for (const [key, color] of Object.entries(value)) {
                    if (typeof key !== 'string' || typeof color !== 'string') return false;
                    if (!this.isValidColor(color)) return false;
                }
                return true;
            },
            
            userPreferences: (value) => {
                if (typeof value !== 'object' || value === null) return false;
                const validAnimationSpeeds = ['slow', 'normal', 'fast'];
                const validBorderRadius = ['small', 'medium', 'large'];
                const validCardSpacing = ['compact', 'normal', 'spacious'];
                
                return (
                    (!value.animationSpeed || validAnimationSpeeds.includes(value.animationSpeed)) &&
                    (!value.borderRadius || validBorderRadius.includes(value.borderRadius)) &&
                    (!value.cardSpacing || validCardSpacing.includes(value.cardSpacing))
                );
            }
        };
    }
    
    /**
     * 验证颜色值
     */
    isValidColor(color) {
        // 支持的颜色格式：hex, rgb, rgba, hsl, hsla, 颜色名称
        const colorRegex = /^(#[0-9A-Fa-f]{3,8}|rgb\(.*\)|rgba\(.*\)|hsl\(.*\)|hsla\(.*\)|[a-zA-Z]+)$/;
        return colorRegex.test(color);
    }
    
    /**
     * 加载配置
     */
    async loadConfig() {
        try {
            let config = { ...this.defaultConfig };
            
            // 1. 从localStorage加载
            const localConfig = this.loadFromLocalStorage();
            if (localConfig) {
                config = this.mergeConfig(config, localConfig);
            }
            
            // 2. 从服务器加载（如果可用）
            const serverConfig = await this.loadFromServer();
            if (serverConfig) {
                config = this.mergeConfig(config, serverConfig);
            }
            
            // 3. 验证配置
            config = this.validateConfig(config);
            
            this.log('配置加载完成:', config);
            return config;
            
        } catch (error) {
            this.error('配置加载失败:', error);
            return { ...this.defaultConfig };
        }
    }
    
    /**
     * 从localStorage加载配置
     */
    loadFromLocalStorage() {
        try {
            const saved = localStorage.getItem(this.configKey);
            if (saved) {
                return JSON.parse(saved);
            }
        } catch (error) {
            this.error('localStorage配置解析失败:', error);
        }
        return null;
    }
    
    /**
     * 从服务器加载配置
     */
    async loadFromServer() {
        try {
            const response = await fetch(this.apiEndpoint, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });
            
            if (response.ok) {
                return await response.json();
            } else {
                this.log('服务器配置不可用:', response.status);
            }
        } catch (error) {
            this.log('服务器配置加载失败:', error.message);
        }
        return null;
    }
    
    /**
     * 保存配置
     */
    async saveConfig(config) {
        try {
            // 验证配置
            const validatedConfig = this.validateConfig(config);
            
            // 保存到localStorage
            this.saveToLocalStorage(validatedConfig);
            
            // 保存到服务器
            await this.saveToServer(validatedConfig);
            
            this.log('配置保存完成');
            return validatedConfig;
            
        } catch (error) {
            this.error('配置保存失败:', error);
            throw error;
        }
    }
    
    /**
     * 保存到localStorage
     */
    saveToLocalStorage(config) {
        try {
            localStorage.setItem(this.configKey, JSON.stringify(config));
        } catch (error) {
            this.error('localStorage保存失败:', error);
            throw error;
        }
    }
    
    /**
     * 保存到服务器
     */
    async saveToServer(config) {
        try {
            const response = await fetch(this.apiEndpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(config)
            });
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
        } catch (error) {
            this.log('服务器配置保存失败:', error.message);
            // 不抛出错误，允许仅本地保存
        }
    }
    
    /**
     * 合并配置
     */
    mergeConfig(baseConfig, newConfig) {
        const merged = { ...baseConfig };
        
        Object.keys(newConfig).forEach(key => {
            if (key in this.defaultConfig) {
                if (typeof this.defaultConfig[key] === 'object' && this.defaultConfig[key] !== null) {
                    merged[key] = { ...merged[key], ...newConfig[key] };
                } else {
                    merged[key] = newConfig[key];
                }
            }
        });
        
        return merged;
    }
    
    /**
     * 验证配置
     */
    validateConfig(config) {
        const validated = { ...this.defaultConfig };
        
        Object.keys(config).forEach(key => {
            if (key in this.validators) {
                if (this.validators[key](config[key])) {
                    if (typeof this.defaultConfig[key] === 'object' && this.defaultConfig[key] !== null) {
                        validated[key] = { ...validated[key], ...config[key] };
                    } else {
                        validated[key] = config[key];
                    }
                } else {
                    this.log(`配置项 ${key} 验证失败，使用默认值`);
                }
            } else if (key in this.defaultConfig) {
                validated[key] = config[key];
            }
        });
        
        return validated;
    }
    
    /**
     * 重置配置
     */
    async resetConfig() {
        try {
            const defaultConfig = { ...this.defaultConfig };
            await this.saveConfig(defaultConfig);
            this.log('配置已重置为默认值');
            return defaultConfig;
        } catch (error) {
            this.error('配置重置失败:', error);
            throw error;
        }
    }
    
    /**
     * 导出配置
     */
    async exportConfig() {
        try {
            const config = await this.loadConfig();
            const exportData = {
                version: config.version,
                exportDate: new Date().toISOString(),
                config: config
            };
            
            return JSON.stringify(exportData, null, 2);
        } catch (error) {
            this.error('配置导出失败:', error);
            throw error;
        }
    }
    
    /**
     * 导入配置
     */
    async importConfig(configData) {
        try {
            let importedData;
            
            if (typeof configData === 'string') {
                importedData = JSON.parse(configData);
            } else {
                importedData = configData;
            }
            
            // 验证导入数据格式
            if (!importedData.config) {
                throw new Error('无效的配置文件格式');
            }
            
            // 验证版本兼容性
            if (importedData.version && importedData.version !== this.defaultConfig.version) {
                this.log('配置文件版本不同，尝试兼容性转换');
            }
            
            const validatedConfig = this.validateConfig(importedData.config);
            await this.saveConfig(validatedConfig);
            
            this.log('配置导入完成');
            return validatedConfig;
            
        } catch (error) {
            this.error('配置导入失败:', error);
            throw error;
        }
    }
    
    /**
     * 获取配置项
     */
    async getConfigValue(key, defaultValue = null) {
        try {
            const config = await this.loadConfig();
            return this.getNestedValue(config, key, defaultValue);
        } catch (error) {
            this.error('获取配置项失败:', error);
            return defaultValue;
        }
    }
    
    /**
     * 设置配置项
     */
    async setConfigValue(key, value) {
        try {
            const config = await this.loadConfig();
            this.setNestedValue(config, key, value);
            return await this.saveConfig(config);
        } catch (error) {
            this.error('设置配置项失败:', error);
            throw error;
        }
    }
    
    /**
     * 获取嵌套值
     */
    getNestedValue(obj, path, defaultValue = null) {
        const keys = path.split('.');
        let current = obj;
        
        for (const key of keys) {
            if (current && typeof current === 'object' && key in current) {
                current = current[key];
            } else {
                return defaultValue;
            }
        }
        
        return current;
    }
    
    /**
     * 设置嵌套值
     */
    setNestedValue(obj, path, value) {
        const keys = path.split('.');
        let current = obj;
        
        for (let i = 0; i < keys.length - 1; i++) {
            const key = keys[i];
            if (!(key in current) || typeof current[key] !== 'object') {
                current[key] = {};
            }
            current = current[key];
        }
        
        current[keys[keys.length - 1]] = value;
    }
    
    /**
     * 日志输出
     */
    log(...args) {
        console.log('[Config Manager]', ...args);
    }
    
    /**
     * 错误输出
     */
    error(...args) {
        console.error('[Config Manager]', ...args);
    }
}

// 导出单例
const configManager = new ConfigManager();

if (typeof window !== 'undefined') {
    window.EmbyConfigManager = configManager;
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = ConfigManager;
}