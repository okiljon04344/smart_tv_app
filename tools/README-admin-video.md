# Admin Video CLI (Realtime Database)

Use from project root.

## Add video

```powershell
./tools/admin-video.ps1 add -Id 101 -Category cat_popular -Title "My Video" -Genre "Sci-Fi" -Year "2026" -Rating "8.7" -Duration "1:44" -YoutubeId "aqz-KE-bpKQ" -IsNew:$true
```

## Update video

```powershell
./tools/admin-video.ps1 update -Id 101 -Title "My Video Updated" -Category cat_recommended -YoutubeUrl "https://www.youtube.com/watch?v=5PSNL1qE6VY"
```

## Delete video

```powershell
./tools/admin-video.ps1 delete -Id 101
```

Notes:
- The script updates `/movies/{id}`.
- On add/update, it ensures the video id exists in `/categories/{category}/items`.
- On delete, it removes the id from all category lists.
- Requires Firebase CLI login and active project alias.
