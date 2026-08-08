# ---------- 阶段 2：前端构建 ----------
FROM node:20-slim AS web
WORKDIR /web
COPY web-ui/package.json web-ui/package-lock.json* ./
RUN npm ci
COPY web-ui ./
RUN npx vite build

# ---------- 阶段 1：后端编译 ----------
FROM rust:1.97-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY .cargo ./.cargo
# GAP 176：epub 导出内嵌中文字体（include_bytes 编译期内嵌 web-ui/public/fonts/）
COPY web-ui/public/fonts ./web-ui/public/fonts
# rust-embed 编译期嵌入前端（需先构建 dist——见下方 web 阶段；顺序：web 先构建，builder 再编译）
COPY --from=web /web/dist ./web-ui/dist
ENV RUSTFLAGS="--cfg reqwest_unstable"
RUN cargo build --release

# ============================================================
# reader-dev (Rust) 多阶段构建
#   - 运行镜像内置 obscura（唯一浏览器后端）：书源登录/滑块验证码/CF 质询浏览器流
#     （browser.rs spawn `obscura serve --stealth`——READER_OBSCURA_BIN=/opt/obscura/obscura）
#   - GAP 175：运行镜像内置 python3 + camoufox（验证码求解 HTTP 后端
#     scripts/camoufox_solver.py——CDP 失败后的强质询兜底，端口 8196）
#   - 构建：docker build -t reader-dev .
# ============================================================

# ---------- 阶段 2.5：camoufox 求解后端（pip 包 + 浏览器二进制，构建期下载） ----------
FROM python:3.12-slim AS camo
RUN pip install --no-cache-dir camoufox==0.5.4 \
    && python -m camoufox fetch

# ---------- 阶段 3：obscura 浏览器（release stealth 构建——BoringSSL TLS 指纹模拟/反检测/追踪器拦截） ----------
FROM debian:trixie-slim AS obscura
ARG TARGETARCH
ARG OBSCURA_VERSION=v0.2.0
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# 仓库无安装脚本——直接下载官方 release 资产（-stealth 后缀为 stealth 构建，
# 含 BoringSSL/wreq 传输层）。版本固定为 OBSCURA_VERSION（默认 v0.2.0——不用
# /releases/latest：upstream 更新会让层内容变化，导致每次 pull 几乎全量下载；
# 固定 tag 后该层 blob 不变，registry 层复用率显著提升）。TARGETARCH 由
# buildx --platform 自动注入（amd64/arm64）；普通 docker build 未注入时默认
# x86_64。资产内含 obscura + obscura-worker（同目录）
RUN set -eux; \
    case "${TARGETARCH:-}" in \
      ""|amd64|x86_64) ASSET="obscura-x86_64-linux-stealth.tar.gz" ;; \
      arm64|aarch64) ASSET="obscura-aarch64-linux-stealth.tar.gz" ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fL --retry 3 -o /tmp/obscura.tar.gz \
      "https://github.com/h4ckf0r0day/obscura/releases/download/${OBSCURA_VERSION}/${ASSET}"; \
    mkdir -p /opt/obscura; \
    tar xzf /tmp/obscura.tar.gz -C /opt/obscura; \
    rm /tmp/obscura.tar.gz; \
    test -x /opt/obscura/obscura; \
    ls -la /opt/obscura

# ---------- 阶段 4：运行镜像 ----------
FROM debian:trixie-slim

# 时区 + CA + python3（camoufox 后端）——obscura 为静态依赖少的 Rust 二进制（无需 chromium）
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        tzdata \
        fonts-noto-cjk \
        python3 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# camoufox 运行时系统库（Firefox 内核——playwright firefox 依赖集）+ tini（ENTRYPOINT 入口）
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tini \
        libnss3 libnspr4 libdbus-1-3 libatk1.0-0 libatk-bridge2.0-0 \
        libcups2 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
        libxfixes3 libxrandr2 libgbm1 libasound2 libpango-1.0-0 libcairo2 \
    && ln -sf /usr/bin/tini /sbin/tini \
    && rm -rf /var/lib/apt/lists/*

# camoufox：pip 包 + 浏览器二进制（从 camo 阶段拷贝——免容器内在线下载）
COPY --from=camo /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=camo /root/.cache/camoufox /root/.cache/camoufox
COPY scripts/camoufox_solver.py /usr/local/bin/camoufox_solver.py

# obscura 浏览器（唯一后端——stealth 构建：BoringSSL TLS 指纹模拟/反检测/追踪器拦截）
COPY --from=obscura /opt/obscura /opt/obscura

ENV TZ=Asia/Shanghai
ENV READER_APP_WEB_ROOT=/app/web-ui/dist
ENV READER_OBSCURA_BIN=/opt/obscura/obscura
ENV READER_CAMOUFOX_URL=http://127.0.0.1:8196

COPY --from=builder /app/target/release/reader-dev /usr/local/bin/reader-dev
# 前端 dist 从 builder 阶段拷贝（builder 已为 rust-embed 编译嵌入同一份 dist）——
# 减少一层，且把唯一高频变化层（二进制 + dist）放在镜像末尾，稳定层前置
COPY --from=builder /app/web-ui/dist /app/web-ui/dist

EXPOSE 8080
VOLUME ["/data"]
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["reader-dev"]
