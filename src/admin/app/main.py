import os
import subprocess
from typing import List, Optional

import uvicorn
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import declarative_base, sessionmaker

app = FastAPI()

# CORS 設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/demo", StaticFiles(directory="static", html=True))


@app.get("/")
async def root():
    return RedirectResponse(url="/demo/")


# 建立資料庫連線引擎
engine = create_engine("postgresql://user:password@localhost/dbname")

# 定義 SessionLocal 來管理資料庫會話
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 定義 Artists 和 Tracks 資料表的資料模型
Base = declarative_base()


class DatabaseConfig(BaseModel):
    database_url: str  # RDS Endpoint，例如 your-rds-endpoint
    username: str  # 資料庫使用者名稱，例如 postgres
    password: str  # 資料庫密碼


class Artist(Base):
    __tablename__ = "Artists"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    display_name = Column(String)
    avatar = Column(JSONB)  # Avatar 儲存為 JSONB 格式
    gender = Column(String)


class Track(Base):
    __tablename__ = "Tracks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    tags = Column(String)
    moods = Column(String)
    genres = Column(String)
    movements = Column(String)
    track_name = Column(String, index=True)
    duration = Column(Integer)
    download_url = Column(String)
    src = Column(String)
    cover_image = Column(JSONB)


# Pydantic model for request body
class ArtistCreate(BaseModel):
    id: int
    username: str
    display_name: str
    avatar: dict  # 使用 dict 來接收 JSONB 的資料
    gender: str


class InitDatabaseRequest(BaseModel):
    database_url: str  # RDS Endpoint，例如 your-rds-endpoint
    username: str  # 資料庫使用者名稱，例如 postgres
    password: str  # 資料庫密碼
    db_name: str  # 資料庫名稱，例如 musive
    port: int = 5432  # 預設 port 為 5432


# Dependency - 根據請求中的資料動態建立資料庫連線
def get_db(config: DatabaseConfig):
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# POST /artists - 新增 Artist 資料
@app.post("/artists/")
def create_artist(
    artist: ArtistCreate, config: DatabaseConfig, db: sessionmaker = Depends(get_db)
):
    db_artist = db.query(Artist).filter(Artist.username == artist.username).first()
    if db_artist:
        raise HTTPException(
            status_code=400, detail="Artist with this username already exists"
        )

    new_artist = Artist(
        id=artist.id,
        username=artist.username,
        display_name=artist.display_name,
        avatar=artist.avatar,
        gender=artist.gender,
    )
    db.add(new_artist)
    db.commit()
    db.refresh(new_artist)
    return new_artist


# 初始化 API - 執行 backup.sql
@app.post("/initialize/")
def initialize_database(request: InitDatabaseRequest):
    backup_file = os.path.join(os.getcwd(), "backup.sql")

    if not os.path.exists(backup_file):
        raise HTTPException(status_code=400, detail="Backup file not found.")

    psql_command = [
        "psql",
        f"-h{request.database_url}",
        f"-U{request.username}",
        f"-d{request.db_name}",
        f"-p{request.port}",
        "-f",
        backup_file,
    ]

    env = os.environ.copy()
    env["PGPASSWORD"] = request.password

    try:
        result = subprocess.run(psql_command, env=env, capture_output=True, text=True)
        if result.returncode != 0:
            raise HTTPException(status_code=500, detail=result.stderr)

        return {"message": "Database initialized successfully."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
