# =============================================================================
# 1. SELECTION CHECK & INITIAL SETTINGS
# =============================================================================
# Check if exactly two Sound objects are selected in the object list.
# Object 1 (top) must be the 'burst' (the sharp release click part).
# Object 2 (bottom) must be the 'vowel' (the vocalic portion).
num = numberOfSelected("Sound")
if num <> 2
    exitScript: "Error: Please select exactly 2 Sound objects (1st: burst, 2nd: vowel)."
endif

# Store the IDs of the selected original sounds into variables for easy reference
burst_id = selected("Sound", 1)
vowel_id = selected("Sound", 2)

# Get the sampling frequency (Hz) of the burst to match it with the generated silence later
selectObject: burst_id
fs = Get sampling frequency

# =============================================================================
# 2. OUTPUT DESTINATION SELECTION
# =============================================================================
# Prompt the user to select the folder where the generated WAV files will be saved
directory$ = chooseDirectory$ ("Select the output folder")
if directory$ = ""
    exitScript: "Script aborted: No folder was selected."
endif

# =============================================================================
# 3. CONTINUUM GENERATION LOOP (Creates 9 Stimuli)
# =============================================================================
# Loop 9 times to generate a VOT continuum consisting of 9 step-by-step stimuli
for i from 1 to 9
    # --- Calculate Voice Onset Time (VOT) ---
    # Current setting increases the VOT by 20 ms per step.
    # (e.g., stim1 = 0ms, stim2 = 20ms, stim3 = 40ms ... stim9 = 160ms)
    # Customize the multiplier below if needed (e.g., * 5 for 5ms steps, * 10 for 10ms steps)
    vot_ms = (i - 1) * 20
    vot_sec = vot_ms / 1000

    # Praat cannot create an audio object with a duration of exactly 0 seconds.
    # For the first stimulus (0ms VOT), we apply a microscopic duration (0.1ms) to prevent errors.
    if vot_sec <= 0
        vot_sec = 0.0001
    endif

    # --- Duplicate the Burst Component ---
    # Create a temporary copy of the burst so the original sound is safe from deletion
    selectObject: burst_id
    Copy: "burst_tmp"
    burst_tmp_id = selected("Sound", 1)

    # --- Generate the Silence Segment ---
    # Create a silent audio object from a formula ("0" means absolute silence).
    # The duration dynamically changes based on the calculated 'vot_sec' for each trial.
    silence_id = Create Sound from formula: "silence_tmp", 1, 0, vot_sec, fs, "0"

    # --- Duplicate the Vowel Component ---
    # Create a temporary copy of the vowel for the concatenation process
    selectObject: vowel_id
    Copy: "vowel_tmp"
    vowel_tmp_id = selected("Sound", 1)

    # --- Combine Components ---
    # Chain the audio pieces together in the precise structural order: Burst -> Silence -> Vowel
    selectObject: burst_tmp_id
    plusObject: silence_id
    plusObject: vowel_tmp_id
    Concatenate
    combined_id = selected("Sound", 1)

    # --- Export to WAV File ---
    # Save the combined sound into the chosen folder as "stim1.wav" through "stim9.wav"
    selectObject: combined_id
    filename$ = directory$ + "/stim" + string$(i) + ".wav"
    Save as WAV file: filename$

    # --- Clean Up Temporary Objects ---
    # Remove the temporary copies and intermediate silence to keep the Praat Objects window clean
    selectObject: burst_tmp_id
    plusObject: silence_id
    plusObject: vowel_tmp_id
    plusObject: combined_id
    Remove
endfor

# Notify the user of successful completion
appendInfoLine: "Process Complete! stim1.wav through stim9.wav have been generated successfully."