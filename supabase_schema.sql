-- BrnnoPro Marketplace Schema
-- Run this in your Supabase SQL editor

-- Profiles
create table if not exists pro_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  trade text,
  city text,
  bio text,
  photo_url text,
  rating numeric(3,2),
  completed_jobs integer default 0,
  total_earned numeric(10,2) default 0,
  stripe_account_id text,
  created_at timestamptz default now()
);
alter table pro_profiles enable row level security;
create policy "Public profiles" on pro_profiles for select using (true);
create policy "Own profile" on pro_profiles for all using (auth.uid() = id);

-- Listings (rentals + for sale)
create table if not exists pro_listings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references pro_profiles(id) on delete cascade,
  title text not null,
  description text,
  listing_type text not null check (listing_type in ('rent','sell')),
  category text not null,
  price numeric(10,2) not null,
  price_period text,
  condition text,
  city text,
  photo_url text,
  status text default 'active' check (status in ('active','rented','sold','removed')),
  views integer default 0,
  created_at timestamptz default now()
);
alter table pro_listings enable row level security;
create policy "Public listings" on pro_listings for select using (true);
create policy "Owner all" on pro_listings for all using (auth.uid() = user_id);

-- Jobs (job board)
create table if not exists pro_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references pro_profiles(id) on delete cascade,
  title text not null,
  description text,
  service_type text,
  budget numeric(10,2) not null,
  city text,
  deadline text,
  tags text[],
  status text default 'open' check (status in ('open','in_progress','completed','cancelled')),
  accepted_bid_id uuid,
  created_at timestamptz default now()
);
alter table pro_jobs enable row level security;
create policy "Public jobs" on pro_jobs for select using (true);
create policy "Owner all" on pro_jobs for all using (auth.uid() = user_id);

-- Bids
create table if not exists pro_bids (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references pro_jobs(id) on delete cascade,
  user_id uuid references pro_profiles(id) on delete cascade,
  amount numeric(10,2) not null,
  note text,
  status text default 'pending' check (status in ('pending','accepted','rejected')),
  created_at timestamptz default now(),
  unique(job_id, user_id)
);
alter table pro_bids enable row level security;
create policy "Public bids" on pro_bids for select using (true);
create policy "Bidder all" on pro_bids for all using (auth.uid() = user_id);

-- Reviews
create table if not exists pro_reviews (
  id uuid primary key default gen_random_uuid(),
  reviewer_id uuid references pro_profiles(id),
  reviewee_id uuid references pro_profiles(id),
  job_id uuid references pro_jobs(id),
  rating integer check (rating between 1 and 5),
  comment text,
  created_at timestamptz default now()
);
alter table pro_reviews enable row level security;
create policy "Public reviews" on pro_reviews for select using (true);
create policy "Author review" on pro_reviews for insert with check (auth.uid() = reviewer_id);

-- Messages
create table if not exists pro_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references pro_profiles(id),
  receiver_id uuid references pro_profiles(id),
  listing_id uuid references pro_listings(id),
  content text not null,
  read boolean default false,
  created_at timestamptz default now()
);
alter table pro_messages enable row level security;
create policy "Own messages" on pro_messages for select using (auth.uid() = sender_id or auth.uid() = receiver_id);
create policy "Send message" on pro_messages for insert with check (auth.uid() = sender_id);
