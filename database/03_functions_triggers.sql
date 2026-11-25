-- =========================================
-- 1. AUTOMATIC UPDATED_AT TRIGGER
-- =========================================

-- Function to update the timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();

    RETURN NEW;
END;
$$;


-- Trigger for profiles
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


-- Trigger for fares
CREATE TRIGGER update_fares_updated_at
BEFORE UPDATE ON fares
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


-- Trigger for transport requests
CREATE TRIGGER update_requests_updated_at
BEFORE UPDATE ON transport_requests
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


-- Trigger for reviews
CREATE TRIGGER update_reviews_updated_at
BEFORE UPDATE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


-- Trigger for fare reports
CREATE TRIGGER update_fare_reports_updated_at
BEFORE UPDATE ON fare_reports
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- =========================================
-- 2. FARE HISTORY TRIGGER
-- =========================================

-- Function to record fare changes
CREATE OR REPLACE FUNCTION record_fare_history()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    -- Only record a history entry if the fare actually changes
    IF OLD.amount_nle IS DISTINCT FROM NEW.amount_nle THEN

        INSERT INTO fare_history (
            fare_id,
            old_amount_nle,
            new_amount_nle,
            changed_by
        )
        VALUES (
            OLD.fare_id,
            OLD.amount_nle,
            NEW.amount_nle,
            auth.uid()
        );

    END IF;

    RETURN NEW;

END;
$$;


-- Trigger for fare changes
CREATE TRIGGER record_fare_history_after_update
AFTER UPDATE ON fares
FOR EACH ROW
EXECUTE FUNCTION record_fare_history();

-- =========================================
-- 3. TRANSPORT REQUEST AUDIT TRIGGER
-- =========================================

-- Function to record transport request changes
CREATE OR REPLACE FUNCTION log_transport_request_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    -- Record a new transport request
    IF TG_OP = 'INSERT' THEN

        INSERT INTO audit_logs (
            actor_id,
            action,
            table_name,
            record_id,
            details
        )
        VALUES (
            auth.uid(),
            'INSERT',
            'transport_requests',
            NEW.request_id::text,
            jsonb_build_object(
                'new_values', to_jsonb(NEW)
            )
        );

        RETURN NEW;

    -- Record updates to a transport request
    ELSIF TG_OP = 'UPDATE' THEN

        INSERT INTO audit_logs (
            actor_id,
            action,
            table_name,
            record_id,
            details
        )
        VALUES (
            auth.uid(),
            'UPDATE',
            'transport_requests',
            NEW.request_id::text,
            jsonb_build_object(
                'old_values', to_jsonb(OLD),
                'new_values', to_jsonb(NEW)
            )
        );

        RETURN NEW;

    -- Record deleted transport requests
    ELSIF TG_OP = 'DELETE' THEN

        INSERT INTO audit_logs (
            actor_id,
            action,
            table_name,
            record_id,
            details
        )
        VALUES (
            auth.uid(),
            'DELETE',
            'transport_requests',
            OLD.request_id::text,
            jsonb_build_object(
                'old_values', to_jsonb(OLD)
            )
        );

        RETURN OLD;

    END IF;

    RETURN NULL;

END;
$$;


-- Trigger for transport request changes
CREATE TRIGGER audit_transport_request_changes
AFTER INSERT OR UPDATE OR DELETE
ON transport_requests
FOR EACH ROW
EXECUTE FUNCTION log_transport_request_changes();

-- ============================================
-- 4. AUTOMATIC PROFILE CREATION TRIGGER
-- UPDATED FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_username TEXT;
    new_full_name TEXT;
    new_phone TEXT;
BEGIN

    -- Get registration details
    new_username := LOWER(BTRIM(NEW.raw_user_meta_data ->> 'username'));
    new_full_name := BTRIM(NEW.raw_user_meta_data ->> 'full_name');
    new_phone := BTRIM(NEW.raw_user_meta_data ->> 'phone');

    -- If registration details are missing,
    -- allow the Auth account to be created.
    IF new_username IS NULL OR new_username = ''
       OR new_full_name IS NULL OR new_full_name = ''
       OR new_phone IS NULL OR new_phone = '' THEN

        RETURN NEW;
    END IF;

    -- Create the user's profile
    INSERT INTO public.profiles (
        id,
        username,
        full_name,
        phone,
        role
    )
    VALUES (
        NEW.id,
        new_username,
        new_full_name,
        new_phone,
        'passenger'
    );

    RETURN NEW;
END;
$$;