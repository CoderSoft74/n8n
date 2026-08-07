import os
import re
import sys

TOKEN_PATTERN = re.compile(r'glpat-[a-zA-Z0-9_\-]+')

def replace_tokens_in_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        if 'glpat-' in content:
            new_content = TOKEN_PATTERN.sub('REPLACE_WITH_YOUR_GITLAB_TOKEN', content)
            with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
                f.write(new_content)
            return True
    except Exception as e:
        pass
    return False

def process_directory(directory):
    changed = False
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(('.json', '.md', '.OLD', '.yml', '.yaml')):
                filepath = os.path.join(root, file)
                if replace_tokens_in_file(filepath):
                    changed = True
                    print(f"Fixed: {filepath}")
    return changed

if __name__ == '__main__':
    directory = sys.argv[1] if len(sys.argv) > 1 else '.'
    process_directory(directory)
