from datetime import datetime

from pydantic import BaseModel, Field


class NotificationItem(BaseModel):
    id: int

    type: str = "analysis"

    title: str

    message: str

    result_id: int | None = None

    is_read: bool = False

    created_at: datetime | None = None


class NotificationListData(BaseModel):
    items: list[NotificationItem] = Field(default_factory=list)

    total: int = 0

    unread_count: int = 0

    limit: int = 20

    offset: int = 0


class NotificationListResponse(BaseModel):
    success: bool = True

    data: NotificationListData


class NotificationItemResponse(BaseModel):
    success: bool = True

    data: NotificationItem


class NotificationReadAllData(BaseModel):
    updated: int = 0

    unread_count: int = 0


class NotificationReadAllResponse(BaseModel):
    success: bool = True

    data: NotificationReadAllData


class NotificationPreferenceData(BaseModel):
    notificaciones_activas: bool = True


class NotificationPreferenceUpdate(BaseModel):
    notificaciones_activas: bool


class NotificationPreferenceResponse(BaseModel):
    success: bool = True

    data: NotificationPreferenceData
