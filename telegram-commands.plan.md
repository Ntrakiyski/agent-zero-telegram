# Telegram Bot Enhancement: Multi-Agent Sessions & Utility Commands

## Context

This enhancement adds significant new capabilities to the Agent Zero Telegram bot, enabling users to manage multiple agent sessions within a single Telegram chat and access useful utility commands.

**Current State:**
- Telegram bot supports basic commands: `/start`, `/new`, `/id`
- One AgentContext per Telegram chat
- Simple message routing to single agent

**Desired Outcome:**
- Multiple independent agent sessions in one Telegram chat (e.g., @agent0, @agent1, @agent2)
- Message routing based on @agent tags
- Utility commands: `/skills`, `/mcp`, `/status`, `/new skill`, `/new agent`
- Clear indication of which agent is responding

---

## Implementation Plan

### Phase 1: Multi-Agent Session Infrastructure

**File: `python/helpers/telegram_bot.py`**

#### 1.1 Extend Context Storage
```python
# Change from single context per chat to multiple contexts
# Current: _chat_contexts: dict[int, str]  # telegram_chat_id -> context_id
# New: _chat_contexts: dict[int, dict[str, str]]  # telegram_chat_id -> {tag: context_id}
```

#### 1.2 Add Agent Counter
```python
# Track next agent number per chat
_chat_agent_counters: dict[int, int] = {}  # telegram_chat_id -> next_agent_number
```

#### 1.3 Message Routing Function
```python
def _parse_agent_tag(message: str, telegram_chat_id: int) -> tuple[str, str]:
    """
    Parse message for @agent tag and return (tag, message_without_tag)
    Default to "@agent0" if no tag found
    """
```

#### 1.4 Response Prefixing
```python
async def _send_response(chat_id: int, text: str, context, agent_tag: str):
    """Prefix response with agent tag like [@agent0] response text"""
```

#### 1.5 Context Retrieval with Tag Support
```python
def _get_context_for_tag(telegram_chat_id: int, agent_tag: str) -> AgentContext:
    """Get AgentContext for specific tag, create if doesn't exist"""
```

### Phase 2: New Command Handlers

#### 2.1 `/new agent` Command
```python
async def _handle_new_agent(update, context) -> None:
    """Create a new agent session with auto-incremented number"""
    # 1. Get next agent number for this chat
    # 2. Create new AgentContext
    # 3. Store with tag @agent{N}
    # 4. Send confirmation with agent tag
```

#### 2.2 `/skills` Command
```python
async def _handle_skills(update, context) -> None:
    """List all available skills"""
    # Use python.helpers.skills or skills_tool to list
    # Format: skill_name, description, version, tags
```

#### 2.3 `/mcp` Command
```python
async def _handle_mcp(update, context) -> None:
    """List connected MCP servers with status"""
    # Use MCPConfig.get_instance() to get server list
    # Format: server_name, status, tool_count, errors
```

#### 2.4 `/status` Command
```python
async def _handle_status(update, context) -> None:
    """Show status of all agents in this chat"""
    # For each agent: tag, running_state, log_length, last_message_time
```

#### 2.5 `/new skill` Command
```python
async def _handle_new_skill(update, context) -> None:
    """Create a new skill via interactive flow"""
    # Prompt for skill name, description, triggers
    # Create SKILL.md file in usr/skills/
    # Optionally create Python helper script
```

### Phase 3: Update Existing Handlers

#### 3.1 Modify `_handle_message`
```python
async def _handle_message(update, context) -> None:
    # 1. Parse message for @agent tag
    # 2. Get context for that tag (create agent0 if doesn't exist)
    # 3. Route message to appropriate context
    # 4. Prefix response with agent tag
```

#### 3.2 Update `/new` Command
```python
async def _handle_new(update, context) -> None:
    # Now resets ONLY agent0, not all agents
    # Or rename to /reset for clarity
```

#### 3.3 Register New Commands in `_run_bot`
```python
commands = [
    BotCommand("start", "Show welcome message and available commands"),
    BotCommand("new_agent", "Create a new agent session"),
    BotCommand("skills", "List available skills"),
    BotCommand("mcp", "List connected MCP servers"),
    BotCommand("status", "Show all agents status"),
    BotCommand("new_skill", "Create a new skill"),
    BotCommand("new", "Reset agent0 conversation"),
    BotCommand("id", "Show your Telegram user ID"),
]
```

---

## File Modifications

### Primary File
| File | Changes |
|------|---------|
| `python/helpers/telegram_bot.py` | Major changes: add multi-agent support, new command handlers |

### Supporting Files (No changes required - use existing APIs)
| File | Usage |
|------|--------|
| `python/helpers/skills.py` | For `/skills` command |
| `python/helpers/mcp_handler.py` | For `/mcp` command |
| `agent.py` (AgentContext) | For `/status` command |

---

## Implementation Details

### Multi-Agent Context Structure

```python
# Before: Single context per chat
_chat_contexts = {123456789: "abc12345"}  # chat_id -> context_id

# After: Multiple contexts per chat with tags
_chat_contexts = {
    123456789: {
        "@agent0": "abc12345",
        "@agent1": "def67890",
        "@agent2": "ghi13579"
    }
}
```

### Message Flow with Tags

1. User sends: "Hello @agent1"
2. Bot parses: tag="@agent1", message="Hello"
3. Bot gets context for @agent1
4. Routes to that agent
5. Responds: "[@agent1] Hi! How can I help?"

### Default Behavior

1. User sends: "What's the weather?" (no tag)
2. Bot defaults to @agent0
3. Creates @agent0 if doesn't exist
4. Responds: "[@agent0] Let me check the weather for you..."

---

## Verification Plan

### Test Multi-Agent Sessions
1. Start a chat, send message → should create @agent0
2. Send `/new agent` → should create @agent1
3. Send another `/new agent` → should create @agent2
4. Send "hello @agent1" → should respond with [@agent1] prefix
5. Send "hello" (no tag) → should respond from @agent0
6. Verify contexts are independent (different history/memory)

### Test Commands
1. `/skills` → Should list all available skills
2. `/mcp` → Should show MCP server status
3. `/status` → Should show all agents with their states
4. `/new skill` → Should guide through skill creation
5. `/new agent` → Should create new agent with incremented number

### Test Edge Cases
1. Invalid tag like @agent999 → should show error
2. Non-numeric tag like @custom → should show error (unless we support custom names)
3. Empty message with tag → should handle gracefully
4. Multiple tags in one message → should use first tag or show error

---

## Key Code References

### Existing Code to Reuse

| Function/Class | Location | Purpose |
|----------------|----------|---------|
| `_get_allowed_users()` | `telegram_bot.py` | Authorization check |
| `_send_long_message()` | `telegram_bot.py` | Handle long responses |
| `AgentContext.get()` | `agent.py` | Get context by ID |
| `AgentContext.all()` | `agent.py` | Get all contexts |
| `skills_tool` | `python/tools/skills_tool.py` | List/load skills |
| `MCPConfig.get_instance()` | `python/helpers/mcp_handler.py` | MCP status |

---

## User-Facing Changes

### New Commands Summary

| Command | Description | Example |
|---------|-------------|---------|
| `/new agent` | Create new agent session | Creates @agent1, @agent2... |
| `/skills` | List available skills | Shows all skills with descriptions |
| `/mcp` | List MCP servers | Shows server connection status |
| `/status` | Show agent status | Shows all agents with states |
| `/new skill` | Create new skill | Interactive skill creation |

### Behavior Changes

| Feature | Before | After |
|---------|--------|-------|
| `/new` | Resets conversation | Resets only @agent0 |
| No tag message | Goes to single agent | Goes to @agent0 |
| Response format | Plain text | Prefixed with [@agentX] |

---

## Future Enhancements (Out of Scope)

- Custom agent names (e.g., @coder, @researcher)
- Agent-to-agent communication
- Agent cloning
- Export/import agent sessions
- Agent templates
- Persistent agent names across restarts
