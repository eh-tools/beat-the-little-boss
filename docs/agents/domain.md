# Domain Docs

本项目采用 single-context 布局，领域术语统一记录在根目录 `CONTEXT.md`，架构决策记录在根目录 `docs/adr/`。

## Before exploring, read these

- 阅读根目录 `CONTEXT.md`。
- 阅读 `docs/adr/` 中与当前任务相关的 ADR。
- 若未来存在根目录 `CONTEXT-MAP.md`，按其指向读取相关领域的术语表，并检查相应领域的 ADR。
- 如果上述文件不存在，继续任务，不因缺失而阻塞，也不预先创建空文档。由 domain-modeling 在术语或决策明确时按需创建。

## File structure

- `CONTEXT.md`：本项目领域术语表，不承载实施细节或需求草稿。
- `docs/adr/`：有实际取舍且值得记录的架构决策。

本项目目前无多包或多领域布局，不新增 `CONTEXT-MAP.md`。

## Use the glossary's vocabulary

规格、任务标题、测试描述、研究假设和重构建议使用 `CONTEXT.md` 中的规范术语，避免使用其中明确排除的同义词。

若需要的概念尚未定义，先判断是否确有领域术语缺口；需要补充时交由 domain-modeling 澄清并记录，不凭空引入另一套命名。

## Flag ADR conflicts

若方案与已有 ADR 冲突，明确指出冲突的 ADR 和重新讨论的理由，不静默覆盖已有决策。
