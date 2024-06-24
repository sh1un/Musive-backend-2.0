-- 安裝 uuid 擴展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 創建 Users 表
CREATE TABLE public."Users" (
    id serial PRIMARY KEY,
    username varchar(28) NOT NULL UNIQUE,
    passhash varchar NOT NULL
);

-- 創建 Artists 表
CREATE TABLE public."Artists" (
    id integer UNIQUE NOT NULL, 
    username text NOT NULL UNIQUE,
    display_name text NOT NULL,
    avatar jsonb,
    gender varchar,
    PRIMARY KEY(id)
);

-- 創建 Tracks 表
CREATE TABLE public."Tracks" (
    id integer UNIQUE NOT NULL,
    user_id integer NOT NULL,
    tags text[] NOT NULL DEFAULT '{}',
    moods text[] NOT NULL DEFAULT '{}',
    genres text[] NOT NULL DEFAULT '{}',
    movements text[] NOT NULL DEFAULT '{}',
    keywords text NOT NULL,
    duration float NOT NULL,
    track_name text NOT NULL,
    download_url text NOT NULL,
    src text NOT NULL,
    cover_image jsonb,
    PRIMARY KEY(id),
    CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES public."Artists"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 創建 Liked 表
CREATE TABLE public."Liked" (
    id serial PRIMARY KEY,
    track_id integer NOT NULL,
    username varchar(28) NOT NULL,
    CONSTRAINT track_id_fk FOREIGN KEY(track_id) REFERENCES public."Tracks"(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT user_id_fk FOREIGN KEY(username) REFERENCES public."Users"(username) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 創建 Collections 表
CREATE TABLE public."Collections" (
    id uuid PRIMARY KEY NOT NULL DEFAULT uuid_generate_v4(),
    name text NOT NULL,
    username varchar(28) NOT NULL,
    total_tracks integer DEFAULT 0,
    CONSTRAINT user_id_fk FOREIGN KEY(username) REFERENCES public."Users"(username) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 創建 CollectionItems 表
CREATE TABLE public."CollectionItems" (
    collection_id uuid NOT NULL,
    track_id integer NOT NULL,
    CONSTRAINT collection_id_fk FOREIGN KEY(collection_id) REFERENCES public."Collections"(id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT track_id_fk FOREIGN KEY(track_id) REFERENCES public."Tracks"(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- 創建 update_collections 函數和觸發器
CREATE OR REPLACE FUNCTION update_collections()
  RETURNS trigger AS $$
  BEGIN
    IF TG_OP = 'INSERT' THEN
      EXECUTE 'UPDATE public."Collections" SET total_tracks = total_tracks + 1 WHERE id = $1;'
      USING NEW.collection_id;
    ELSIF TG_OP = 'DELETE' THEN
      EXECUTE 'UPDATE public."Collections" SET total_tracks = total_tracks - 1 WHERE id = $1;'
      USING OLD.collection_id;
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_collection
AFTER INSERT OR DELETE ON public."CollectionItems"
FOR EACH ROW EXECUTE PROCEDURE update_collections();

-- pg_dump -U postgres -h containers-us-west-63.railway.app -p 7771 railway >> sqlfile.sql
