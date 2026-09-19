#!/usr/bin/env python3
"""Claude Code / Codex PreToolUse(Bash) 守卫: 只做 git 机制原理上做不到的事。

1. 拦截 `git commit/push/... --no-verify` 与 `-c core.hooksPath=...`
   (绕过 git hooks 的后门, git 自身管不了)
2. 拦截 main 上的直接 commit
   (GitHub ruleset 已要求 main 必须走 PR, 在本地提前拦下比推不上去更省事)

输入: stdin 的 hook JSON (tool_input.command + cwd)
放行 exit 0; 拦截 exit 2, stderr 反馈给 agent。
"""

from __future__ import annotations

import json
import os
import subprocess
import sys

# --no-verify 在这些 git 子命令里有意义; 其他子命令(如 clone -n)不误伤
NO_VERIFY_SUBCOMMANDS = {"commit", "push", "merge", "tag", "cherry-pick", "revert", "am"}

# 短选项簇里"吞掉剩余部分或下一个 token 作为值"的选项, 避免把值误判成 -n
VALUE_OPTS = "mFCctu"

STANDALONE_VALUE_OPTS = {
    "--message",
    "--file",
    "--reuse-message",
    "--reedit-message",
    "--author",
    "--date",
    "--template",
    "--cleanup",
    "--untracked-files",
}

# 带值的 git 全局选项(值在下一个 token)
GIT_VALUE_OPTS = {"-C", "--git-dir", "--work-tree", "--namespace"}

# 键=值占一个 token 的全局选项: -c <key>=<value> / --config-env <key>=<env>
GIT_PAIR_VALUE_OPTS = {"-c", "--config-env"}


def block(reason: str) -> None:
    print(reason, file=sys.stderr)
    sys.exit(2)


def tokenize(command: str) -> list[str]:
    try:
        import shlex

        return shlex.split(command)
    except ValueError:
        return command.split()


def find_subcommand(tokens: list[str]) -> str | None:
    """跳过 git 全局选项(含带值形式), 返回子命令。"""
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok == "--":
            i += 1
            continue
        if tok in GIT_VALUE_OPTS:
            i += 2  # 跳过 -C <dir> 等的值
            continue
        if tok in GIT_PAIR_VALUE_OPTS:
            i += 2  # 跳过 -c <key>=<value> 的值
            continue
        if tok.startswith("-C") and len(tok) > 2:
            i += 1  # -C<dir> 紧凑写法
            continue
        if tok.startswith("-"):
            i += 1
            continue
        return tok
    return None


def has_no_verify(tokens: list[str], sub: str | None) -> bool:
    """检测 --no-verify; 短选项 -n 只在 commit 上表示 no-verify。

    push -n = --dry-run、merge -n = --no-stat、cherry-pick/revert -n = --no-commit,
    都不是绕过 hooks, 不能误伤。
    """
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok == "--":
            break
        if tok == "--no-verify":
            return True
        if tok in STANDALONE_VALUE_OPTS:
            i += 2
            continue
        if tok.startswith("--"):
            i += 1
            continue
        if tok.startswith("-") and len(tok) > 1:
            cluster = tok[1:]
            for pos, ch in enumerate(cluster):
                if sub == "commit" and ch == "n":
                    return True
                if ch in VALUE_OPTS:
                    if pos == len(cluster) - 1:
                        i += 1  # 值是下一个 token
                    break
        i += 1
    return False


def has_hooks_bypass(tokens: list[str]) -> bool:
    """git -c core.hooksPath=<空目录> 会把 hooks 指到别处, 等价 --no-verify 的旁路。"""
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok == "--":
            break
        nxt = tokens[i + 1] if i + 1 < len(tokens) else ""
        if tok in GIT_PAIR_VALUE_OPTS and nxt.startswith("core.hooksPath"):
            return True
        if tok in GIT_PAIR_VALUE_OPTS:
            i += 2
            continue
        if tok.startswith(("-c=", "--config-env=")) and "core.hooksPath" in tok.split("=", 1)[1]:
            return True
        i += 1
    return False


def git_target_dir(tokens: list[str], cwd: str) -> str:
    """命令里 -C 指向的目录(相对 cwd 解析, 多个 -C 依次叠加); 没有则用 cwd。"""
    target = cwd
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if tok == "--":
            break
        if tok == "-C" and i + 1 < len(tokens):
            val = tokens[i + 1]
            target = val if os.path.isabs(val) else os.path.normpath(os.path.join(target, val))
            i += 2
            continue
        if tok.startswith("-C") and len(tok) > 2:
            val = tok[2:]
            target = val if os.path.isabs(val) else os.path.normpath(os.path.join(target, val))
            i += 1
            continue
        if tok.startswith("-"):
            i += 1
            continue
        break  # 子命令之后的参数不属于全局选项
    return target


def on_main_with_history(cwd: str) -> bool:
    def git(*args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["git", "-C", cwd, *args], capture_output=True, text=True, check=False
        )

    branch = git("symbolic-ref", "--quiet", "--short", "HEAD")
    if branch.returncode != 0 or branch.stdout.strip() != "main":
        return False
    if git("rev-parse", "--quiet", "--verify", "MERGE_HEAD").returncode == 0:
        return False  # merge 提交
    return git("rev-parse", "--quiet", "--verify", "HEAD").returncode == 0


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0  # 输入异常不阻塞正常操作

    command = payload.get("tool_input", {}).get("command", "")
    tokens = tokenize(command)
    if not tokens or tokens[0] != "git":
        return 0

    sub = find_subcommand(tokens)

    # 1. --no-verify / hooksPath 后门
    if sub in NO_VERIFY_SUBCOMMANDS and has_no_verify(tokens, sub):
        block(
            "已拦截: 禁止使用 --no-verify 绕过 git hooks。\n"
            "检查不通过时请修复问题后正常提交/推送, 或与人确认后再决定。"
        )
    if sub in NO_VERIFY_SUBCOMMANDS and has_hooks_bypass(tokens):
        block(
            "已拦截: 禁止用 -c core.hooksPath=... 绕过 git hooks。\n"
            "检查不通过时请修复问题后正常提交/推送, 或与人确认后再决定。"
        )

    # 2. main 上的直接提交 -> 引导开分支走 PR
    cwd = git_target_dir(tokens, payload.get("cwd") or os.getcwd())
    if sub == "commit" and on_main_with_history(cwd):
        block(
            "已拦截: 禁止直接在 main 上提交。\n"
            "请在分支上开发: git switch -c <名字>, 推送后开 PR 合并。\n"
            "(main 已开启 GitHub ruleset 保护, 必须走 PR; 流程见 PERSONAL.md)"
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
