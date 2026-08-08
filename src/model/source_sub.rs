//! 书源订阅（表：source_subs）
//!
//! 订阅远程书源集合链接（url 主键）：raw_json 保存抓取到的完整书源数组 JSON 原文
//! （保底不丢字段），订阅保存/刷新时校验后批量导入 book_sources 表。
//! 订阅支持「禁用」：禁用后不再自动刷新，但保留订阅记录与已导入书源；
//! 重新启用即恢复自动刷新。

use serde::{Deserialize, Serialize};
use sqlx::FromRow;

/// 书源订阅（表：source_subs）
#[derive(Debug, Clone, Default, Serialize, Deserialize, FromRow)]
#[serde(default)]
pub struct SourceSub {
    /// 订阅链接（远程书源集合 URL，主键）
    pub url: String,
    /// 订阅名称
    pub name: String,
    /// 是否启用（禁用后定时任务跳过该订阅，保留记录与已导入书源）
    #[serde(default = "default_true")]
    pub enabled: bool,
    #[serde(skip)]
    #[sqlx(rename = "user_namespace")]
    pub user_namespace: String,
    /// 用户私有“已删除”覆盖标记（普通用户删除 default 系统订阅时复制到本人命名空间并隐藏）
    #[serde(skip)]
    #[sqlx(rename = "hidden")]
    pub hidden: bool,
    /// 抓取到的书源数组 JSON 原文
    #[serde(skip)]
    #[sqlx(rename = "raw_json")]
    pub raw_json: Option<String>,
}

fn default_true() -> bool {
    true
}
