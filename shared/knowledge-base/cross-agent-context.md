# Departments & Agents Registry

## Active Departments
| ID | Department | TG Bot | Status | Skills Count |
|----|-----------|--------|--------|-------------|
| D01 | marketing | @digital_office_marketing_bot | Active | 0 (building) |

## Planned Departments
| ID | Department | Priority | Prerequisites |
|----|-----------|----------|---------------|
| D02 | code | High | Marketing stable |
| D03 | research | Medium | Marketing + Code stable |
| D04 | content | Medium | Marketing stable |
| D05 | personal | Low | Core system stable |

## Cross-Agent Rules
- Agents can READ shared/knowledge-base/ (read-only)
- Agents can READ/WRITE their own groups/{dept}/ only
- Main agent can access all departments
- Never write to another department's memory/
