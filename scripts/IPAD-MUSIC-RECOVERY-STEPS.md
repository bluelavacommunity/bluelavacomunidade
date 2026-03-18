# Recover music from your iPad — step-by-step

Do these steps in order. Don’t skip any.

---

## Part 1: Back up the iPad to your Mac

### Step 1.1 — Connect the iPad
- Plug the iPad into your Mac with the cable.
- Unlock the iPad.
- If a popup says **“Trust This Computer?”** → tap **Trust** and enter your iPad passcode.

### Step 1.2 — Open Finder
- Click the **Finder** icon in the Dock (the blue smiling face),  
  **or** click the desktop and press **Command + N** to open a new Finder window.

### Step 1.3 — Select your iPad
- In the **left sidebar** of the Finder window, under **Locations**, you should see your **iPad’s name**.
- Click your **iPad’s name** once.

### Step 1.4 — Set backup to “this Mac”
- The main part of the window will show your iPad’s info.
- Find the line that says something like: **“Back up all of the data on your iPad to this Mac”**.
- If you see a choice between **“This Mac”** and **“iCloud”**, make sure **“This Mac”** is selected.

### Step 1.5 — Turn OFF encryption
- Look for an option like **“Encrypt local backup”**.
- **Leave the box UNCHECKED** (no tick).  
  If it’s checked, click it once to turn it off.

### Step 1.6 — Start the backup
- Click the blue button **“Back Up Now”**.
- Wait until it finishes. It can take a long time (many minutes).  
  You’ll see progress on the same screen. Do **not** unplug the iPad until it says the backup is done.

---

## Part 2: See what’s in the backup (optional check)

### Step 2.1 — Open Terminal
- Press **Command + Space**, type **Terminal**, then press **Enter**.  
  A window with a black or white background and text will open.

### Step 2.2 — Go to your project folder
- Copy this line (without the quote marks), paste it into Terminal, then press **Enter**:

```bash
cd ~/Documents/GitHub/bluelava-community
```

### Step 2.3 — Run the “scan” to see if there is any music
- Copy this line, paste it into Terminal, then press **Enter**:

```bash
./scripts/extract-music-from-ipad-backup.sh --scan
```

- Wait until it finishes. It will print:
  - A list of file types in the backup.
  - A line like: **“Files detected as audio by magic bytes (m4a/mp3): X”**.

- **If X is 0:**  
  The backup has no normal music files (often the case if you only use Apple Music streaming). You can stop here; the next steps won’t find songs to copy.

- **If X is greater than 0:**  
  There is music in the backup. Continue to Part 3.

---

## Part 3: Copy the music to your Mac

### Step 3.1 — Make sure you’re still in the right folder
- In Terminal, run (copy, paste, Enter):

```bash
cd ~/Documents/GitHub/bluelava-community
```

### Step 3.2 — Run the extraction script
- Copy this line, paste it into Terminal, then press **Enter**:

```bash
./scripts/extract-music-from-ipad-backup.sh
```

- Wait until it finishes. It will say how many files were copied (e.g. “.m4a: 50”, “.mp3: 0”).

### Step 3.3 — Find the recovered music on your Desktop
- On your **Desktop** you should see a folder named **“Recovered Music”**.
- Open it and check that there are audio files inside.

---

## Part 4: Put the music in the Music app

### Step 4.1 — Open the Music app
- Open **Music** (the app with the musical note icon).

### Step 4.2 — Import the folder
- In the menu bar, click **File**.
- Click **Import…**.
- In the window that opens, go to your **Desktop** and select the **“Recovered Music”** folder.
- Click **Open** (or **Import**).  
  Music will add all the songs from that folder to your library.

### Step 4.3 — Remove duplicates (optional)
- In the menu bar: **File** → **Library** → **Show Duplicate Items**.
- In the list that appears, you can delete duplicates so you don’t have the same song twice.

---

## Part 5: Sync music back to the iPad (optional)

Only do this if you want these recovered songs on your iPad again.

### Step 5.1 — Connect the iPad
- Plug the iPad into the Mac again and unlock it.

### Step 5.2 — Open Finder and select the iPad
- Open **Finder** and click your **iPad** in the left sidebar.

### Step 5.3 — Turn on music sync
- In the top bar, click **Music** (or find the **Music** section for your iPad).
- Turn **on** the option like **“Sync music onto [your iPad name]”**.
- Click **Apply** and wait for the sync to finish.

---

## Quick reference — order of steps

| Part | What you do |
|------|------------------|
| 1    | Back up iPad in Finder (unencrypted). |
| 2    | In Terminal: `cd ~/Documents/GitHub/bluelava-community` then `./scripts/extract-music-from-ipad-backup.sh --scan` to see if there’s music. |
| 3    | In Terminal: `./scripts/extract-music-from-ipad-backup.sh` to copy music to Desktop → **Recovered Music**. |
| 4    | In Music app: **File → Import** → choose **Recovered Music** folder. |
| 5    | (Optional) In Finder: iPad → Music → Sync music onto iPad → **Apply**. |

If anything doesn’t look like what’s described (e.g. you don’t see “Back Up Now” or “Recovered Music”), say which step number you’re on and what you see, and we can fix it.
