local M = {}

function M.find_session(chat)
    vim.ui.input({ prompt = 'Session topic: ' }, function(input)
        local query = input and vim.trim(input)
        if not query or query == '' then
            return
        end
        local current_id = chat.acp_connection and chat.acp_connection.session_id or ''

        chat:add_message({
            role = 'user',
            content = string.format(
                [[Find the ACP session whose conversation discussed %q.

Search the local Codex sessions in ~/.codex/sessions/**/rollout-*.jsonl and
Claude sessions in ~/.claude/projects/*/*.jsonl. Use rg to shortlist files by
distinctive query concepts independently, allowing likely spelling variants,
then parse only those candidates. Do not require the exact phrase.

For Codex, search input_text/output_text in response_item records whose
payload.role is "user" or "assistant". Ignore sessions whose session_meta has
thread_source="subagent". For Claude, search text content in top-level user and
assistant records, excluding tool calls and tool results. Do not count prompts
or answers whose only purpose is finding another session as matching evidence.
Resolve generated titles from %s; Claude files may also contain aiTitle.
Exclude the current session ID %q because this request contains the search terms.

Return at most five likely matches, newest first, with provider, exact title,
full session ID, updated date, and a short matching excerpt. Do not edit files
or load a session.]],
                query,
                vim.fs.joinpath(
                    vim.fn.stdpath('data'),
                    'codecompanion',
                    'acp-session-titles.json'
                ),
                current_id
            ),
        }, { visible = false })
        chat:submit({ auto_submit = true })
        vim.schedule(function()
            if vim.api.nvim_get_current_buf() == chat.bufnr then
                vim.cmd.stopinsert()
            end
        end)
    end)
end

return M
