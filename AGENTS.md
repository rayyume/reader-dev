# 项目总目标（GOAL）——长期有效，勿忘

## 基础分支决策（已定，勿反复）

**默认分支与开发基础 = `master`**（2026-08-22 定）：
- master 是完整可运行产品：axum+SQLite+boa 规则引擎、634 测试全绿、web-ui 内嵌、
  实际发版至 v5.2.4；v5.0.x→v5.2.4 本身即 "legacy 全量核销" 系列——对齐主体已具规模
- rust 分支的 Rust 源码是 Kotlin 文件逐个机械转译（*.kt ↔ *.rs 成对），无真实服务端
  架构，不作为基础；该分支保持原样不动（Kotlin 历史 + 转译参考 + v6.0.x tag）
- legacy / archive/master-v5.2.4 分支均为只读参考

## 核心目标

**当前 master（Rust 重写版）功能严重缺失、细节不足。以 legacy 分支的 Kotlin 实现为细节基准，
在 Rust 分支上重写/补齐全部功能；UI 设计语言遵循 archive/master-v5.2.4 分支的风格。**

- **功能基准 = legacy ∪ archive/master-v5.2.4 的功能并集**
  - origin/legacy：Kotlin 源码，功能与细节的最终对照标准
    （书源规则引擎语义、API 行为、缓存策略、用户系统、本地书解析、TXT/EPUB 细节等）
  - origin/archive/master-v5.2.4：其 UI 缺失大量功能，仅作设计语言参考；
    它独有的功能也要保留并与 legacy 功能合并
- **UI 设计风格 = archive/master-v5.2.4**（布局 / 视觉 / 交互设计语言）

## 参考分支

| 分支 | 用途 |
|---|---|
| `origin/legacy` | Kotlin 功能细节基准（对齐目标） |
| `origin/archive/master-v5.2.4` | UI 设计语言基准 + 功能合并来源之一 |
| `master` | 工作分支：Rust 源码 + web-ui |

## 工作方式

1. 逐模块审计差异：Rust 现状 vs legacy Kotlin vs archive/master-v5.2.4
2. 在 Rust 中按 legacy 语义实现（细节逐项对齐，不是近似）
3. 每项修复配测试 → cargo test 全绿 → 提交推送 master

## 当前会话目标（本次，未完成勿结）

1. **EPUB tocUrl 六模式收尾**：parse_epub 六模式已实现且测试通过（含路由层接入书架书
   toc_url），但改动仍在工作区未提交 → 跑全量测试后提交推送
2. **修复 GitHub Actions**：
   - docker.yml 每次推送 0s 失败，根因＝`if:` 条件中直接引用 `secrets` 上下文（GitHub 禁止，
     解析即失败）→ 改为 job 级 env 间接引用；同时修复多 tag `-t` 逗号串接问题
   - binary-windows.yml / binary-linux.yml 仅 tag 触发从未实跑 → 手动 workflow_dispatch 验证绿
3. **继续 legacy 细节对齐**：长章节拆分、API 差异逐条核销

## 进度快照（持续更新）

### 已完成（本会话批次）
- P0 数据隔离：章节/目录缓存命名空间隔离（B1）、书级变量缓存隔离（B13）
- P0 多源搜索去重（B2）、多设备 token 过期机制（B12，token_map 对齐 legacy 对象形态）
- P1 getBookContent 自动保存进度；getBookSources simple 参数
- P1 TXT 目录规则改 legacy 单规则选择（命中数最多）
- P1 JS 引擎补 legacy 顶层函数别名（md5Encode/base64Encode 等 12 个）
- P1 EPUB tocUrl 六模式（toc/spin<toc/spin+toc/toc+spin/toc<spin + toc.ncx/nav 解析）
- P1 TXT 长章节拆分（splitLongChapter：单章 >100KB → ≥10KB 换行边界切块，
  子章标题 {原标题}(n)；目录/正文/缓存全链路同参保证 #index 一致）
- 缺失端点补齐：setBookSource（换源持久化）/ getUserInfo / cover（封面代理）/
  deleteFile / deleteBookSourcesFile
- 细节对齐批次：
  - saveBook：name+author 判重（换源式保存不丢进度）、dur 三字段库内保护、
    上限文案「你已达到书籍数上限，请联系管理员」、新书 durChapterTime=now 置顶、isInShelf=true
  - saveBookProgress：searchBook.bookUrl 兜底、「章节不存在」越界校验（ns 安全计数+目录缓存）
  - searchBook/searchBookMulti/SSE：legacy "=" 前缀精确语义
  - deleteBook：name+author 兜底匹配、「书架书籍不存在」未命中报错、「删除书籍成功」文案
  - getBookInfo：searchBook.bookUrl POST 兜底
- 基础分支决策落定：默认分支 = master；docker.yml secrets-in-if 解析失败修复；
  binary-windows/binary-linux workflow_dispatch 首次实跑均绿；Rust CI 绿

### 进行中
- docker 多架构构建验证中（QEMU arm64 慢，~1.5h 属正常）

### 待办（审计差异清单遗留）
- RSS/WebDAV 备份/替换规则的细节级对比（下一批）
- UI：web-ui 按 archive/master-v5.2.4 设计语言补齐缺失功能（大项）
