#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const docPath = path.join(__dirname, '..', 'Docs', 'CLI', 'RenderCLI.md');
const openapiPath = path.join(__dirname, '..', 'openapi.yaml');

const doc = fs.readFileSync(docPath, 'utf8');
const openapi = fs.readFileSync(openapiPath, 'utf8');

// Extract flags from CLI markdown
const flagRegex = /--([a-zA-Z-]+)/g;
const flags = new Set();
let match;
while ((match = flagRegex.exec(doc)) !== null) {
  let name = match[1];
  if (name === 'version' || name === 'help') continue;
  // convert kebab-case to camelCase to match OpenAPI property names
  const camel = name.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
  flags.add(camel);
}

// Extract property names from RenderRequest schema in OpenAPI
const requestBlockMatch = openapi.match(/RenderRequest:[\s\S]*?RenderResponse:/);
if (!requestBlockMatch) {
  console.error('Could not find RenderRequest schema in openapi.yaml');
  process.exit(1);
}
const requestBlock = requestBlockMatch[0];
const propertyRegex = /\n\s{8}([a-zA-Z0-9]+):/g;
const properties = new Set();
while ((match = propertyRegex.exec(requestBlock)) !== null) {
  properties.add(match[1]);
}

let missingInOpenAPI = [...flags].filter(f => !properties.has(f));
let missingInDocs = [...properties].filter(p => !flags.has(p));

if (missingInOpenAPI.length || missingInDocs.length) {
  if (missingInOpenAPI.length) {
    console.error('Flags missing in openapi.yaml:', missingInOpenAPI.join(', '));
  }
  if (missingInDocs.length) {
    console.error('Properties missing in CLI docs:', missingInDocs.join(', '));
  }
  process.exit(1);
}
console.log('CLI docs and OpenAPI spec are in sync.');
