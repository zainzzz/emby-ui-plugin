#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// 项目根目录
const projectRoot = path.resolve(__dirname, '..');

// 必需的文件和目录结构
const requiredStructure = {
  files: [
    'README.md',
    'LICENSE',
    'CHANGELOG.md',
    'CONTRIBUTING.md',
    'QUICK_START.md',
    '.env.example',
    'package.json',
    'Dockerfile',
    'docker-compose.yml'
  ],
  directories: [
    'src',
    'src/js',
    'src/css',
    'themes',
    'pages',
    'api',
    'scripts',
    'docker'
  ],
  themeFiles: [
    'themes/dark-modern.css',
    'themes/light-elegant.css'
  ],
  jsFiles: [
    'src/js/emby-ui-enhancer.js',
    'src/js/config-manager.js'
  ],
  pageFiles: [
    'pages/plugin-manager.html',
    'pages/theme-preview.html',
    'pages/settings.html'
  ],
  scriptFiles: [
    'scripts/install-plugin.sh',
    'scripts/init-plugin.sh',
    'scripts/plugin-service.sh',
    'scripts/install-plugin.ps1',
    'scripts/uninstall-plugin.ps1'
  ],
  apiFiles: [
    'api/config.php'
  ]
};

// 验证函数
function validateStructure() {
  let errors = [];
  let warnings = [];
  
  console.log('🔍 验证项目结构...');
  
  // 检查必需的目录
  requiredStructure.directories.forEach(dir => {
    const dirPath = path.join(projectRoot, dir);
    if (!fs.existsSync(dirPath)) {
      errors.push(`缺少目录: ${dir}`);
    } else {
      console.log(`✅ 目录存在: ${dir}`);
    }
  });
  
  // 检查必需的文件
  const allFiles = [
    ...requiredStructure.files,
    ...requiredStructure.themeFiles,
    ...requiredStructure.jsFiles,
    ...requiredStructure.pageFiles,
    ...requiredStructure.scriptFiles,
    ...requiredStructure.apiFiles
  ];
  
  allFiles.forEach(file => {
    const filePath = path.join(projectRoot, file);
    if (!fs.existsSync(filePath)) {
      errors.push(`缺少文件: ${file}`);
    } else {
      console.log(`✅ 文件存在: ${file}`);
    }
  });
  
  // 检查文件内容完整性
  console.log('\n🔍 验证文件内容...');
  
  // 检查package.json
  try {
    const packageJson = JSON.parse(fs.readFileSync(path.join(projectRoot, 'package.json'), 'utf8'));
    if (!packageJson.name || !packageJson.version) {
      warnings.push('package.json 缺少必要字段');
    } else {
      console.log('✅ package.json 格式正确');
    }
  } catch (e) {
    errors.push('package.json 格式错误');
  }
  
  // 检查主题文件
  requiredStructure.themeFiles.forEach(themeFile => {
    const filePath = path.join(projectRoot, themeFile);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      if (content.includes(':root') && content.includes('--primary-color')) {
        console.log(`✅ 主题文件格式正确: ${themeFile}`);
      } else {
        warnings.push(`主题文件可能缺少CSS变量: ${themeFile}`);
      }
    }
  });
  
  // 检查JavaScript文件
  requiredStructure.jsFiles.forEach(jsFile => {
    const filePath = path.join(projectRoot, jsFile);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      if (content.includes('function') || content.includes('class') || content.includes('=>')) {
        console.log(`✅ JavaScript文件格式正确: ${jsFile}`);
      } else {
        warnings.push(`JavaScript文件可能为空或格式错误: ${jsFile}`);
      }
    }
  });
  
  // 输出结果
  console.log('\n📊 验证结果:');
  console.log(`✅ 成功检查: ${allFiles.length - errors.length}/${allFiles.length} 个文件`);
  
  if (warnings.length > 0) {
    console.log('\n⚠️  警告:');
    warnings.forEach(warning => console.log(`   - ${warning}`));
  }
  
  if (errors.length > 0) {
    console.log('\n❌ 错误:');
    errors.forEach(error => console.log(`   - ${error}`));
    console.log('\n项目验证失败！请修复上述错误。');
    process.exit(1);
  } else {
    console.log('\n🎉 项目结构验证通过！');
    console.log('\n📋 项目统计:');
    console.log(`   - 主题文件: ${requiredStructure.themeFiles.length}`);
    console.log(`   - JavaScript文件: ${requiredStructure.jsFiles.length}`);
    console.log(`   - 页面文件: ${requiredStructure.pageFiles.length}`);
    console.log(`   - 脚本文件: ${requiredStructure.scriptFiles.length}`);
    console.log(`   - API文件: ${requiredStructure.apiFiles.length}`);
    console.log('\n✨ Emby UI美化插件已准备就绪！');
  }
}

// 运行验证
validateStructure();