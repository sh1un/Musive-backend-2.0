--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_collections(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_collections() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.update_collections() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Artists; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Artists" (
    id integer NOT NULL,
    username text NOT NULL,
    display_name text NOT NULL,
    avatar jsonb,
    gender character varying
);


ALTER TABLE public."Artists" OWNER TO postgres;

--
-- Name: CollectionItems; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CollectionItems" (
    collection_id uuid NOT NULL,
    track_id integer NOT NULL
);


ALTER TABLE public."CollectionItems" OWNER TO postgres;

--
-- Name: Collections; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Collections" (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    username character varying(28) NOT NULL,
    total_tracks integer DEFAULT 0
);


ALTER TABLE public."Collections" OWNER TO postgres;

--
-- Name: Liked; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Liked" (
    id integer NOT NULL,
    track_id integer NOT NULL,
    username character varying(28) NOT NULL
);


ALTER TABLE public."Liked" OWNER TO postgres;

--
-- Name: Liked_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Liked_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Liked_id_seq" OWNER TO postgres;

--
-- Name: Liked_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Liked_id_seq" OWNED BY public."Liked".id;


--
-- Name: Tracks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Tracks" (
    id integer NOT NULL,
    user_id integer NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    moods text[] DEFAULT '{}'::text[] NOT NULL,
    genres text[] DEFAULT '{}'::text[] NOT NULL,
    movements text[] DEFAULT '{}'::text[] NOT NULL,
    keywords text NOT NULL,
    duration double precision NOT NULL,
    track_name text NOT NULL,
    download_url text NOT NULL,
    src text NOT NULL,
    cover_image jsonb
);


ALTER TABLE public."Tracks" OWNER TO postgres;

--
-- Name: Users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Users" (
    id integer NOT NULL,
    username character varying(28) NOT NULL,
    passhash character varying NOT NULL
);


ALTER TABLE public."Users" OWNER TO postgres;

--
-- Name: Users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Users_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Users_id_seq" OWNER TO postgres;

--
-- Name: Users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Users_id_seq" OWNED BY public."Users".id;


--
-- Name: Liked id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Liked" ALTER COLUMN id SET DEFAULT nextval('public."Liked_id_seq"'::regclass);


--
-- Name: Users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users" ALTER COLUMN id SET DEFAULT nextval('public."Users_id_seq"'::regclass);


--
-- Data for Name: Artists; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Artists" (id, username, display_name, avatar, gender) FROM stdin;
27953103	sunoai	Suno AI	{"url": "https://dva2ezlbhiel5.cloudfront.net/artist/Suno-AI.jpg?", "color": "#d9c0c0"}	male
24653570	lofigirl	Lofi Girl	{"url": "https://dva2ezlbhiel5.cloudfront.net/artist/Lofi_girl_logo.jpg?", "color": "#d9d9d9"}	female
\.


--
-- Data for Name: CollectionItems; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CollectionItems" (collection_id, track_id) FROM stdin;
\.


--
-- Data for Name: Collections; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Collections" (id, name, username, total_tracks) FROM stdin;
\.


--
-- Data for Name: Liked; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Liked" (id, track_id, username) FROM stdin;
\.


--
-- Data for Name: Tracks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Tracks" (id, user_id, tags, moods, genres, movements, keywords, duration, track_name, download_url, src, cover_image) FROM stdin;
99124	24653570	{}	{}	{}	{}	Good	181	Aurora	https://dva2ezlbhiel5.cloudfront.net/music/2.-aurora-ft.-Outgrown-master.mp3	https://dva2ezlbhiel5.cloudfront.net/music/2.-aurora-ft.-Outgrown-master.mp3	{"url": "https://dva2ezlbhiel5.cloudfront.net/cover/aurora-cover.png?", "color": "#6ccab3"}
421790	27953103	{}	{}	{}	{}	Good	134	Cloud Journey	https://dva2ezlbhiel5.cloudfront.net/music/Cloud+Journey.mp3	https://dva2ezlbhiel5.cloudfront.net/music/Cloud+Journey.mp3	{"url": "https://dva2ezlbhiel5.cloudfront.net/cover/cloud-journey-cover.png?", "color": "#f3913a"}
421789	27953103	{}	{}	{}	{}	Good	94	Midnight Snack	https://dva2ezlbhiel5.cloudfront.net/music/Midnight+Snack.mp3	https://dva2ezlbhiel5.cloudfront.net/music/Midnight+Snack.mp3	{"url": "https://dva2ezlbhiel5.cloudfront.net/cover/midnight-snack-cover.png?", "color": "#dc2640"}
99123	24653570	{}	{}	{}	{}	Good	139	breezehome	https://dva2ezlbhiel5.cloudfront.net/music/1.%20breezehome.mp3	https://dva2ezlbhiel5.cloudfront.net/music/1.%20breezehome.mp3	{"url": "https://dva2ezlbhiel5.cloudfront.net/artist/offline-cover.png?", "color": "#0c2640"}
\.


--
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Users" (id, username, passhash) FROM stdin;
\.


--
-- Name: Liked_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Liked_id_seq"', 1, false);


--
-- Name: Users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Users_id_seq"', 4, true);


--
-- Name: Artists Artists_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Artists"
    ADD CONSTRAINT "Artists_pkey" PRIMARY KEY (id);


--
-- Name: Artists Artists_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Artists"
    ADD CONSTRAINT "Artists_username_key" UNIQUE (username);


--
-- Name: Collections Collections_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Collections"
    ADD CONSTRAINT "Collections_pkey" PRIMARY KEY (id);


--
-- Name: Liked Liked_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Liked"
    ADD CONSTRAINT "Liked_pkey" PRIMARY KEY (id);


--
-- Name: Tracks Tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Tracks"
    ADD CONSTRAINT "Tracks_pkey" PRIMARY KEY (id);


--
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY (id);


--
-- Name: Users Users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_username_key" UNIQUE (username);


--
-- Name: CollectionItems update_collection; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_collection AFTER INSERT OR DELETE ON public."CollectionItems" FOR EACH ROW EXECUTE FUNCTION public.update_collections();


--
-- Name: CollectionItems collection_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CollectionItems"
    ADD CONSTRAINT collection_id_fk FOREIGN KEY (collection_id) REFERENCES public."Collections"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Liked track_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Liked"
    ADD CONSTRAINT track_id_fk FOREIGN KEY (track_id) REFERENCES public."Tracks"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: CollectionItems track_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CollectionItems"
    ADD CONSTRAINT track_id_fk FOREIGN KEY (track_id) REFERENCES public."Tracks"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Tracks user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Tracks"
    ADD CONSTRAINT user_id_fk FOREIGN KEY (user_id) REFERENCES public."Artists"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Liked user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Liked"
    ADD CONSTRAINT user_id_fk FOREIGN KEY (username) REFERENCES public."Users"(username) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Collections user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Collections"
    ADD CONSTRAINT user_id_fk FOREIGN KEY (username) REFERENCES public."Users"(username) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

