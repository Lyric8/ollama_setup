# Ollama macOS 部署指南

适用环境：Apple Silicon（M1/M2/M3 系列），macOS Sequoia，32GB 统一内存。

---

## 一、前置准备

### 1. 安装 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安装完成后将 Homebrew 加入 PATH：

```bash
echo >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
```

### 2. 安装 Ollama

```bash
brew install ollama
```

---

## 二、拉取模型

### 可用模型（Gemma 4）

| 模型 | 大小 | 适用场景 |
|------|------|----------|
| `gemma4:e4b` | 9.6 GB | 轻量快速，简单问答、代码补全 |
| `gemma4:26b` | 17 GB | 复杂推理、长上下文、高质量输出 |

### 拉取命令

```bash
ollama pull gemma4:e4b
ollama pull gemma4:26b
```

### 注意事项

- 模型文件大，网络不稳定会断。Ollama 支持断点续传，断了重新执行同一命令即可。
- **切换网络会导致 CDN 节点变化，partial 文件 hash 不同，无法续传，会重新下载。** 下载期间保持同一网络。
- 查看已下载的模型：

```bash
ollama list
```

---

## 三、部署与配置

### 配置说明

通过 launchd plist 配置 Ollama 服务，实现开机自启和环境变量注入。

创建 `~/Library/LaunchAgents/com.ollama.server.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/opt/ollama/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>0.0.0.0:11434</string>
        <key>OLLAMA_MODELS</key>
        <string>/Users/YOUR_USERNAME/OllamaModels</string>
        <key>OLLAMA_CONTEXT_LENGTH</key>
        <string>65536</string>
        <key>OLLAMA_KEEP_ALIVE</key>
        <string>10m</string>
        <key>OLLAMA_NO_CLOUD</key>
        <string>1</string>
        <key>OLLAMA_FLASH_ATTENTION</key>
        <string>1</string>
        <key>OLLAMA_KV_CACHE_TYPE</key>
        <string>q8_0</string>
        <key>OLLAMA_NUM_PARALLEL</key>
        <string>2</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/OllamaModels/ollama.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/OllamaModels/ollama-error.log</string>
</dict>
</plist>
```

将 `YOUR_USERNAME` 替换为实际用户名（`whoami` 查看）。

### 关键配置项说明

| 参数 | 值 | 说明 |
|------|----|------|
| `OLLAMA_HOST` | `0.0.0.0:11434` | 监听所有网卡，允许局域网访问 |
| `OLLAMA_CONTEXT_LENGTH` | `65536` | 最大上下文长度（token 数） |
| `OLLAMA_KEEP_ALIVE` | `10m` | 模型无请求后 10 分钟自动卸载释放内存。设为 `-1` 永不卸载，但会阻止模型切换 |
| `OLLAMA_FLASH_ATTENTION` | `1` | 开启 Flash Attention，降低显存占用、提升速度 |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | KV Cache 量化，节省约 50% 显存 |
| `OLLAMA_NUM_PARALLEL` | `2` | 并发请求数（全局，对所有模型生效） |

### 启动服务

```bash
# 首次加载（开机后自动执行，手动也可以运行）
launchctl load ~/Library/LaunchAgents/com.ollama.server.plist

# 修改配置后重启
launchctl unload ~/Library/LaunchAgents/com.ollama.server.plist
launchctl load ~/Library/LaunchAgents/com.ollama.server.plist
```

### 验证服务

```bash
# 本地
curl http://localhost:11434/api/version

# 局域网（替换为实际 IP）
curl http://192.168.x.x:11434/api/version
```

---

## 四、对外接口管理

### 查看当前局域网 IP

```bash
ipconfig getifaddr en0
```

> ⚠️ 局域网 IP 是 DHCP 分配的，换网络会变。如需固定 IP，在路由器设置 MAC 地址绑定（手机热点不支持）。

### API 接口

服务启动后暴露标准 Ollama API：

#### 查看可用模型

```bash
curl http://SERVER_IP:11434/api/tags
```

#### 文本生成（非推理模式）

```bash
curl http://SERVER_IP:11434/api/generate -d '{
  "model": "gemma4:e4b",
  "prompt": "你好",
  "stream": false,
  "think": false
}'
```

#### 文本生成（推理模式）

```bash
curl http://SERVER_IP:11434/api/generate -d '{
  "model": "gemma4:26b",
  "prompt": "解释一下快速排序",
  "stream": false,
  "think": true
}'
```

推理模式响应会多一个 `thinking` 字段，包含推理过程。

#### 对话接口

```bash
curl http://SERVER_IP:11434/api/chat -d '{
  "model": "gemma4:e4b",
  "stream": false,
  "messages": [
    {"role": "user", "content": "你好"}
  ]
}'
```

#### OpenAI 兼容接口

Ollama 同时支持 OpenAI 格式，可直接接入 OpenAI SDK：

```bash
curl http://SERVER_IP:11434/v1/chat/completions -d '{
  "model": "gemma4:e4b",
  "messages": [{"role": "user", "content": "你好"}]
}'
```

### 模型管理

```bash
# 查看已加载的模型及显存占用
ollama ps

# 手动卸载模型（释放显存）
ollama stop gemma4:26b

# 模型切换
# 直接向目标模型发请求，Ollama 自动卸载当前模型、加载新模型
# 切换耗时：e4b 约 5-10 秒，26b 约 20-30 秒
```

### 日志

```bash
tail -f ~/OllamaModels/ollama.log        # 访问日志
tail -f ~/OllamaModels/ollama-error.log  # 错误日志
```

---

## 五、32GB 统一内存性能表现

Apple M1 Pro 32GB 的统一内存架构中，CPU 和 GPU 共享同一块内存，Ollama 自动使用 GPU（Metal）加速推理。

### 显存分配

系统为 GPU 预留约 21.3GB 可用显存。

| 模型 | 权重占用 | KV Cache（q8_0, ctx=65536） | 合计 | 并发 2 是否可行 |
|------|---------|----------------------------|------|----------------|
| `gemma4:e4b` | ~5 GB | ~4 GB × 2 | ~13 GB | ✅ 充裕 |
| `gemma4:26b` | ~17 GB | ~4 GB | ~21 GB | ⚠️ 接近上限，建议并发 1 |

> 两个模型不能同时加载，切换时会自动卸载另一个。

### 推理速度实测（M1 Pro 32GB，Ollama 0.20.5）

测试 prompt：「用中文写一段 100 字左右的自我介绍」，单并发，冷启动加载后首次请求。

| 模型 | 模式 | 首 token 延迟 | 生成速度 | 生成 token 数 | 总耗时 |
|------|------|--------------|---------|--------------|--------|
| `gemma4:e4b` | 非推理 | 136 ms | **28.8 tok/s** | 342 | 12 秒 |
| `gemma4:26b` | 非推理 | 329 ms | **9.5 tok/s** | 479 | 50 秒 |
| `gemma4:26b` | 推理模式 | 398 ms | **7.7 tok/s** | 1143 | 149 秒 |

**结论：**
- e4b 速度约为 26b 的 **3 倍**，适合对延迟敏感的场景
- 26b 推理模式生成 token 数更多（含思考过程），总耗时约 2.5 分钟
- 首 token 延迟均在 400ms 以内，模型已加载时响应很快

> 实测环境：Apple M1 Pro，32GB 统一内存，Flash Attention 开启，KV Cache q8_0，context 65536。

### 优化建议

- **轻量任务用 e4b**：速度快 2-3 倍，显存占用一半
- **保持 Flash Attention 开启**：对 Apple Silicon 有明显加速
- **KV Cache 用 q8_0**：在精度损失极小的前提下节省约 50% 显存，可以跑更长上下文
- **不要同时运行其他大内存应用**：统一内存被其他程序占用会影响推理速度
