import os
import glob
import hashlib

dst_dir = "/Users/markgentry/Projects/onerepstrength-main/oneREP/OneRepStrength/Resources/Audio"
files = glob.glob(os.path.join(dst_dir, "voice_*.mp3"))
files.sort()

# Group by size
by_size = {}
for f in files:
    sz = os.path.getsize(f)
    if sz not in by_size:
        by_size[sz] = []
    by_size[sz].append(f)

duplicates = []
keep = []

print(f"Scanning {len(files)} files...")

for sz, group in by_size.items():
    if len(group) == 1:
        keep.append(group[0])
        continue
        
    # If multiple files have same size, compare contents
    # We can try to compare from byte 1000 to end? To skip header?
    # Or just compare full content if we suspect EXACT duplication passed through rename?
    # My previous script used MD5 on FULL content.
    # If MD5 differed, they were kept.
    # So if they have same size but different MD5, they are "different" binary.
    # But are they different AUDIO?
    
    # Let's check if the difference is only in the first few bytes?
    # Reference file
    ref = group[0]
    keep.append(ref)
    
    with open(ref, 'rb') as f:
        ref_data = f.read()
    
    for other in group[1:]:
        with open(other, 'rb') as f:
            other_data = f.read()
            
        # Check similarity
        # If absolute difference is small? No, audio is binary.
        # If they match starting from offset 100?
        if len(ref_data) > 100 and len(other_data) > 100:
            if ref_data[1000:] == other_data[1000:]:
               print(f"Found fuzzy duplicate: {os.path.basename(other)} == {os.path.basename(ref)}")
               duplicates.append(other)
               continue
        
        # If not matched, keep
        keep.append(other)

# Remove duplicates
for d in duplicates:
    os.remove(d)

print(f"Removed {len(duplicates)} fuzzy duplicates.")

# Renumber
keep.sort() # Sort by original name to keep order stableish
# Actually, 'keep' contains paths.
# We need to re-read directory because we deleted files.
remaining = glob.glob(os.path.join(dst_dir, "voice_*.mp3"))
remaining.sort()

temp_dir = os.path.join(dst_dir, "temp_renumber")
if not os.path.exists(temp_dir):
    os.makedirs(temp_dir)

# Move to temp names first to avoid collision
for index, f in enumerate(remaining):
    # shutil.move?
    # Just rename to temp
    new_name = f"temp_{index:03d}.mp3"
    os.rename(f, os.path.join(dst_dir, new_name))

# Rename back to voice_XXX
for index in range(len(remaining)):
    src = os.path.join(dst_dir, f"temp_{index:03d}.mp3")
    dst = os.path.join(dst_dir, f"voice_{index + 1:03d}.mp3")
    os.rename(src, dst)

print(f"Renumbered {len(remaining)} files.")
