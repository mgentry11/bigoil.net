#!/usr/bin/env python3
"""
Transcribe all audio files using AssemblyAI API.
This will help us know what each audio file says for mapping.
"""

import os
import json
import time
import requests

API_KEY = "c18c7750353b446c9734078f11f37829"
AUDIO_DIR = "/tmp/audio_rep"
OUTPUT_FILE = "/Users/markgentry/Projects/onerepstrength-main/oneREP/audio_transcriptions.json"

headers = {
    "authorization": API_KEY,
    "content-type": "application/json"
}

def upload_file(file_path):
    """Upload a file to AssemblyAI and return the upload URL."""
    upload_url = "https://api.assemblyai.com/v2/upload"
    
    with open(file_path, 'rb') as f:
        response = requests.post(
            upload_url,
            headers={"authorization": API_KEY},
            data=f
        )
    
    if response.status_code == 200:
        return response.json()['upload_url']
    else:
        print(f"Upload failed for {file_path}: {response.text}")
        return None

def transcribe(audio_url):
    """Submit transcription job and wait for result."""
    transcript_url = "https://api.assemblyai.com/v2/transcript"
    
    # Submit for transcription
    response = requests.post(
        transcript_url,
        headers=headers,
        json={"audio_url": audio_url}
    )
    
    if response.status_code != 200:
        print(f"Transcription submit failed: {response.text}")
        return None
    
    transcript_id = response.json()['id']
    
    # Poll for completion
    polling_url = f"{transcript_url}/{transcript_id}"
    while True:
        response = requests.get(polling_url, headers=headers)
        status = response.json()['status']
        
        if status == 'completed':
            return response.json()['text']
        elif status == 'error':
            print(f"Transcription error: {response.json()['error']}")
            return None
        
        time.sleep(1)  # Wait 1 second before polling again

def main():
    # Get all MP3 files
    files = sorted([f for f in os.listdir(AUDIO_DIR) if f.endswith('.mp3')])
    print(f"Found {len(files)} audio files to transcribe.")
    
    transcriptions = {}
    
    for i, filename in enumerate(files):
        file_path = os.path.join(AUDIO_DIR, filename)
        print(f"[{i+1}/{len(files)}] Processing: {filename}")
        
        # Upload
        upload_url = upload_file(file_path)
        if not upload_url:
            continue
        
        # Transcribe
        text = transcribe(upload_url)
        if text:
            transcriptions[filename] = text
            print(f"  -> \"{text}\"")
        else:
            transcriptions[filename] = "[FAILED]"
            print(f"  -> FAILED")
        
        # Save progress periodically
        if (i + 1) % 10 == 0:
            with open(OUTPUT_FILE, 'w') as f:
                json.dump(transcriptions, f, indent=2)
            print(f"  Saved progress ({i+1} files)")
    
    # Final save
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(transcriptions, f, indent=2)
    
    print(f"\nDone! Transcriptions saved to: {OUTPUT_FILE}")
    print(f"Successfully transcribed: {len([t for t in transcriptions.values() if t != '[FAILED]'])} files")

if __name__ == "__main__":
    main()
