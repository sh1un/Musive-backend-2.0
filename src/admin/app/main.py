import os
from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import JSONB, Column, Integer, String, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

app = FastAPI()

# 定義 Artists 資料表的資料模型
Base = declarative_base()


class Artist(Base):
    __tablename__ = "Artists"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    display_name = Column(String)
    avatar = Column(JSONB)  # Avatar 儲存為 JSONB 格式
    gender = Column(String)


# Pydantic model for request body
class ArtistCreate(BaseModel):
    id: int
    username: str
    display_name: str
    avatar: dict  # 使用 dict 來接收 JSONB 的資料
    gender: str


# 請求中帶入 database_url 和 password
class DatabaseConfig(BaseModel):
    database_url: str
    username: str
    password: str


# Dependency - 根據請求中的資料動態建立資料庫連線
def get_db(config: DatabaseConfig):
    # 建立動態的資料庫 URL，這裡用 username 和 password 組合
    db_url = f"postgresql://{config.username}:{config.password}@{config.database_url}"
    engine = create_engine(db_url)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# POST /artists - 新增 Artist 資料
@app.post("/artists/")
def create_artist(
    artist: ArtistCreate, config: DatabaseConfig, db: SessionLocal = Depends(get_db)
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


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
