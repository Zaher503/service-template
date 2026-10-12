from fastapi import FastAPI

app = FastAPI(title="my-service")


@app.get("/healthz")
def healthz():
    return {"ok": True}
