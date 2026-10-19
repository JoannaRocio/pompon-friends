-- Pompon Friends: partidas en la nube con un codigo de transferencia (sin cuentas ni emails).
--
-- Como usarlo: en Supabase, abrir "SQL Editor", pegar todo este archivo y tocar "Run". Se puede volver
-- a correr sin problema (no borra datos).
--
-- Seguridad: la tabla queda cerrada (nadie la lee ni la escribe directo con la clave publica del juego).
-- Solo se puede usar a traves de dos funciones, y cada una pide el codigo de la partida:
--   pompon_upload(p_code, p_data, p_base)  -> sube o actualiza la partida; devuelve la fecha del servidor
--   pompon_download(p_code)                -> devuelve {data, updated_at} o null si el codigo no existe
-- `p_base` es la fecha de la ultima vez que ese dispositivo sincronizo: si la partida en la nube es mas
-- nueva (se siguio jugando en otro dispositivo), la subida se rechaza con 'conflict' para no pisarla.
-- Para pisarla a proposito se manda p_base = null y p_force = true.

create table if not exists public.cloud_saves (
	code text primary key,
	data jsonb not null,
	updated_at timestamptz not null default now(),
	created_at timestamptz not null default now()
);

alter table public.cloud_saves enable row level security;
revoke all on table public.cloud_saves from anon, authenticated;
-- (sin politicas: con RLS activo y sin politicas, el acceso directo queda bloqueado)

create or replace function public.pompon_upload(p_code text, p_data jsonb, p_base timestamptz default null, p_force boolean default false)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
	current_at timestamptz;
	new_at timestamptz;
begin
	-- 12 caracteres sin letras que se confunden (sin I, O, 0 ni 1)
	if p_code is null or p_code !~ '^[A-HJ-NP-Z2-9]{12}$' then
		raise exception 'codigo invalido';
	end if;
	if p_data is null or jsonb_typeof(p_data) <> 'object' then
		raise exception 'partida invalida';
	end if;
	if pg_column_size(p_data) > 1000000 then
		raise exception 'partida muy grande';
	end if;
	select updated_at into current_at from cloud_saves where code = p_code for update;
	if found and not p_force and (p_base is null or current_at > p_base) then
		raise exception 'conflict';
	end if;
	insert into cloud_saves (code, data, updated_at) values (p_code, p_data, now())
	on conflict (code) do update set data = excluded.data, updated_at = now()
	returning updated_at into new_at;
	return new_at;
end;
$$;

create or replace function public.pompon_download(p_code text)
returns jsonb
language sql
security definer
set search_path = public
as $$
	select jsonb_build_object('data', data, 'updated_at', updated_at)
	from cloud_saves
	where code = upper(p_code);
$$;

revoke all on function public.pompon_upload(text, jsonb, timestamptz, boolean) from public;
revoke all on function public.pompon_download(text) from public;
grant execute on function public.pompon_upload(text, jsonb, timestamptz, boolean) to anon;
grant execute on function public.pompon_download(text) to anon;

-- que la API vea las funciones nuevas enseguida
notify pgrst, 'reload schema';


-- ======================================================================================================
-- Amigos por codigo (solicitud que el otro acepta). Sin cuentas: cada jugador se registra con una clave
-- secreta que genera su juego (se guarda solo su hash) y recibe un codigo de amigo de 8 caracteres.
-- La "tarjeta" (snapshot) tiene el Pompon, su casa y el nombre del jugador, para mostrarlo a sus amigos.
-- No hay mensajes ni texto libre entre jugadores: solo solicitudes y avisos de visita armados por el juego.
-- ======================================================================================================

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.friend_profiles (
	code text primary key,
	secret_hash text not null,
	snapshot jsonb not null default '{}'::jsonb,
	updated_at timestamptz not null default now(),
	created_at timestamptz not null default now()
);

create table if not exists public.friend_links (
	from_code text not null references public.friend_profiles(code) on delete cascade,
	to_code text not null references public.friend_profiles(code) on delete cascade,
	status text not null default 'pending',   -- 'pending' (esperando respuesta) o 'accepted'
	created_at timestamptz not null default now(),
	primary key (from_code, to_code)
);

create table if not exists public.friend_events (
	id bigserial primary key,
	to_code text not null references public.friend_profiles(code) on delete cascade,
	from_code text not null references public.friend_profiles(code) on delete cascade,
	kind text not null,                        -- 'visit', 'pet', 'play', 'gift' o 'art' (dibujo regalado)
	seen boolean not null default false,       -- ya se mostro en el juego del amigo
	created_at timestamptz not null default now()
);
create index if not exists friend_events_to_idx on public.friend_events (to_code);
-- (agregada despues) un dibujo de pixel art regalado: 256 letras de 0-9 y a-f
alter table public.friend_events add column if not exists data text;

alter table public.friend_profiles enable row level security;
alter table public.friend_links enable row level security;
alter table public.friend_events enable row level security;
revoke all on table public.friend_profiles, public.friend_links, public.friend_events from anon, authenticated;

-- (interna) la clave secreta corresponde a ese codigo
create or replace function public.pompon_friend_auth(p_code text, p_secret text)
returns boolean
language sql
security definer
set search_path = public, extensions
as $$
	select exists (
		select 1 from friend_profiles
		where code = p_code and secret_hash = encode(extensions.digest(coalesce(p_secret, ''), 'sha256'), 'hex')
	);
$$;
revoke all on function public.pompon_friend_auth(text, text) from public, anon, authenticated;

-- Registrarse: devuelve el codigo de amigo nuevo (8 caracteres sin I, O, 0 ni 1)
create or replace function public.pompon_friend_register(p_secret text)
returns text
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
	alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
	b bytea;
	new_code text;
begin
	if p_secret is null or length(p_secret) < 24 then
		raise exception 'clave invalida';
	end if;
	for attempt in 1..10 loop
		b := extensions.gen_random_bytes(8);
		new_code := '';
		for i in 0..7 loop
			new_code := new_code || substr(alphabet, (get_byte(b, i) % 32) + 1, 1);
		end loop;
		begin
			insert into friend_profiles (code, secret_hash) values (new_code, encode(extensions.digest(p_secret, 'sha256'), 'hex'));
			return new_code;
		exception when unique_violation then
			-- ese codigo ya existe: se prueba otro
		end;
	end loop;
	raise exception 'sin codigo';
end;
$$;

-- Actualizar la tarjeta (Pompon, casa y nombre del jugador)
create or replace function public.pompon_friend_update(p_code text, p_secret text, p_snapshot jsonb)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	if p_snapshot is null or jsonb_typeof(p_snapshot) <> 'object' or pg_column_size(p_snapshot) > 65536 then
		raise exception 'tarjeta invalida';
	end if;
	update friend_profiles set snapshot = p_snapshot, updated_at = now() where code = p_code;
	return true;
end;
$$;

-- Mandar solicitud. Devuelve: 'sent', 'accepted' (el otro ya te la habia mandado), 'friends', 'self',
-- 'not_found' o 'limit' (demasiadas solicitudes hoy)
create or replace function public.pompon_friend_request(p_code text, p_secret text, p_to text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
	target text := upper(coalesce(p_to, ''));
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	if target = p_code then
		return 'self';
	end if;
	if not exists (select 1 from friend_profiles where code = target) then
		return 'not_found';
	end if;
	if exists (select 1 from friend_links where status = 'accepted'
			and ((from_code = p_code and to_code = target) or (from_code = target and to_code = p_code))) then
		return 'friends';
	end if;
	if exists (select 1 from friend_links where from_code = target and to_code = p_code and status = 'pending') then
		update friend_links set status = 'accepted' where from_code = target and to_code = p_code;
		return 'accepted';
	end if;
	if exists (select 1 from friend_links where from_code = p_code and to_code = target) then
		return 'sent';
	end if;
	if (select count(*) from friend_links where from_code = p_code and created_at > now() - interval '1 day') >= 20 then
		return 'limit';
	end if;
	insert into friend_links (from_code, to_code) values (p_code, target);
	return 'sent';
end;
$$;

-- Aceptar o rechazar una solicitud recibida
create or replace function public.pompon_friend_answer(p_code text, p_secret text, p_from text, p_accept boolean)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	if p_accept then
		update friend_links set status = 'accepted' where from_code = p_from and to_code = p_code and status = 'pending';
	else
		delete from friend_links where from_code = p_from and to_code = p_code and status = 'pending';
	end if;
	return 'ok';
end;
$$;

-- Dejar de ser amigos (o cancelar una solicitud enviada)
create or replace function public.pompon_friend_remove(p_code text, p_secret text, p_other text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	delete from friend_links where (from_code = p_code and to_code = p_other) or (from_code = p_other and to_code = p_code);
	return 'ok';
end;
$$;

-- Avisar una visita (o caricia, juego, regalo) a un amigo. Una por tipo cada 20 horas.
-- Devuelve 'ok', 'already' o 'not_friends'.
create or replace function public.pompon_friend_visit(p_code text, p_secret text, p_to text, p_kind text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	if p_kind not in ('visit', 'pet', 'play', 'gift') then
		raise exception 'tipo invalido';
	end if;
	if not exists (select 1 from friend_links where status = 'accepted'
			and ((from_code = p_code and to_code = p_to) or (from_code = p_to and to_code = p_code))) then
		return 'not_friends';
	end if;
	if exists (select 1 from friend_events where from_code = p_code and to_code = p_to and kind = p_kind
			and created_at > now() - interval '20 hours') then
		return 'already';
	end if;
	insert into friend_events (to_code, from_code, kind) values (p_to, p_code, p_kind);
	return 'ok';
end;
$$;

-- Buzon: solicitudes recibidas y enviadas, amigos (con su tarjeta) y avisos de visitas nuevos.
-- Los avisos leidos se marcan y se borran a los 2 dias (mientras tanto sirven para el limite de visitas).
create or replace function public.pompon_friend_inbox(p_code text, p_secret text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
	box jsonb;
	last_id bigint;
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	select coalesce(max(id), 0) into last_id from friend_events where to_code = p_code;
	select jsonb_build_object(
		'requests', coalesce((select jsonb_agg(jsonb_build_object('code', l.from_code, 'snapshot', p.snapshot) order by l.created_at)
			from friend_links l join friend_profiles p on p.code = l.from_code
			where l.to_code = p_code and l.status = 'pending'), '[]'::jsonb),
		-- (las enviadas sin aceptar muestran solo el codigo: la tarjeta del otro se ve recien cuando acepta)
		'sent', coalesce((select jsonb_agg(jsonb_build_object('code', l.to_code, 'snapshot', '{}'::jsonb) order by l.created_at)
			from friend_links l
			where l.from_code = p_code and l.status = 'pending'), '[]'::jsonb),
		'friends', coalesce((select jsonb_agg(jsonb_build_object('code', p.code, 'snapshot', p.snapshot) order by p.code)
			from friend_profiles p
			where p.code in (select to_code from friend_links where from_code = p_code and status = 'accepted'
				union select from_code from friend_links where to_code = p_code and status = 'accepted')), '[]'::jsonb),
		'events', coalesce((select jsonb_agg(jsonb_build_object('from', e.from_code, 'kind', e.kind, 'at', e.created_at, 'data', e.data) order by e.id)
			from friend_events e where e.to_code = p_code and e.id <= last_id and not e.seen), '[]'::jsonb)
	) into box;
	-- leidos: se marcan (no se borran enseguida) para que el limite de una visita por tipo cada 20 h siga valiendo
	update friend_events set seen = true where to_code = p_code and id <= last_id and not seen;
	delete from friend_events where to_code = p_code and created_at < now() - interval '2 days';
	return box;
end;
$$;

-- Regalar un dibujo de pixel art (16 x 16) a un amigo: le llega con el buzon como un cuadro para colgar.
-- Hasta 3 por dia al mismo amigo. Devuelve 'ok', 'limit' o 'not_friends'.
create or replace function public.pompon_friend_gift_art(p_code text, p_secret text, p_to text, p_art text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
	if not pompon_friend_auth(p_code, p_secret) then
		raise exception 'auth';
	end if;
	if p_art is null or p_art !~ '^[0-9a-f]{256}$' then
		raise exception 'dibujo invalido';
	end if;
	if not exists (select 1 from friend_links where status = 'accepted'
			and ((from_code = p_code and to_code = p_to) or (from_code = p_to and to_code = p_code))) then
		return 'not_friends';
	end if;
	if (select count(*) from friend_events where from_code = p_code and to_code = p_to and kind = 'art'
			and created_at > now() - interval '20 hours') >= 3 then
		return 'limit';
	end if;
	insert into friend_events (to_code, from_code, kind, data) values (p_to, p_code, 'art', p_art);
	return 'ok';
end;
$$;

revoke all on function public.pompon_friend_register(text) from public;
revoke all on function public.pompon_friend_update(text, text, jsonb) from public;
revoke all on function public.pompon_friend_request(text, text, text) from public;
revoke all on function public.pompon_friend_answer(text, text, text, boolean) from public;
revoke all on function public.pompon_friend_remove(text, text, text) from public;
revoke all on function public.pompon_friend_visit(text, text, text, text) from public;
revoke all on function public.pompon_friend_inbox(text, text) from public;
revoke all on function public.pompon_friend_gift_art(text, text, text, text) from public;
grant execute on function public.pompon_friend_register(text) to anon;
grant execute on function public.pompon_friend_update(text, text, jsonb) to anon;
grant execute on function public.pompon_friend_request(text, text, text) to anon;
grant execute on function public.pompon_friend_answer(text, text, text, boolean) to anon;
grant execute on function public.pompon_friend_remove(text, text, text) to anon;
grant execute on function public.pompon_friend_visit(text, text, text, text) to anon;
grant execute on function public.pompon_friend_inbox(text, text) to anon;
grant execute on function public.pompon_friend_gift_art(text, text, text, text) to anon;

notify pgrst, 'reload schema';
