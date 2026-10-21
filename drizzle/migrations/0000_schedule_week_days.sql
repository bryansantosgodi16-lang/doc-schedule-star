ALTER TABLE public.schedule_settings ADD COLUMN week_days jsonb;

CREATE OR REPLACE FUNCTION public.validate_appointment_slot()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  cfg public.schedule_settings%ROWTYPE;
  day_cfg jsonb;
  dow integer;
  start_min integer;
  end_min integer;
  slot_min integer;
  last_visit date;
BEGIN
  IF NEW.status = 'cancelado' THEN RETURN NEW; END IF;
  -- Keep existing appointments valid: only re-check the slot when date or time changes
  IF TG_OP = 'UPDATE' AND NEW.date = OLD.date AND NEW.time = OLD.time THEN RETURN NEW; END IF;

  SELECT * INTO cfg FROM public.schedule_settings WHERE owner_id = NEW.owner_id;
  dow := EXTRACT(ISODOW FROM NEW.date)::integer;
  day_cfg := cfg.week_days -> dow::text;

  IF day_cfg IS NOT NULL THEN
    IF NOT COALESCE((day_cfg ->> 'open')::boolean, false) THEN
      RAISE EXCEPTION 'O consultório não atende neste dia';
    END IF;
    start_min := EXTRACT(HOUR FROM (day_cfg ->> 'start')::time)::integer * 60 + EXTRACT(MINUTE FROM (day_cfg ->> 'start')::time)::integer;
    end_min := EXTRACT(HOUR FROM (day_cfg ->> 'end')::time)::integer * 60 + EXTRACT(MINUTE FROM (day_cfg ->> 'end')::time)::integer;
  ELSE
    IF dow > 5 THEN
      RAISE EXCEPTION 'O consultório funciona somente de segunda a sexta-feira';
    END IF;
    start_min := COALESCE(EXTRACT(HOUR FROM cfg.start_time)::integer * 60 + EXTRACT(MINUTE FROM cfg.start_time)::integer, 540);
    end_min := COALESCE(EXTRACT(HOUR FROM cfg.end_time)::integer * 60 + EXTRACT(MINUTE FROM cfg.end_time)::integer, 1080);
  END IF;

  slot_min := EXTRACT(HOUR FROM NEW.time)::integer * 60 + EXTRACT(MINUTE FROM NEW.time)::integer;
  IF slot_min < start_min OR slot_min > end_min OR (slot_min - start_min) % COALESCE(cfg.interval_minutes, 15) <> 0 OR EXTRACT(SECOND FROM NEW.time) <> 0 THEN
    RAISE EXCEPTION 'Horário fora do funcionamento ou do intervalo de consultas';
  END IF;

  IF TG_OP = 'INSERT' THEN
    SELECT MAX(date) INTO last_visit FROM public.appointments
      WHERE owner_id = NEW.owner_id AND patient_id = NEW.patient_id AND status = 'concluído' AND date <= NEW.date;
    NEW.kind := CASE WHEN last_visit IS NOT NULL AND NEW.date - last_visit <= 30 THEN 'retorno' ELSE 'consulta' END;
  END IF;
  RETURN NEW;
END $function$;