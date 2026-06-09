-- Drop the existing foods table to ensure schema updates (like unique constraints) are applied
drop table if exists public.foods cascade;

-- Create the foods table
create table public.foods (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  price text not null,
  category text not null,
  rating text not null,
  image text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.foods enable row level security;

-- Create policy to allow anyone to read foods
create policy "Allow public read access"
on public.foods
for select
using (true);

-- Create policy to allow anyone to insert foods (needed for initial seeding from client app)
create policy "Allow public insert access"
on public.foods
for insert
with check (true);

-- Clear existing foods to remove duplicates
truncate table public.foods;

-- Insert 10 unique food products
insert into public.foods (name, price, category, rating, image) values
('Cheese Lava Burger', '149', 'Burger', '4.5', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=500'),
('Veggie Supreme Pizza', '299', 'Pizza', '4.3', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=500'),
('Hyderabadi Chicken Biryani', '249', 'Biryani', '4.8', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=500'),
('Premium Cold Coffee', '79', 'Drinks', '4.5', 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?q=80&w=500'),
('Maharaja Mac Burger', '199', 'Burger', '4.6', 'https://images.unsplash.com/photo-1550547660-d9450f859349?q=80&w=500'),
('Spicy Paneer Pizza', '349', 'Pizza', '4.4', 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=500'),
('Loaded Cheesy Nachos', '129', 'Snacks', '4.2', 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?q=80&w=500'),
('Garlic Breadsticks', '89', 'Snacks', '4.1', 'https://images.unsplash.com/photo-1544982503-9f984c14501a?q=80&w=500'),
('Mutton Dum Biryani', '329', 'Biryani', '4.7', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=500'),
('Mango Lassi', '59', 'Drinks', '4.3', 'https://images.unsplash.com/photo-1546173152-3160becbd147?q=80&w=500')
on conflict (name) do nothing;

-- Create the users table if it does not exist
create table if not exists public.users (
  id uuid primary key, -- matches auth.users.id or can store arbitrary auth id
  full_name text not null,
  email text not null,
  phone text not null,
  gender text not null,
  interests text[] not null,
  house text,
  street text,
  area text,
  city text,
  state text,
  pincode text,
  landmark text,
  live_location text,
  latitude text,
  longitude text,
  use_for_delivery boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS) for users table
alter table public.users enable row level security;

-- Create policy to allow anyone to read users
create policy "Allow public read access"
on public.users
for select
using (true);

-- Create policy to allow anyone to insert users
create policy "Allow public insert access"
on public.users
for insert
with check (true);

-- Create policy to allow anyone to update users
create policy "Allow public update access"
on public.users
for update
using (true);

-- Create policy to allow anyone to delete users
create policy "Allow public delete access"
on public.users
for delete
using (true);

-- Create the addresses table if it does not exist
create table if not exists public.addresses (
  id text primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  house text not null,
  street text not null,
  area text not null,
  city text not null,
  state text not null,
  pincode text not null,
  landmark text,
  is_default boolean not null default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS) for addresses table
alter table public.addresses enable row level security;

-- Create policy to allow anyone to read addresses
create policy "Allow public read access"
on public.addresses
for select
using (true);

-- Create policy to allow anyone to insert addresses
create policy "Allow public insert access"
on public.addresses
for insert
with check (true);

-- Create policy to allow anyone to update addresses
create policy "Allow public update access"
on public.addresses
for update
using (true);

-- Create policy to allow anyone to delete addresses
create policy "Allow public delete access"
on public.addresses
for delete
using (true);
