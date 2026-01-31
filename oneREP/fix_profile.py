import sys
import os

path = "/Users/markgentry/Projects/onerepstrength-main/oneREP/OneRepStrength.xcodeproj/project.pbxproj"

with open(path, 'r') as f:
    lines = f.readlines()

# Check if Profile.swift is already there
has_profile = any("Profile.swift" in l for l in lines)
if has_profile:
    print("Profile.swift already present")
    sys.exit(0)

new_lines = []
for line in lines:
    new_lines.append(line)
    
    # Profile Ref (add after WorkoutTemplate.swift ref)
    if "/* WorkoutTemplate.swift */ = {isa = PBXFileReference" in line:
        new_lines.append('\t\tE1EBE1A355E401CE00000005 /* Profile.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Profile.swift; sourceTree = "<group>"; };\n')

    # Profile Build (add after WorkoutTemplate.swift build)
    if "/* WorkoutTemplate.swift in Sources */ = {isa = PBXBuildFile" in line:
        new_lines.append('\t\tE1EBE1A355E401CE00000006 /* Profile.swift in Sources */ = {isa = PBXBuildFile; fileRef = E1EBE1A355E401CE00000005 /* Profile.swift */; };\n')

    # Profile Group (add after WorkoutTemplate.swift in children list)
    if line.strip().endswith("/* WorkoutTemplate.swift */,") and "isa = PBXFileReference" not in line:
        indent = line[:line.find(line.strip())]
        new_lines.append(indent + 'E1EBE1A355E401CE00000005 /* Profile.swift */,\n')

    # Profile Sources (add after WorkoutTemplate.swift in Sources in files list)
    if line.strip().endswith("/* WorkoutTemplate.swift in Sources */,") and "isa = PBXBuildFile" not in line:
        indent = line[:line.find(line.strip())]
        new_lines.append(indent + 'E1EBE1A355E401CE00000006 /* Profile.swift in Sources */,\n')

with open(path, 'w') as f:
    f.writelines(new_lines)

print("Profile.swift added successfully")
