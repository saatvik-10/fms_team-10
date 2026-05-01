
import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix print(error) -> print("[ERROR] \(error)")
    content = re.sub(r'print\(error\)', r'print("[ERROR] \(error)")', content)
    
    # Fix print("...:", var) -> print("[DEBUG] ...: \(var)")
    def complex_print_replacer(match):
        inner = match.group(1)
        if "[" in inner: # Already has a prefix
            return f'print({inner})'
        return f'print("[DEBUG] {inner}")'

    # This is tricky, let's just do manual-ish replacement for common patterns
    content = content.replace('print("Monitoring failed', 'print("[ERROR] Monitoring failed')
    
    # Remove any stray non-ascii
    content = re.sub(r'[^\x00-\x7F]+', '', content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

files_to_fix = [
    "/Users/anshulk/Desktop/FMS./fms_team-10/fms_frontend/FMS Frontend/FMS Frontend/FleetManager/Managers/FleetGeofenceManager.swift",
    "/Users/anshulk/Desktop/FMS./fms_team-10/fms_frontend/FMS Frontend/FMS Frontend/FleetManager/TripCreationAndAssignment/Views/FleetCreateTripModal.swift",
    "/Users/anshulk/Desktop/FMS./fms_team-10/fms_frontend/FMS Frontend/FMS Frontend/Driver/Dashboard/Services/GoogleDirectionsService.swift"
]

for f in files_to_fix:
    if os.path.exists(f):
        fix_file(f)
        print(f"Polished {f}")
