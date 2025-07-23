# Use environment variables from parent
set positional-arguments := true
set export := true

# Default server URL from environment
default_server_url := env_var_or_default("MCP_SERVER_URL", "https://echo-stateless.localhost/mcp")

# ============================================================================
# TOKEN GENERATION AND MANAGEMENT
# ============================================================================

# Generate test token for MCP client (complete OAuth flow)
token-generate server-url=default_server_url:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Initiating OAuth flow for {{server-url}}..."
    MCP_SERVER_URL="{{server-url}}" pixi run mcp-streamablehttp-client --token

# Check current token status
token-status:
    pixi run mcp-streamablehttp-client --token

# Clear all OAuth credentials
token-reset:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Clearing OAuth credentials..."
    pixi run mcp-streamablehttp-client --reset-auth

# Test authentication with current token
token-test:
    pixi run mcp-streamablehttp-client --test-auth

# ============================================================================
# DEVELOPMENT AND TESTING
# ============================================================================

# Install dependencies
install:
    pixi install

# Run the client in proxy mode (for Claude Desktop)
run:
    pixi run mcp-streamablehttp-client

# Execute a single command
exec command:
    pixi run mcp-streamablehttp-client -c "{{command}}"

# List available tools
list-tools:
    pixi run mcp-streamablehttp-client --list-tools

# List available resources  
list-resources:
    pixi run mcp-streamablehttp-client --list-resources

# List available prompts
list-prompts:
    pixi run mcp-streamablehttp-client --list-prompts

# ============================================================================
# OAUTH CLIENT MANAGEMENT (RFC 7592)
# ============================================================================

# Get current OAuth client info
client-info:
    pixi run mcp-streamablehttp-client --get-client-info

# Update OAuth client registration
client-update updates:
    pixi run mcp-streamablehttp-client --update-client "{{updates}}"

# Delete OAuth client (PERMANENT!)
client-delete:
    pixi run mcp-streamablehttp-client --delete-client

# ============================================================================
# TESTING WORKFLOWS
# ============================================================================

# Complete test workflow: setup token and test
test-setup server-url=default_server_url:
    just token-generate {{server-url}}
    just token-test
    just list-tools

# Test with echo server
test-echo message="Hello from MCP client!":
    pixi run mcp-streamablehttp-client -c 'echo message="{{message}}"'

# Test stateful echo server
test-stateful:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Testing stateful functionality..."
    pixi run mcp-streamablehttp-client -c 'echo message="First message"'
    pixi run mcp-streamablehttp-client -c 'echo message="Second message"'
    pixi run mcp-streamablehttp-client -c 'get_history'

# ============================================================================
# DOCKER OPERATIONS
# ============================================================================

# Build Docker image
docker-build:
    docker build -t mcp-streamablehttp-client:latest .

# Run in Docker container
docker-run server-url=default_server_url:
    docker run --rm -it \
        -e MCP_SERVER_URL={{server-url}} \
        -v $(pwd)/.env:/app/.env:ro \
        mcp-streamablehttp-client:latest

# ============================================================================
# UTILITIES
# ============================================================================

# Show current environment configuration
env-show:
    @echo "Current MCP client configuration:"
    @echo "MCP_SERVER_URL: ${MCP_SERVER_URL:-not set}"
    @echo "OAUTH_METADATA_URL: ${OAUTH_METADATA_URL:-not set}"
    @echo "CLIENT_NAME: ${CLIENT_NAME:-mcp-http-stdio}"
    @echo "LOG_LEVEL: ${LOG_LEVEL:-INFO}"


# Show help
help:
    @echo "MCP StreamableHTTP Client Commands:"
    @echo ""
    @echo "Token Management:"
    @echo "  just token-generate [server-url]  - Generate OAuth tokens"
    @echo "  just token-status                 - Check token status"
    @echo "  just token-test                   - Test authentication"
    @echo "  just token-reset                  - Clear all credentials"
    @echo ""
    @echo "Development:"
    @echo "  just run                          - Run in proxy mode"
    @echo "  just exec <command>               - Execute single command"
    @echo "  just list-tools                   - List available tools"
    @echo ""
    @echo "Testing:"
    @echo "  just test-setup [server-url]      - Complete test setup"
    @echo "  just test-echo [message]          - Test echo command"
    @echo "  just test-stateful                - Test stateful server"