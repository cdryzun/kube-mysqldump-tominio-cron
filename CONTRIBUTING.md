# Contributing to kube-mysqldump-tominio-cron

[English](#english) | [中文](#中文)

---

## English

First off, thank you for considering contributing to kube-mysqldump-tominio-cron! It's people like you that make this tool better for everyone.

### How Can I Contribute?

#### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (YAML configurations, environment variables, etc.)
- **Describe the behavior you observed and what you expected**
- **Include logs** if applicable
- **Specify your environment** (Kubernetes version, MySQL version, MinIO version)

#### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any alternatives you've considered**

#### Pull Requests

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

##### Pull Request Guidelines

- Follow the existing code style
- Update documentation if needed
- Add tests if applicable
- Keep commits atomic and well-described
- Reference any related issues

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/kube-mysqldump-tominio-cron.git
cd kube-mysqldump-tominio-cron

# Build Docker image locally
docker build -t kube-mysqldump-tominio-cron:dev ./Docker

# Test locally with docker-compose or kind/minikube
```

### Code Style

- Shell scripts should pass `shellcheck`
- YAML files should be properly indented (2 spaces)
- Use meaningful variable names
- Add comments for complex logic

### License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## 中文

首先，感谢您考虑为 kube-mysqldump-tominio-cron 做出贡献！正是像您这样的人让这个工具变得更好。

### 如何贡献？

#### 报告 Bug

在创建 Bug 报告之前，请先检查现有的 issues 以避免重复。创建 Bug 报告时，请尽可能包含详细信息：

- **使用清晰描述性的标题**
- **描述重现问题的确切步骤**
- **提供具体示例**（YAML 配置、环境变量等）
- **描述您观察到的行为以及您期望的行为**
- **如果适用，请包含日志**
- **指定您的环境**（Kubernetes 版本、MySQL 版本、MinIO 版本）

#### 建议增强功能

增强建议作为 GitHub issues 进行跟踪。创建增强建议时：

- **使用清晰描述性的标题**
- **提供建议增强功能的详细描述**
- **解释为什么这个增强功能会有用**
- **列出您考虑过的任何替代方案**

#### Pull Requests

1. Fork 仓库
2. 创建您的功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开 Pull Request

##### Pull Request 指南

- 遵循现有的代码风格
- 如果需要，更新文档
- 如果适用，添加测试
- 保持提交原子化且描述清晰
- 引用任何相关的 issues

### 开发环境设置

```bash
# 克隆您的 fork
git clone https://github.com/YOUR_USERNAME/kube-mysqldump-tominio-cron.git
cd kube-mysqldump-tominio-cron

# 本地构建 Docker 镜像
docker build -t kube-mysqldump-tominio-cron:dev ./Docker

# 使用 docker-compose 或 kind/minikube 进行本地测试
```

### 代码风格

- Shell 脚本应通过 `shellcheck` 检查
- YAML 文件应正确缩进（2 个空格）
- 使用有意义的变量名
- 为复杂逻辑添加注释

### 许可证

通过贡献，您同意您的贡献将根据 MIT 许可证进行许可。
