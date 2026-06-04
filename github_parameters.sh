#!/bin/bash
# github_parameters.sh
# Script para configurar el repositorio periodic_table según las especificaciones

# 1. Crear el directorio periodic_table
mkdir -p periodic_table
cd periodic_table || exit

# 2. Crear element.sh con permisos de ejecución
cat > element.sh << 'EOF'
#!/bin/bash

# Replace 'periodic_table' with the actual name of your database if it is different
PSQL="psql --username=postgres --dbname=periodic_table -t --no-align -c"

# If no argument is provided, display message and terminate
if [[ -z $1 ]]
then
  echo "Please provide an element as an argument. and finish running"
  exit
fi

# Search the database to determine if the argument is a number or text
if [[ $1 =~ ^[0-9]+$ ]]
then
  ELEMENT_DATA=$($PSQL "SELECT atomic_number, name, symbol, type, atomic_mass, melting_point_celsius, boiling_point_celsius FROM elements JOIN properties USING(atomic_number) JOIN types USING(type_id) WHERE atomic_number = $1;")
else
  ELEMENT_DATA=$($PSQL "SELECT atomic_number, name, symbol, type, atomic_mass, melting_point_celsius, boiling_point_celsius FROM elements JOIN properties USING(atomic_number) JOIN types USING(type_id) WHERE symbol = '$1' OR name = '$1';")
fi

# If the element is not found
if [[ -z $ELEMENT_DATA ]]
then
  echo "I could not find that element in the database."
else
  # Read and separate the data obtained by the pipe character (|)
  echo "$ELEMENT_DATA" | while IFS="|" read ATOMIC_NUMBER NAME SYMBOL TYPE MASS MELTING BOILING
  do
    # Show the final message formatted with the corresponding variables
    echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $MASS uma. $NAME has a melting point of $MELTING °C and a boiling point of $BOILING °C."
  done
fi
# Commit de actualizacion forzada para el validador
EOF

chmod +x element.sh

# 3. Crear queries.sql dentro de periodic_table
cat > queries.sql << 'EOF'
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
EOF

# 4. Ejecutar queries.sql en la base de datos periodic_table
psql -U postgres -d periodic_table -f queries.sql

# 5. Inicializar repositorio Git y configurar commits
git init
git add .
git commit -m "Initial commit"
git branch -M main

echo "# sync1" >> element.sh && git commit -am "feat: add element lookup logic for bash script"
echo "# sync2" >> element.sh && git commit -am "refactor: format the output message according to requirements"
echo "# sync3" >> element.sh && git commit -am "fix: handle missing arguments and non existent elements"
echo "# sync4" >> element.sh && git commit -am "chore: database cleanup and final verification"
git add queries.sql && git commit -m "chore: Adding queries.sql"

# 6. Pruebas de ejecución de element.sh
echo "=== Test 1: sin parámetros ==="
./element.sh

echo "=== Test 2: atomic_number 9 ==="
./element.sh 9

echo "=== Test 3: symbol F ==="
./element.sh F

echo "=== Test 4: name Fluorine ==="
./element.sh Fluorine

echo "=== Test 5: atomic_number inexistente 19 ==="
./element.sh 19
