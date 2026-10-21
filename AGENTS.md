<!-- LOVABLE:BEGIN -->
> [!IMPORTANT]
> This project is connected to [Lovable](https://lovable.dev). Avoid rewriting
> published git history — force pushing, or rebasing/amending/squashing commits
> that are already pushed — as it rewrites history on Lovable's side and the
> user will likely lose their project history.
>
> Commits you push to the connected branch sync back to Lovable and show up in
> the editor, so keep the branch in a working state.
<!-- LOVABLE:END -->

- Keep patient, appointment, and schedule data in Lovable Cloud with per-user RLS because medical records must persist privately.
- Use the browser Supabase client for authenticated agenda CRUD because its session enforces per-user RLS on each request.
- Per-weekday opening hours live in schedule_settings.week_days (jsonb keyed by ISO weekday 1-7); when null, Mon-Fri use the global start/end, and the validate_appointment_slot trigger mirrors the frontend slot rules because the database must reject bookings the UI would not offer.
