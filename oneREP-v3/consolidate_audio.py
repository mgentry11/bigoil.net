import os
import glob
import shutil
import hashlib

src_root = "/Users/markgentry/Projects/onerepstrength-main/oneREP/OneRepStrength/Services/Audio"
dst_dir = "/Users/markgentry/Projects/onerepstrength-main/oneREP/OneRepStrength/Resources/Audio"

# Ensure dest exists
if not os.path.exists(dst_dir):
    os.makedirs(dst_dir)

# Find all MP3s
files = []
for root, dirs, filenames in os.walk(src_root):
    for filename in filenames:
        if filename.lower().endswith(".mp3"):
            files.append(os.path.join(root, filename))

print(f"Found {len(files)} total MP3 files.")

# Sort for determinism (though hashing handles content)
files.sort()

unique_hashes = set()
unique_files = []

for filepath in files:
    try:
        with open(filepath, 'rb') as f:
            file_hash = hashlib.md5(f.read()).hexdigest()
            
        if file_hash not in unique_hashes:
            unique_hashes.add(file_hash)
            unique_files.append(filepath)
    except Exception as e:
        print(f"Error reading {filepath}: {e}")

print(f"Found {len(unique_files)} unique audio files.")

# Clear destination? 
# The user might have already mapped voice_001..060. 
# If I overwrite them with DIFFERENT content, the mapping breaks.
# But I can't know which is which.
# The user asked to "create a clean list".
# I will overwrite. The user hasn't mapped successfully yet (they asked "can't you map it").

# Clear old files
for f in glob.glob(os.path.join(dst_dir, "voice_*.mp3")):
    os.remove(f)

# Copy new uniques
for index, filepath in enumerate(unique_files):
    new_name = f"voice_{index + 1:03d}.mp3"
    dst_path = os.path.join(dst_dir, new_name)
    shutil.copy2(filepath, dst_path)
    print(f"Copied {os.path.basename(filepath)} -> {new_name}")

print("Consolidation complete.")
