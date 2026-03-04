📁 TreeStyle - 精美可折叠目录树生成器

https://img.shields.io/badge/License-MIT-yellow.svg

一个用 Bash 编写的脚本，可将当前目录结构生成为一个精美、可折叠、响应式的 HTML 页面。支持夜间模式、亚克力毛玻璃效果、文件夹优先排序、隐藏文件开关、自动展示 README、文件总数统计等功能，非常适合用作 GitHub 项目的文档首页或本地文件浏览器。

---

✨ 特性

· 🌳 树形目录展示 – 使用 details 元素实现原生折叠，支持无限层级。
· 📁 文件夹优先 – 所有文件夹排在文件前面，同类型按名称字母排序。
· 🌙 夜间模式 – 一键切换，主题偏好保存在 localStorage 中。
· 🥃 亚克力效果 – 毛玻璃背景，现代美观。
· 📊 统计信息 – 在顶部显示当前目录下的文件夹总数和文件总数（递归统计，不包含根目录本身）。
· 📖 README 自动嵌入 – 若存在 README.md / README.txt / README，会自动渲染并显示在目录树下方（支持 Markdown 转换，需 pandoc 或 markdown 命令）。
· 👁️ 隐藏文件开关 – 可通过脚本开头的变量控制是否显示以点开头的隐藏文件。
· 📱 手机响应式 – 小屏幕下自动调整字体、间距，触摸友好。
· ⚙️ 可自定义 – 项目名称、简介可在脚本开头修改。
· 🚀 轻量快速 – 仅依赖 tree 命令，生成速度快。

---

📦 依赖

· tree – 用于生成目录结构的 JSON 数据。
    安装方法：
  ```bash
  # Ubuntu / Debian
  sudo apt install tree
  
  # macOS (Homebrew)
  brew install tree
  
  # 其他系统请使用对应包管理器
  ```
· （可选）pandoc 或 markdown – 用于将 README.md 转换为 HTML。若未安装，README 将以纯文本形式显示在 <pre> 中。
· （可选）jq – 脚本未直接使用，但若您想手动处理 JSON 可安装。

---

🚀 使用方法

1. 下载脚本
      将 generate_tree.sh 保存到您的项目根目录。
2. 赋予执行权限
   ```bash
   chmod +x generate_tree.sh
   ```
3. （可选）修改配置
      用文本编辑器打开 generate_tree.sh，调整开头的变量：
   ```bash
   SHOW_HIDDEN=false          # true 则显示隐藏文件，false 则隐藏
   PROJECT_NAME="我的项目"     # 显示在简介卡片中的项目名称
   PROJECT_DESCRIPTION="..."   # 项目简介文字
   ```
4. 运行脚本
   ```bash
   ./generate_tree.sh
   ```
5. 查看结果
      脚本会在当前目录生成 index.html，用浏览器打开即可看到精美目录树。

---

⚙️ 配置选项详解

变量名 默认值 说明
SHOW_HIDDEN false 是否在目录树中显示以点开头的隐藏文件和目录。
PROJECT_NAME "我的项目" 页面顶部项目简介卡片中的标题。
PROJECT_DESCRIPTION "这是一个文件目录浏览器..." 项目简介的详细描述。

您也可以在执行时通过环境变量覆盖，例如：

```bash
SHOW_HIDDEN=true PROJECT_NAME="My Awesome Project" ./generate_tree.sh
```

---

🧩 自定义样式

所有样式都内嵌在生成的 index.html 中。您可以直接修改 HTML 中的 <style> 部分，或通过浏览器开发者工具调整后保存。
页面支持通过 localStorage 进行额外设置（与之前脚本兼容），例如：

```js
localStorage.setItem("siteSettings", JSON.stringify({
  bgUrl: "https://example.com/bg.jpg",
  fontColor: "#fff",
  folderWidth: 1000,
  // ... 更多设置参见之前的脚本
}));
```

---

📝 示例

https://via.placeholder.com/800x500?text=示例截图待补充

· 文件夹显示为浅蓝色背景、加粗、左侧蓝色边框。
· 展开的文件夹背景加深，边框变粗。
· 文件为灰色背景。
· 左上角有统计信息，右上角有夜间模式切换按钮。
· 底部自动嵌入 README.md 内容。

---

⚠️ 注意事项

· 脚本会在当前目录生成 index.html，会覆盖已存在的同名文件，请注意备份。
· 生成的 HTML 中文件链接为相对路径，点击文件会尝试在浏览器中打开（如果浏览器支持预览则预览，否则下载）。请确保目录结构未被移动。
· 统计信息中的总数不包含根目录本身，只包含根目录下的所有子目录和文件（递归统计），这与 tree 命令的默认行为一致。

---

🤝 贡献

欢迎提交 Issue 或 Pull Request！如果您有好的改进想法，请随时联系。

---

📄 许可证

MIT License © 2025
