from __future__ import annotations

import os
from typing import Any

import requests
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field


OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434").rstrip("/")
DEFAULT_MODEL = os.getenv("GEMMA_DEFAULT_MODEL", "gemma4:e4b")
DEFAULT_NUM_CTX = int(os.getenv("GEMMA_DEFAULT_NUM_CTX", "4096"))
DEFAULT_MAX_TOKENS = int(os.getenv("GEMMA_DEFAULT_MAX_TOKENS", "256"))
DEFAULT_TEMPERATURE = float(os.getenv("GEMMA_DEFAULT_TEMPERATURE", "0.2"))
API_TOKEN = os.getenv("GEMMA_AGENT_API_TOKEN", "").strip()
REQUEST_TIMEOUT = int(os.getenv("GEMMA_OLLAMA_TIMEOUT_SEC", "180"))

app = FastAPI(
    title="Gemma Agent API",
    version="1.0.0",
    description="A thin local API wrapper around Ollama for direct agent integration.",
)


class AskRequest(BaseModel):
    question: str = Field(..., description="The user question or task.")
    system: str | None = Field(default=None, description="Optional system instruction.")
    model: str = Field(default=DEFAULT_MODEL)
    num_ctx: int = Field(default=DEFAULT_NUM_CTX, ge=512, le=65536)
    max_tokens: int = Field(default=DEFAULT_MAX_TOKENS, ge=1, le=4096)
    temperature: float = Field(default=DEFAULT_TEMPERATURE, ge=0, le=2)
    think: bool = Field(default=False)
    keep_alive: int | str = Field(default=0)


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    messages: list[ChatMessage]
    model: str = Field(default=DEFAULT_MODEL)
    num_ctx: int = Field(default=DEFAULT_NUM_CTX, ge=512, le=65536)
    max_tokens: int = Field(default=DEFAULT_MAX_TOKENS, ge=1, le=4096)
    temperature: float = Field(default=DEFAULT_TEMPERATURE, ge=0, le=2)
    think: bool = Field(default=False)
    keep_alive: int | str = Field(default=0)


def _check_auth(authorization: str | None) -> None:
    if not API_TOKEN:
        return
    if authorization != f"Bearer {API_TOKEN}":
        raise HTTPException(status_code=401, detail="Unauthorized")


def _ollama_request(path: str, body: dict[str, Any] | None = None, method: str = "GET") -> dict[str, Any]:
    url = f"{OLLAMA_BASE_URL}{path}"
    try:
        response = requests.request(method=method, url=url, json=body, timeout=REQUEST_TIMEOUT)
    except requests.RequestException as exc:
        raise HTTPException(status_code=502, detail=f"Ollama request failed: {exc}") from exc

    if not response.ok:
        detail = response.text.strip() or response.reason
        raise HTTPException(status_code=response.status_code, detail=f"Ollama error: {detail}")

    try:
        return response.json()
    except ValueError as exc:
        raise HTTPException(status_code=502, detail="Ollama returned non-JSON response") from exc


@app.get("/health")
def health(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _check_auth(authorization)
    tags = _ollama_request("/api/tags")
    return {
        "ok": True,
        "ollama_base_url": OLLAMA_BASE_URL,
        "default_model": DEFAULT_MODEL,
        "models": [item["name"] for item in tags.get("models", [])],
    }


@app.get("/models")
def models(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _check_auth(authorization)
    return _ollama_request("/v1/models")


@app.post("/ask")
def ask(request: AskRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _check_auth(authorization)
    prompt = request.question if not request.system else f"System: {request.system}\n\nUser: {request.question}"
    payload = {
        "model": request.model,
        "stream": False,
        "think": request.think,
        "keep_alive": request.keep_alive,
        "prompt": prompt,
        "options": {
            "num_ctx": request.num_ctx,
            "num_predict": request.max_tokens,
            "temperature": request.temperature,
        },
    }
    result = _ollama_request("/api/generate", body=payload, method="POST")
    return {
        "ok": True,
        "model": result.get("model", request.model),
        "answer": result.get("response", ""),
        "done_reason": result.get("done_reason"),
        "raw": result,
    }


@app.post("/chat")
def chat(request: ChatRequest, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    _check_auth(authorization)
    payload = {
        "model": request.model,
        "stream": False,
        "think": request.think,
        "keep_alive": request.keep_alive,
        "messages": [message.model_dump() for message in request.messages],
        "options": {
            "num_ctx": request.num_ctx,
            "num_predict": request.max_tokens,
            "temperature": request.temperature,
        },
    }
    result = _ollama_request("/api/chat", body=payload, method="POST")
    message = result.get("message", {})
    return {
        "ok": True,
        "model": result.get("model", request.model),
        "answer": message.get("content", ""),
        "thinking": message.get("thinking", ""),
        "done_reason": result.get("done_reason"),
        "raw": result,
    }
