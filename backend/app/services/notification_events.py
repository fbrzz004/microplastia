import asyncio

from fastapi import WebSocket


class NotificationEventManager:
    def __init__(self) -> None:
        self._connections: dict[
            int,
            dict[WebSocket, asyncio.Queue],
        ] = {}

    async def connect(
        self,
        user_id: int,
        websocket: WebSocket,
    ) -> asyncio.Queue:

        await websocket.accept()

        queue: asyncio.Queue = asyncio.Queue()

        self._connections.setdefault(
            user_id,
            {},
        )[websocket] = queue

        return queue

    def disconnect(
        self,
        user_id: int,
        websocket: WebSocket,
    ) -> None:

        connections = self._connections.get(user_id)

        if not connections:
            return

        connections.pop(
            websocket,
            None,
        )

        if not connections:
            self._connections.pop(
                user_id,
                None,
            )

    def publish(
        self,
        user_id: int,
        payload: dict,
    ) -> int:

        connections = self._connections.get(
            user_id,
            {},
        )

        for queue in list(connections.values()):
            queue.put_nowait(payload)

        return len(connections)


notification_events = NotificationEventManager()
