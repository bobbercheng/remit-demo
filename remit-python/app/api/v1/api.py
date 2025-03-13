from fastapi import APIRouter

from app.api.v1.routes import remittances, webhooks, rates

# Create main API router
api_router = APIRouter()

# Include all route modules
api_router.include_router(
    remittances.router,
    prefix="/remittances",
    tags=["remittances"]
)

api_router.include_router(
    webhooks.router,
    prefix="/webhooks",
    tags=["webhooks"]
)

api_router.include_router(
    rates.router,
    prefix="/rates",
    tags=["rates"]
) 