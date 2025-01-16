#!/bin/bash

# Check if argument is provided
if [ -z "$1" ]; then
  echo "Please provide an element as an argument."
  exit 0
fi

# Database connection details
DB_NAME="periodic_table"
DB_USER="freecodecamp"

# Query database based on input
RESULT=$(psql -U "$DB_USER" -d "$DB_NAME" -t --no-align -c "
  SELECT elements.atomic_number, elements.name, elements.symbol, types.type, 
         properties.atomic_mass, properties.melting_point_celsius, properties.boiling_point_celsius
  FROM elements
  JOIN properties ON elements.atomic_number = properties.atomic_number
  JOIN types ON properties.type_id = types.type_id
  WHERE elements.atomic_number::TEXT = '$1'
     OR elements.symbol ILIKE '$1'
     OR elements.name ILIKE '$1';")

# Check if query returned a result
if [ -z "$RESULT" ]; then
  echo "I could not find that element in the database."
  exit 0
fi

# Parse query result
IFS='|' read -r ATOMIC_NUMBER NAME SYMBOL TYPE MASS MELTING BOILING <<< "$RESULT"

# Display information
echo "The element with atomic number $ATOMIC_NUMBER is $NAME ($SYMBOL). It's a $TYPE, with a mass of $MASS amu. $NAME has a melting point of $MELTING celsius and a boiling point of $BOILING celsius." 
