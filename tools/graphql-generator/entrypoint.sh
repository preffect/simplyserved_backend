#!/bin/sh
set -e

# Default values
SCHEMA_PATH="./schema.graphql"
OUTPUT_DIR="./src/app/graphql"

# Parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -i|--introspect)
      MODE="introspect"
      shift
      ;;
    -o|--operations)
      MODE="operations"
      shift
      ;;
    --schema)
      SCHEMA_PATH="$2"
      shift 2
      ;;
    --output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Export variables for codegen.yml
export SCHEMA_PATH
export OUTPUT_DIR

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

if [ "$MODE" = "introspect" ]; then
  echo "Running introspection on schema: $SCHEMA_PATH"
  npx graphql-codegen introspect-schema --schema "$SCHEMA_PATH" --output "${OUTPUT_DIR}/schema.json"
elif [ "$MODE" = "operations" ]; then
  echo "Generating operations from schema: $SCHEMA_PATH"
  npx graphql-codegen --config codegen.yml
else
  echo "Error: Mode not specified. Use -i/--introspect or -o/--operations"
  exit 1
fi

echo "GraphQL generation completed successfully!"
