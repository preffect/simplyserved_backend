#!/usr/bin/env python3

import argparse
import re
import os
import sys
from typing import List, Set, Dict, Any

def remove_comments(content: str) -> str:
    """
    Remove all comments from GraphQL schema.
    - Single line comments starting with #
    - Multi-line comments between triple quotes
    """
    # Remove multi-line comments ("""...""")
    content = re.sub(r'""".*?"""', '', content, flags=re.DOTALL)
    
    # Remove single line comments (# ...)
    content = re.sub(r'#.*?$', '', content, flags=re.MULTILINE)
    
    # Clean up any extra newlines that might have been created
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    return content

def extract_type_names(content: str) -> Set[str]:
    """Extract all type names from the schema"""
    type_patterns = [
        r'type\s+(\w+)',
        r'input\s+(\w+)',
        r'enum\s+(\w+)',
        r'interface\s+(\w+)',
        r'scalar\s+(\w+)'
    ]
    
    type_names = set()
    for pattern in type_patterns:
        matches = re.finditer(pattern, content)
        for match in matches:
            type_names.add(match.group(1))
    
    return type_names

def is_relevant_to_tables(type_name: str, tables: List[str]) -> bool:
    """Check if a type is relevant to the specified tables"""
    # Always include Query and Mutation types
    if type_name in ['Query', 'Mutation']:
        return True
    
    # Check if the type is related to any of the tables
    for table in tables:
        table_singular = table[:-1] if table.endswith('s') else table
        patterns = [
            f"^{table}",
            f"^{table_singular}",
            f"{table}$",
            f"{table_singular}$"
        ]
        
        for pattern in patterns:
            if re.search(pattern, type_name, re.IGNORECASE):
                return True
    
    return False

def extract_relevant_types(content: str, tables: List[str]) -> Dict[str, Any]:
    """Extract types relevant to the specified tables"""
    all_type_names = extract_type_names(content)
    relevant_type_names = set()
    
    # First pass: find directly relevant types
    for type_name in all_type_names:
        if is_relevant_to_tables(type_name, tables):
            relevant_type_names.add(type_name)
    
    # Extract all type definitions
    type_definitions = {}
    for type_kind in ['type', 'input', 'enum', 'interface', 'scalar']:
        pattern = rf'{type_kind}\s+(\w+)(?:\s+implements\s+\w+)?\s*{{(.*?)}}|{type_kind}\s+(\w+)(?:\s+implements\s+\w+)?\s*'
        matches = re.finditer(pattern, content, re.DOTALL)
        
        for match in matches:
            name = match.group(1) or match.group(3)
            if name in relevant_type_names:
                definition = match.group(0)
                type_definitions[name] = {
                    'kind': type_kind,
                    'definition': definition
                }
    
    return type_definitions

def simplify_interactions(type_definitions: Dict[str, Any]) -> Dict[str, Any]:
    """Keep only CRUD mutations and queries and associated types"""
    crud_patterns = [
        r'create', r'update', r'delete', r'get', r'list', r'by'
    ]
    
    simplified_definitions = {}
    for name, info in type_definitions.items():
        # Always keep Query and Mutation types
        if name in ['Query', 'Mutation']:
            # Filter their content to only include CRUD operations
            definition = info['definition']
            for pattern in crud_patterns:
                if re.search(pattern, definition, re.IGNORECASE):
                    simplified_definitions[name] = info
                    break
        # For other types, check if they're used in CRUD operations
        elif any(pattern in name.lower() for pattern in crud_patterns):
            simplified_definitions[name] = info
    
    return simplified_definitions

def remove_object_definitions(type_definitions: Dict[str, Any]) -> Dict[str, Any]:
    """
    Keep only ENUM definitions complete. For other types, just show names without definitions.
    """
    simplified_definitions = {}
    for name, info in type_definitions.items():
        if info['kind'] == 'enum':
            # Keep enum definitions as they are
            simplified_definitions[name] = info
        else:
            # For other types, just keep the name and kind
            simplified_definitions[name] = {
                'kind': info['kind'],
                'definition': f"{info['kind']} {name}"
            }
    
    return simplified_definitions

def process_schema(content: str, args) -> str:
    """Process the schema according to the provided arguments"""
    processed_content = content
    
    # First pass: remove comments if requested
    if args.remove_comments:
        processed_content = remove_comments(processed_content)
    
    # Second pass: extract relevant types if tables are specified
    if args.tables:
        tables = [table.strip() for table in args.tables.split(',')]
        type_definitions = extract_relevant_types(processed_content, tables)
        
        # Third pass: apply additional filters
        if args.simple_interactions:
            type_definitions = simplify_interactions(type_definitions)
        
        if args.no_objects:
            type_definitions = remove_object_definitions(type_definitions)
        
        # Reconstruct the schema with only the relevant types
        processed_content = '\n\n'.join(info['definition'] for info in type_definitions.values())
    
    return processed_content

def main():
    parser = argparse.ArgumentParser(description='Process GraphQL schema file')
    parser.add_argument('--schema-file', required=True, help='Path to the GraphQL schema file')
    parser.add_argument('--remove-comments', action='store_true', help='Remove all comments from the schema')
    parser.add_argument('--tables', help='Comma-separated list of tables to include')
    parser.add_argument('--simple-interactions', action='store_true', help='Only keep CRUD mutations and queries')
    parser.add_argument('--no-objects', action='store_true', help='Only keep ENUM definitions complete')
    
    args = parser.parse_args()
    
    try:
        with open(args.schema_file, 'r') as f:
            content = f.read()
        
        processed_content = process_schema(content, args)
        
        # Generate output filename
        output_filename = "api_context"
        if args.tables:
            tables_suffix = args.tables.replace(',', '-')
            output_filename += f"_{tables_suffix}"
        output_filename += ".graphql"
        
        with open(output_filename, 'w') as f:
            f.write(processed_content)
        
        print(f"Processed schema saved to {output_filename}")
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
