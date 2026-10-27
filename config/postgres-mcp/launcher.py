"""Defer Postgres MCP tunnel setup and AWS login until a database tool runs."""

import asyncio
import sys
from typing import NoReturn

from postgres_mcp import main, server

tunnel = sys.argv.pop(1)
db = server.db_connection
get_sql_driver = server.get_sql_driver


async def skip_startup_connect(connection_url: str | None = None) -> NoReturn:
    """Save the connection URL without contacting AWS during startup."""
    db.connection_url = connection_url
    # Later connections use the original method again
    del db.pool_connect
    raise ValueError("The connection opens on the first query")


async def open_tunnel_first() -> server.SqlDriver | server.SafeSqlDriver:
    """Open the tunnel before tools start their 30-second query timeout.

    Otherwise a slow browser login would make the first query time out.
    """
    if not db.is_valid:
        proc = await asyncio.create_subprocess_exec(tunnel, "--open", stdout=sys.stderr)
        if await proc.wait():
            raise ValueError("Could not open the Internal Data tunnel")
    return await get_sql_driver()


db.pool_connect = skip_startup_connect  # ty: ignore[invalid-assignment]
server.get_sql_driver = open_tunnel_first  # ty: ignore[invalid-assignment]
sys.exit(main())
