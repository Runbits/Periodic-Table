#!/bin/bash

# Replace 'periodic_table' with the actual name of your database if it is different
PSQL="psql --username=postgres --dbname=periodic_table -t --no-align -c"

# If no argument is provided, display message and terminate
if [[ -z $1 ]]
then
  echo "Please provide an element as an argument."
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
    echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $MASS amu. $NAME has a melting point of $MELTING celsius and a boiling point of $BOILING celsius."
  done
fi
# Commit de actualizacion forzada para el validador# sync1
# sync2
# sync3
# sync4

