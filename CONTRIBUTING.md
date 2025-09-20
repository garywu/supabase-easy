# Contributing to Supabase Easy

First off, thank you for considering contributing to Supabase Easy! It's people like you that make this tool better for everyone.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps which reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include logs from `make logs`**
* **Include your environment details** (OS, Docker version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior and explain which behavior you expected to see instead**
* **Explain why this enhancement would be useful**

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the style guides
* Include thoughtfully-worded, well-structured tests
* Document new code
* End all files with a newline

## Development Process

1. Fork the repo and create your branch from `main`
2. Make your changes
3. Test your changes with `make install`
4. Ensure all scripts are executable: `chmod +x scripts/*.sh`
5. Update documentation if needed
6. Submit a pull request

## Testing Your Changes

```bash
# Test the full installation
make clean
make install PROJECT=test-pr

# Verify it works
make verify PROJECT=test-pr

# Check logs for errors
make logs PROJECT=test-pr
```

## Style Guides

### Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

### Shell Script Style Guide

* Use `#!/bin/bash` for all scripts
* Set `set -e` to exit on errors
* Use meaningful variable names
* Add comments for complex logic
* Use `echo` statements to show progress
* Handle errors gracefully

### Documentation Style Guide

* Use Markdown for all documentation
* Include code examples where relevant
* Keep explanations clear and concise
* Update the CHANGELOG.md for notable changes

## Project Structure

```
supabase-easy/
├── scripts/          # Bash scripts for automation
├── fixes/           # Configuration fixes
├── cache/           # Downloaded files (gitignored)
├── projects/        # User projects (gitignored)
└── Makefile        # Main automation
```

## Questions?

Feel free to open an issue with your question or contact the maintainers directly.

Thank you for contributing! 🚀