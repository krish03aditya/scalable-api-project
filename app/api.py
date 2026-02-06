from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "FastAPI scalable app running"}

@app.get("/health")
def health():
    return {"status": "healthy"}