#!/usr/bin/env node

/**
 * GraphQL Schema Extractor
 * 
 * This tool extracts relevant parts of a GraphQL schema based on specified tables.
 * It creates a smaller context file for AI to generate client-side code.
 */

const fs = require('fs');
const path = require('path');

// Check if arguments are provided
if (process.argv.length < 3) {
  console.error('Usage: node schema-extractor.js <table1> <table2> ...');
  process.exit(1);
}

// Get tables from command line arguments
const tables = process.argv.slice(2);
const tableNames = tables.map(t => t.toLowerCase());
const outputFileName = `api_context_${tables.join('-')}.graphql`;

// Read the schema file
const schemaPath = path.join(__dirname, 'post-graphile/schema/schema.graphql');
let schemaContent;

try {
  schemaContent = fs.readFileSync(schemaPath, 'utf8');
} catch (error) {
  console.error(`Error reading schema file: ${error.message}`);
  process.exit(1);
}

// Parse the schema content
const lines = schemaContent.split('\n');
let currentType = null;
let currentDepth = 0;
let captureContent = false;
let extractedContent = [];
let rootTypes = new Set();

// Add standard GraphQL scalar types and interfaces that should always be included
extractedContent.push('# Standard GraphQL types and interfaces');
extractedContent.push('scalar Datetime');
extractedContent.push('scalar UUID');
extractedContent.push('interface Node { nodeId: ID! }');
extractedContent.push('');

// Helper function to check if a type is related to our tables
function isRelevantType(typeName) {
  if (!typeName) return false;
  
  // Always include Query and Mutation types
  if (typeName === 'Query' || typeName === 'Mutation') {
    rootTypes.add(typeName);
    return true;
  }
  
  // Check if the type is related to any of our tables
  for (const table of tableNames) {
    const singularTable = table.endsWith('s') ? table.slice(0, -1) : table;
    const capitalizedTable = singularTable.charAt(0).toUpperCase() + singularTable.slice(1);
    
    if (typeName.includes(capitalizedTable)) {
      return true;
    }
  }
  
  return false;
}

// Process the schema line by line
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  
  // Check for type definitions
  if (line.match(/^(type|input|enum|interface|scalar|union)\s+(\w+)/)) {
    const match = line.match(/^(type|input|enum|interface|scalar|union)\s+(\w+)/);
    const typeName = match[2];
    
    // If we were capturing a previous type, add a blank line for separation
    if (captureContent) {
      extractedContent.push('');
    }
    
    // Check if this type is relevant to our tables
    if (isRelevantType(typeName)) {
      currentType = typeName;
      currentDepth = 0;
      captureContent = true;
      extractedContent.push(line);
    } else {
      currentType = null;
      captureContent = false;
    }
  } 
  // If we're capturing a type, track the depth with braces
  else if (captureContent) {
    // Track depth with braces
    currentDepth += (line.match(/{/g) || []).length;
    currentDepth -= (line.match(/}/g) || []).length;
    
    // Add the line to our extracted content
    extractedContent.push(line);
    
    // If we've reached the end of the type definition, stop capturing
    if (currentDepth === 0 && line.trim() === '}') {
      captureContent = false;
    }
  }
}

// For Query and Mutation types, filter out fields that aren't related to our tables
let finalContent = [];
let processingRootType = false;
let rootTypeContent = [];
let currentRootType = null;

for (let i = 0; i < extractedContent.length; i++) {
  const line = extractedContent[i];
  
  // Check if we're starting a root type
  if (line.match(/^type (Query|Mutation)/)) {
    processingRootType = true;
    currentRootType = line.includes('Query') ? 'Query' : 'Mutation';
    rootTypeContent = [line];
    continue;
  }
  
  if (processingRootType) {
    // Add the line to the current root type content
    rootTypeContent.push(line);
    
    // Check if we've reached the end of the root type
    if (line.trim() === '}') {
      processingRootType = false;
      
      // Filter the root type content to only include fields related to our tables
      let filteredRootContent = [rootTypeContent[0]]; // Include the type declaration
      
      for (let j = 1; j < rootTypeContent.length - 1; j++) { // Skip first and last lines (type declaration and closing brace)
        const fieldLine = rootTypeContent[j];
        let includeField = false;
        
        for (const table of tableNames) {
          const singularTable = table.endsWith('s') ? table.slice(0, -1) : table;
          const lowerTable = singularTable.toLowerCase();
          const fieldLower = fieldLine.toLowerCase();
          
          if (fieldLower.includes(lowerTable) || 
              (currentRootType === 'Query' && fieldLine.includes('node')) || 
              (currentRootType === 'Query' && fieldLine.includes('query'))) {
            includeField = true;
            break;
          }
        }
        
        if (includeField) {
          filteredRootContent.push(fieldLine);
        }
      }
      
      // Add the closing brace
      filteredRootContent.push(rootTypeContent[rootTypeContent.length - 1]);
      
      // Add the filtered root type content to the final content
      finalContent = finalContent.concat(filteredRootContent);
      finalContent.push(''); // Add a blank line for separation
    }
  } else {
    // For non-root types, add the line directly to the final content
    finalContent.push(line);
  }
}

// Write the extracted content to the output file
try {
  fs.writeFileSync(outputFileName, finalContent.join('\n'));
  console.log(`Successfully created ${outputFileName}`);
} catch (error) {
  console.error(`Error writing output file: ${error.message}`);
  process.exit(1);
}
