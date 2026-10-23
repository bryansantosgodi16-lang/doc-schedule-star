ALTER TABLE public.patients
  ADD COLUMN address text CHECK (address IS NULL OR length(address) <= 300),
  ADD COLUMN birthplace text CHECK (birthplace IS NULL OR length(birthplace) <= 120),
  ADD COLUMN marital_status text CHECK (marital_status IS NULL OR length(marital_status) <= 40);