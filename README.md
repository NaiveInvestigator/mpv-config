# mpv-config
My personal mpv config for linux :> (Tested only on KDE Wayland)

# Preview
A preview of how this config looks:
### User Interface (UOSC)
| **Full UI when watching local videos** | **Full UI when streaming videos** |
| :-: | :-: |
| ![image](https://user-images.githubusercontent.com/72654596/219562727-ed56a3d9-898b-4160-b2e0-61a7ea59965a.png) | ![image](https://user-images.githubusercontent.com/72654596/223330203-b9263b59-8af2-4bd2-933c-085faba5faa2.png)   |
| **Mouse hovering over timeline** | **At idle** |
| ![image](https://user-images.githubusercontent.com/72654596/219563959-ac3dc446-4a44-4dbe-9d4b-2687c82ff391.png) | ![image](https://github.com/NaiveInvestigator/mpv-config/assets/72654596/c17662a0-0bf1-48b7-bc65-a25a92c752dc)    |
### Linux integration
![image](https://github.com/NaiveInvestigator/mpv-config/assets/72654596/270afa3a-6b82-4537-94ed-7bed8c626b93)

# Requirements
Make sure to install them with your respective package manager or add them to your [path](https://www.howtogeek.com/658904/how-to-add-a-directory-to-your-path-in-linux).
* [python](https://www.python.org/downloads)
* [ffmpeg](https://ffmpeg.org)
* [alass](https://github.com/kaegi/alass)
* [ffsubsync](https://github.com/smacke/ffsubsync)
* [Subliminal](https://github.com/Diaoul/subliminal)
* [yt-dlp](https://github.com/yt-dlp/yt-dlp)
# Installation Instructions

*  Put the commands in this order. (I only tested these commands on bash. Should work on other shells too.)
   ```sh
    mkdir ~/.config/mpv
    cd ~/.config/mpv
    git clone https://github.com/NaiveInvestigator/mpv-config -b linux
    ```
* Additional cool scripts you can try setting up! 

  Edit the following scripts/folders and read their respective readme to see how to properly configure them for your system:
  * [autosubsync](https://github.com/joaquintorres/autosubsync-mpv)
  * [autosub.lua](https://github.com/davidde/mpv-autosub)
  * [mpv-remote-node](https://github.com/husudosu/mpv-remote-node) (Check out [KDEConnect](https://kdeconnect.kde.org) instead if you haven't)
  * [webtorrent-mpv-hook](https://github.com/mrxdst/webtorrent-mpv-hook) (not in this repo because of how it is setup)
