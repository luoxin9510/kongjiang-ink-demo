# itch.io HTML5 部署知识笔记

基于「控江隔离」demo 部署到 itch.io 的实战记录，整理坑点、修复方法与参考资料。  
最后更新：2026-05-02

---

## TL;DR — 5 个最致命的坑

| # | 坑 | 现象 | 解决 |
|---|---|---|---|
| 1 | **PowerShell `Compress-Archive` 用反斜杠路径** | 子目录文件 access denied (GCS) | 用 Python `zipfile` 打包 |
| 2 | **`<a href="en/">`（无 index.html）** | access denied | 全部用完整文件名 `href="en/index.html"` |
| 3 | **iframe 内 `100dvh` 不可靠** | iOS Safari 不能滚动 | 用 `height: 100%`（继承自 `<html>`） |
| 4 | **中间包了一层 `display: block` 的 div** | flex 高度约束失效，main 撑出 iframe | 让每层都是 flex 容器 |
| 5 | **没有版本标识** | 改了不知道有没有传上去 | 页面加 `BUILD YYYY-MM-DD-X` |

---

## 1. itch.io 后端架构

| 层 | 是什么 | 关键事实 |
|---|---|---|
| 项目页 | `https://USERNAME.itch.io/PROJECT` | itch.io 主域名，承载 password / 描述 / 评论 |
| iframe 内容 | `https://html-classic.itch.zone/html/<GAME_ID>/<path>` | itch.zone 子域，由 **Google Cloud Storage** 后端服务 |
| 上传后处理 | itch.io 把 zip 解压到 GCS 桶 | 路径 = zip 内路径，**不做目录索引重定向** |

「Anonymous caller does not have storage.objects.get access」= GCS 里那个对象不存在（或路径错），不是真的权限问题。

---

## 2. ZIP 打包必备规则

### 2.1 itch.io 的硬性要求
官方文档 https://itch.io/docs/creators/html5：
- zip 根目录必须有 `index.html`
- zip 不能包含外层文件夹（不能 `mygame/index.html`，必须 `index.html`）
- 单个 zip 上限 1 GB
- 总文件数没硬限制但越多越慢

### 2.2 路径分隔符必须是正斜杠 `/`
**这是这次最大的坑。** ZIP 规范（APPNOTE）要求条目名用正斜杠。Windows PowerShell `Compress-Archive` 偏偏用反斜杠 `\`。

```powershell
# ❌ 不要用这个 — 在 itch.io 上会 access denied
Compress-Archive -Path 'index.html','en' -DestinationPath out.zip
```

itch.io 把 `en\index.html` 当成**带反斜杠的扁平文件名**存进 GCS，浏览器请求 `en/index.html` 找不到。

```python
# ✅ 用 Python，跨平台都正确
import zipfile, os
src = r'C:\path\to\repo'
dst = r'C:\path\to\out.zip'
files = ['index.html', 'main.json', 'en/index.html', 'en/data.json']
with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in files:
        z.write(os.path.join(src, *f.split('/')), arcname=f)  # arcname 用 /
```

其他可用工具：
- `7z a out.zip files/*` — 7-Zip 默认正斜杠
- WSL / Git Bash `zip -r out.zip .` — 也正斜杠
- macOS / Linux `zip` — 天然正斜杠

### 2.3 验证 zip 路径分隔符
```bash
unzip -l out.zip
# 应该看到 en/index.html，不能是 en\index.html
```

或 PowerShell：
```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::OpenRead('out.zip').Entries | % { $_.FullName }
```

---

## 3. 链接路径必须是完整文件名

GCS **不做目录索引**。`href="en/"` 不会被重定向到 `en/index.html`。

```html
<!-- ❌ 本地能跑，itch.io 上 access denied -->
<a href="en/">English</a>
<a href="../">中文</a>

<!-- ✅ 必须写全 -->
<a href="en/index.html">English</a>
<a href="../index.html">中文</a>
```

同理：所有相对路径必须明确指向某个文件。CSS 里的 `url('images/')` 不行，要 `url('images/bg.png')`。

---

## 4. iframe 内的滚动布局（iOS Safari 重灾区）

### 4.1 iframe 大小由 itch.io 控制
在项目设置 → Embed options → Viewport dimensions 设宽高（CSS 像素）。  
推荐：以最常见的目标设备为准。

| 设备 | CSS 像素 |
|---|---|
| iPhone 16 / 17 | 390 × 844 |
| iPhone 16 Plus / 17 Pro Max | 440 × 956 |
| iPad Mini | 768 × 1024 |
| Desktop 默认 | 960 × 600（itch.io 默认） |

勾选「Mobile friendly」让 itch.io 在手机端把 iframe 全屏化。

### 4.2 让游戏内容自己消化滚动（关键模式）

**不要让 iframe 自身滚动**（iOS Safari 滚动条丑）。让你的 HTML 内部用 flex 布局 + 内部 overflow 滚动。

```css
/* 必须的基础设置 */
html { height: 100%; overscroll-behavior: none; }
body {
  height: 100%;          /* ← 用 100% 而非 100dvh, iframe 内更可靠 */
  overflow: hidden;       /* 禁止 body 整体滚动 */
  display: flex;
  flex-direction: column;
}

/* 中间的 wrapper 也必须是 flex 容器（这是这次踩到的另一个坑） */
#game {
  flex: 1 1 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

/* 顶部 HUD：固定不滚 */
header.hud { flex: 0 0 auto; }

/* 主内容区：内部滚动 */
main {
  flex: 1 1 0;            /* basis 0 而非 auto，强制 flex 分配 */
  min-height: 0;          /* 允许收缩到比内容小，触发 overflow */
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;   /* iOS 惯性滚动 */
  touch-action: pan-y;                 /* 显式声明触摸方向 */
  overscroll-behavior: contain;
  transform: translateZ(0);            /* 强制 GPU 合成层（iOS hack） */
}

/* 底部按钮区：内部滚动，不挤压主区 */
nav#choices {
  flex: 0 1 auto;
  max-height: 50%;        /* 上限避免吃掉主区 */
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  touch-action: pan-y;
}
```

### 4.3 `flex: 1 1 auto` vs `flex: 1 1 0`
- `auto` 基线 = 内容固有大小 → 内容很高时元素也很高 → 不触发 overflow
- `0` 基线 = 0 → 完全靠 grow 分配 → 自动适配剩余空间 → 内容溢出时触发 overflow

**滚动容器必须用 `flex: 1 1 0` + `min-height: 0`。**

### 4.4 `100dvh` 在 iframe 里的坑
`dvh`（动态视口高度）是为浏览器 URL 栏伸缩设计的，但在 iframe 里：
- iOS Safari 不一定正确反映 iframe 的实际高度
- `100dvh` 可能比 iframe 实际可用区域大或小

**用 `height: 100%`** 继承自 `html { height: 100% }`，这个永远等于 iframe 容器的高度，最可靠。

### 4.5 中间 wrapper 必须穿透 flex
```html
<body style="display:flex;flex-direction:column;height:100%">
  <div id="game">       <!-- ← 这层默认 display:block，flex 在这就断了！ -->
    <header class="hud" />
    <main />
    <nav />
  </div>
</body>
```
表现：HUD/main/nav 不再受 flex 控制，main 撑到内容高度，body `overflow:hidden` 把超出部分裁掉但用户感觉「卡死不能滚」。

修：把 `#game` 也设成 flex 容器。

---

## 5. 移动端按钮密度

iPhone 17 Pro Max CSS 高 956，按 desktop 默认按钮高度（48px + 14/16 padding）做选项区，7 个选项 ≈ 50% 屏幕。给个媒体查询压缩：

```css
@media (max-width: 600px) {
  nav#choices { gap: 6px; max-height: 42%; }
  nav#choices button {
    padding: 9px 12px;
    font-size: 14px;
    min-height: 40px;
  }
}
```

⚠️ 不要用 `max-height: 800px` 做断点 —— 现代旗舰手机普遍 > 800 高，触发不到。**用 `max-width`** 才能覆盖所有手机。

---

## 6. 安全区（Safe Area Insets）

iPhone 有 Dynamic Island 和 home indicator。itch.io iframe 全屏后这些会侵占内容。

```css
body {
  padding:
    env(safe-area-inset-top)
    env(safe-area-inset-right)
    0
    env(safe-area-inset-left);
}

/* 底部按钮自己处理 */
nav#choices {
  padding-bottom: calc(env(safe-area-inset-bottom) + 16px);
}
```

`<head>` 里 viewport meta 必须加 `viewport-fit=cover`：
```html
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
```

---

## 7. 上传 / 验证流程

### 7.1 第一次上传
1. itch.io → 头像 → Upload new project
2. **Kind of project**: HTML（不是 Downloadable）
3. Uploads → 选 zip → 勾「This file will be played in the browser」
4. Embed options 设 viewport / Mobile friendly
5. Visibility: Restricted + Password（内测期）
6. Save & view page → 自测

### 7.2 内测期访问限制
| 模式 | 谁能进 | 适合 |
|---|---|---|
| Draft | 只有作者 | 自己测 |
| Restricted + Password | 知道密码的人 | 内测分享，链接可流传 |
| Restricted | 作者明确加白名单的账号 | 受邀内测 |
| Public | 所有人 | 正式发布 |

### 7.3 加 BUILD 标识便于验证缓存
itch.io / Cloudflare / Safari 的 iframe URL 都可能缓存。改完上传后用户可能还在看旧版。

```html
<!-- 标题页或 footer 显眼处 -->
<div style="font-size:10px;color:#444;letter-spacing:0.2em;text-align:center;">
  BUILD 2026-05-02-A
</div>
```

每次推送改这个值。看不到对应版本号 = 没传成功 / 缓存没刷。

### 7.4 强制刷新
- 桌面 Chrome / Firefox：`Ctrl+Shift+R` / `Cmd+Shift+R`
- iOS Safari：长按刷新按钮 → 「重新加载并忽略缓存」，或**完全关闭标签页重开**

---

## 8. 常见错误对照表

| 报错 / 现象 | 真实原因 | 修法 |
|---|---|---|
| `AccessDeniedAccess denied. Anonymous caller does not have storage.objects.get access` | GCS 里没这个对象（路径错或目录索引） | 检查 zip 路径分隔符 + 链接是否完整文件名 |
| 手机不能滚动剧情 | iframe 内 body 没合规 flex 层级 | 见 §4.2、§4.5 |
| 选项把屏幕吃掉一半 | 移动端按钮太大 | 见 §5 |
| iframe 顶部被刘海挡住 | 缺 viewport-fit=cover + safe-area-inset | 见 §6 |
| 改了上传没生效 | iframe URL 被 Safari 缓存 | 见 §7.3、§7.4 |
| 双语切换跳到 itch.io 项目页而不是英文版 | 链接 `target="_top"` 或浏览器 strict referrer | 显式 `target="_self"` 或不写（默认就是当前 frame） |

---

## 9. Butler 自动化部署

不想每次都手动拖 zip：

```bash
# 安装：https://itch.io/docs/butler/installing.html
butler login

# 推送（会自动 diff，只传变化的文件）
butler push out.zip USERNAME/PROJECT:html
butler status USERNAME/PROJECT
```

`html` 是 channel 名，可自定义（`html-en`、`beta` 等）。后续每次：
```bash
python pack.py && butler push out.zip USERNAME/PROJECT:html
```

---

## 10. 参考文档

| 主题 | URL |
|---|---|
| HTML5 项目（最相关） | https://itch.io/docs/creators/html5 |
| 创建者总览 | https://itch.io/docs/creators/getting-started |
| Embed options | https://itch.io/docs/creators/html5#embed-options |
| Mobile friendly | https://itch.io/docs/creators/html5#mobile-friendly |
| URL 参数 | https://itch.io/docs/creators/html5#html-game-options |
| Restricted / Password | https://itch.io/docs/creators/getting-started#privacy-mode |
| Butler CLI | https://itch.io/docs/butler/ |
| ZIP 规范（APPNOTE 路径分隔符） | https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT |

---

## 11. 推荐 pack 脚本（可复用）

```python
# pack.py — 控江隔离用，可复制改路径
import zipfile, os, sys, datetime

ROOT = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(os.path.expanduser('~'), 'Desktop', 'kongjiang-demo.zip')

INCLUDE = [
    'index.html',
    'kongjiang_act0.json', 'kongjiang_act1.json',
    'kongjiang_act2.json', 'kongjiang_act3.json',
    'en/index.html', 'en/kongjiang_act0_en.json',
]

if os.path.exists(DEST):
    os.remove(DEST)

with zipfile.ZipFile(DEST, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in INCLUDE:
        src = os.path.join(ROOT, *f.split('/'))
        if not os.path.exists(src):
            print(f'MISSING: {src}', file=sys.stderr)
            sys.exit(1)
        z.write(src, arcname=f)  # arcname 必须用 / 分隔

print(f'OK -> {DEST}')
print('Build:', datetime.date.today())
print('Entries:')
with zipfile.ZipFile(DEST) as z:
    for n in z.namelist():
        print(' ', n)
```

---

## 附：本次实战时间线（控江隔离 v1）

| 步骤 | 发现 |
|---|---|
| 第 1 次上传 | 用 PowerShell 打包，看似成功 |
| 用户报「不能滚动」 | 改了 body 高度 + main flex |
| 用户报「还不能滚」 | 发现 `dvh` 不可靠，改 `height: 100%` |
| 用户报「换不了英文 access denied」 | 改 `href="en/"` → `href="en/index.html"` |
| 用户**还是**报 access denied | **真正根因**：PowerShell zip 用反斜杠路径，GCS 路径错乱 |
| 改用 Python 打包 | 解决 |

**教训：跨平台部署，工具链每个环节都要验证一遍——尤其是文件名/路径分隔符这种「肉眼看不出」的问题。**
