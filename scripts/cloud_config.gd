class_name CloudConfig
extends RefCounted
## Datos del proyecto de Supabase para guardar partidas en la nube (ver server/supabase.sql).
## Se copian de Supabase > Project Settings > API: la "Project URL" y la clave publica ("anon" o
## "publishable"). Esa clave es publica a proposito: la base solo deja usar las dos funciones del juego.
## Vacios = la nube esta apagada (el boton del menu dice que llega pronto).

const SUPABASE_URL := "https://zbdtwbrkcqljlslwxjeu.supabase.co"
const SUPABASE_KEY := "sb_publishable_JIfSbHyTGOBQ2eW0GyRaUQ_WwVkCrrF"   # clave publica (publishable)
