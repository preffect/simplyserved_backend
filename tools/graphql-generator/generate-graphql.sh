#!/bin/bash
set -e

# Default values
SCHEMA_PATH="./schema.graphql"
OUTPUT_DIR="./src/app/graphql"
MODE=""

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Generate GraphQL documents for client-side code generation"
  echo ""
  echo "Options:"
  echo "  -i, --introspect       Run introspection on schema"
  echo "  -o, --operations       Generate operations from schema"
  echo "  --schema PATH          Path to schema file (default: ./schema.graphql)"
  echo "  --output DIR           Output directory (default: ./src/app/graphql)"
  echo "  -h, --help             Display this help message"
  echo ""
  echo "Examples:"
  echo "  $0 -i --schema ./my-schema.graphql --output ./output"
  echo "  $0 -o --schema ./my-schema.graphql --output ./output"
}

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
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Check if mode is specified
if [ -z "$MODE" ]; then
  echo "Error: Mode not specified. Use -i/--introspect or -o/--operations"
  usage
  exit 1
fi

# Ensure schema file exists
if [ ! -f "$SCHEMA_PATH" ]; then
  echo "Error: Schema file not found: $SCHEMA_PATH"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Convert to absolute paths
SCHEMA_PATH=$(realpath "$SCHEMA_PATH")
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

echo "Running GraphQL generator with mode: $MODE"
echo "Schema: $SCHEMA_PATH"
echo "Output directory: $OUTPUT_DIR"

# Run the Docker container
docker run --rm \
  -v "$SCHEMA_PATH:$SCHEMA_PATH" \
  -v "$OUTPUT_DIR:$OUTPUT_DIR" \
  graphql-generator \
  --"$MODE" \
  --schema "$SCHEMA_PATH" \
  --output "$OUTPUT_DIR"

echo "GraphQL generation completed successfully!"
