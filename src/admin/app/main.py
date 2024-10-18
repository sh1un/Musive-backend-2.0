import os
import subprocess
from typing import List, Optional

import psycopg2
import uvicorn
from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
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


# 定義資料模型
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
    tags = Column(ARRAY(String))  # 使用 ARRAY 來儲存文字陣列
    moods = Column(ARRAY(String))
    genres = Column(ARRAY(String))
    movements = Column(ARRAY(String))
    keywords = Column(String)
    duration = Column(Integer)
    track_name = Column(String, index=True)
    download_url = Column(String)
    src = Column(String)
    cover_image = Column(JSONB)  # 使用 JSONB 儲存封面資料


# Pydantic model for creating a new artist
class ArtistCreate(BaseModel):
    id: int
    username: str
    display_name: str
    avatar: dict  # 使用 dict 來接收 JSONB 的資料
    gender: str


# Pydantic model for updating artist avatar
class ArtistUpdate(BaseModel):
    avatar: dict  # 更新 avatar 需使用 dict 來接收 JSONB 的資料


# Pydantic model for creating a new track
class TrackCreate(BaseModel):
    id: int
    user_id: int
    track_name: str
    duration: int
    download_url: str
    src: str
    cover_image: dict  # 使用 dict 來接收 JSONB 的資料
    tags: Optional[List[str]] = []  # Add tags field
    moods: Optional[List[str]] = []  # Add moods field
    genres: Optional[List[str]] = []  # Add genres field
    movements: Optional[List[str]] = []  # Add movements field


# Pydantic model for updating track info
class TrackUpdate(BaseModel):
    download_url: str
    src: str
    cover_image: dict  # 使用 dict 來接收 JSONB 的資料


class InitDatabaseRequest(BaseModel):
    database_url: str  # RDS Endpoint，例如 your-rds-endpoint
    username: str  # 資料庫使用者名稱，例如 postgres
    password: str  # 資料庫密碼
    db_name: str  # 資料庫名稱，例如 musive
    port: int = 5432  # 預設 port 為 5432


# Dependency - 根據請求中的資料動態建立資料庫連線
def get_db(config: DatabaseConfig):
    db_url = f"postgresql://{config.username}:{config.password}@{config.database_url}"
    try:
        engine = create_engine(db_url)
        print(f"Connecting to {db_url}")  # 添加 log
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        Base.metadata.create_all(bind=engine)

        db = SessionLocal()
        yield db
    except Exception as e:
        print(f"Error in get_db: {e}")  # 添加更多錯誤處理 log
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# POST /artists - 新增 Artist 資料
@app.post("/artists/")
def create_artist(
    artist: ArtistCreate, config: DatabaseConfig, db: sessionmaker = Depends(get_db)
):
    try:
        # Log: 檢查連線到的資料庫 URL
        print(f"Connecting to database: {config.database_url}")

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
        db.commit()  # 確保 commit 正確執行

        # 確保刷新資料庫後返回最新的 new_artist
        db.refresh(new_artist)

        # Log: 確保新的 artist 已被創建並刷新
        print(f"Artist created: {new_artist}")

        return {
            "id": new_artist.id,
            "username": new_artist.username,
            "display_name": new_artist.display_name,
            "avatar": new_artist.avatar,
            "gender": new_artist.gender,
        }  # 明確回傳新的 artist 資料

    except Exception as e:
        # Log: 錯誤訊息
        print(f"Error creating artist: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error")


# PUT /artists/{username} - 更新 Artist 的 avatar 資料
@app.put("/artists/{username}")
def update_artist(
    username: str,
    artist_update: ArtistUpdate,
    config: DatabaseConfig,  # 從 client 傳入 dbURL 和 password
    db=Depends(get_db),  # 使用 get_db 動態連接到資料庫
):
    db_artist = db.query(Artist).filter(Artist.username == username).first()

    if not db_artist:
        raise HTTPException(status_code=404, detail="Artist not found")

    # 更新 artist 的 avatar
    db_artist.avatar = artist_update.avatar
    db.commit()
    db.refresh(db_artist)

    return {"message": "Artist updated successfully", "artist": db_artist}


# PUT /tracks/{track_name} - 更新 Track 的資料
@app.put("/tracks/{track_name}")
def update_track(
    track_name: str,
    track_update: TrackUpdate,
    config: DatabaseConfig,  # 從 client 傳入 dbURL 和 password
    db=Depends(get_db),  # 使用 get_db 動態連接到資料庫
):
    db_track = db.query(Track).filter(Track.track_name == track_name).first()

    if not db_track:
        raise HTTPException(status_code=404, detail="Track not found")

    # 更新 track 的資料
    db_track.download_url = track_update.download_url
    db_track.src = track_update.src
    db_track.cover_image = track_update.cover_image
    db.commit()
    db.refresh(db_track)

    return {"message": "Track updated successfully", "track": db_track}


# POST /tracks - 新增 Track 資料
@app.post("/tracks/")
def create_track(
    track: TrackCreate, config: DatabaseConfig, db: sessionmaker = Depends(get_db)
):
    try:
        # Log: 檢查連線到的資料庫 URL
        print(f"Connecting to database: {config.database_url}")

        # 確認 Track 是否已經存在
        db_track = db.query(Track).filter(Track.track_name == track.track_name).first()
        if db_track:
            raise HTTPException(
                status_code=400, detail="Track with this name already exists"
            )

        # 建立新的 Track
        new_track = Track(
            id=track.id,
            user_id=track.user_id,
            track_name=track.track_name,
            duration=track.duration,
            tags=track.tags if track.tags else [],  # 使用傳入的 tags 或空陣列
            moods=track.moods if track.moods else [],  # 使用傳入的 moods 或空陣列
            genres=track.genres if track.genres else [],  # 使用傳入的 genres 或空陣列
            movements=(
                track.movements if track.movements else []
            ),  # 使用傳入的 movements 或空陣列
            keywords=track.track_name,
            download_url=track.download_url,
            src=track.src,
            cover_image=track.cover_image,
        )

        # 插入並提交新的 Track 資料
        db.add(new_track)
        db.commit()
        db.refresh(new_track)  # 確保返回最新的資料

        # Log: 確認新的 track 被創建
        print(f"Track created: {new_track}")

        return {
            "id": new_track.id,
            "user_id": new_track.user_id,
            "track_name": new_track.track_name,
            "duration": new_track.duration,
            "tags": new_track.tags,
            "moods": new_track.moods,
            "genres": new_track.genres,
            "movements": new_track.movements,
            "download_url": new_track.download_url,
            "src": new_track.src,
            "cover_image": new_track.cover_image,
        }  # 明確回傳新的 track 資料

    except Exception as e:
        # Log: 錯誤訊息
        print(f"Error creating track: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error")


# 初始化 API - 執行 backup.sql
@app.post("/initialize/")
def initialize_database(request: InitDatabaseRequest):
    try:
        # 使用 psycopg2 連接到資料庫
        connection = psycopg2.connect(
            host=request.database_url,
            user=request.username,
            password=request.password,
            dbname=request.db_name,
            port=request.port,
        )
        cursor = connection.cursor()

        # 打開 backup.sql 檔案並執行其中的 SQL 指令
        with open("backup.sql", "r") as backup_file:
            sql_commands = backup_file.read()

        cursor.execute(sql_commands)
        connection.commit()

        return {"message": "Database initialized successfully."}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cursor.close()
        connection.close()


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
