"""
Schema converter to make Pydantic v2 schemas compatible with Google Generative AI.
Removes $defs, validation constraints, and other unsupported fields.
"""

def convert_pydantic_schema_for_gemini(schema: dict) -> dict:
    """
    Convert Pydantic v2 schema to be compatible with deprecated google-generativeai library.

    The old library only supports basic JSON Schema:
    - type, properties, items, enum, required, description
    - Does NOT support: maximum, minimum, maxLength, minLength, maxItems, minItems, etc.
    """
    import copy
    schema = copy.deepcopy(schema)

    # Extract $defs if they exist
    defs = schema.pop('$defs', {})

    # Fields to KEEP (all others will be removed)
    allowed_fields = {
        'type', 'properties', 'items', 'enum', 'required', 'description', 'anyOf'
    }

    def inline_refs_and_clean(obj):
        if isinstance(obj, dict):
            # Handle $ref
            if '$ref' in obj:
                ref = obj['$ref']
                if ref.startswith('#/$defs/'):
                    def_name = ref.replace('#/$defs/', '')
                    if def_name in defs:
                        return inline_refs_and_clean(defs[def_name].copy())
                return obj

            # Keep only allowed fields
            cleaned = {}
            for k, v in obj.items():
                if k in allowed_fields:
                    cleaned[k] = inline_refs_and_clean(v)

            # Filter required array to only include properties that exist
            if 'required' in cleaned and 'properties' in cleaned:
                cleaned['required'] = [
                    prop for prop in cleaned['required']
                    if prop in cleaned['properties']
                ]

            return cleaned

        elif isinstance(obj, list):
            return [inline_refs_and_clean(item) for item in obj]
        else:
            return obj

    schema = inline_refs_and_clean(schema)
    return schema
