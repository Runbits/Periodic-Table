BEGIN;

-- CORRECCIÓN INICIAL: Renombrar las columnas a sus nuevos nombres requeridos
ALTER TABLE properties RENAME COLUMN melting_point TO melting_point_celsius;
ALTER TABLE properties RENAME COLUMN boiling_point TO boiling_point_celsius;
ALTER TABLE properties RENAME COLUMN weight TO atomic_mass;

-- 1) Your melting_point_celsius and boiling_point_celsius columns should not accept null values
ALTER TABLE properties 
  ALTER COLUMN melting_point_celsius SET NOT NULL,
  ALTER COLUMN boiling_point_celsius SET NOT NULL;

-- 2) You should add the UNIQUE constraint to the symbol and name columns from the elements table 
-- 3) Your symbol and name columns should have the NOT NULL constraint 
ALTER TABLE elements 
  ALTER COLUMN symbol SET NOT NULL,
  ALTER COLUMN name SET NOT NULL,
  ADD CONSTRAINT elements_symbol_key UNIQUE (symbol),
  ADD CONSTRAINT elements_name_key UNIQUE (name);

-- 4) You should set the atomic_number column from the properties table as a foreign key that references the column of the same name in the elements table
ALTER TABLE properties 
  ADD CONSTRAINT properties_atomic_number_fkey 
  FOREIGN KEY (atomic_number) REFERENCES elements(atomic_number);

-- 5) You should create a types table that will store the three types of elements
-- 6) Your types table should have a type_id column that is an integer and the primary key
-- 7) Your types table should have a type column thats a VARCHAR and cannot be null. It will store the different types from the type column in the properties table
CREATE TABLE types (
  type_id SERIAL PRIMARY KEY,
  type VARCHAR(30) NOT NULL
);

-- 8) You should add three rows to your types table whose values are the three different types from the properties table.
INSERT INTO types (type) VALUES ('nonmetal'), ('metal'), ('metalloid');

-- 9) Your properties table should have a type_id foreign key column that references the type_id column from the types table. It should be an INT with the NOT NULL constraint.
ALTER TABLE properties ADD COLUMN type_id INT;

-- 10) Your properties table should have a type_id foreign key column that references the type_id column from the types table.
UPDATE properties p 
SET type_id = t.type_id 
FROM types t 
WHERE p.type = t.type;

-- It should be an INT with the NOT NULL constraint and deleted the old column.
ALTER TABLE properties 
  ALTER COLUMN type_id SET NOT NULL,
  ADD CONSTRAINT properties_type_id_fkey FOREIGN KEY (type_id) REFERENCES types(type_id),
  DROP COLUMN type;

-- 11) Capitalize the first letter of all the symbol values in the elements table.
UPDATE elements SET symbol = INITCAP(symbol);

-- 12) Remove all the trailing zeros after the decimals from each row of the atomic_mass column.
ALTER TABLE properties ALTER COLUMN atomic_mass TYPE TEXT;

UPDATE properties 
SET atomic_mass = REGEXP_REPLACE(REGEXP_REPLACE(atomic_mass, '0+$', ''), '\.$', '');

ALTER TABLE properties ALTER COLUMN atomic_mass TYPE NUMERIC USING atomic_mass::NUMERIC;

-- 13) Add the element with atomic number 9 to your database.
INSERT INTO elements (atomic_number, symbol, name) 
VALUES (9, 'F', 'Fluorine');

INSERT INTO properties (atomic_number, atomic_mass, melting_point_celsius, boiling_point_celsius, type_id) 
VALUES (9, 18.998, -220, -188.1, (SELECT type_id FROM types WHERE type = 'nonmetal'));

-- 14) You should add the element with atomic number 10 to your database.
INSERT INTO elements (atomic_number, symbol, name) 
VALUES (10, 'Ne', 'Neon');

INSERT INTO properties (atomic_number, atomic_mass, melting_point_celsius, boiling_point_celsius, type_id) 
VALUES (10, 20.18, -248.6, -246.1, (SELECT type_id FROM types WHERE type = 'nonmetal'));

-- 28) You should delete the rows of the non-existent element from your tables
DELETE FROM properties WHERE atomic_number = 1000;
DELETE FROM elements WHERE atomic_number = 1000;

COMMIT;
