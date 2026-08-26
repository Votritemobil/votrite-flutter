# App Store listing assets

Screenshots for the iOS App Store listing (app id 1526084390), at 1290x2796 --
Apple's 6.7"/6.9" iPhone size. Upload in the numbered order; the first three are
what appears in search results.

These are captures of the **real app**, not mockups. `capture.py` drives the
existing `build/web` bundle through a complete ballot in headless Chromium while
`mockapi.py` stands in for the API on 127.0.0.1:8972 (the URL that build was
compiled against), so nothing touches production and no vote is ever cast. The
election, candidates and PIN in `mockdata.py` are invented. `compose.py` then
puts the headline and the background around each raw screen.

To regenerate after a UI change:

    python3 mockapi.py &
    (cd ../../../build/web && python3 -m http.server 8899) &
    python3 capture.py 8899 normal && python3 capture.py 8899 pin && python3 capture.py 8899 vi
    python3 compose.py

`description.txt` is the App Store description. Name, subtitle, keywords,
promotional text and the category recommendation are written up at
https://votritemobil.com/r-1sjm31kz/appstore-listing.html
