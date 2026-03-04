#!/usr/bin/env bash
# NAS油条版权所有
# 欢迎加入NAS油条技术交流群
# 有什么技术可以进来交流
# 群号:610699712
# 原理是通过tree命令高速扫描并输出json文件结构
# 并用JavaScript读取json文件进行展示



# ===== 可配置选项 =====
output_name=${1:-"nlist.html"} # 输出网页文件名(默认nlist.html)
api="https://www.loliapi.com/acg/" # 背景图片API地址设置
hide=${hide:-false}   # 显示隐藏文件，默认为 false
title=${title:-"nlist"}    # 项目主页名称
introduce=${introduce:-"本网站由nlist脚本构建，这是一个文件目录浏览器，基于tree命令生成"}
# ======================












# 检查包管理器的函数
check_pkg_install() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release #加载变量
    fi
    if [[ -z $PRETTY_NAME ]]; then
        sys="(Termux 终端)"
        PRETTY_NAME="Termux终端"
        sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list >/dev/null
        pkg_install="pkg install"
        pkg_remove="pkg remove"
        pkg_update="pkg update"
        deb_sys="pkg"
        yes_tg="-y"
        
        termux-toast "欢迎使用NAS油条termux脚本" &
        
    elif command -v apt-get >/dev/null 2>&1; then
        sys="(Debian/Ubuntu 系列)"
        pkg_install="sudo apt install"
        pkg_remove="sudo apt remove"
        pkg_update="sudo apt update"
        sudo_setup="sudo"
        deb_sys="apt"
        yes_tg="-y"
        
    elif command -v dnf >/dev/null 2>&1; then
        sys="(Fedora/RHEL/CentOS 8 及更高版本)"
        pkg_install="sudo dnf install"
        pkg_remove="sudo dnf remove"
        pkg_update="sudo dnf update"
        sudo_setup="sudo"
        deb_sys="dnf"
        yes_tg="-y"
        
    elif command -v yum >/dev/null 2>&1; then
        sys="(Fedora/RHEL/Rocky/CentOS 7 及更早版本)"
        pkg_install="sudo yum install"
        pkg_remove="sudo yum remove"
        pkg_update="sudo yum update"
        sudo_setup="sudo"
        deb_sys="yum"
        yes_tg="-y"
        
    elif command -v pacman >/dev/null 2>&1; then
        sys="(Arch Linux 系列)"
        pkg_install="sudo pacman -S"
        pkg_remove="sudo pacman -R"
        pkg_update="sudo pacman -Syu"
        sudo_setup="sudo"
        deb_sys="pacman"
        yes_tg="-y"
        
    elif command -v zypper >/dev/null 2>&1; then
        sys="(openSUSE 系列)"
        pkg_install="sudo zypper in -y"
        pkg_remove="sudo zypper rm"
        sudo_setup="sudo"
        deb_sys="zypper"
        yes_tg="-y"
        
    elif command -v apk >/dev/null 2>&1; then
        sys="(Alpine/PostmarketOS系统)"
        sed -i 's#https\?://dl-cdn.alpinelinux.org/alpine#https://mirrors.tuna.tsinghua.edu.cn/alpine#g' /etc/apk/repositories
        pkg_install="sudo apk add"
        pkg_remove="sudo apk del"
        sudo_setup="sudo"
        deb_sys="apk"
        yes_tg=""
        
    elif command -v emerge >/dev/null 2>&1; then
        sys="(gentoo/funtoo 系统)"
        pkg_install="sudo emerge -avk"
        pkg_remove="sudo emerge -C"
        sudo_setup="sudo"
        deb_sys="emerge"
        yes_tg="-y"
        
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        brew_install #brew安装检测
        sys="(MacOS 系统)"
        pkg_install="brew install"
        sudo_setup="sudo"
        deb_sys="brew"
        yes_tg="-y"
        read -p "抱歉，目前没有完全适配MacOS系统"
        
    else
        echo -e "$(info) >_<未检测到支持的系统。"
    fi
    echo -e "操作系统: $green $PRETTY_NAME $color"
}

#通用安装函数
test_install() {
    if command -v $* >/dev/null 2>&1; then
        echo -e "$(info) $green $*已安装,跳过安装$color"
    else
        echo -e "$(info) 正在安装$*"
        $sudo_setup $pkg_install $* $yes_tg
        install_error=$?
        if [ $install_error -ne 0 ]; then
            echo -e "$(info) $red $*安装失败。$color"
            echo -e "$(info) 正在更新软件包"
            $pkg_update $yes_tg
            if [ $? -ne 0 ]; then
                echo -e "$(info) $red 更新软件包失败$color"
            else
                echo -e "$(info) $green 更新软件包成功,正在尝试重新安装。$color"
                $sudo_setup $pkg_install $* $yes_tg
            fi
        else
            echo -e "$(info) $green $*安装成功。$color"
        fi
    fi
}

#颜色变量
color='\033[0m'
green='\033[0;32m'
blue='\033[0;34m'
red='\033[31m'
yellow='\033[33m'
grey='\e[37m'
pink='\033[38;5;218m'
cyan='\033[96m'

info() {
    echo -e "$cyan[$(date +"%r")]$color $green[INFO]$color" $*
}

br() {
    echo -e "\e[1;34m----------------------------\e[0m"
}

esc() {
    echo -e "$(info) 按$green回车键$color$blue返回$color,按$yellow Ctrl+C$color$red退出$color"
    read
}


echo
br
check_pkg_install #系统检测

# 根据 hide 决定 tree 的排除参数
if [[ "$hide" == "true" ]]; then
    TREE_EXCLUDE=""
else
    TREE_EXCLUDE="-I '.*'"
fi

# 检查 tree 安装
test_install tree

echo -e "$(info) $blue 正在扫描目录结构中...$color"
# 生成 JSON 树，根据 hide 决定是否排除隐藏文件
TREE_JSON=$(eval tree -J $TREE_EXCLUDE --noreport "$PWD")
DIR_NAME=$(basename "$PWD")

# ===== 处理 README 文件 =====
README_HTML=""
for readme_file in "README.md" "README.txt" "README"; do
    if [[ -f "$readme_file" ]]; then
        echo -e "$(info) 发现 README 文件: $readme_file"
        if [[ "$readme_file" == *.md ]]; then
            if command -v pandoc >/dev/null 2>&1; then
                README_HTML=$(pandoc -f markdown -t html "$readme_file")
            elif command -v markdown >/dev/null 2>&1; then
                README_HTML=$(markdown "$readme_file")
            else
                README_HTML="<pre>$(cat "$readme_file")</pre>"
            fi
        else
            README_HTML="<pre>$(cat "$readme_file")</pre>"
        fi
        README_HTML="
<div class=\"readme-card\">
    <h3>📖 README</h3>
    <div class=\"readme-content\">$README_HTML</div>
</div>"
        break
    fi
done

# ========== 写入 HTML 头部 ==========
cat > "$output_name" <<EOF
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes">
<title>目录树 - $title</title>
<style>
/* ========== 全局样式 ========== */
html, body {
    margin: 0;
    padding: 0;
    min-height: 100vh;
    background-size: cover;
    background-position: center;
}
body {
    background: url('$api') no-repeat center center fixed;
    font-family: 'Segoe UI', Arial, sans-serif;
    transition: background-color 0.3s, color 0.3s;
}
.container {
    max-width: 900px;
    margin: 20px auto;
    background: rgba(255, 255, 255, 0.7);
    border-radius: 15px;
    padding: 30px;
    box-shadow: 0 0 20px rgba(0,0,0,0.2);
    backdrop-filter: blur(15px) saturate(180%);
    -webkit-backdrop-filter: blur(15px) saturate(180%);
    border: 1px solid rgba(255, 255, 255, 0.3);
    transition: background 0.3s, backdrop-filter 0.3s;
}

/* ========== 顶栏 ========== */
.top-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}
.theme-btn {
    background: rgba(255, 255, 255, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.5);
    border-radius: 30px;
    padding: 8px 16px;
    cursor: pointer;
    font-size: 14px;
    backdrop-filter: blur(5px);
    transition: all 0.3s;
    color: #333;
}
.theme-btn:hover {
    background: rgba(255, 255, 255, 0.5);
    transform: scale(1.05);
}

/* ========== 统计信息 ========== */
.stats {
    margin: 10px 0 20px 0;
    font-size: 0.95em;
    color: #555;
    display: flex;
    gap: 20px;
    align-items: center;
    flex-wrap: wrap;
}
.stats-item {
    background: rgba(255, 255, 255, 0.5);
    padding: 6px 12px;
    border-radius: 20px;
    backdrop-filter: blur(5px);
    border: 1px solid rgba(255, 255, 255, 0.3);
}

/* ========== 项目简介卡片 ========== */
.project-info {
    background: rgba(255, 255, 255, 0.5);
    border-radius: 12px;
    padding: 20px;
    margin-bottom: 20px;
    backdrop-filter: blur(5px);
    border: 1px solid rgba(255, 255, 255, 0.3);
}
.project-info h2 {
    margin-top: 0;
    color: #333;
    font-size: 1.8em;
}
.project-info p {
    margin-bottom: 0;
    color: #555;
    line-height: 1.6;
}

/* ========== README 卡片 ========== */
.readme-card {
    background: rgba(255, 255, 255, 0.5);
    border-radius: 12px;
    padding: 20px;
    margin: 20px 0;
    backdrop-filter: blur(5px);
    border: 1px solid rgba(255, 255, 255, 0.3);
}
.readme-card h3 {
    margin-top: 0;
    color: #333;
    border-bottom: 1px solid rgba(0,0,0,0.1);
    padding-bottom: 10px;
}
.readme-content {
    overflow-x: auto;
    color: #333;
}
.readme-content pre {
    background: rgba(0,0,0,0.05);
    padding: 10px;
    border-radius: 8px;
    overflow-x: auto;
}
.readme-content code {
    background: rgba(0,0,0,0.05);
    padding: 2px 5px;
    border-radius: 4px;
}

/* ========== 树形列表 ========== */
.tree-root {
    list-style: none;
    padding-left: 0;
}
.tree-root ul {
    list-style: none;
    padding-left: 20px;
    margin: 5px 0;
    position: relative;
}
.tree-root ul::before {
    content: '';
    position: absolute;
    left: 8px;
    top: 0;
    bottom: 0;
    width: 1px;
    background: linear-gradient(to bottom, rgba(44, 130, 201, 0.3), rgba(44, 130, 201, 0.1));
    border-left: 1px dashed #2c82c9;
}
.tree-root li {
    margin: 4px 0;
    position: relative;
}
.tree-root .entry {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 8px 12px;
    border-radius: 8px;
    transition: all 0.3s;
    text-decoration: none;
    color: #333;
}
.tree-root .folder-entry {
    background: rgba(225, 240, 255, 0.8);
    font-weight: 600;
    border-left: 4px solid #2c82c9;
}
details[open] > summary.folder-entry {
    background: rgba(180, 215, 255, 0.9);
    border-left: 6px solid #1a5a9c;
    font-weight: 700;
}
.tree-root .file-entry {
    background: rgba(245, 245, 245, 0.8);
}
.tree-root .entry:hover {
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
.tree-root .folder-entry:hover {
    background: rgba(200, 225, 255, 0.9);
}
.tree-root .file-entry:hover {
    background: rgba(225, 235, 255, 0.9);
}
.file-info {
    color: #666;
    font-size: 0.85em;
    margin-left: 15px;
    white-space: nowrap;
}

/* 折叠按钮动画 */
details > summary {
    list-style: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    outline: none;
}
details > summary::-webkit-details-marker {
    display: none;
}
details > summary::before {
    content: '▶';
    margin-right: 8px;
    font-size: 0.8em;
    transition: transform 0.3s ease-in-out;
    color: #2c82c9;
}
details[open] > summary::before {
    transform: rotate(90deg);
}
details[open] ~ ul,
details[open] ul {
    animation: fadeIn 0.4s ease-out;
}
@keyframes fadeIn {
    from { opacity: 0; transform: translateY(-5px); }
    to   { opacity: 1; transform: translateY(0); }
}

.icon {
    margin-right: 8px;
    font-size: 1.2em;
}
a {
    color: #2c82c9;
    text-decoration: none;
}
a:hover {
    text-decoration: underline;
}
h1 {
    color: #333;
    display: flex;
    align-items: center;
    gap: 10px;
}
hr {
    border: none;
    border-top: 1px solid rgba(0,0,0,0.1);
    margin: 20px 0;
}

/* ========== 夜间模式 ========== */
body.night-mode {
    background: #1a1a1a;
}
body.night-mode .container {
    background: rgba(30, 30, 30, 0.7);
    backdrop-filter: blur(15px) saturate(180%);
    border-color: rgba(255, 255, 255, 0.1);
    color: #eee;
}
body.night-mode .project-info,
body.night-mode .readme-card {
    background: rgba(40, 40, 40, 0.6);
    border-color: rgba(255, 255, 255, 0.1);
}
body.night-mode .project-info h2,
body.night-mode .project-info p,
body.night-mode .readme-card h3,
body.night-mode .readme-content {
    color: #eee;
}
body.night-mode .readme-content pre,
body.night-mode .readme-content code {
    background: rgba(255,255,255,0.1);
}
body.night-mode .stats-item {
    background: rgba(50, 50, 50, 0.6);
    border-color: rgba(255, 255, 255, 0.1);
    color: #ccc;
}
body.night-mode h1,
body.night-mode .top-bar,
body.night-mode .theme-btn {
    color: #eee;
}
body.night-mode .theme-btn {
    background: rgba(50, 50, 50, 0.5);
    border-color: rgba(255, 255, 255, 0.2);
}
body.night-mode .tree-root .folder-entry {
    background: rgba(40, 60, 80, 0.8);
    border-left-color: #5a9acf;
    color: #ddd;
}
body.night-mode details[open] > summary.folder-entry {
    background: rgba(50, 80, 110, 0.9);
    border-left-color: #7ab0e0;
}
body.night-mode .tree-root .file-entry {
    background: rgba(50, 50, 50, 0.8);
    color: #ccc;
}
body.night-mode .tree-root .entry:hover {
    box-shadow: 0 2px 8px rgba(255,255,255,0.1);
}
body.night-mode .file-info {
    color: #aaa;
}
body.night-mode a {
    color: #7ab0e0;
}
body.night-mode hr {
    border-top-color: rgba(255,255,255,0.1);
}
body.night-mode .tree-root ul::before {
    background: linear-gradient(to bottom, rgba(122, 176, 224, 0.3), rgba(122, 176, 224, 0.1));
    border-left-color: #5a9acf;
}

/* ========== 手机响应式 ========== */
@media screen and (max-width: 600px) {
    .container {
        max-width: 100%;
        margin: 10px;
        padding: 15px;
    }
    .tree-root ul {
        padding-left: 10px;
    }
    .tree-root ul::before {
        left: 4px;
    }
    .tree-root .entry {
        padding: 10px 8px;
        font-size: 14px;
    }
    .icon {
        font-size: 1.1em;
    }
    .file-info {
        font-size: 0.75em;
    }
    h1 {
        font-size: 1.5em;
    }
    .project-info h2 {
        font-size: 1.5em;
    }
    .readme-card {
        padding: 15px;
    }
    .stats {
        gap: 10px;
    }
}
</style>
</head>
<body>

<div class="container">
    <div class="top-bar">
        <h1>🌳 目录树 <span style="font-size:0.6em; color:#666;">$DIR_NAME</span></h1>
        <button class="theme-btn" id="themeToggle">🌙 夜间模式</button>
    </div>

    <!-- 项目简介卡片 -->
    <div class="project-info">
        <h2>$title</h2>
        <p>$introduce</p>
    </div>

    <!-- 统计信息区域（将由 JavaScript 填充） -->
    <div class="stats" id="stats">
        <span class="stats-item">📁 文件夹: <span id="folder-count">0</span></span>
        <span class="stats-item">📄 文件: <span id="file-count">0</span></span>
    </div>

<hr>
<div id="tree-container" class="tree-root"></div>
<hr>

<!-- README 内容显示区域 -->
$README_HTML

<div style="text-align:center;">
    <img src="https://foruda.gitee.com/avatar/1748842563869716713/14577413_nasyt_1748842563.png!avatar100" alt="访问计数" />
</div>
</div>

<script>
// ========== 从 tree -J 输出的 JSON 构建树 ==========
const treeData = 
EOF

# ========== 插入 JSON 数据 ==========
echo "$TREE_JSON" >> "$output_name"

# ========== 写入剩余的 JavaScript 代码 ==========
cat >> "$output_name" <<'EOF'
;

// 图标映射
function getIcon(name, isDir) {
    if (isDir) return '📁';
    const ext = name.split('.').pop().toLowerCase();
    const icons = {
        'zip':'📦', 'rar':'📦', '7z':'📦', 'gz':'📦',
        'mp4':'🎬', 'mkv':'🎬', 'avi':'🎬',
        'mp3':'🎵', 'flac':'🎵', 'wav':'🎵',
        'png':'🖼', 'jpg':'🖼', 'jpeg':'🖼', 'gif':'🖼', 'bmp':'🖼', 'webp':'🖼',
        'pdf':'📕', 'txt':'📄', 'md':'📄',
        'py':'🐍', 'js':'🌐', 'html':'🌐', 'css':'🎨',
        'rs':'🦀', 'sh':'📜', 'rb':'📜', 'bat':'📜',
    };
    return icons[ext] || '📄';
}

// 排序函数：文件夹在前，文件在后
function sortNodes(contents) {
    if (!contents) return [];
    return contents.sort((a, b) => {
        const aIsDir = a.type === 'directory' ? 0 : 1;
        const bIsDir = b.type === 'directory' ? 0 : 1;
        if (aIsDir !== bIsDir) {
            return aIsDir - bIsDir;
        }
        return a.name.localeCompare(b.name);
    });
}

// 递归渲染树节点，path 为当前节点在文件系统中的相对路径（以 / 结尾表示目录）
function renderTree(node, path = '') {
    if (Array.isArray(node)) {
        if (node.length > 0 && node[0].type === 'directory') {
            return renderTree(node[0], path);
        }
        return '';
    }
    if (node.type === 'report') return '';

    const name = node.name;
    const isDir = node.type === 'directory';
    const icon = getIcon(name, isDir);
    const sizeStr = '';

    let childrenHtml = '';
    if (isDir && node.contents && node.contents.length > 0) {
        const sortedContents = sortNodes(node.contents);
        childrenHtml = '<ul>' + sortedContents.map(child => renderTree(child, path + name + '/')).join('') + '</ul>';
    }

    const entryClass = isDir ? 'folder-entry' : 'file-entry';

    if (isDir) {
        return `
<li>
    <details>
        <summary class="entry ${entryClass}">
            <span><span class="icon">${icon}</span>${name}</span>
            <span class="file-info">${sizeStr}</span>
        </summary>
        ${childrenHtml}
    </details>
</li>`;
    } else {
        const filePath = encodeURI(path + name);
        return `
<li>
    <a href="${filePath}" class="entry ${entryClass}">
        <span><span class="icon">${icon}</span>${name}</span>
        <span class="file-info">${sizeStr}</span>
    </a>
</li>`;
    }
}

// 处理根节点
let rootHtml = '';
let folderCount = 0, fileCount = 0;

if (Array.isArray(treeData) && treeData.length > 0 && treeData[0].type === 'directory') {
    const rootNode = treeData[0];
    if (rootNode.contents && rootNode.contents.length > 0) {
        // 统计根目录下的文件夹和文件数量
        rootNode.contents.forEach(item => {
            if (item.type === 'directory') folderCount++;
            else if (item.type === 'file') fileCount++;
        });
        const sortedContents = sortNodes(rootNode.contents);
        rootHtml = '<ul>' + sortedContents.map(child => renderTree(child, '')).join('') + '</ul>';
    } else {
        rootHtml = '<ul></ul>';
    }
} else {
    // 备用处理（理论上不会进入）
    rootHtml = '<ul>' + renderTree(treeData, '') + '</ul>';
    // 无法统计数量，保持默认0
}
document.getElementById('tree-container').innerHTML = rootHtml;

// 更新统计信息
document.getElementById('folder-count').textContent = folderCount;
document.getElementById('file-count').textContent = fileCount;

// ========== 夜间模式切换 ==========
const themeToggle = document.getElementById('themeToggle');
const body = document.body;

const savedTheme = localStorage.getItem('theme');
if (savedTheme === 'night') {
    body.classList.add('night-mode');
    themeToggle.textContent = '☀️ 日间模式';
} else {
    themeToggle.textContent = '🌙 夜间模式';
}

themeToggle.addEventListener('click', () => {
    body.classList.toggle('night-mode');
    const isNight = body.classList.contains('night-mode');
    themeToggle.textContent = isNight ? '☀️ 日间模式' : '🌙 夜间模式';
    localStorage.setItem('theme', isNight ? 'night' : 'day');
});

// ========== 应用 localStorage 其他设置 ==========
(function() {
    const settings = JSON.parse(localStorage.getItem("siteSettings") || "{}");
    if (settings.bgUrl) {
        document.body.style.background = `url('${settings.bgUrl}') fixed`;
        document.body.style.backgroundSize = "cover";
    }
    if (settings.fontColor) document.body.style.color = settings.fontColor;
    if (settings.fontSize) document.body.style.fontSize = settings.fontSize + "px";
    if (settings.linkColor) {
        document.querySelectorAll("a").forEach(a => a.style.color = settings.linkColor);
    }
    if (settings.folderWidth) {
        document.querySelector(".container").style.maxWidth = settings.folderWidth + "px";
    }
    if (settings.folderHeight) {
        document.querySelectorAll(".entry, summary").forEach(e => {
            e.style.minHeight = settings.folderHeight + "px";
        });
    }
    if (settings.folderColor) {
        document.querySelectorAll(".entry, summary").forEach(e => {
            e.style.background = settings.folderColor;
        });
    }
    if (settings.bgColor) document.body.style.backgroundColor = settings.bgColor;
    if (settings.bgOpacity) {
        document.querySelector(".container").style.background =
            `rgba(255,255,255,${settings.bgOpacity})`;
    }
})();
</script>

</body>
</html>
EOF

# ========== 完成提示 ==========
if [[ "$hide" == "true" ]]; then
    echo -e "$(info) $green 生成完成（包含隐藏文件）：$color"
else
    echo -e "$(info) $green 生成完成（已排除隐藏文件）：$color"
fi
echo -e "$blue $PWD/$output_name $color"
echo -e "$(info) 推荐使用nweb运行"