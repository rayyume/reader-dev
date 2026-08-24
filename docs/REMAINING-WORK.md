# 剩余工作清单与状态报告

> 生成日期：2026-08-24 · 基线：master@df02756d · 后端测试 717 全绿 · 前端构建通过
>
> 本报告汇总「legacy/reader-pro-3.2.14 对齐工程」完成后仍存在的全部已知差距，
> 按影响分为：A 功能未实现 / B 审计未覆盖 / C 测试缺口 / D 已评估不移植。

## 总体完成度

| 维度 | 状态 |
|---|---|
| 后端 API 控制器层对齐（~90 函数） | ✅ 完成（签名/参数/文案/核心语义） |
| 规则引擎对齐（AnalyzeRule/Regex/XPath/JSonPath/JSoup/CSS 链） | ✅ 主干完成（~85% 逐行，长尾见 B 类） |
| WebBook/本地书/用户安全/基础设施 | ✅ 完成 |
| UI 差距积压（P0×3 + P1×5 + P2×7） | ✅ 全部执行完毕 |
| CI（Rust/Frontend/Docker 多架构） | ✅ 基线正常 |

---

## A. 功能已识别差异但未实现

按影响排序：

| # | 项 | 说明 | 建议 |
|---|---|---|---|
| A1 | **webView 抓取路径** | AnalyzeUrl 的 webView 模式在 master 仅标注缺失。依赖 JS 渲染的书源（少量）无法取正文 | 可用 camoufox/CDP 复用现有浏览器基建实现；工作量中等，受益书源占比小 |
| A2 | **concurrentRate 共享滑窗限速** | 书源级并发限速未实现共享滑窗（当前仅 semaphore 并发上限）。高频访问严格限速的源可能被封 | 实现 `RefCell<HashMap<String,滑动窗口>>` 或 Redis 式计数；小工作量 |
| A3 | **textToSpeechCn 引擎** | legacy 中文 TTS 引擎（百度翻译接口合成）未移植，master 统一回退 Edge TTS。Edge 音质通常更好，实际损失有限 | 低优先；如需可照 legacy 协议实现 httpTTS 源即可覆盖同场景 |
| A4 | **searchChapter/getAllContents 契约差异** | Pro JAR 提取出的两接口行为与 master 有细节出入（分页语义），未修 | 需先确认真实调用方（App 端？）；Web 前端不使用 |
| A5 | **exportToEpub 结构差异** | 导出 EPUB 的 OPF 结构与 legacy epublib 输出有差异（nav 页/字体嵌入策略）。功能可用但产物不完全一致 | 仅在需要与其他阅读器交换进度/高亮时有影响 |

## B. 审计覆盖的长尾（约 15% 未逐行）

静态审计边际收益递减区——多为极端边界条件：

| 区域 | 具体未穷举点 |
|---|---|
| AnalyzeRule.java | getString 分支树边界；splitSource 嵌套 `{{}}` 内含 `@` 的切分精确性；put/get 三级作用域跨请求持久化完整行为矩阵（SQLite 持久化已做，回退链矩阵未穷举） |
| AnalyzeByJSoup 选择器差异矩阵 | jsoup 与 scraper CSS 方言语法逐条对照表未建立（`:eq/:lt/:gt/:contains/:matches` 已通过预处理修复 ✅；其余伪类如 `:not` 嵌套、属性正则 `~=|=^=$=*=` 差异未系统验证） |
| BookHelp 图片管线 | saveImages 并发去重+轮询等待完整流程仅概述；updateImageLinkInContent 正则边界未穷举 |
| CacheManager/ACache LRU | 精确淘汰时机、hashCode 碰撞、启动扫描竞态窗口 |
| CookieStore 序列化 | ACache 文件格式 ↔ SQLite 在读写边界的影响未系统测试 |
| EncoderUtils escape() | 字符集精确边界、hex/base64 自动识别阈值 |

## C. 测试缺口

| # | 缺口 | 说明 |
|---|---|---|
| C1 | **真实书源全链路实测** ⭐ 最高价值 | 未用真实书源跑「搜索→详情→目录→正文→换源」全链路。这是暴露上述所有盲区的最快方式，比继续静态对比高效得多 |
| C2 | 新增前端模块无单测 | epubLoader/ttsCache/rssMedia/EpubIframe 无 vitest 用例（web-ui 现有测试框架为 vitest，utils 目录已有多个 .test.ts 先例） |
| C3 | EPUB 原版渲染真机验证 | EpubIframe 的 srcdoc 渲染、内链跳转、进度同步未在真实 .epub 上验证过 |
| C4 | SSE 单源/并发参数集成测试 | P1-4 加的 bookSourceUrl 参数后端有编译保障但无 e2e 断言 |

## D. 经评估明确不移植

| 项 | 理由 |
|---|---|
| WiFi 局域网传书专页 | Web 版即服务端，FileManage 上传已覆盖同一场景 |
| MPCode 公众号二维码弹窗 | 推广组件 |
| MP3 下载（P2-7 半项） | 星标已完成；MP3 落盘下载受 CORS 限制需后端代理配合，收益低，暂缓 |

---

## 推荐行动顺序

1. **C1 真实书源实测**（半天）——准备 3-5 个典型源（普通/JS 模板/charset/限速源各一），跑通全链路，失败项回流修复
2. **A2 concurrentRate 限速**（2 小时）——防止实测时封 IP
3. **C2 补 epubLoader/ttsCache/rssMedia 单测**（半天）
4. C3 真机过一遍新 UI 功能（EPUB raw/TTS 缓存/点击方案）
5. A1 webView 路径视实测结果决定是否投入
6. 其余 B 类长尾：随实测暴露再修，不做预防性审计
