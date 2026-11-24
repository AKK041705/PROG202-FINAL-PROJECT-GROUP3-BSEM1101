-- =========================================
-- 1. DRIVER TYPES
-- =========================================

INSERT INTO driver_types (driver_type)
VALUES
    ('Okada'),
    ('Kekeh'),
    ('Taxi'),
    ('Private vehicle'),
    ('Poda-poda'),
    ('Bus')

ON CONFLICT (driver_type) DO NOTHING;
-- =========================================
-- 2. TRANSPORT MODES
-- =========================================

INSERT INTO transport_modes
    (mode_name, driver_type, seat_capacity, is_per_passenger, base_fare_nle, rate_per_km_nle)
VALUES
    ('Okada', 'Okada', 1, TRUE, 5.00, 1.600),
    ('Kekeh', 'Kekeh', 3, TRUE, 5.00, 1.300),
    ('Taxi (shared)', 'Taxi', 4, TRUE, 5.00, 0.800),
    ('Taxi (private hire)', 'Taxi', 4, FALSE, 20.00, 2.500),
    ('Private vehicle', 'Private vehicle', 6, FALSE, 30.00, 3.000),
    ('Poda-poda', 'Poda-poda', 12, TRUE, 3.00, 0.450),
    ('Bus', 'Bus', 30, TRUE, 5.00, 0.620)

ON CONFLICT (mode_name) DO NOTHING;


-- =========================================
-- 3. PLACES
-- =========================================

INSERT INTO places (name, area, km_from_freetown)
VALUES
    -- Freetown city
    ('Freetown', 'City', 0),
    ('PZ', 'City', 1),
    ('Bombay Street', 'City', 3),
    ('Douzak', 'City', 3),
    ('Wilberforce', 'City', 4),
    ('Imatt', 'City', 4),
    ('Model', 'City', 4),
    ('Up-gun', 'City', 5),
    ('Aberdeen', 'City', 5),
    ('Aberdeen Road Junction', 'City', 6),
    ('Wilkinson Road', 'City', 6),
    ('Congo Cross', 'City', 6),
    ('Lumley', 'City', 7),
    ('Regent', 'City', 9),
    ('Bah Junction', 'City', 9),
    ('Levumaa Beach', 'City', 9),
    ('Funkia Junction', 'City', 9),
    ('Femi Turner', 'City', 10),
    ('College Junction', 'City', 10),
    ('Ogu Farm Junction', 'City', 11),
    ('Laka Junction', 'City', 12),
    ('Hamilton Junction', 'City', 12),
    ('Mambo Junction', 'City', 14),

    -- Western Area peninsula
    ('Calaba Town', 'Peninsula', 14),
    ('Jui', 'Peninsula', 17),
    ('Yams Farm', 'Peninsula', 20),
    ('Tombo Junction', 'Peninsula', 29),
    ('Waterloo 55', 'Peninsula', 33),
    ('Kerry Town', 'Peninsula', 34),
    ('Devil Hole', 'Peninsula', 34),
    ('Fire Force', 'Peninsula', 34),
    ('Waterloo', 'Peninsula', 35),
    ('Rokel', 'Peninsula', 36),
    ('4 Mile', 'Peninsula', 38),
    ('Crossing', 'Peninsula', 40),
    ('Brama', 'Peninsula', 42),
    ('Tombo', 'Peninsula', 45),
    ('Songo', 'Peninsula', 50),
    ('Tokeh', 'Peninsula', 55),

    -- Lungi
    ('Lungi', 'Lungi', 40),

    -- North
    ('Port Loko', 'North', 90),
    ('Lunsar', 'North', 105),
    ('Kambia', 'North', 150),
    ('Makeni', 'North', 180),
    ('Kamabai', 'North', 220),
    ('Kamakwei', 'North', 250),
    ('Kabala', 'North', 290),

    -- South and East
    ('Moyamba', 'Southeast', 130),
    ('Gbangbatoke', 'Southeast', 200),
    ('Magburaka', 'Southeast', 215),
    ('Mattru/Bonthe', 'Southeast', 215),
    ('Mattru Jong', 'Southeast', 220),
    ('Rutile', 'Southeast', 230),
    ('Bo', 'Southeast', 250),
    ('Taima', 'Southeast', 270),
    ('Jendema', 'Southeast', 300),
    ('Kenema', 'Southeast', 300),
    ('Pujehun', 'Southeast', 300),
    ('Kono', 'Southeast', 330),
    ('Segbema', 'Southeast', 330),
    ('Pamalap', 'Southeast', 340),
    ('Gendema', 'Southeast', 360),
    ('Kailahun', 'Southeast', 380)

ON CONFLICT (name) DO NOTHING;        


-- =========================================
-- 4. PUBLISHED FARES
-- =========================================

WITH fare_seed (mode_name, from_place, to_place, is_flat, amount_nle, fare_type, source) AS (
    VALUES

    -- Flat pole-to-pole fares
    ('Okada', NULL, NULL, TRUE, 7.00, 'Flat pole-to-pole', 'Official price list'),
    ('Kekeh', NULL, NULL, TRUE, 7.00, 'Flat pole-to-pole', 'Official price list'),

    -- Kekeh routes
    ('Kekeh', 'Lumley', 'Wilberforce', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Wilberforce', 'Imatt', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Wilberforce', 'Regent', FALSE, 20.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Wilberforce', 'Douzak', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Douzak', 'Up-gun', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'PZ', FALSE, 30.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Douzak', FALSE, 23.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Model', FALSE, 30.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Congo Cross', FALSE, 15.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Aberdeen', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Bah Junction', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Levumaa Beach', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Funkia Junction', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Femi Turner', FALSE, 15.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'College Junction', FALSE, 15.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Ogu Farm Junction', FALSE, 18.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Laka Junction', FALSE, 18.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Hamilton Junction', FALSE, 23.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Mambo Junction', FALSE, 28.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Up-gun', 'PZ', FALSE, 15.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'PZ', 'Model', FALSE, 15.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Wilkinson Road', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Aberdeen Road Junction', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Wilberforce', 'Jui', FALSE, 35.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Lumley', 'Jui', FALSE, NULL, 'At the rider''s discretion', 'Official price list'),
    ('Kekeh', 'Regent', 'Jui', FALSE, 18.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Up-gun', 'Jui', FALSE, 33.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Up-gun', 'Calaba Town', FALSE, 20.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Calaba Town', 'Jui', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Jui', 'Tombo Junction', FALSE, 20.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Jui', 'Waterloo 55', FALSE, 25.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Tombo Junction', 'Waterloo 55', FALSE, 7.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Waterloo 55', '4 Mile', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Waterloo 55', 'Crossing', FALSE, 18.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Waterloo 55', 'Brama', FALSE, 22.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Waterloo 55', 'Songo', FALSE, 30.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Tombo Junction', 'Kerry Town', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Tombo Junction', 'Tombo', FALSE, 25.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Tombo Junction', 'Rokel', FALSE, 12.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Tombo Junction', 'Devil Hole', FALSE, 10.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Tombo Junction', 'Fire Force', FALSE, 10.00, 'Per passenger', 'Official price list'),
    ('Kekeh', 'Jui', 'Yams Farm', FALSE, 10.00, 'Per passenger', 'Official price list'),

    -- Provincial bus routes
    ('Bus', 'Freetown', 'Kailahun', FALSE, 394.90, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Kono', FALSE, 300.20, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Kabala', FALSE, 252.70, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Kenema', FALSE, 236.90, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Bo', FALSE, 205.30, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Kambia', FALSE, 189.60, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Makeni', FALSE, 189.60, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Port Loko', FALSE, 189.60, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Moyamba', FALSE, 205.30, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Mattru/Bonthe', FALSE, 221.20, 'Per passenger', 'Official price list'),
    ('Bus', 'Freetown', 'Lunsar', FALSE, 142.20, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Kailahun', FALSE, 190.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Jendema', FALSE, 292.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Segbema', FALSE, 118.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Gendema', FALSE, 332.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Bo', FALSE, 95.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Pamalap', FALSE, 411.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Mattru Jong', FALSE, 142.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Rutile', FALSE, 134.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Gbangbatoke', FALSE, 142.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Kenema', 'Makeni', FALSE, 332.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Bo', 'Jendema', FALSE, 213.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Bo', 'Taima', FALSE, 71.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Bo', 'Pujehun', FALSE, 103.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Bo', 'Magburaka', FALSE, 63.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Bo', 'Kabala', FALSE, 205.00, 'Per passenger (mini-bus)', 'Official price list'),
    ('Bus', 'Makeni', 'Kamabai', FALSE, 79.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Makeni', 'Kono', FALSE, 190.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Makeni', 'Lunsar', FALSE, 95.00, 'Per passenger', 'Official price list'),
    ('Bus', 'Makeni', 'Kamakwei', FALSE, 205.00, 'Per passenger', 'Official price list'),

    -- Poda-poda samples from news reports
    ('Poda-poda', 'Waterloo', 'Bombay Street', FALSE, 14.70, 'Per passenger', 'Published sample (news)'),
    ('Poda-poda', 'Waterloo', 'Tokeh', FALSE, 30.70, 'Per passenger', 'Published sample (news)')
)

INSERT INTO fares
    (mode_name, from_place_id, to_place_id, is_flat, amount_nle, fare_type, source)

SELECT
    fare_seed.mode_name,
    from_place.place_id,
    to_place.place_id,
    fare_seed.is_flat,
    fare_seed.amount_nle,
    fare_seed.fare_type,
    fare_seed.source

FROM fare_seed

LEFT JOIN places AS from_place
    ON from_place.name = fare_seed.from_place

LEFT JOIN places AS to_place
    ON to_place.name = fare_seed.to_place

ON CONFLICT DO NOTHING;