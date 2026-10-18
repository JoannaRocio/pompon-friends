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
