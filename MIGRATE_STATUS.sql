-- SQL to migrate status from 'missed' to 'incomplete'
-- and update the default value for the status column

-- 1. Update existing records
UPDATE public.queue_entries 
SET status = 'incomplete' 
WHERE status = 'missed';

-- 2. Update status check constraints if any exist (none found in schema but good practice)
-- ALTER TABLE public.queue_entries DROP CONSTRAINT IF EXISTS check_status;
-- ALTER TABLE public.queue_entries ADD CONSTRAINT check_status CHECK (status IN ('waiting', 'current', 'done', 'incomplete', 'cancelled'));

-- 3. Update any views that might be using the 'missed' status
-- Note: You may need to recreate views like department_stats if they use hardcoded 'missed' strings

-- If you have a view called department_overview, update it like this:
/*
CREATE OR REPLACE VIEW public.department_overview AS
SELECT 
    d.code,
    d.name,
    COUNT(qe.id) as total_entries,
    COUNT(CASE WHEN qe.status = 'waiting' THEN 1 END) as waiting_count,
    COUNT(CASE WHEN qe.status = 'current' THEN 1 END) as current_count,
    COUNT(CASE WHEN qe.status = 'done' OR qe.status = 'completed' THEN 1 END) as completed_count,
    COUNT(CASE WHEN qe.status = 'incomplete' OR qe.status = 'missed' THEN 1 END) as incomplete_count
FROM departments d
LEFT JOIN queue_entries qe ON d.code = qe.department
GROUP BY d.code, d.name;
*/



