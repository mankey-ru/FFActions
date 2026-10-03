# Explorer context menu layout, the single source for both menus:
#   - FFActions.iss generates the installer's "FFActions" menu from it at compile time
#   - dev\dev_menu.ps1 registers the "FFActionsDev" menu from it
# Item order here is the order in the submenu. A '-' entry starts a new group: the
# separator goes before the first item of the group that is actually written for an
# extension, so skipped components never leave leading, trailing or doubled separators.
#   Label      - menu text
#   Exe        - file name in actions\
#   Icon       - file name in tools\icons\icones menus\ (optional)
#   Component  - installer component the item belongs to
#   AllUsers   - installer also writes the item to HKLM (optional)
#   Extensions - per-item override of the family extensions (optional)
# Groups: edit the file itself / convert to another file / take a part out / info.
@{
    Families = @(
        @{
            Name       = 'video'
            Extensions = @('.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v')
            Items      = @(
                @{ Label = 'Cut Video';      Exe = 'cut_video.exe';            Icon = 'cut_video_audio_icon.ico';              Component = 'video\cut_video' }
                @{ Label = 'Crop Video';     Exe = 'crop_video.exe';           Icon = 'crop_video_image_icon.ico';             Component = 'video\crop_video' }
                @{ Label = 'Resize Video';   Exe = 'resize_video.exe';         Icon = 'resize_image_video_icon.ico';           Component = 'video\resize_video'; AllUsers = $true }
                @{ Label = 'Rotate / Flip';  Exe = 'rotate_video.exe';         Icon = 'rotate_video_image_icon.ico';           Component = 'video\rotate' }
                @{ Label = 'Change Speed';   Exe = 'change_video_speed.exe';   Icon = 'change.speed_audio_icon.ico';           Component = 'video\change_speed'; AllUsers = $true }
                @{ Label = 'Interpolate';    Exe = 'interpolate.exe';          Icon = 'interpolate_video_icon.ico';            Component = 'video\interpolate' }
                '-'
                @{ Label = 'Convert';        Exe = 'convert_video_picker.exe'; Icon = 'convert_audio_video_image_icon.ico';    Component = 'video\convert' }
                @{ Label = 'Compress Video'; Exe = 'compress_video.exe';       Icon = 'compress_video_image_audio_icon.ico';   Component = 'video\compress' }
                @{ Label = 'Create GIF';     Exe = 'create_gif.exe';           Icon = 'create.gif_video_icon.ico';             Component = 'video\create_gif' }
                '-'
                @{ Label = 'Extract Audio';  Exe = 'extract_audio_picker.exe'; Icon = 'extract.audio_video_icon.ico';          Component = 'video\extract_audio' }
                @{ Label = 'Extract Frames'; Exe = 'extract_frames.exe';       Icon = 'extract.frames_video_icon.ico';         Component = 'video\extract_frames' }
                @{ Label = 'Remove Audio';   Exe = 'remove_audio.exe';         Icon = 'remove.audio_video_icon.ico';           Component = 'video\remove_audio' }
                '-'
                @{ Label = 'Media Info';     Exe = 'media_info.exe';           Icon = 'media.info_video_image_audio_icon.ico'; Component = 'video\media_info' }
            )
        }
        @{
            Name       = 'audio'
            Extensions = @('.wav', '.mp3', '.flac', '.m4a', '.ogg')
            Items      = @(
                @{ Label = 'Cut Audio';      Exe = 'cut_audio.exe';            Icon = 'cut_video_audio_icon.ico';              Component = 'audio\cut_audio' }
                @{ Label = 'Change Speed';   Exe = 'change_audio_speed.exe';   Icon = 'change.speed_audio_icon.ico';           Component = 'audio\change_speed' }
                @{ Label = 'Change Pitch';   Exe = 'change_audio_pitch.exe';   Icon = 'change.pitch_audio_icon.ico';           Component = 'audio\change_pitch' }
                @{ Label = 'Reverse Audio';  Exe = 'reverse_audio.exe';        Icon = 'reverse.audio_audio_icon.ico';          Component = 'audio\reverse' }
                '-'
                @{ Label = 'Convert';        Exe = 'convert_audio_picker.exe'; Icon = 'convert_audio_video_image_icon.ico';    Component = 'audio\convert'; AllUsers = $true }
                @{ Label = 'Compress Audio'; Exe = 'compress_audio.exe';       Icon = 'compress_video_image_audio_icon.ico';   Component = 'audio\compress' }
                '-'
                @{ Label = 'Media Info';     Exe = 'media_info.exe';           Icon = 'media.info_video_image_audio_icon.ico'; Component = 'audio\media_info' }
            )
        }
        @{
            Name       = 'image'
            Extensions = @('.png', '.jpg', '.jpeg', '.bmp', '.webp')
            Items      = @(
                @{ Label = 'Crop Image';      Exe = 'crop_image.exe';           Icon = 'crop_video_image_icon.ico';             Component = 'image\crop' }
                @{ Label = 'Resize Image';    Exe = 'resize_image.exe';         Icon = 'resize_image_video_icon.ico';           Component = 'image\resize_image' }
                @{ Label = 'Rotate / Flip';   Exe = 'flip_image.exe';           Icon = 'rotate_video_image_icon.ico';           Component = 'image\flip' }
                '-'
                @{ Label = 'Convert';         Exe = 'convert_image_picker.exe'; Icon = 'convert_audio_video_image_icon.ico';    Component = 'image\convert'; AllUsers = $true }
                @{ Label = 'Compress Image';  Exe = 'compress_image.exe';       Icon = 'compress_video_image_audio_icon.ico';   Component = 'image\compress' }
                @{ Label = 'Convert to Icon'; Exe = 'convert_icon.exe';         Icon = 'convert.icon_image_icon.ico';           Component = 'image\icon' }
                @{ Label = 'Image to PDF';    Exe = 'image_to_pdf.exe';         Icon = 'image.to.pdf_image_icon.ico';           Component = 'image\image_to_pdf'; Extensions = @('.png', '.jpg', '.jpeg', '.bmp') }
                '-'
                @{ Label = 'Media Info';      Exe = 'media_info.exe';           Icon = 'media.info_video_image_audio_icon.ico'; Component = 'image\media_info' }
            )
        }
    )
}
