#!/usr/bin/env python3
"""
Generate default sound mappings based on transcriptions.
Creates a Swift extension with pre-populated mappings.
"""

import json

# Load transcriptions
with open("/Users/markgentry/Projects/onerepstrength-main/oneREP/audio_transcriptions.json", "r") as f:
    transcriptions = json.load(f)

# Create mapping from transcription text to filename
# We need to map app event keys to the appropriate audio files

# Define mapping rules: transcription text -> app event key
MAPPING_RULES = {
    # Countdown numbers
    "Two.": "count_2",
    "Three.": "count_3",
    "Four.": "count_4",
    "Five.": "count_5",
    "Six.": "count_6",
    "Seven.": "count_7",
    "Eight.": "count_8",
    "Nine.": "count_9",
    "10.": "count_10",
    
    # Phase cues
    "Get ready.": "phase_get_ready",
    "Position yourself.": "phase_position",
    "Eccentric phase. Lower slowly.": "phase_eccentric",
    "Concentric phase. Push.": "phase_concentric",
    "Final eccentric all the way down.": "phase_final_eccentric",
    "Exercise complete.": "phase_complete",
    "Rest period.": "rest_starting",
    
    # Time cues
    "Halfway there.": "time_halfway",
    "Almost there.": "time_almost",
    "Almost done.": "time_almost",
    "Ten seconds remaining.": "time_10_sec",
    "Five seconds remaining.": "time_5_sec",
    "30 seconds remaining.": "time_30_sec",
    "20 seconds remaining.": "time_20_sec",
    
    # Rest cues
    "Rest period starting.": "rest_starting",
    "Take a breath.": "rest_breathe",
    "Recover.": "rest_recover",
    "Get ready for the next exercise.": "rest_get_ready",
    "30 seconds of rest remaining.": "rest_30_sec",
    "15 seconds until next exercise.": "rest_15_sec",
    "Next exercise coming up.": "rest_next_coming",
    "Rest complete.": "rest_complete",
    
    # Transition cues
    "Next exercise.": "trans_next",
    "Moving on.": "trans_moving",
    "Prepare for the next exercise.": "trans_prepare",
    
    # Workout cues
    "Workout starting.": "workout_starting",
    "Lets begin.": "workout_begin",
    "Workout complete.": "workout_complete",
    "Great session.": "workout_great_session",
    "You crushed it.": "workout_crushed",
    "See you next time.": "workout_see_you",
    
    # Eccentric cues (for random selection)
    "Lower slowly.": "ecc_lower_slowly",
    "Control the weight.": "ecc_control_weight",
    "Nice and slow.": "ecc_nice_slow",
    "Keep tension on the muscle.": "ecc_keep_tension",
    "Feel the stretch.": "ecc_feel_stretch",
    "Resist the weight.": "ecc_resist",
    "Smooth and controlled.": "ecc_smooth",
    
    # Concentric cues
    "Push now.": "con_push_now",
    "Drive up.": "con_drive_up",
    "Power through.": "con_power",
    "Squeeze at the top.": "con_squeeze",
    "Contract the muscle. Contract the muscle.": "con_contract",
    "Strong push.": "con_strong_push",
    "Keep pushing.": "con_keep_pushing",
    
    # Final negative cues
    "Final negative.": "final_negative",
    "All the way down.": "final_all_way",
    "Maximum time under tension.": "final_max_tension",
    "Fight the weight.": "final_fight",
    "Slow as possible.": "final_slow",
    "Control it.": "final_control",
    "Don't give up.": "final_dont_give_up",
    "Last push of effort.": "final_last_push",
    
    # Encouragement
    "Great work.": "enc_great_work",
    "You got this.": "enc_you_got_this",
    "Stay strong.": "enc_stay_strong",
    "Keep going.": "enc_keep_going",
    "Excellent form.": "enc_excellent_form",
    "That's it.": "enc_thats_it",
    "Perfect.": "enc_perfect",
    "Well done.": "enc_well_done",
    "Fantastic effort.": "enc_fantastic",
    "One more.": "enc_one_more",
    "Push through.": "enc_push_through",
    "You're doing great.": "enc_doing_great",
    "Strong finish.": "enc_strong_finish",
    
    # Positioning cues
    "Get into position.": "cue_get_position",
    "Find your starting weight.": "cue_starting_weight",
    "Grip the handles.": "cue_grip",
    "Set your posture.": "cue_posture",
    "Control the movement.": "cue_control",
    
    # Exercise names
    "Leg press.": "ex_leg_press",
    "Pull down.": "ex_lat_pulldown",
    "Chest press.": "ex_chest_press",
    "Overhead. Press.": "ex_shoulder_press",
    "Leg curl.": "ex_leg_curl",
    "Bicep curl.": "ex_bicep_curl",
    "Tricep extension.": "ex_tricep_extension",
    "Calf raise.": "ex_calf_raise",
    "Leg extension.": "ex_leg_extension",
    "Seated row.": "ex_seated_row",
    "Incline press.": "ex_incline_press",
    "Lateral raise.": "ex_lateral_raise",
    "Shrug.": "ex_shrug",
    "Pop crunch.": "ex_ab_crunch",
    "Back extension.": "ex_back_extension",
}

# Build the mapping from event key to filename
event_to_filename = {}

for filename, transcription in transcriptions.items():
    if transcription in MAPPING_RULES:
        event_key = MAPPING_RULES[transcription]
        # Use the filename without extension
        base_filename = filename.replace(".mp3", "")
        event_to_filename[event_key] = base_filename

# Print the mappings for Swift
print("// Auto-generated default mappings")
print("static let defaultMappings: [String: String] = [")
for key, filename in sorted(event_to_filename.items()):
    print(f'    "{key}": "{filename}",')
print("]")

print(f"\n// Total mappings: {len(event_to_filename)}")

# Also save as JSON for use in the app
output_path = "/Users/markgentry/Projects/onerepstrength-main/oneREP/default_sound_mappings.json"
with open(output_path, "w") as f:
    json.dump(event_to_filename, f, indent=2)

print(f"\nSaved to: {output_path}")
