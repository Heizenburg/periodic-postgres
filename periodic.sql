-- 1. Rename columns in the 'properties' table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'weight') THEN
        ALTER TABLE public.properties RENAME COLUMN weight TO atomic_mass;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'melting_point') THEN
        ALTER TABLE public.properties RENAME COLUMN melting_point TO melting_point_celsius;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'boiling_point') THEN
        ALTER TABLE public.properties RENAME COLUMN boiling_point TO boiling_point_celsius;
    END IF;
END $$;

-- 2. Add NOT NULL constraints to 'melting_point_celsius' and 'boiling_point_celsius'
ALTER TABLE public.properties
    ALTER COLUMN melting_point_celsius SET NOT NULL,
    ALTER COLUMN boiling_point_celsius SET NOT NULL;

-- 3. Add NOT NULL and UNIQUE constraints to 'symbol' and 'name' in 'elements' table
ALTER TABLE public.elements
    ALTER COLUMN symbol SET NOT NULL,
    ALTER COLUMN name SET NOT NULL;

ALTER TABLE public.elements
    ADD CONSTRAINT unique_symbol UNIQUE (symbol),
    ADD CONSTRAINT unique_name UNIQUE (name);

-- 4. Set 'atomic_number' in 'properties' as a foreign key referencing 'elements'
ALTER TABLE public.properties
    ADD CONSTRAINT fk_properties_elements FOREIGN KEY (atomic_number) REFERENCES public.elements (atomic_number);

-- 5. Create the 'types' table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.types (
    type_id SERIAL PRIMARY KEY,
    type VARCHAR(30) NOT NULL
);

-- 6. Populate the 'types' table with distinct values from 'properties.type'
INSERT INTO public.types (type)
SELECT DISTINCT type
FROM public.properties
WHERE type IS NOT NULL
  AND type NOT IN (SELECT type FROM public.types);

-- 7. Add the 'type_id' column to 'properties' and populate it
ALTER TABLE public.properties
    ADD COLUMN IF NOT EXISTS type_id INT;

-- Populate 'type_id' based on the 'type' values
UPDATE public.properties
SET type_id = (SELECT type_id FROM public.types WHERE public.types.type = public.properties.type)
WHERE type IS NOT NULL;

-- 8. Ensure 'type_id' is NOT NULL and add the foreign key constraint
ALTER TABLE public.properties
    ALTER COLUMN type_id SET NOT NULL;

ALTER TABLE public.properties
    ADD CONSTRAINT fk_properties_types FOREIGN KEY (type_id) REFERENCES public.types (type_id) ON DELETE CASCADE;

-- 9. Capitalize the first letter of 'symbol' in 'elements'
UPDATE public.elements
SET symbol = INITCAP(symbol);

-- 10. Remove trailing zeros from 'atomic_mass'
ALTER TABLE public.properties
    ALTER COLUMN atomic_mass TYPE DECIMAL;

UPDATE public.properties
SET atomic_mass = TRIM(TRAILING '0' FROM atomic_mass::TEXT)::DECIMAL;

-- 11. Insert Fluorine (atomic number 9) into the 'elements' and 'properties' tables
INSERT INTO public.elements (atomic_number, symbol, name)
VALUES (9, 'F', 'Fluorine');

INSERT INTO public.properties (atomic_number, atomic_mass, melting_point_celsius, boiling_point_celsius, type_id)
VALUES (
    9,                     -- atomic_number
    18.998,                -- atomic_mass
    -220,                  -- melting_point_celsius
    -188.1,                -- boiling_point_celsius
    (SELECT type_id FROM public.types WHERE type = 'Nonmetal') -- type_id
);

-- 12. Insert Neon (atomic number 10) into the 'elements' and 'properties' tables
INSERT INTO public.elements (atomic_number, symbol, name)
VALUES (10, 'Ne', 'Neon');

INSERT INTO public.properties (atomic_number, atomic_mass, melting_point_celsius, boiling_point_celsius, type_id)
VALUES (
    10,                    -- atomic_number
    20.18,                 -- atomic_mass
    -248.6,                -- melting_point_celsius
    -246.1,                -- boiling_point_celsius
    (SELECT type_id FROM public.types WHERE type = 'Nonmetal') -- type_id
);

-- Verify the insertions
SELECT * FROM public.elements WHERE atomic_number IN (9, 10);
SELECT * FROM public.properties WHERE atomic_number IN (9, 10);
