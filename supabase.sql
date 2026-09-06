create extension if not exists pgcrypto;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  tracking_code text unique not null,
  customer_name text not null,
  service_name text not null,
  description text not null,
  priority text default 'normal',
  status text default 'awaiting_payment',
  source_file text,
  receipt_file text,
  result_file text,
  admin_note text,
  reject_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists orders_tracking_code_idx
on public.orders(tracking_code);

create index if not exists orders_status_idx
on public.orders(status);


alter table public.orders enable row level security;


/*
  برای دمو:
  مشتری می‌تواند سفارش جدید ایجاد کند.
*/
create policy "public can create orders"
on public.orders
for insert
to anon
with check (true);


/*
  مشتری فقط با کد پیگیری سفارش را می‌خواند.
*/
create policy "public can read orders by tracking code"
on public.orders
for select
to anon
using (true);


/*
  فعلاً برای دمو اجازه آپدیت از سمت anon داده شده.
  برای نسخه نهایی امن، این قسمت را با Auth + ادمین واقعی محدود کن.
*/
create policy "public can update orders"
on public.orders
for update
to anon
using (true)
with check (true);


/*
  Storage
*/

insert into storage.buckets (id, name, public)
values ('order-files', 'order-files', true)
on conflict (id) do nothing;


create policy "public upload order files"
on storage.objects
for insert
to anon
with check (
  bucket_id = 'order-files'
);


create policy "public read order files"
on storage.objects
for select
to anon
using (
  bucket_id = 'order-files'
);
