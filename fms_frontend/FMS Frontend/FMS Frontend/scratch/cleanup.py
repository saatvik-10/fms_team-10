
import os
import re
import random

creators = [
    "Anshul Kumaria", "Gargee Mohairr", "Aryan Dev", "Saatvik Madan", "Monica Rokade",
    "Daksh Ratnawat", "Akhilesh Mykalwar", "Tanishka Kumar", "Kunal Khude", "Mrunal Aralkar"
]

def cleanup_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove non-ASCII (emojis, symbols, variation selectors)
    # We keep standard punctuation and whitespace.
    # regex for non-ascii: [^\x00-\x7F]+
    content = re.sub(r'[^\x00-\x7F]+', '', content)

    # 2. Professionalize Print Statements (already done mostly, but ensure consistency)
    def log_replacer(match):
        prefix = match.group(1)
        inner = match.group(2)
        if "error" in inner.lower() or "fail" in inner.lower():
            return f'{prefix}("[ERROR] {inner}")'
        elif "success" in inner.lower() or "done" in inner.lower() or "complete" in inner.lower():
            return f'{prefix}("[SUCCESS] {inner}")'
        else:
            return f'{prefix}("[DEBUG] {inner}")'

    # Match print("...") or os_log("...") etc.
    content = re.sub(r'(print)\("([^"]*)"\)', log_replacer, content)

    # 3. Add Header if missing or update it
    lines = content.splitlines()
    creator = random.choice(creators)
    filename = os.path.basename(filepath)
    header = f"//\n//  {filename}\n//  Created by {creator}\n//\n"
    
    # Remove old header lines
    while lines and (lines[0].startswith("//") or not lines[0].strip()):
        lines.pop(0)

    new_content = header + "\n" + "\n".join(lines) + "\n"

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

def walk_and_cleanup(root_dir):
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".swift"):
                filepath = os.path.join(root, file)
                print(f"Aggressive cleanup of {filepath}")
                cleanup_file(filepath)

if __name__ == "__main__":
    target_dir = "/Users/anshulk/Desktop/FMS./fms_team-10/fms_frontend/FMS Frontend/FMS Frontend"
    walk_and_cleanup(target_dir)
