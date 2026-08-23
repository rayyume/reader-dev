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

## 当前状态（2026-08-23 更新）

### 后端对齐：✅ 完成
- P0 全部 17 项清零
- 引擎 E1-E16 + AR1-AR5 全部完成
- F 批 F2-F12 基本完成
- 路由全量对齐（110+ 条，含别名）
- WebDAV RFC 合规修复
- 测试 699 全绿；CI 全绿基线
- 审计报告固化于 docs/audit/

### 下一步：UI 大项
web-ui 设计语言已与 archive/master-v5.2.4 一致（diff 仅 5 文件）。
剩余为**前端功能组件开发**：
1. EPUB 阅读模式（消费 getBookContent epubContent=1 的 HTML 响应）
2. CBZ 漫画阅读模式（消费 img 标签列表响应）
3. TTS 面板完善（对接 type=api 按名解析的听书源）
4. 书源管理页增强（分组过滤、调试面板改进）

### 积压清单
详见 docs/AUDIT-BACKLOG.md 和 docs/audit/ 目录。

