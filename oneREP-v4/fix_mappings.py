#!/usr/bin/env python3
"""
Fix mappings to use voice_XXX filenames instead of ElevenLabs names.
The bundle has voice_001.mp3 through voice_153.mp3.
We need to map transcriptions to voice_XXX based on file order.
"""

import json
import os

# The audio files in the bundle are sorted alphabetically by ElevenLabs name
# and renamed to voice_001, voice_002, etc.

# Load transcriptions
with open("/Users/markgentry/Projects/onerepstrength-main/oneREP/audio_transcriptions.json", "r") as f:
    transcriptions = json.load(f)

# Sort filenames to match the order they were renamed
sorted_filenames = sorted(transcriptions.keys())

# Create mapping: ElevenLabs name -> voice_XXX
elevenlabs_to_voice = {}
for i, filename in enumerate(sorted_filenames):
    voice_name = f"voice_{i+1:03d}"
    elevenlabs_to_voice[filename.replace(".mp3", "")] = voice_name

# Create transcription -> voice_XXX mapping (using first match)
text_to_voice = {}
for filename in sorted_filenames:
    text = transcriptions[filename]
    base = filename.replace(".mp3", "")
    voice = elevenlabs_to_voice[base]
    if text not in text_to_voice and text != "[FAILED]":
        text_to_voice[text] = voice

# Now create the event -> voice mapping
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
    
    # Phase cues
    "Get ready.": "phase_get_ready",
    "Position yourself.": "phase_position",
    "Eccentric phase. Lower slowly.": "phase_eccentric",
    "Concentric phase. Push.": "phase_concentric",
    "Final eccentric all the way down.": "phase_final_eccentric",
    "Exercise complete.": "phase_complete",
    
    # Time cues
    "Halfway there.": "time_halfway",
    "Almost there.": "time_almost",
    "Almost done.": "time_almost_done",
    "Ten seconds remaining.": "time_10_sec",
    "Five seconds remaining.": "time_5_sec",
    "30 seconds remaining.": "time_30_sec",
    "20 seconds remaining.": "time_20_sec",
    
    # Rest cues
    "Rest period.": "rest_starting",
    "Rest period starting.": "rest_starting_2",
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
    
    # Eccentric cues
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

# Build final mapping: event_key -> voice_XXX
event_to_voice = {}
for text, event_key in MAPPING_RULES.items():
    if text in text_to_voice:
        event_to_voice[event_key] = text_to_voice[text]

# Save the corrected mappings
output_path = "/Users/markgentry/Projects/onerepstrength-main/oneREP/OneRepStrength/Resources/default_sound_mappings.json"
with open(output_path, "w") as f:
    json.dump(event_to_voice, f, indent=2)

print(f"Generated {len(event_to_voice)} mappings using voice_XXX filenames")
print(f"Saved to: {output_path}")

# Print a few examples
print("\nExamples:")
for key in list(event_to_voice.keys())[:10]:
    print(f"  {key} -> {event_to_voice[key]}")
